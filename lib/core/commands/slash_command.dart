/// A command shown in the slash-command palette.
///
/// Used by both GUI (Flutter) and TUI (Nocterm) interfaces.
/// This model lives in `core` so both can share the same business logic
/// without depending on presentation widgets.
class SlashCommand {
  final String name;
  final String description;

  /// Payload of a file-defined command; null for built-in commands.
  final String? template;
  final String? agent;
  final String? model;
  final String? variant;
  final bool? subtask;
  final List<String> hints;

  const SlashCommand(
    this.name,
    this.description, {
    this.template,
    this.agent,
    this.model,
    this.variant,
    this.subtask,
    this.hints = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlashCommand &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          template == other.template &&
          agent == other.agent &&
          model == other.model &&
          variant == other.variant &&
          subtask == other.subtask &&
          _listEquals(hints, other.hints);

  @override
  int get hashCode => Object.hash(
    name,
    description,
    template,
    agent,
    model,
    variant,
    subtask,
    Object.hashAll(hints),
  );

  @override
  String toString() => 'SlashCommand(name: $name, description: $description)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
