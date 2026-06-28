import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/filesystem_boundary.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FilesystemBoundary', () {
    late Directory workspace;

    setUp(() {
      workspace = Directory.current;
    });

    group('resolve — inside workspace', () {
      late FilesystemBoundary boundary;
      setUp(() => boundary = FilesystemBoundary(workspace: workspace));

      test('relative path resolves absolute inside workspace', () {
        final result = boundary.resolve('lib/main.dart');
        expect(result.isExternal, isFalse);
        expect(
          result.path,
          p.normalize(p.join(workspace.path, 'lib/main.dart')),
        );
        expect(result.externalRule, isNull);
      });

      test('absolute path inside workspace is not external', () {
        final absPath = p.join(workspace.path, 'lib', 'main.dart');
        final result = boundary.resolve(absPath);
        expect(result.isExternal, isFalse);
        expect(result.externalRule, isNull);
      });

      test('workspace root is not external', () {
        expect(
          FilesystemBoundary(
            workspace: workspace,
          ).resolve(workspace.path).isExternal,
          isFalse,
        );
      });
    });

    group('resolve — outside workspace', () {
      test('no rules -> external with ask', () {
        final boundary = FilesystemBoundary(workspace: workspace);
        expect(
          boundary.resolve('/tmp/ext_file.txt').externalRule,
          PermissionAction.ask,
        );
      });

      test('allow rule for specific external path', () {
        final boundary = FilesystemBoundary(
          workspace: workspace,
          externalDirectoryRules: {'/tmp/ext_allow': PermissionAction.allow},
        );
        expect(
          boundary.resolve(p.join('/tmp/ext_allow', 'file.txt')).externalRule,
          PermissionAction.allow,
        );
      });

      test('deny rule for specific external path', () {
        final boundary = FilesystemBoundary(
          workspace: workspace,
          externalDirectoryRules: {'/tmp/ext_deny': PermissionAction.deny},
        );
        expect(
          boundary.resolve(p.join('/tmp/ext_deny', 'file.txt')).externalRule,
          PermissionAction.deny,
        );
      });

      test('last-match-wins through wildcard suffix', () {
        final boundary = FilesystemBoundary(
          workspace: workspace,
          externalDirectoryRules: {
            p.join('/tmp/ext_lmw', '*'): PermissionAction.allow,
            p.join('/tmp/ext_lmw', 'secret*'): PermissionAction.deny,
          },
        );
        expect(
          boundary.resolve(p.join('/tmp/ext_lmw', 'doc.txt')).externalRule,
          PermissionAction.allow,
        );
      });

      test('exact match beats wildcard', () {
        final boundary = FilesystemBoundary(
          workspace: workspace,
          externalDirectoryRules: {
            p.join('/tmp/ext_lmw', '*'): PermissionAction.allow,
            p.join('/tmp/ext_lmw', 'secret.txt'): PermissionAction.deny,
          },
        );
        expect(
          boundary.resolve(p.join('/tmp/ext_lmw', 'secret.txt')).externalRule,
          PermissionAction.deny,
        );
      });

      test('tilde ~ expands to HOME', () {
        final home =
            Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            '/tmp';
        final boundary = FilesystemBoundary(
          workspace: workspace,
          externalDirectoryRules: {home: PermissionAction.ask},
        );
        final result = boundary.resolve('~/ext_file.txt');
        expect(result.isExternal, isTrue);
        expect(result.path, p.normalize(p.join(home, 'ext_file.txt')));
      });

      test('empty rules map defaults to ask', () {
        final boundary = FilesystemBoundary(
          workspace: workspace,
          externalDirectoryRules: const {},
        );
        expect(
          boundary.resolve('/tmp/any.txt').externalRule,
          PermissionAction.ask,
        );
      });
    });

    group('symlink resolution', () {
      tearDown(() {
        for (final dir in ['/tmp/realdir_sb_ft2', '/tmp/test_ws_sb_ft2']) {
          if (Directory(dir).existsSync()) {
            Directory(dir).deleteSync(recursive: true);
          }
        }
      });

      test('symlink outside workspace detected as external', () async {
        final realDir = Directory('/tmp/realdir_sb_ft2');
        realDir.createSync(recursive: true);

        final testWs = Directory('/tmp/test_ws_sb_ft2');
        testWs.createSync(recursive: true);

        final linkPath = p.join(testWs.path, 'escape');
        await Link(linkPath).create(realDir.path);

        final boundary = FilesystemBoundary(workspace: testWs);
        expect(
          boundary.resolve(p.join(linkPath, 'file.txt')).isExternal,
          isTrue,
        );

        await Link(linkPath).delete();
      });
    });

    group('class', () {
      test('default externalDirectoryRules is empty', () {
        expect(
          FilesystemBoundary(workspace: workspace).externalDirectoryRules,
          isEmpty,
        );
      });

      test('custom rules are stored', () {
        final rules = {'/tmp': PermissionAction.allow};
        expect(
          FilesystemBoundary(
            workspace: workspace,
            externalDirectoryRules: rules,
          ).externalDirectoryRules,
          equals(rules),
        );
      });

      test('workspace property returns the passed directory', () {
        expect(
          FilesystemBoundary(workspace: workspace).workspace.path,
          workspace.path,
        );
      });
    });
  });
}
