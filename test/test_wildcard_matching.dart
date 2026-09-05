import 'package:test/test.dart';
import 'package:chatorai/core/permission/wildcard.dart';
import 'package:chatorai/core/permission/evaluator.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';

/// Unit tests for wildcard matching and permission evaluation.
void main() {
  group('wildcard.match', () {
    group('exact matching', () {
      test('exact string matches', () {
        expect(match('hello', 'hello'), isTrue);
      });

      test('exact string mismatch', () {
        expect(match('hello', 'world'), isFalse);
      });

      test('case insensitive matching', () {
        expect(match('Hello', 'hello'), isTrue);
        expect(match('HELLO', 'hello'), isTrue);
      });
    });

    group('star wildcard (*)', () {
      test('star matches any characters', () {
        expect(match('hello world', 'hello*'), isTrue);
        expect(match('hello', 'hello*'), isTrue);
        expect(match('helloworld', 'hello*'), isTrue);
      });

      test('star at beginning', () {
        expect(match('hello world', '*world'), isTrue);
        expect(match('say hello world', '*world'), isTrue);
      });

      test('star in middle', () {
        expect(match('hello world', 'hello*world'), isTrue);
        expect(match('hello beautiful world', 'hello*world'), isTrue);
      });

      test('star matches empty', () {
        expect(match('hello', '*'), isTrue);
        expect(match('', '*'), isTrue);
      });

      test('multiple stars', () {
        expect(match('a b c', '*b*'), isTrue);
        expect(match('a c', '*b*'), isFalse);
      });
    });

    group('question mark wildcard (?)', () {
      test('question mark matches single character', () {
        expect(match('cat', 'c?t'), isTrue);
        expect(match('cot', 'c?t'), isTrue);
        expect(match('ct', 'c?t'), isFalse);
        expect(match('caat', 'c?t'), isFalse);
      });

      test('multiple question marks', () {
        expect(match('abc', 'a??'), isTrue);
        expect(match('ab', 'a??'), isFalse);
        expect(match('abcd', 'a??'), isFalse);
      });
    });

    group('path normalization', () {
      test('backslashes converted to forward slashes', () {
        expect(match(r'path\to\file', 'path/to/file'), isTrue);
      });

      test('mixed separators', () {
        expect(match(r'path/to\file', 'path/to/file'), isTrue);
      });
    });

    group('special regex characters escaped', () {
      test('dots are literal', () {
        expect(match('file.txt', 'file.txt'), isTrue);
        expect(match('fileXtxt', 'file.txt'), isFalse);
      });

      test('parentheses are literal', () {
        expect(match('func()', 'func()'), isTrue);
        expect(match('func', 'func()'), isFalse);
      });

      test('brackets are literal', () {
        expect(match('array[0]', 'array[0]'), isTrue);
        expect(match('array0', 'array[0]'), isFalse);
      });

      test('plus sign is literal', () {
        expect(match('a+b', 'a+b'), isTrue);
        expect(match('ab', 'a+b'), isFalse);
      });

      test('pipe is literal', () {
        expect(match('a|b', 'a|b'), isTrue);
        expect(match('ab', 'a|b'), isFalse);
      });
    });

    group('multiline matching', () {
      test('matches multiline input', () {
        expect(match('line1\nline2\nline3', 'line1*'), isTrue);
      });
    });

    group('edge cases', () {
      test('empty pattern matches empty input', () {
        expect(match('', ''), isTrue);
      });

      test('empty pattern does not match non-empty input', () {
        expect(match('hello', ''), isFalse);
      });

      test('complex pattern', () {
        expect(match('git commit -m "fix bug"', 'git commit*'), isTrue);
        expect(match('git status', 'git commit*'), isFalse);
      });
    });
  });

  group('evaluate', () {
    test('returns matching rule', () {
      final rulesets = [
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'read',
              pattern: '*.txt',
              action: PermissionAction.allow,
            ),
          ],
        ),
      ];

      final result = evaluate('read', 'file.txt', rulesets);
      expect(result.action, equals(PermissionAction.allow));
    });

    test('returns last matching rule (last-match-wins)', () {
      final rulesets = [
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'shell',
              pattern: '*',
              action: PermissionAction.allow,
            ),
            const PermissionRule(
              permission: 'shell',
              pattern: 'rm *',
              action: PermissionAction.deny,
            ),
          ],
        ),
      ];

      final result = evaluate('shell', 'rm -rf /', rulesets);
      expect(result.action, equals(PermissionAction.deny));
    });

    test('returns default ask when no rule matches', () {
      final rulesets = [PermissionRuleset(rules: [])];

      final result = evaluate('unknown', 'pattern', rulesets);
      expect(result.action, equals(PermissionAction.ask));
      expect(result.pattern, equals('*'));
    });

    test('sessionApproved rules take precedence over base rules', () {
      final rulesets = [
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'shell',
              pattern: '*',
              action: PermissionAction.deny,
            ),
          ],
          sessionApproved: [
            const PermissionRule(
              permission: 'shell',
              pattern: 'git *',
              action: PermissionAction.allow,
            ),
          ],
        ),
      ];

      // Session approved rule should win (it's last in the flat list)
      final result = evaluate('shell', 'git status', rulesets);
      expect(result.action, equals(PermissionAction.allow));
    });

    test('permission must match', () {
      final rulesets = [
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'read',
              pattern: '*',
              action: PermissionAction.allow,
            ),
          ],
        ),
      ];

      // Looking for 'shell' permission, but rule is for 'read'
      final result = evaluate('shell', 'anything', rulesets);
      expect(result.action, equals(PermissionAction.ask));
    });

    test('wildcard permission matches any', () {
      final rulesets = [
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: '*',
              pattern: '*',
              action: PermissionAction.deny,
            ),
          ],
        ),
      ];

      final result = evaluate('anything', 'anything', rulesets);
      expect(result.action, equals(PermissionAction.deny));
    });

    test('multiple rulesets are flattened', () {
      final rulesets = [
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'shell',
              pattern: '*',
              action: PermissionAction.allow,
            ),
          ],
        ),
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'shell',
              pattern: 'rm *',
              action: PermissionAction.deny,
            ),
          ],
        ),
      ];

      // Second ruleset's rule should win (last match)
      final result = evaluate('shell', 'rm -rf /', rulesets);
      expect(result.action, equals(PermissionAction.deny));
    });
  });
}
