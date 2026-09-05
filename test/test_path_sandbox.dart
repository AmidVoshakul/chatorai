import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:chatorai/shared/utils/path_sandbox.dart' hide contains;
import 'package:chatorai/shared/utils/hard_denied_paths.dart';
import 'package:chatorai/core/workspace/workspace_runtime.dart';

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

  group('isHardDeniedPath', () {
    test('returns true for /etc/shadow', () {
      expect(
        isHardDeniedPath('/etc/shadow', workspaceRuntimeCurrent.path),
        isTrue,
      );
    });

    test('returns true for ~/.ssh/id_rsa after normalization', () {
      expect(
        isHardDeniedPath('~/.ssh/id_rsa', workspaceRuntimeCurrent.path),
        isTrue,
      );
    });

    test('returns true for path containing /.ssh/', () {
      expect(
        isHardDeniedPath(
          '/home/user/.ssh/config',
          workspaceRuntimeCurrent.path,
        ),
        isTrue,
      );
    });

    test('returns true for path ending with /.ssh', () {
      expect(
        isHardDeniedPath('/home/user/.ssh', workspaceRuntimeCurrent.path),
        isTrue,
      );
    });

    test('returns true for windows/system32 path', () {
      expect(
        isHardDeniedPath(
          'C:/Windows/System32/cmd.exe',
          workspaceRuntimeCurrent.path,
        ),
        isTrue,
      );
    });

    test('returns true for windows\\system32 path', () {
      expect(
        isHardDeniedPath(
          'C:\\Windows\\System32\\cmd.exe',
          workspaceRuntimeCurrent.path,
        ),
        isTrue,
      );
    });

    test('returns true for authorized_keys', () {
      expect(
        isHardDeniedPath(
          '/home/user/.ssh/authorized_keys',
          workspaceRuntimeCurrent.path,
        ),
        isTrue,
      );
    });

    test('returns false for normal external path', () {
      expect(
        isHardDeniedPath('/tmp/foo.txt', workspaceRuntimeCurrent.path),
        isFalse,
      );
    });

    test('returns false for /etc/passwd', () {
      expect(
        isHardDeniedPath('/etc/passwd', workspaceRuntimeCurrent.path),
        isFalse,
      );
    });

    test('does not false-positive on authorized_keys substring', () {
      expect(
        isHardDeniedPath(
          '/home/user/my_authorized_keys_backup.txt',
          workspaceRuntimeCurrent.path,
        ),
        isFalse,
      );
    });

    test('returns true for authorized_keys2 (real ssh key file)', () {
      expect(
        isHardDeniedPath(
          '/home/user/.ssh/authorized_keys2',
          workspaceRuntimeCurrent.path,
        ),
        isTrue,
      );
    });

    test('returns true for Windows backslash .ssh path', () {
      expect(
        isHardDeniedPath(
          'C:\\Users\\me\\.ssh\\config',
          workspaceRuntimeCurrent.path,
        ),
        isTrue,
      );
    });
  });

  group('resolveSafePath', () {
    test('throws PathDeniedException for non-dangerous external path', () {
      expect(
        () => resolveSafePath('/tmp/foo.txt'),
        throwsA(isA<PathDeniedException>()),
      );
      try {
        resolveSafePath('/tmp/foo.txt');
      } on PathDeniedException catch (e) {
        expect(e.path, equals('/tmp/foo.txt'));
        expect(e.reason, equals('path outside workspace'));
        expect(e.hint, contains('Auto-Approve'));
      }
    });

    test('returns normalized path for project root', () {
      final projectRoot = Directory.current.path;
      final result = resolveSafePath(projectRoot);
      expect(result, equals(projectRoot));
    });

    test('returns normalized path for path inside project root', () {
      final projectRoot = Directory.current.path;
      final result = resolveSafePath('$projectRoot/subdir/file.txt');
      expect(result, contains('subdir/file.txt'));
    });

    test('returns normalized path for managedReadRoots', () {
      final roots = managedReadRoots;
      for (final root in roots) {
        final result = resolveSafePath(root, allowedRoots: roots);
        expect(result, equals(root));
      }
    });

    test('throws PathDeniedException for /etc/shadow with hint', () {
      expect(
        () => resolveSafePath('/etc/shadow'),
        throwsA(isA<PathDeniedException>()),
      );
      try {
        resolveSafePath('/etc/shadow');
      } on PathDeniedException catch (e) {
        expect(e.path, equals('/etc/shadow'));
        expect(e.reason, equals('protected system path'));
        expect(e.hint, contains('Auto-Approve'));
      }
    });

    test('normalizes ~ paths as before', () {
      final projectRoot = Directory.current.path;
      final result = resolveSafePath('~/subdir/file.txt');
      expect(result, equals('$projectRoot/subdir/file.txt'));
    });
  });

  group('isPathAllowed', () {
    test('allows project root path', () {
      final projectRoot = Directory.current.path;
      expect(isPathAllowed(projectRoot), isTrue);
    });

    test('denies non-dangerous external path', () {
      expect(isPathAllowed('/tmp/foo.txt'), isFalse);
    });

    test('denies dangerous system path without allowedRoots', () {
      expect(isPathAllowed('/etc/shadow'), isFalse);
    });
  });

  group('symlink escape', () {
    test(
      'resolveSafePath denies canonical path outside workspace via symlink',
      () async {
        // Symlinks can be unreliable in some test environments (e.g. Windows,
        // certain containers). Skip gracefully rather than failing.
        final canCreateSymlink = await _canCreateSymlink();
        if (!canCreateSymlink) {
          markTestSkipped('Symlinks not supported in this test environment');
          return;
        }

        final workspace = Directory.systemTemp.createTempSync(
          'chatorai_workspace_',
        );
        final outsideTarget = Directory.systemTemp.createTempSync(
          'chatorai_outside_',
        );
        final symlinkPath = p.join(workspace.path, 'link_to_outside');

        try {
          Link(symlinkPath).createSync(outsideTarget.path);
          final canonicalOutside = Link(symlinkPath).resolveSymbolicLinksSync();

          expect(
            () => resolveSafePath(canonicalOutside),
            throwsA(isA<PathDeniedException>()),
          );
        } finally {
          if (Link(symlinkPath).existsSync()) {
            Link(symlinkPath).deleteSync();
          }
          outsideTarget.deleteSync(recursive: true);
          workspace.deleteSync(recursive: true);
        }
      },
    );
  });
}

Future<bool> _canCreateSymlink() async {
  try {
    final temp = Directory.systemTemp.createTempSync('symlink_probe_');
    final target = p.join(temp.path, 'target');
    final link = p.join(temp.path, 'link');
    Directory(target).createSync();
    Link(link).createSync(target);
    final resolved = Link(link).resolveSymbolicLinksSync();
    final ok = resolved == target;
    if (Link(link).existsSync()) Link(link).deleteSync();
    Directory(target).deleteSync();
    temp.deleteSync();
    return ok;
  } on Exception {
    return false;
  }
}
