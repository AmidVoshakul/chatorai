import 'dart:io';

import 'package:chatorai/shared/utils/path_sandbox.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  setUp(() async {
    await XdgPaths.init();
  });

  group('resolveSafePath', () {
    test('denies absolute paths outside the project root', () {
      expect(() => resolveSafePath('/etc/passwd'), throwsArgumentError);
    });

    test('denies relative paths escaping the project root', () {
      expect(() => resolveSafePath('../secrets.txt'), throwsArgumentError);
    });

    test('allows files inside the project root', () {
      final inside = p.join(Directory.current.path, 'pubspec.yaml');
      expect(resolveSafePath(inside), equals(inside));
    });

    test(
      'allows the managed tool-output directory outside the project root',
      () {
        final root = XdgPaths.dataSubdirSync('tool-output').path;
        final inside = p.join(root, 'tool_123.txt');
        expect(
          resolveSafePath(inside, allowedRoots: managedReadRoots),
          equals(inside),
        );
      },
    );

    test('allows the managed root itself', () {
      final root = XdgPaths.dataSubdirSync('tool-output').path;
      expect(
        resolveSafePath(root, allowedRoots: managedReadRoots),
        equals(root),
      );
    });

    test('still denies unrelated external paths when roots are allowed', () {
      final root = XdgPaths.dataSubdirSync('tool-output').path;
      expect(
        () => resolveSafePath('/etc/passwd', allowedRoots: [root]),
        throwsArgumentError,
      );
    });
  });

  group('isPathAllowed', () {
    test('reflects allowedRoots', () {
      final root = XdgPaths.dataSubdirSync('tool-output').path;
      final inside = p.join(root, 'tool_123.txt');
      expect(isPathAllowed(inside, allowedRoots: managedReadRoots), isTrue);
      expect(
        isPathAllowed('/etc/passwd', allowedRoots: managedReadRoots),
        isFalse,
      );
    });
  });

  group('isWithinAnyRoot', () {
    test('matches paths inside any supplied root', () {
      final root = XdgPaths.dataSubdirSync('tool-output').path;
      final inside = p.join(root, 'tool_123.txt');
      expect(isWithinAnyRoot(inside, managedReadRoots), isTrue);
      expect(isWithinAnyRoot('/etc/passwd', managedReadRoots), isFalse);
    });

    test('rejects symlink escapes from a managed root', () {
      // Mirrors FilesystemBoundary.resolve(): the whitelist must be checked
      // against the *symlink-resolved* path, never the raw (string-wise) one.
      final root = XdgPaths.dataSubdirSync('tool-output').path;
      final link = p.join(root, 'escape_link');
      final target = '/etc/passwd';
      final linkEntity = Link(link);
      if (linkEntity.existsSync()) linkEntity.deleteSync();
      linkEntity.createSync(target);
      try {
        final resolved = linkEntity.resolveSymbolicLinksSync();
        expect(isWithinAnyRoot(resolved, managedReadRoots), isFalse);
      } finally {
        if (linkEntity.existsSync()) linkEntity.deleteSync();
      }
    });
  });
}
