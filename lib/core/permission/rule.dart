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

PermissionAction? resolveToolAction(dynamic value) {
  if (value is bool) {
    return value ? PermissionAction.allow : PermissionAction.deny;
  }
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'allow':
        return PermissionAction.allow;
      case 'ask':
        return PermissionAction.ask;
      case 'deny':
        return PermissionAction.deny;
    }
  }
  return null;
}
