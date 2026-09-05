import 'package:chatorai/core/config/models/permission_section.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';

import 'evaluator.dart';
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
          permission: 'read',
          pattern: '*.env',
          action: PermissionAction.ask,
        ),
        const PermissionRule(
          permission: 'read',
          pattern: '*.env.*',
          action: PermissionAction.ask,
        ),
        const PermissionRule(
          permission: 'read',
          pattern: '*.env.example',
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
          permission: 'shell',
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
          action: PermissionAction.deny,
        ),
        const PermissionRule(
          permission: 'question',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        const PermissionRule(
          permission: 'plan_enter',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        const PermissionRule(
          permission: 'plan_exit',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        const PermissionRule(
          permission: 'external_directory',
          pattern: '*',
          action: PermissionAction.ask,
        ),
        const PermissionRule(
          permission: 'todowrite',
          pattern: '*',
          action: PermissionAction.deny,
        ),
      ],
    );
  }
}

class PermissionRulesetCodec {
  static Map<String, dynamic>? toJson(PermissionRuleset? pr) {
    if (pr == null) return null;
    if (pr.rules.isEmpty && pr.sessionApproved.isEmpty) return null;
    return {
      'rules': pr.rules
          .map(
            (r) => {
              'permission': r.permission,
              'pattern': r.pattern,
              'action': r.action.name,
            },
          )
          .toList(),
      'sessionApproved': pr.sessionApproved
          .map(
            (r) => {
              'permission': r.permission,
              'pattern': r.pattern,
              'action': r.action.name,
            },
          )
          .toList(),
    };
  }

  static PermissionRuleset? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final rules = (json['rules'] as List<dynamic>?)
        ?.map((r) => _ruleFromJson(r as Map<String, dynamic>))
        .toList();
    final sessionApproved = (json['sessionApproved'] as List<dynamic>?)
        ?.map((r) => _ruleFromJson(r as Map<String, dynamic>))
        .toList();
    return PermissionRuleset(
      rules: rules ?? const [],
      sessionApproved: sessionApproved ?? const [],
    );
  }

  static PermissionRule _ruleFromJson(Map<String, dynamic> json) {
    final actionName = json['action'] as String?;
    PermissionAction action;
    if (actionName != null &&
        PermissionAction.values.any((a) => a.name == actionName)) {
      action = PermissionAction.values.byName(actionName);
    } else {
      action = PermissionAction.ask;
      LogTags.permission.logWarning(
        'Unknown permission action "$actionName", falling back to ask',
      );
    }
    return PermissionRule(
      permission: json['permission'] as String,
      pattern: json['pattern'] as String,
      action: action,
    );
  }
}

extension PermissionRulesetX on PermissionRuleset {
  bool isAllowed(String permission, String pattern) {
    return evaluate(permission, pattern, [this]).action ==
        PermissionAction.allow;
  }
}
