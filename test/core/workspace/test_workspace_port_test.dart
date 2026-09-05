import 'dart:io';

import 'package:chatorai/core/config/config_loader.dart';
import 'package:chatorai/core/workspace/workspace_port.dart';
import 'package:test/test.dart';

class FakeWorkspace implements WorkspacePort {
  @override
  final String currentPath;
  FakeWorkspace(this.currentPath);

  @override
  Directory get directory => Directory(currentPath);
}

void main() {
  group('WorkspacePort', () {
    test('exposes current path and directory', () {
      final workspace = FakeWorkspace('/tmp/demo');
      expect(workspace.currentPath, '/tmp/demo');
      expect(workspace.directory.path, '/tmp/demo');
    });

    test(
      'project config path follows the given workspace, not globals',
      () async {
        final workspace = FakeWorkspace('/tmp/demo-project');
        final resolved = await ConfigLoader.resolveConfigPath(
          global: false,
          projectRoot: workspace.directory,
        );
        expect(resolved, contains('/tmp/demo-project'));
        expect(resolved, contains('.chatorai'));
        expect(resolved, contains('chatorai.json'));
      },
    );

    test('different workspaces resolve different project configs', () async {
      final first = FakeWorkspace('/tmp/first');
      final second = FakeWorkspace('/tmp/second');
      final firstPath = await ConfigLoader.resolveConfigPath(
        global: false,
        projectRoot: first.directory,
      );
      final secondPath = await ConfigLoader.resolveConfigPath(
        global: false,
        projectRoot: second.directory,
      );
      expect(firstPath, isNot(equals(secondPath)));
    });
  });
}
