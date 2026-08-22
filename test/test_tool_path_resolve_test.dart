import 'dart:io';

import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/tool_path_resolve.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';
import 'package:chatorai/core/permission/wildcard.dart';

ToolContext _mockCtx({
  List<String>? askedPermissions,
  List<String>? askedPatterns,
}) {
  askedPermissions = askedPermissions;
  askedPatterns = askedPatterns;
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: 'test-session',
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {
          askedPermissions = [permission];
          askedPatterns = patterns;
        },
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );
}

void main() {
  group('resolveToolPath', () {
    test(
      'workspace path returns canonical path without asking external_directory',
      () async {
        final ctx = _mockCtx();
        final testFile = File(
          '${Directory.current.path}/test_resolve_tool_path.txt',
        );
        await testFile.writeAsString('test');

        final resolved = await resolveToolPath(
          ctx: ctx,
          userPath: testFile.path,
          toolName: 'read',
        );
        expect(resolved.isError, isFalse);
        expect(resolved.path, equals(testFile.path));
        testFile.deleteSync();
      },
    );

    test(
      'external non-dangerous path asks external_directory and returns path',
      () async {
        final ctx = _mockCtx();
        final target = '/tmp/chatorai_resolve_tool_path_test.txt';

        try {
          final resolved = await resolveToolPath(
            ctx: ctx,
            userPath: target,
            toolName: 'read',
          );
          expect(resolved.isError, isFalse);
          expect(resolved.path, equals(target));
        } finally {
          if (File(target).existsSync()) File(target).deleteSync();
        }
      },
    );

    test('path in managedReadRoots does not ask external_directory', () async {
      final ctx = _mockCtx();
      final roots = managedReadRoots;
      String? target;
      for (final root in roots) {
        final candidate = '$root/test_managed_read_root.txt';
        target = candidate;
        break;
      }
      if (target == null) {
        fail('No managedReadRoots available for test');
      }

      final resolved = await resolveToolPath(
        ctx: ctx,
        userPath: target,
        toolName: 'read',
      );
      expect(resolved.isError, isFalse);
      expect(resolved.path, isNotNull);
    });

    test(
      'dangerous path returns error without asking external_directory',
      () async {
        final ctx = _mockCtx();
        final resolved = await resolveToolPath(
          ctx: ctx,
          userPath: '/etc/shadow',
          toolName: 'read',
        );
        expect(resolved.isError, isTrue);
        expect(resolved.error, isNotNull);
        expect(resolved.error!.output, contains('Error:'));
        expect(resolved.error!.metadata?['error'], isTrue);
      },
    );

    test(
      'external file asks external_directory with dirname/* glob (recursive)',
      () async {
        final captured = <String>[];
        final ctx = ToolContext(
          toolCallId: 'test',
          sessionId: 'test',
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                captured.addAll(patterns);
              },
          askQuestion:
              ({
                required question,
                options = const [],
                multiple = false,
              }) async => '',
        );
        final target = '/tmp/chatorai_resolve_glob_test.txt';
        try {
          final resolved = await resolveToolPath(
            ctx: ctx,
            userPath: target,
            toolName: 'read',
          );
          expect(resolved.isError, isFalse);
          expect(resolved.path, equals(target));
          expect(captured, contains('/tmp/*'));
        } finally {
          if (File(target).existsSync()) File(target).deleteSync();
        }
      },
    );
  });

  group('externalDirectoryGlobPatterns', () {
    const workspace = '/home/user/project';

    test('file → grants dirname/* (recursive directory glob)', () {
      final patterns = externalDirectoryGlobPatterns(
        '/tmp/a/b',
        workspacePath: workspace,
        fallback: '/tmp/a/b/notes.txt',
      );
      expect(patterns, equals(['/tmp/a/b/*']));
    });

    test('filesystem root → exact path, no /* (over-broad guard)', () {
      final patterns = externalDirectoryGlobPatterns(
        '/', // dir == '/'
        workspacePath: workspace,
        fallback: '/rootfile.txt',
      );
      expect(patterns, equals(['/rootfile.txt']));
    });

    test('directory above workspace → exact path, no /*', () {
      final patterns = externalDirectoryGlobPatterns(
        '/home/user', // ancestor of /home/user/project
        workspacePath: workspace,
        fallback: '/home/user/notes.txt',
      );
      expect(patterns, equals(['/home/user/notes.txt']));
    });

    test('recursive coverage via wildcard.match', () {
      final glob = externalDirectoryGlobPatterns(
        '/tmp/a/b',
        workspacePath: workspace,
        fallback: '/tmp/a/b/notes.txt',
      ).single;
      expect(match('/tmp/a/b/notes.txt', glob), isTrue);
      expect(match('/tmp/a/b/sub/deep/file.txt', glob), isTrue);
      expect(match('/tmp/a/other.txt', glob), isFalse);
      expect(match('/tmp/a/b', glob), isFalse);
    });
  });
}
