import 'package:test/test.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/config/models/permission_section.dart';

/// Unit tests for PermissionRuleset and its config parsing.
void main() {
  group('PermissionRuleset.fromConfig', () {
    test('parses string action (allow)', () {
      final rules = PermissionRuleset.fromConfig({
        'read': 'allow',
      });

      expect(rules, hasLength(1));
      expect(rules[0].permission, equals('read'));
      expect(rules[0].pattern, equals('*'));
      expect(rules[0].action, equals(PermissionAction.allow));
    });

    test('parses string action (deny)', () {
      final rules = PermissionRuleset.fromConfig({
        'bash': 'deny',
      });

      expect(rules, hasLength(1));
      expect(rules[0].permission, equals('bash'));
      expect(rules[0].action, equals(PermissionAction.deny));
    });

    test('parses string action (ask)', () {
      final rules = PermissionRuleset.fromConfig({
        'edit': 'ask',
      });

      expect(rules, hasLength(1));
      expect(rules[0].permission, equals('edit'));
      expect(rules[0].action, equals(PermissionAction.ask));
    });

    test('parses map as patternActions (direct key-value)', () {
      // PermissionRuleConfig.fromJson treats a Map as patternActions directly.
      // Each key is a pattern, each value is an action.
      final rules = PermissionRuleset.fromConfig({
        'bash': {
          'git *': 'allow',
          'rm *': 'deny',
        },
      });

      expect(rules, hasLength(2));
      expect(rules[0].permission, equals('bash'));
      expect(rules[0].pattern, equals('git *'));
      expect(rules[0].action, equals(PermissionAction.allow));
      expect(rules[1].pattern, equals('rm *'));
      expect(rules[1].action, equals(PermissionAction.deny));
    });

    test('expands home directory in patterns', () {
      final rules = PermissionRuleset.fromConfig({
        'read': {
          '~/.ssh/*': 'deny',
        },
      });

      expect(rules, hasLength(1));
      // The ~ should be expanded to the home directory
      expect(rules[0].pattern, isNot(contains('~')));
      expect(rules[0].pattern, contains('/.ssh/'));
    });

    test('throws ArgumentError for unknown action string', () {
      expect(
        () => PermissionRuleset.fromConfig({
          'read': 'unknown_action',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for unknown action in pattern map', () {
      expect(
        () => PermissionRuleset.fromConfig({
          'read': {
            '*.txt': 'invalid',
          },
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handles empty config', () {
      final rules = PermissionRuleset.fromConfig({});
      expect(rules, isEmpty);
    });

    test('handles multiple permissions', () {
      final rules = PermissionRuleset.fromConfig({
        'read': 'allow',
        'bash': 'ask',
        'write': 'deny',
      });

      expect(rules, hasLength(3));
      expect(rules.map((r) => r.permission).toSet(),
          equals({'read', 'bash', 'write'}));
    });

    test('handles PermissionRuleConfig object with patternActions', () {
      final rules = PermissionRuleset.fromConfig({
        'read': PermissionRuleConfig(
          patternActions: {'*.secret': 'deny', '*.txt': 'allow'},
        ),
      });

      expect(rules, hasLength(2));
      expect(rules[0].action, equals(PermissionAction.deny));
      expect(rules[1].action, equals(PermissionAction.allow));
    });

    test('handles PermissionRuleConfig object with defaultAction', () {
      final rules = PermissionRuleset.fromConfig({
        'read': PermissionRuleConfig(
          defaultAction: 'allow',
        ),
      });

      expect(rules, hasLength(1));
      expect(rules[0].action, equals(PermissionAction.allow));
      expect(rules[0].pattern, equals('*'));
    });
  });

  group('PermissionRuleset.defaults', () {
    test('returns non-empty default rules', () {
      final defaults = PermissionRuleset.defaults();

      expect(defaults.rules, isNotEmpty);
    });

    test('defaults include read as allow', () {
      final defaults = PermissionRuleset.defaults();

      expect(
        defaults.rules.any(
          (r) =>
              r.permission == 'read' &&
              r.action == PermissionAction.allow,
        ),
        isTrue,
      );
    });

    test('defaults include bash as ask', () {
      final defaults = PermissionRuleset.defaults();

      expect(
        defaults.rules.any(
          (r) =>
              r.permission == 'bash' &&
              r.action == PermissionAction.ask,
        ),
        isTrue,
      );
    });

    test('defaults include webfetch as allow', () {
      final defaults = PermissionRuleset.defaults();

      expect(
        defaults.rules.any(
          (r) =>
              r.permission == 'webfetch' &&
              r.action == PermissionAction.allow,
        ),
        isTrue,
      );
    });
  });
}
