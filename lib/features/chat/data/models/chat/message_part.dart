// ── MessagePart base types ───────────────────────────────────

enum ToolState { pending, running, completed, error }

// Note: Using `abstract` instead of `sealed` to allow subclasses
// across multiple files (split architecture).
// Existing switch-by-type patterns remain exhaustive.
abstract class MessagePart {
  const MessagePart();

  Map<String, dynamic> toJson();
}
