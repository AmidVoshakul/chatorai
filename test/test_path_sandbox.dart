import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';

void main() {
  group('path_sandbox managedReadRoots', () {
    test('includes tool-output directory', () {
      final roots = managedReadRoots;
      expect(roots.any((r) => r.contains('tool-output')), isTrue);
    });

    test('includes attachments directory', () {
      final roots = managedReadRoots;
      expect(roots.any((r) => r.contains('attachments')), isTrue);
    });

    test('has exactly 3 managed roots', () {
      final roots = managedReadRoots;
      expect(roots.length, 3);
    });
  });

  group('isWithinAnyRoot', () {
    test('returns true for path inside root', () {
      expect(
        isWithinAnyRoot('/data/app/tool-output/file.txt', [
          '/data/app/tool-output',
        ]),
        isTrue,
      );
    });

    test('returns false for path outside all roots', () {
      expect(
        isWithinAnyRoot('/etc/passwd', ['/data/app/tool-output']),
        isFalse,
      );
    });

    test('returns true for exact root match', () {
      expect(
        isWithinAnyRoot('/data/app/tool-output', ['/data/app/tool-output']),
        isTrue,
      );
    });
  });

  group('isPathAllowed', () {
    test('allows project root path', () {
      // Paths inside the current project root are allowed without allowedRoots
      final projectRoot = Directory.current.path;
      expect(isPathAllowed(projectRoot), isTrue);
    });

    test('denies path outside project root without allowedRoots', () {
      // /etc is outside the project root, so it should be denied
      expect(isPathAllowed('/etc/passwd'), isFalse);
    });
  });
}
