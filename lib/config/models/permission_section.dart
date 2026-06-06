/// Configuration for a single permission rule.
///
/// Supports two JSON shapes:
/// - String: `"allow"`, `"ask"`, or `"deny"` (default action for all patterns)
/// - Object: `{ "pattern": "action", ... }` (per-pattern actions)
class PermissionRuleConfig {
  final String? defaultAction;
  final Map<String, String>? patternActions;

  const PermissionRuleConfig({this.defaultAction, this.patternActions});

  factory PermissionRuleConfig.fromJson(dynamic value) {
    if (value is String) {
      return PermissionRuleConfig(defaultAction: value);
    }
    if (value is Map<String, dynamic>) {
      final actions = <String, String>{};
      for (final entry in value.entries) {
        if (entry.value is String) {
          actions[entry.key] = entry.value as String;
        }
      }
      return PermissionRuleConfig(patternActions: actions);
    }
    return const PermissionRuleConfig();
  }

  /// Returns either a String (for default action) or a Map (for pattern actions).
  dynamic toJson() {
    if (patternActions != null) {
      return patternActions!;
    }
    if (defaultAction != null) {
      return defaultAction!;
    }
    return {};
  }
}
