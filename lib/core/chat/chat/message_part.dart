// ── MessagePart base types ───────────────────────────────────

enum ToolState { pending, running, completed, error }

// Note: Using `abstract` instead of `sealed` to allow subclasses
// across multiple files (split architecture).
// Existing switch-by-type patterns remain exhaustive.
abstract class MessagePart {
  final bool synthetic;
  const MessagePart({this.synthetic = false});

  Map<String, dynamic> toJson();
}
