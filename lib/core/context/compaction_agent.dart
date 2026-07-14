import 'package:chatorai/core/context/completion_provider.dart';

/// Hidden compaction agent —  `compaction` agent contract.
///
/// defines this agent as:
/// - `mode: "primary"`, `native: true`, `hidden: true`
/// - `permission: Permission.merge(defaults, Permission.fromConfig({"*": "deny"}))`
/// — i.e. ALL tools are denied.
///
/// In ChatORAI the agent's "no tools" contract is enforced structurally:
/// [summarize] calls `generateCompletion` without passing `tools` or
/// `onToolStart`/`onToolEnd` callbacks — the LLM has zero tool access.
///
/// Use this class to:
/// 1. Make the no-tools contract explicit in the type system.
/// 2. Centralise the system prompt and temperature so they can be
///    referenced from `CompactionService` without duplication.
/// 3. Provide a seam for injecting a custom provider in tests.
class CompactionAgent {
  /// System prompt injected by [summarize].
  ///
  /// Mirrors `agent/prompt/compaction.txt` with the anchored
  /// summary update instruction.
  static const String systemPrompt =
      'You are an anchored context summarization assistant for coding sessions.\n'
      '\n'
      'Summarize only the conversation history you are given. The newest turns '
      'may be kept verbatim outside your summary, so focus on the older context '
      'that still matters for continuing the work.\n'
      '\n'
      'If the prompt includes a <previous-summary> block, treat it as the '
      'current anchored summary. Update it with the new history by preserving '
      'still-true details, removing stale details, and merging in new facts.\n'
      '\n'
      'Always follow the exact output structure requested by the user prompt. '
      'Keep every section, preserve exact file paths and identifiers when known, '
      'and prefer terse bullets over paragraphs.\n'
      '\n'
      'Do not answer the conversation itself. Do not mention that you are '
      'summarizing, compacting, or merging context. Respond in the same '
      'language as the conversation.';

  /// Fixed temperature for summarization — low temperature for determinism.
  static const double temperature = 0.3;

  /// Creates a compaction agent bound to [provider].
  ///
  /// Pass a custom provider in tests to avoid real LLM calls.
  const CompactionAgent(this.provider);

  /// The underlying LLM provider. No tools are ever attached to calls
  /// made through this agent.
  final CompletionProvider provider;

  /// Summarize [head] messages, optionally merging [previousSummary].
  ///
  /// permission contract.
  Future<String> summarize({
    required List<Map<String, dynamic>> head,
    String? previousSummary,
    required String model,
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

    return provider.generateCompletion(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': prompt},
      ],
      model: model,
      temperature: temperature,
    );
  }
}
