import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/context/compaction_agent.dart';
import 'package:chatorai/core/context/completion_provider.dart';
import 'package:chatorai/core/context/token_counter.dart';

///
/// Splits messages into head (old) + tail (recent), summarizes the head
/// via an LLM call, and returns [summary, ...tail] passed through [prune].
class CompactionService {
  /// Marker distinguishing a persisted compaction summary (system message
  /// produced by [CompactionAgent]) from ephemeral system prompts (agent
  /// prompt, user system prompt, project instructions) that the chat screen
  /// injects per API call via `_buildSystemChain()`.
  static const String _summaryMarker = '## Goal';

  final int tailTurns;
  final int pruneProtectTokens;
  final bool pruneEnabled;

  const CompactionService({
    this.tailTurns = 2,
    this.pruneProtectTokens = 40000,
    // Default MUST stay `false`: CompactionConfig.prune and the default
    // chatorai.json both disable pruning. A `true` default would enable
    // irreversible tool-output clearing for any session created without an
    // explicit config (e.g. via `const CompactionService()`).
    this.pruneEnabled = false,
  });

  /// Creates a [CompactionService] from [CompactionConfig].
  ///
  /// Falls back to hardcoded defaults for any missing/null config values.
  factory CompactionService.fromConfig(CompactionConfig config) {
    return CompactionService(
      tailTurns: config.tailTurns,
      pruneProtectTokens: config.buffer,
      pruneEnabled: config.prune,
    );
  }

  /// Returns the index where the tail starts (inclusive).
  ///
  /// Keeps the last [tailTurns] user–assistant pairs (4 messages when
  /// tailTurns=2).
  ///
  /// Returns 0 when the entire message list fits within the pairs budget.
  int _tailStart(List<Map<String, dynamic>> messages) {
    var pairs = 0;
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i]['role'] == 'assistant' || messages[i]['role'] == 'user') {
        pairs++;
      }
      if (pairs >= tailTurns * 2) return i;
    }
    return 0;
  }

  /// Run full compaction cycle.
  ///
  /// Splits messages into head (old) + tail (recent), summarizes the head
  /// via an LLM call, and returns [summary, ...tail] passed through [prune].
  Future<List<Map<String, dynamic>>> compact({
    required List<Map<String, dynamic>> messages,
    required CompletionProvider aiService,
    required String model,
  }) async {
    if (messages.length < 4) {
      return _stripEphemeralSystemPrompts(messages);
    }

    final tailIdx = _tailStart(messages);
    final head = messages.sublist(0, tailIdx);
    final tail = messages.sublist(tailIdx);

    if (head.isEmpty) {
      return _stripEphemeralSystemPrompts(messages);
    }

    // Compaction operates on conversation messages only — ephemeral system
    // prompts (agent prompt, user system prompt, project instructions) are
    // excluded before summarizing. System prompts are re-injected on every
    // API call and must not enter the persisted message history.
    final conversationHead = _stripEphemeralSystemPrompts(head);
    if (conversationHead.isEmpty) {
      return _stripEphemeralSystemPrompts(messages);
    }

    final previousSummary = _findPreviousSummary(messages);

    final summary = await _summarize(
      head: conversationHead,
      aiService: aiService,
      model: model,
      previousSummary: previousSummary,
    );

    // The freshly generated summary is preserved unconditionally; only the
    // tail is scanned for ephemeral system prompts (a safety net — the
    // prompts injected by `_buildSystemChain()` normally land in the head
    // and get summarized away).
    //
    // The summary is an assistant message from the hidden `compaction`
    // agent with metadata `agent: "compaction"` and `isCompactionSummary:
    // true`; it renders as a normal assistant bubble and can be deleted
    // like any other message.
    final result = [
      {
        'role': 'assistant',
        'content': summary,
        'isCompactionSummary': true,
        'agent': 'compaction',
      },
      ..._stripEphemeralSystemPrompts(tail),
    ];

    if (pruneEnabled) {
      return prune(result);
    }
    return result;
  }

  /// Find the last compaction summary — a message flagged with
  /// `isCompactionSummary`, with a fallback to legacy system messages
  /// starting with [_summaryMarker] (produced before summaries became
  /// assistant messages).
  String? _findPreviousSummary(List<Map<String, dynamic>> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m['isCompactionSummary'] == true) {
        final content = m['content'] as String? ?? '';
        if (content.isNotEmpty) return content;
        continue;
      }
      if (m['role'] == 'system') {
        final content = m['content'] as String? ?? '';
        if (content.startsWith(_summaryMarker)) return content;
      }
    }
    return null;
  }

  /// Removes ephemeral system prompts (agent prompt, user system prompt,
  /// project instructions) from [messages].
  ///
  /// These prompts are re-injected on every API call by the chat screen, so
  /// persisting them into `chat.messages` would leak them into the visible
  /// chat history. Compaction summaries are assistant messages flagged with
  /// `isCompactionSummary` and are never affected; legacy system-role
  /// summaries starting with [_summaryMarker] are kept for compatibility.
  List<Map<String, dynamic>> _stripEphemeralSystemPrompts(
    List<Map<String, dynamic>> messages,
  ) {
    return messages
        .where(
          (m) =>
              m['role'] != 'system' ||
              ((m['content'] as String? ?? '').startsWith(_summaryMarker)),
        )
        .toList();
  }

  /// Call LLM to produce an anchored summary of the head messages.
  ///
  /// Delegates to [CompactionAgent] — a built-in hidden agent whose
  /// permission contract is "no tools, no side effects". See
  /// [CompactionAgent] for the full contract.
  Future<String> _summarize({
    required List<Map<String, dynamic>> head,
    required CompletionProvider aiService,
    required String model,
    String? previousSummary,
  }) async {
    final agent = CompactionAgent(aiService);
    return agent.summarize(
      head: head,
      previousSummary: previousSummary,
      model: model,
    );
  }

  /// Prune old tool outputs, keeping the last [pruneProtectTokens] chars
  /// of accumulated content (~tokens × 4 via [TokenCounter.estimate]).
  ///
  /// Walks backwards through messages accumulating content length (chars).
  /// Messages older than the protect window with role 'tool' are
  /// replaced with a placeholder. Returns a new list without mutating
  /// the input.
  List<Map<String, dynamic>> prune(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return messages;

    var charsKept = 0;
    var pruneBefore = -1;
    for (var i = messages.length - 1; i >= 0; i--) {
      final content = messages[i]['content'] as String? ?? '';
      charsKept += content.length;
      if (charsKept > pruneProtectTokens) {
        pruneBefore = i;
        break;
      }
    }

    return messages.asMap().entries.map((entry) {
      final idx = entry.key;
      final msg = Map<String, dynamic>.from(entry.value);
      if (pruneBefore >= 0 && idx <= pruneBefore && msg['role'] == 'tool') {
        msg['content'] = '[Old tool result content cleared]';
      }
      return msg;
    }).toList();
  }
}
