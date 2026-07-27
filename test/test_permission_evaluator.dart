import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/core/permission/evaluator.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';

void main() {
  group('PermissionEvaluator.evaluate', () {
    test('default ask when no rule matches', () {
      final result = evaluate('unknown', '*.xyz', [
        PermissionRuleset.defaults(),
      ]);
      expect(result.action, equals(PermissionAction.ask));
    });

    test('allow wins when matched', () {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );
      final result = evaluate('read', '*.dart', [ruleset]);
      expect(result.action, equals(PermissionAction.allow));
    });

    test('deny takes precedence over ask', () {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.ask,
          ),
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      final result = evaluate('shell', 'git *', [ruleset]);
      expect(result.action, equals(PermissionAction.deny));
    });

    test('most-specific-wins (last match wins)', () {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.ask,
          ),
          const PermissionRule(
            permission: 'read',
            pattern: '*.secret',
            action: PermissionAction.deny,
          ),
        ],
      );
      final result = evaluate('read', '*.secret', [ruleset]);
      expect(result.action, equals(PermissionAction.deny));
    });

    test('sessionApproved overrides ask → allow', () {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'edit',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
        sessionApproved: [
          const PermissionRule(
            permission: 'edit',
            pattern: '*.dart',
            action: PermissionAction.allow,
          ),
        ],
      );
      final result = evaluate('edit', '*.dart', [ruleset]);
      expect(result.action, equals(PermissionAction.allow));
    });

    test('pattern expansion (~/ → home dir)', () {
      final home = Platform.environment['HOME'] ?? '/home/test';
      final ruleset = PermissionRuleset(
        rules: PermissionRuleset.fromConfig({
          'read': {'~/secret.txt': 'deny'},
        }),
      );
      final result = evaluate('read', '$home/secret.txt', [ruleset]);
      expect(result.action, equals(PermissionAction.deny));
    });
  });
}
