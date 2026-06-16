import 'package:test/test.dart';
import 'package:chatorai/core/permission/wildcard.dart';

void main() {
  group('Wildcard.match', () {
    test('match("src/main.dart", "*.dart") → true', () {
      expect(match('src/main.dart', '*.dart'), isTrue);
    });

    test('match("a_b", "a?b") → true (single-char wildcard)', () {
      expect(match('a_b', 'a?b'), isTrue);
    });

    test('match("git checkout main", "git *") → true (prefix)', () {
      expect(match('git checkout main', 'git *'), isTrue);
    });

    test('match("foo.ts", "*.ts") → true', () {
      expect(match('foo.ts', '*.ts'), isTrue);
    });

    test('match("src/index.ts", "*.ts") → true', () {
      expect(match('src/index.ts', '*.ts'), isTrue);
    });

    test('match("AB", "ab") → true (case insensitive)', () {
      expect(match('AB', 'ab'), isTrue);
    });

    test(r'match(r"a\b", "a/b") → true (normalize backslash → slash)', () {
      expect(match(r'a\b', 'a/b'), isTrue);
    });

    test('match("allow", "deny") → false', () {
      expect(match('allow', 'deny'), isFalse);
    });

    test('more specific pattern still matches if pattern is "git *"', () {
      expect(match('git branch', 'git *'), isTrue);
      expect(match('git status', 'git checkout *'), isFalse);
    });
  });
}
