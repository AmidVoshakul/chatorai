import 'package:chatorai/core/context/completion_provider.dart';

/// OpenCode-style context compaction.
///
/// When the token budget is exhausted, splits messages into
/// head (old) + tail (recent), summarizes the head via an LLM
/// call, and replaces the history with [summary, ...tail].
///
/// Afterwards prunes tool outputs older than 2 turns, keeping
/// the last 40k tokens.
class CompactionService {
  final int tailTurns;
  final int preserveRecentTokens;
  final int pruneProtectTokens;

  const CompactionService({
    this.tailTurns = 2,
    this.preserveRecentTokens = 8000,
    this.pruneProtectTokens = 40000,
  });

  /// Returns the index where the tail starts: last [tailTurns] user–assistant pairs.
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
  /// [messages] — current chat message list (Map role/content).
  /// [aiService] — used for the non-streaming summarizer LLM call.
  /// [model] — model ID for the summary.
  /// Returns a new message list with the compacted history.
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

    return _pruneToolOutputs(result);
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
  Future<String> _summarize({
    required List<Map<String, dynamic>> head,
    required CompletionProvider aiService,
    required String model,
    String? previousSummary,
  }) async {
    final headText = head
        .map((m) {
          final role = m['role'] ?? 'unknown';
          final content = m['content'] ?? '';
          return '[$role]: $content';
        })
        .join('\n\n');

    final prevBlock = previousSummary != null
        ? '<previous-summary>\n$previousSummary\n</previous-summary>\n\n'
        : '';

    final prompt =
        '''
$prevBlock## Goal
- Summarize the following conversation context concisely.

## Constraints & Preferences
- (none)

## Progress
### Done
- (extract from context)
### In Progress
- (extract from context)
### Blocked
- (extract from context)

## Key Decisions
- (extract from context)

## Next Steps
- (extract from context)

## Critical Context
- (extract from context)

## Relevant Files
- (extract from context)

## Raw conversation to summarize:
$headText
''';

    return aiService.generateCompletion(
      messages: [
        {
          'role': 'system',
          'content':
              'You are a context compaction agent. Summarize accurately and concisely.',
        },
        {'role': 'user', 'content': prompt},
      ],
      model: model,
      temperature: 0.3,
    );
  }

  /// Prune old tool outputs, keeping the last [pruneProtectTokens] chars.
  List<Map<String, dynamic>> _pruneToolOutputs(
    List<Map<String, dynamic>> messages,
  ) {
    // Find the index where tail starts protecting
    var charsKept = 0;
    var pruneBefore = 0;
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
      if (idx < pruneBefore && msg['role'] == 'tool') {
        msg['content'] = '[Old tool result content cleared]';
      }
      return msg;
    }).toList();
  }
}
