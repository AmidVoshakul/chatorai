/// Tracks in-flight tool calls so that every tool which received
/// `onToolStart` is guaranteed to receive a terminal event
/// (`onToolEnd` / `onToolError`).
///
/// The underlying `ai_sdk_dart` `streamText` step loop runs the tool calls of
/// a single assistant step sequentially. When a tool executor throws,
/// `_executeToolCall` rethrows, breaking the loop, so sibling tool calls that
/// come after the failing one are never executed and never emit a terminal
/// event — even though their `onToolStart` already fired. That left their
/// `AssistantTool` parts stuck in `ToolState.running` (infinite spinner in the
/// UI). This tracker restores the invariant by finalizing any tool that
/// started but never finished.
class ToolCallTracker {
  final Map<String, String> _started = {};

  /// Records that a tool call started. Idempotent per [toolCallId].
  void markStarted(String toolCallId, String toolName, DateTime startedAt) {
    _started[toolCallId] = toolName;
  }

  /// Records a successful completion for [toolCallId].
  void markEnded(String toolCallId) => _started.remove(toolCallId);

  /// Records a terminal error for [toolCallId].
  void markErrored(String toolCallId) => _started.remove(toolCallId);

  /// Invokes [onDangling] for every tool that started but never finished, then
  /// clears the dangling set so a repeated call is a no-op (idempotent).
  void finalizeDangling(
    void Function(String toolCallId, String toolName) onDangling,
  ) {
    for (final entry in _started.entries) {
      onDangling(entry.key, entry.value);
    }
    _started.clear();
  }

  /// Whether any tool started without a terminal event.
  bool get hasDangling => _started.isNotEmpty;

  /// Clears all tracked state without emitting anything.
  void clear() => _started.clear();
}
