class ToolPermissionRule {
  final String action;
  final List<String> patterns;
  final List<String> save;

  const ToolPermissionRule({
    required this.action,
    required this.patterns,
    this.save = const [],
  });
}
