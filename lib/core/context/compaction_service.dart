import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/context/compaction_agent.dart';
import 'package:chatorai/core/context/completion_provider.dart';
import 'package:chatorai/core/context/token_counter.dart';

///
/// Splits messages into head (old) + tail (recent), summarizes the head
/// via an LLM call, and returns [summary, ...tail] passed through [prune].
class CompactionService {
  final int tailTurns;
  final int preserveRecentTokens;
  final int pruneProtectTokens;

  const CompactionService({
    this.tailTurns = 2,
    this.preserveRecentTokens = 8000,
    this.pruneProtectTokens = 40000,
  });

  /// Creates a [CompactionService] from [CompactionConfig].
  ///
  /// Falls back to hardcoded defaults for any missing/null config values.
  factory CompactionService.fromConfig(CompactionConfig config) {
    return CompactionService(
      tailTurns: 2,
      preserveRecentTokens: config.keepTokens,
      pruneProtectTokens: config.buffer,
    );
  }

  /// Returns the index where the tail starts (inclusive).
  ///
  /// Keeps the last [tailTurns] user–assistant pairs (4 messages when
  /// tailTurns=2). The [preserveRecentTokens] budget is reserved for a
  /// future per-message token-aware selection pass; it does not affect
  /// the current pair-count behaviour.
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
    if (messages.length < 4) return messages;

    final tailIdx = _tailStart(messages);
    final head = messages.sublist(0, tailIdx);
    final tail = messages.sublist(tailIdx);

    if (head.isEmpty) return messages;

    final previousSummary = _findPreviousSummary(messages);

    final summary = await _summarize(
      head: head,
      aiService: aiService,
      model: model,
      previousSummary: previousSummary,
    );

    final result = [
      {'role': 'system', 'content': summary},
      ...tail,
    ];

    return prune(result);
  }

  /// Find the last compaction summary (system message starting with compaction marker).
  String? _findPreviousSummary(List<Map<String, dynamic>> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m['role'] == 'system') {
        final content = m['content'] as String? ?? '';
        if (content.startsWith('## Goal')) return content;
      }
    }
    return null;
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
