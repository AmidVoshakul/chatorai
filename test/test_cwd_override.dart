import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:chatorai/core/cli/cwd_override.dart';

void main() {
  group('detectCwdOverride', () {
    test('empty args returns no override with empty remainingArgs', () {
      final result = detectCwdOverride([]);
      expect(result.hasOverride, isFalse);
      expect(result.path, isNull);
      expect(result.remainingArgs, isEmpty);
    });

    test('flag arg returns no override and preserves remaining args', () {
      final result = detectCwdOverride(['--help']);
      expect(result.hasOverride, isFalse);
      expect(result.path, isNull);
      expect(result.remainingArgs, equals(['--help']));
    });

    test('non-existent path returns no override with original args', () {
      final result = detectCwdOverride([
        '/nonexistent/path/that/does/not/exist',
      ]);
      expect(result.hasOverride, isFalse);
      expect(result.path, isNull);
      expect(
        result.remainingArgs,
        equals(['/nonexistent/path/that/does/not/exist']),
      );
    });

    test('existing directory returns override with absolute path', () {
      final cwd = Directory.current.path;
      final result = detectCwdOverride([cwd]);
      expect(result.hasOverride, isTrue);
      expect(result.path, equals(p.absolute(cwd)));
      expect(result.remainingArgs, isEmpty);
    });

    test('path followed by args strips path and keeps remaining', () {
      final cwd = Directory.current.path;
      final result = detectCwdOverride([cwd, 'stats', '--days', '7']);
      expect(result.hasOverride, isTrue);
      expect(result.path, equals(p.absolute(cwd)));
      expect(result.remainingArgs, equals(['stats', '--days', '7']));
    });

    test('relative existing directory resolves to absolute path', () {
      final cwd = Directory.current.path;
      final result = detectCwdOverride(['.']);
      expect(result.hasOverride, isTrue);
      expect(result.path, equals(p.absolute(cwd)));
      expect(result.remainingArgs, isEmpty);
    });
  });

  group('IOOverrides — Directory.current inside zone', () {
    test('Directory.current reflects overridden cwd inside zone', () {
      final targetPath = Directory.current.path;

      IOOverrides.runZoned(() {
        expect(Directory.current.path, equals(targetPath));
      }, getCurrentDirectory: () => Directory(targetPath));

      expect(Directory.current.path, equals(targetPath));
    });
  });
}
