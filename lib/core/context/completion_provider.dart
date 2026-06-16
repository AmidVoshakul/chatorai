/// Minimal interface for a service that can generate non-streaming
/// LLM completions.  Placed in `core/context` so that
/// [CompactionService] does not need to import from `features/`.
abstract class CompletionProvider {
  Future<String> generateCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
  });
}
