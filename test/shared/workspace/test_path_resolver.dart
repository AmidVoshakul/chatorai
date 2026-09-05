import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/shared/workspace/path_resolver.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';
import 'package:chatorai/shared/utils/hard_denied_paths.dart';

void main() {
  group('PathResolver', () {
    late PathResolver resolver;

    setUp(() {
      resolver = PathResolver(
        workspace: Directory('/home/user/project'),
        managedRoots: {
          '/home/user/project',
          '/home/user/.local/share/chatorai/tool-output',
          '/home/user/.local/share/chatorai/attachments',
        },
      );
    });

    test('hard-deny: /etc/shadow is denied', () {
      expect(isHardDeniedPath('/etc/shadow', resolver.workspace.path), isTrue);
      expect(
        isHardDeniedPath('/etc/shadow/extra', resolver.workspace.path),
        isTrue,
      );
    });

    test('hard-deny: SSH private keys denied', () {
      expect(
        isHardDeniedPath('/home/user/.ssh/id_rsa', resolver.workspace.path),
        isTrue,
      );
      expect(
        isHardDeniedPath('/home/user/.ssh/id_ed25519', resolver.workspace.path),
        isTrue,
      );
      expect(
        isHardDeniedPath(
          '/home/user/.ssh/authorized_keys',
          resolver.workspace.path,
        ),
        isTrue,
      );
      expect(
        isHardDeniedPath(
          '/home/user/.ssh/authorized_keys2',
          resolver.workspace.path,
        ),
        isTrue,
      );
    });

    test('hard-deny: Windows system32 denied', () {
      expect(
        isHardDeniedPath(
          'C:\\Windows\\System32\\cmd.exe',
          resolver.workspace.path,
        ),
        isTrue,
      );
      expect(
        isHardDeniedPath(
          '/windows/system32/config/sam',
          resolver.workspace.path,
        ),
        isTrue,
      );
    });

    test('hard-deny: allowed paths pass', () {
      expect(
        isHardDeniedPath(
          '/home/user/project/file.txt',
          resolver.workspace.path,
        ),
        isFalse,
      );
      expect(
        isHardDeniedPath(
          '/home/user/Documents/file.txt',
          resolver.workspace.path,
        ),
        isFalse,
      );
      expect(
        isHardDeniedPath('/tmp/file.txt', resolver.workspace.path),
        isFalse,
      );
    });

    test('isExternal: inside workspace returns false', () {
      final resolution = resolver.resolve('/home/user/project/src/main.dart');
      expect(resolution.isExternal, isFalse);
    });

    test('isExternal: outside workspace returns true', () {
      final resolution = resolver.resolve('/etc/passwd');
      expect(resolution.isExternal, isTrue);
    });

    test('resolveSafePath: internal path returns as-is', () {
      final path = resolver.resolveSafePath('/home/user/project/file.txt');
      expect(path, '/home/user/project/file.txt');
    });

    test('resolveSafePath: managed root allowed', () {
      final path = resolver.resolveSafePath(
        '/home/user/.local/share/chatorai/tool-output/file.txt',
      );
      expect(path, '/home/user/.local/share/chatorai/tool-output/file.txt');
    });

    test('resolveSafePath: hard-denied throws', () {
      expect(
        () => resolver.resolveSafePath('/etc/shadow'),
        throwsA(isA<PathDeniedException>()),
      );
    });

    test('resolveSafePath: external not in managed throws', () {
      expect(
        () => resolver.resolveSafePath('/etc/passwd'),
        throwsA(isA<PathDeniedException>()),
      );
    });
  });
}
