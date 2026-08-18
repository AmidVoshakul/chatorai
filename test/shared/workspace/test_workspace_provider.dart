import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/shared/workspace/workspace_provider.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';

void main() {
  group('WorkspaceNotifier', () {
    late ProviderContainer container;
    late Directory originalCwd;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      originalCwd = Directory.current;
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    tearDown(() async {
      workspaceRuntimeCurrent = Directory.current;
    });

    group('init', () {
      test(
        'loads known list from prefs; prunes missing dirs; pins currentPath at index 0; persists pruned list',
        () async {
          final tempDir = Directory.systemTemp.createTempSync('ws_init_test_');
          final missingDir = '${tempDir.path}/missing';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('known_workspaces', [
            missingDir,
            tempDir.path,
          ]);

          final notifier = container.read(workspaceProvider.notifier);
          await notifier.init();

          final state = container.read(workspaceProvider);
          expect(state.initialized, isTrue);
          expect(state.currentPath, equals(Directory.current.path));
          expect(state.knownDirectories, contains(Directory.current.path));
          expect(state.knownDirectories, isNot(contains(missingDir)));

          final persisted = prefs.getStringList('known_workspaces') ?? [];
          expect(persisted, isNot(contains(missingDir)));
          expect(persisted.first, Directory.current.path);

          tempDir.deleteSync(recursive: true);
        },
      );

      test(
        'idempotent: second call does nothing, initialized stays true',
        () async {
          final notifier = container.read(workspaceProvider.notifier);
          await notifier.init();
          final state1 = container.read(workspaceProvider);

          await notifier.init();
          final state2 = container.read(workspaceProvider);

          expect(state2.initialized, isTrue);
          expect(state2.currentPath, equals(state1.currentPath));
          expect(state2.knownDirectories, equals(state1.knownDirectories));
        },
      );

      test('pins currentPath at index 0 even if absent from prefs', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'ws_init_pin_test_',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('known_workspaces', [tempDir.path]);

        final notifier = container.read(workspaceProvider.notifier);
        await notifier.init();

        final state = container.read(workspaceProvider);
        expect(state.knownDirectories.first, equals(Directory.current.path));
        expect(state.knownDirectories, contains(tempDir.path));

        tempDir.deleteSync(recursive: true);
      });
    });

    group('addDirectory', () {
      test('adds to list + persists', () async {
        final notifier = container.read(workspaceProvider.notifier);
        await notifier.init();

        final tempDir = Directory.systemTemp.createTempSync('ws_add_test_');
        await notifier.addDirectory(tempDir.path);

        final state = container.read(workspaceProvider);
        expect(state.knownDirectories, contains(tempDir.path));

        final prefs = await SharedPreferences.getInstance();
        final persisted = prefs.getStringList('known_workspaces') ?? [];
        expect(persisted, contains(tempDir.path));

        tempDir.deleteSync(recursive: true);
      });

      test('dedupe: adding same path twice -> one entry', () async {
        final notifier = container.read(workspaceProvider.notifier);
        await notifier.init();

        final tempDir = Directory.systemTemp.createTempSync('ws_dedup_test_');
        await notifier.addDirectory(tempDir.path);
        await notifier.addDirectory(tempDir.path);

        final state = container.read(workspaceProvider);
        expect(
          state.knownDirectories.where((p) => p == tempDir.path).length,
          equals(1),
        );

        final prefs = await SharedPreferences.getInstance();
        final persisted = prefs.getStringList('known_workspaces') ?? [];
        expect(persisted.where((p) => p == tempDir.path).length, equals(1));

        tempDir.deleteSync(recursive: true);
      });

      test('throws ArgumentError for non-existent path', () async {
        final notifier = container.read(workspaceProvider.notifier);
        await notifier.init();

        expect(
          () => notifier.addDirectory('/tmp/nonexistent_workspace_12345'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('removeDirectory', () {
      test('removes + persists', () async {
        final notifier = container.read(workspaceProvider.notifier);
        await notifier.init();

        final tempDir = Directory.systemTemp.createTempSync('ws_remove_test_');
        await notifier.addDirectory(tempDir.path);

        await notifier.removeDirectory(tempDir.path);

        final state = container.read(workspaceProvider);
        expect(state.knownDirectories, isNot(contains(tempDir.path)));

        final prefs = await SharedPreferences.getInstance();
        final persisted = prefs.getStringList('known_workspaces') ?? [];
        expect(persisted, isNot(contains(tempDir.path)));

        tempDir.deleteSync(recursive: true);
      });

      test('throws StateError when removing currentPath', () async {
        final notifier = container.read(workspaceProvider.notifier);
        await notifier.init();

        expect(
          () => notifier.removeDirectory(Directory.current.path),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('switchWorkspace', () {
      test(
        'sets workspaceRuntimeCurrent, persists lastWorkspacePrefsKey, pins new path first, updates state.currentPath',
        () async {
          final notifier = container.read(workspaceProvider.notifier);
          await notifier.init();

          final tempDir = Directory.systemTemp.createTempSync(
            'ws_switch_test_',
          );
          await notifier.switchWorkspace(tempDir.path);

          expect(workspaceRuntimeCurrent.path, equals(tempDir.path));

          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('last_workspace'), equals(tempDir.path));

          final state = container.read(workspaceProvider);
          expect(state.currentPath, equals(tempDir.path));
          expect(state.knownDirectories.first, equals(tempDir.path));

          tempDir.deleteSync(recursive: true);
        },
      );

      test('invalidates configProvider', () async {
        var configProviderExecutionCount = 0;
        final countingContainer = ProviderContainer(
          overrides: [
            configProvider.overrideWith((ref) async {
              configProviderExecutionCount++;
              return ChatOrAIConfig(version: 0, permission: {});
            }),
          ],
        );
        addTearDown(countingContainer.dispose);

        final notifier = countingContainer.read(workspaceProvider.notifier);
        await notifier.init();

        // Prime the provider
        await countingContainer.read(configProvider.future);
        final countBefore = configProviderExecutionCount;

        final tempDir = Directory.systemTemp.createTempSync('ws_inval_test_');
        await notifier.switchWorkspace(tempDir.path);

        // After invalidation, reading configProvider.future should re-execute
        final stateAfter = await countingContainer.read(configProvider.future);
        expect(stateAfter, isNotNull);
        expect(configProviderExecutionCount, greaterThan(countBefore));

        tempDir.deleteSync(recursive: true);
      });
    });

    group('pruneMissing', () {
      test(
        'removes deleted dirs + persists; keeps existing + current pinned',
        () async {
          final notifier = container.read(workspaceProvider.notifier);
          await notifier.init();

          final keepDir = Directory.systemTemp.createTempSync('ws_keep_');
          final deleteDir = Directory.systemTemp.createTempSync('ws_delete_');
          await notifier.addDirectory(keepDir.path);
          await notifier.addDirectory(deleteDir.path);

          // Delete one dir on disk.
          deleteDir.deleteSync(recursive: true);

          await notifier.pruneMissing();

          final state = container.read(workspaceProvider);
          expect(state.knownDirectories, contains(keepDir.path));
          expect(state.knownDirectories, isNot(contains(deleteDir.path)));
          expect(state.knownDirectories.first, equals(Directory.current.path));

          final prefs = await SharedPreferences.getInstance();
          final persisted = prefs.getStringList('known_workspaces') ?? [];
          expect(persisted, contains(keepDir.path));
          expect(persisted, isNot(contains(deleteDir.path)));
          expect(persisted.first, Directory.current.path);

          keepDir.deleteSync(recursive: true);
        },
      );

      test('does not touch currentPath', () async {
        final notifier = container.read(workspaceProvider.notifier);
        await notifier.init();

        final tempDir = Directory.systemTemp.createTempSync(
          'ws_current_prune_',
        );
        await notifier.switchWorkspace(tempDir.path);

        final missingDir = Directory.systemTemp.createTempSync(
          'ws_missing_prune_',
        );
        await notifier.addDirectory(missingDir.path);
        missingDir.deleteSync(recursive: true);

        await notifier.pruneMissing();

        final state = container.read(workspaceProvider);
        expect(state.currentPath, equals(tempDir.path));
        expect(state.knownDirectories.first, equals(tempDir.path));
        expect(state.knownDirectories, isNot(contains(missingDir.path)));

        tempDir.deleteSync(recursive: true);
      });
    });
  });
}
