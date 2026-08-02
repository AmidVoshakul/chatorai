import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/permission/evaluator.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/permission/wildcard.dart';
import 'package:chatorai/core/config/models/permission_section.dart';

void main() {
  // ── Wildcard.match ─────────────────────────────────────────────────────

  group('Wildcard.match', () {
    test('matches simple glob pattern (*.dart)', () {
      expect(match('src/main.dart', '*.dart'), isTrue);
      expect(match('foo.ts', '*.ts'), isTrue);
      expect(match('src/index.ts', '*.ts'), isTrue);
    });

    test('matches single-char wildcard (a?b)', () {
      expect(match('a_b', 'a?b'), isTrue);
      expect(match('axb', 'a?b'), isTrue);
      expect(match('ab', 'a?b'), isFalse);
    });

    test('matches prefix pattern (git *)', () {
      expect(match('git checkout main', 'git *'), isTrue);
      expect(match('git branch', 'git *'), isTrue);
      expect(match('git status', 'git *'), isTrue);
    });

    test('does not match wrong prefix', () {
      expect(match('git status', 'git checkout *'), isFalse);
    });

    test('case insensitive matching', () {
      expect(match('AB', 'ab'), isTrue);
      expect(match('Hello', 'hello'), isTrue);
      expect(match('READ', 'read'), isTrue);
    });

    test('normalizes backslash to forward slash', () {
      expect(match(r'a\b', 'a/b'), isTrue);
      expect(match(r'C:\Users\test', 'C:/Users/*'), isTrue);
    });

    test('returns false for non-matching patterns', () {
      expect(match('allow', 'deny'), isFalse);
      expect(match('hello', '*.dart'), isFalse);
      expect(match('foo.go', '*.ts'), isFalse);
    });

    test('escapes regex special characters in pattern', () {
      expect(match('file.txt', 'file.txt'), isTrue);
      expect(match('fileXtxt', 'file.txt'), isFalse);
      expect(match('a+b', 'a+b'), isTrue);
      expect(match('a[b]', 'a[b]'), isTrue);
    });

    test('pattern ending with * allows optional suffix', () {
      // "git *" in the pattern becomes "git .*" after escaping.
      // The wildcard.dart special-cases patterns ending with " .*"
      // to allow optional suffix matching.
      expect(match('git something', 'git *'), isTrue);
      // "git" alone should NOT match "git *" because the pattern
      // "git *" transforms to regex requiring at least one char after space
      // BUT the special case makes suffix optional → "git" matches too
      expect(match('git', 'git *'), isTrue);
    });

    test('exact match without wildcards', () {
      expect(match('hello', 'hello'), isTrue);
      expect(match('hello', 'world'), isFalse);
    });

    test('empty pattern matches empty input', () {
      expect(match('', ''), isTrue);
    });

    test('star matches any string', () {
      expect(match('anything', '*'), isTrue);
      expect(match('', '*'), isTrue);
    });

    test('question mark matches exactly one char', () {
      expect(match('a', '?'), isTrue);
      expect(match('', '?'), isFalse);
      expect(match('ab', '?'), isFalse);
    });

    test('multiline input with dotAll', () {
      expect(match('line1\nline2', 'line1*'), isTrue);
    });
  });

  // ── Evaluator.evaluate ─────────────────────────────────────────────────

  group('Evaluator.evaluate', () {
    test('returns default ask when no rule matches', () {
      final result = evaluate('unknown', '*.xyz', [
        PermissionRuleset.defaults(),
      ]);
      expect(result.action, equals(PermissionAction.ask));
    });

    test('returns allow when matched', () {
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

    test('last match wins over earlier match', () {
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

    test('deny takes precedence over ask when later', () {
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

    test('sessionApproved overrides rules', () {
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

    test('merges multiple rulesets into flat list', () {
      final ruleset1 = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );
      final ruleset2 = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'read',
            pattern: '*.env',
            action: PermissionAction.deny,
          ),
        ],
      );
      final result = evaluate('read', '*.env', [ruleset1, ruleset2]);
      expect(result.action, equals(PermissionAction.deny));
    });

    test('empty rulesets list returns default ask', () {
      final result = evaluate('anything', '* ', []);
      expect(result.action, equals(PermissionAction.ask));
      expect(result.pattern, equals('*'));
    });

    test('matches permission pattern using wildcard', () {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: '*',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      final result = evaluate('anything', 'whatever', [ruleset]);
      expect(result.action, equals(PermissionAction.deny));
    });
  });

  // ── PermissionRuleset.fromConfig ───────────────────────────────────────

  group('PermissionRuleset.fromConfig', () {
    test('parses string values as defaultAction', () {
      final rules = PermissionRuleset.fromConfig({'shell': 'ask'});
      expect(rules, hasLength(1));
      expect(rules[0].permission, equals('shell'));
      expect(rules[0].pattern, equals('*'));
      expect(rules[0].action, equals(PermissionAction.ask));
    });

    test('parses object values as patternActions', () {
      final rules = PermissionRuleset.fromConfig({
        'edit': {'*.dart': 'allow', '*.env': 'deny'},
      });
      expect(rules, hasLength(2));
      expect(
        rules.any(
          (r) =>
              r.pattern.contains('.dart') && r.action == PermissionAction.allow,
        ),
        isTrue,
      );
      expect(
        rules.any(
          (r) =>
              r.pattern.contains('.env') && r.action == PermissionAction.deny,
        ),
        isTrue,
      );
    });

    test('parses mixed default and pattern actions', () {
      final rules = PermissionRuleset.fromConfig({
        'shell': {'default': 'ask', 'git *': 'allow'},
      });
      // Should have default action + pattern action
      expect(rules.length, greaterThanOrEqualTo(2));
    });

    test('throws ArgumentError for invalid action string', () {
      expect(
        () => PermissionRuleset.fromConfig({'shell': 'invalid_action'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handles PermissionRuleConfig objects directly', () {
      final rules = PermissionRuleset.fromConfig({
        'read': PermissionRuleConfig(defaultAction: 'allow'),
      });
      expect(rules, hasLength(1));
      expect(rules[0].action, equals(PermissionAction.allow));
    });

    test('case-insensitive action parsing', () {
      final rules = PermissionRuleset.fromConfig({'shell': 'ALLOW'});
      expect(rules[0].action, equals(PermissionAction.allow));
    });

    test('empty config returns empty rules', () {
      final rules = PermissionRuleset.fromConfig({});
      expect(rules, isEmpty);
    });
  });

  // ── PermissionRuleset.defaults ─────────────────────────────────────────

  group('PermissionRuleset.defaults', () {
    test('returns 20 default rules', () {
      final defaults = PermissionRuleset.defaults();
      expect(defaults.rules, hasLength(20));
    });

    test('read is allowed by default', () {
      final defaults = PermissionRuleset.defaults();
      final readRule = defaults.rules.firstWhere((r) => r.permission == 'read');
      expect(readRule.action, equals(PermissionAction.allow));
    });

    test('*.env files require ask for read', () {
      final defaults = PermissionRuleset.defaults();
      final envRule = defaults.rules.firstWhere(
        (r) => r.permission == 'read' && r.pattern == '*.env',
      );
      expect(envRule.action, equals(PermissionAction.ask));
    });

    test('*.env.* files require ask for read', () {
      final defaults = PermissionRuleset.defaults();
      final envRule = defaults.rules.firstWhere(
        (r) => r.permission == 'read' && r.pattern == '*.env.*',
      );
      expect(envRule.action, equals(PermissionAction.ask));
    });

    test('*.env.example is allowed for read', () {
      final defaults = PermissionRuleset.defaults();
      final envRule = defaults.rules.firstWhere(
        (r) => r.permission == 'read' && r.pattern == '*.env.example',
      );
      expect(envRule.action, equals(PermissionAction.allow));
    });

    test('shell is ask by default (dangerous commands require approval)', () {
      final defaults = PermissionRuleset.defaults();
      final shellRule = defaults.rules.firstWhere(
        (r) => r.permission == 'shell',
      );
      expect(shellRule.action, equals(PermissionAction.ask));
    });

    test('edit is ask by default', () {
      final defaults = PermissionRuleset.defaults();
      final editRule = defaults.rules.firstWhere((r) => r.permission == 'edit');
      expect(editRule.action, equals(PermissionAction.ask));
    });

    test('write is ask by default', () {
      final defaults = PermissionRuleset.defaults();
      final writeRule = defaults.rules.firstWhere(
        (r) => r.permission == 'write',
      );
      expect(writeRule.action, equals(PermissionAction.ask));
    });

    test('webfetch is allowed by default', () {
      final defaults = PermissionRuleset.defaults();
      final rule = defaults.rules.firstWhere((r) => r.permission == 'webfetch');
      expect(rule.action, equals(PermissionAction.allow));
    });

    test('glob is allowed by default', () {
      final defaults = PermissionRuleset.defaults();
      final rule = defaults.rules.firstWhere((r) => r.permission == 'glob');
      expect(rule.action, equals(PermissionAction.allow));
    });

    test('question is denied by default', () {
      final defaults = PermissionRuleset.defaults();
      final rule = defaults.rules.firstWhere((r) => r.permission == 'question');
      expect(rule.action, equals(PermissionAction.deny));
    });

    test('task is denied by default', () {
      final defaults = PermissionRuleset.defaults();
      final rule = defaults.rules.firstWhere((r) => r.permission == 'task');
      expect(rule.action, equals(PermissionAction.deny));
    });

    test('default rules have empty sessionApproved', () {
      final defaults = PermissionRuleset.defaults();
      expect(defaults.sessionApproved, isEmpty);
    });
  });

  // ── PermissionRuleConfig.fromJson ──────────────────────────────────────

  group('PermissionRuleConfig.fromJson', () {
    test('parses string value as defaultAction', () {
      final config = PermissionRuleConfig.fromJson('allow');
      expect(config.defaultAction, equals('allow'));
      expect(config.patternActions, isNull);
    });

    test('parses map value as patternActions', () {
      final config = PermissionRuleConfig.fromJson({
        '*.dart': 'allow',
        '*.env': 'deny',
      });
      expect(config.defaultAction, isNull);
      expect(config.patternActions, isNotNull);
      expect(config.patternActions!['*.dart'], equals('allow'));
      expect(config.patternActions!['*.env'], equals('deny'));
    });

    test('returns empty config for unknown type', () {
      final config = PermissionRuleConfig.fromJson(42);
      expect(config.defaultAction, isNull);
      expect(config.patternActions, isNull);
    });
  });

  // ── PermissionRuleConfig.toJson ────────────────────────────────────────

  group('PermissionRuleConfig.toJson', () {
    test('returns string for defaultAction', () {
      const config = PermissionRuleConfig(defaultAction: 'ask');
      expect(config.toJson(), equals('ask'));
    });

    test('returns map for patternActions', () {
      const config = PermissionRuleConfig(patternActions: {'*.dart': 'allow'});
      expect(config.toJson(), equals({'*.dart': 'allow'}));
    });

    test('returns empty map for neither', () {
      const config = PermissionRuleConfig();
      expect(config.toJson(), equals({}));
    });
  });
}
