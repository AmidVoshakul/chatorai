import 'dart:io';

import 'package:chatorai/core/config/config_loader.dart';
import 'package:chatorai/shared/workspace/workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Fake workspace notifier: tests never touch the real CWD, known-workspaces
/// prefs, or the permission-service re-attach logic of
/// [WorkspaceNotifier.switchWorkspace].
class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  _FakeWorkspaceNotifier(this._path);

  final String _path;

  @override
  WorkspaceState build() => WorkspaceState(currentPath: _path);
}

void main() {
  group('ConfigScreen config loading', () {
    late Directory tmpDir;
    late ProviderContainer container;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('cfg_screen_');
      await Directory(p.join(tmpDir.path, '.chatorai')).create(recursive: true);
      await File(
        p.join(tmpDir.path, '.chatorai', 'chatorai.json'),
      ).writeAsString('{"project": true}');
    });

    tearDown(() async {
      container.dispose();
      if (await tmpDir.exists()) {
        await tmpDir.delete(recursive: true);
      }
    });

    test(
      'project scope resolves the current workspace .chatorai/chatorai.json path',
      () async {
        final currentPath = tmpDir.path;
        container = ProviderContainer(
          overrides: [
            workspaceProvider.overrideWith(
              () => _FakeWorkspaceNotifier(currentPath),
            ),
          ],
        );
        addTearDown(container.dispose);

        final projectPath = await ConfigLoader.resolveConfigPath(
          global: false,
          projectRoot: Directory(currentPath),
        );

        expect(projectPath, p.join(tmpDir.path, '.chatorai', 'chatorai.json'));
        expect(File(projectPath).existsSync(), isTrue);
      },
    );

    test(
      'switching workspace changes the resolved project config path',
      () async {
        final second = await Directory.systemTemp.createTemp('cfg_ws2_');
        addTearDown(() async {
          if (await second.exists()) await second.delete(recursive: true);
        });
        await Directory(
          p.join(second.path, '.chatorai'),
        ).create(recursive: true);
        await File(
          p.join(second.path, '.chatorai', 'chatorai.json'),
        ).writeAsString('{"second": true}');

        var currentPath = tmpDir.path;
        container = ProviderContainer(
          overrides: [
            workspaceProvider.overrideWith(
              () => _FakeWorkspaceNotifier(currentPath),
            ),
          ],
        );
        addTearDown(container.dispose);

        final firstPath = await ConfigLoader.resolveConfigPath(
          global: false,
          projectRoot: Directory(currentPath),
        );
        expect(firstPath, p.join(tmpDir.path, '.chatorai', 'chatorai.json'));

        currentPath = second.path;
        container = ProviderContainer(
          overrides: [
            workspaceProvider.overrideWith(
              () => _FakeWorkspaceNotifier(currentPath),
            ),
          ],
        );
        addTearDown(container.dispose);

        final secondPath = await ConfigLoader.resolveConfigPath(
          global: false,
          projectRoot: Directory(currentPath),
        );
        expect(secondPath, p.join(second.path, '.chatorai', 'chatorai.json'));
        expect(secondPath, isNot(equals(firstPath)));
        expect(File(secondPath).existsSync(), isTrue);
      },
    );

    test('global scope is independent of the workspace', () async {
      final currentPath = tmpDir.path;
      container = ProviderContainer(
        overrides: [
          workspaceProvider.overrideWith(
            () => _FakeWorkspaceNotifier(currentPath),
          ),
        ],
      );
      addTearDown(container.dispose);

      final globalPath = await ConfigLoader.resolveConfigPath(global: true);
      final projectPath = await ConfigLoader.resolveConfigPath(
        global: false,
        projectRoot: Directory(currentPath),
      );

      expect(globalPath, isNot(equals(projectPath)));
      expect(globalPath.endsWith('chatorai.json'), isTrue);
      expect(projectPath.endsWith('.chatorai/chatorai.json'), isTrue);
    });
  });
}
