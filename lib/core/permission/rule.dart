enum PermissionAction { allow, ask, deny }

class PermissionRule {
  final String permission; // "read", "edit", "bash", "webfetch", "*"
  final String pattern; // glob-like: ".env", "*.ts", "git *"
  final PermissionAction action;

  const PermissionRule({
    required this.permission,
    required this.pattern,
    required this.action,
  });
}
