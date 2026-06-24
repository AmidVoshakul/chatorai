import 'package:chatorai/core/config/models/permission_section.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';

import 'rule.dart';

class PermissionRuleset {
  final List<PermissionRule> rules;
  final List<PermissionRule> sessionApproved;

  const PermissionRuleset({
    this.rules = const [],
    this.sessionApproved = const [],
  });

  static List<PermissionRule> fromConfig(
    Map<String, dynamic> permissionConfig,
  ) {
    final rules = <PermissionRule>[];

    for (final entry in permissionConfig.entries) {
      final permission = entry.key;
      final value = entry.value;
      final config = value is PermissionRuleConfig
          ? value
          : PermissionRuleConfig.fromJson(value);

      if (config.defaultAction != null) {
        final action = _parseAction(config.defaultAction!);
        rules.add(
          PermissionRule(permission: permission, pattern: '*', action: action),
        );
      }
      if (config.patternActions != null) {
        for (final patternEntry in config.patternActions!.entries) {
          final action = _parseAction(patternEntry.value);
          final expandedPattern = _expandHome(patternEntry.key);
          rules.add(
            PermissionRule(
              permission: permission,
              pattern: expandedPattern,
              action: action,
            ),
          );
        }
      }
    }

    return rules;
  }

  static PermissionAction _parseAction(String value) {
    switch (value.toLowerCase()) {
      case 'allow':
        return PermissionAction.allow;
      case 'ask':
        return PermissionAction.ask;
      case 'deny':
        return PermissionAction.deny;
      default:
        throw ArgumentError('Unknown permission action: $value');
    }
  }

  static String _expandHome(String pattern) => XdgPaths.expandHome(pattern);

  static PermissionRuleset defaults() {
    return PermissionRuleset(
      rules: [
        const PermissionRule(
          permission: 'read',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        const PermissionRule(
          permission: 'glob',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        const PermissionRule(
          permission: 'grep',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        const PermissionRule(
          permission: 'bash',
          pattern: '*',
          action: PermissionAction.ask,
        ),
        const PermissionRule(
          permission: 'edit',
          pattern: '*',
          action: PermissionAction.ask,
        ),
        const PermissionRule(
          permission: 'write',
          pattern: '*',
          action: PermissionAction.ask,
        ),
        const PermissionRule(
          permission: 'webfetch',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        const PermissionRule(
          permission: 'websearch',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        const PermissionRule(
          permission: 'doom_loop',
          pattern: '*',
          action: PermissionAction.ask,
        ),
        const PermissionRule(
          permission: 'skill',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        const PermissionRule(
          permission: 'lsp',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        const PermissionRule(
          permission: 'task',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        const PermissionRule(
          permission: 'todowrite',
          pattern: '*',
          action: PermissionAction.allow,
        ),
      ],
    );
  }
}
