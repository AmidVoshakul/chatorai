import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/gui/features/settings/providers/auto_approve_provider.dart';
import 'package:chatorai/core/workspace/workspace_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AutoApproveNotifier', () {
    late Directory tempDir;
    late String configPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'chatorai_auto_approve_test_',
      );
      configPath = '${tempDir.path}/chatorai.json';
      // Write a minimal valid config so ConfigManager can load it.
      final initial = <String, dynamic>{
        'version': 1,
        'permission': <String, dynamic>{},
      };
      await File(
        configPath,
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(initial));
      // Override workspace cwd so project-scope path resolves inside tempDir.
      setRuntimeCwd(tempDir.path);
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('save writes permission section and reload reflects it', () async {
      final container = ProviderContainer();
      final notifier = container.read(autoApproveProvider.notifier);
      notifier.setConfigPathForTest(configPath);

      // Load initial state.
      final initialState = await container.read(autoApproveProvider.future);
      expect(initialState.categories.length, 14);

      // Find the shell category and change its default to allow.
      final shellIndex = initialState.categories.indexWhere(
        (c) => c.id == 'shell',
      );
      expect(shellIndex, greaterThan(-1));

      await notifier.save(
        categoryId: 'shell',
        defaultAction: 'allow',
        exceptions: const {},
      );

      // Verify the file was written.
      final config = await ConfigWriter.readRawConfig(configPath);
      expect(config['permission'], isNotNull);
      expect(config['permission']['shell'], equals('allow'));

      // Invalidate to force rebuild with the override path.
      container.invalidate(autoApproveProvider);
      // Reload the notifier to pick up the change.
      final reloaded = await container.read(autoApproveProvider.future);
      final reloadedShell = reloaded.categories.firstWhere(
        (c) => c.id == 'shell',
      );
      expect(reloadedShell.defaultAction, equals('allow'));
    });

    test('save with exceptions writes map format', () async {
      final container = ProviderContainer();
      final notifier = container.read(autoApproveProvider.notifier);
      notifier.setConfigPathForTest(configPath);

      // Build the provider first so state is available.
      await container.read(autoApproveProvider.future);

      await notifier.save(
        categoryId: 'read',
        defaultAction: 'ask',
        exceptions: const {'*.env': 'allow', '/etc/*': 'deny'},
      );

      final config = await ConfigWriter.readRawConfig(configPath);
      final permission = config['permission'] as Map<String, dynamic>;
      expect(permission['read'], isA<Map>());
      final readMap = permission['read'] as Map<String, dynamic>;
      expect(readMap['*'], equals('ask'));
      expect(readMap['*.env'], equals('allow'));
      expect(readMap['/etc/*'], equals('deny'));
    });

    test(
      'save with null default and empty exceptions omits category',
      () async {
        final container = ProviderContainer();
        final notifier = container.read(autoApproveProvider.notifier);
        notifier.setConfigPathForTest(configPath);

        // Build the provider first so state is available.
        await container.read(autoApproveProvider.future);

        // First write something for shell.
        await notifier.save(
          categoryId: 'shell',
          defaultAction: 'allow',
          exceptions: const {},
        );

        // Now save with inherit (null default, empty exceptions).
        await notifier.save(
          categoryId: 'shell',
          defaultAction: null,
          exceptions: const {},
        );

        final config = await ConfigWriter.readRawConfig(configPath);
        final permission = config['permission'] as Map<String, dynamic>?;
        // shell should be absent (inherited from builtin).
        expect(permission?.containsKey('shell'), isFalse);
      },
    );

    test('save preserves non-UI permission keys', () async {
      // Pre-seed a config with keys not managed by the 14 UI categories.
      final preexisting = <String, dynamic>{
        'version': 1,
        'permission': <String, dynamic>{'custom_tool': 'ask', 'shell': 'deny'},
      };
      await File(
        configPath,
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(preexisting));

      final container = ProviderContainer();
      final notifier = container.read(autoApproveProvider.notifier);
      notifier.setConfigPathForTest(configPath);
      await container.read(autoApproveProvider.future);

      // Update a UI-managed category (read -> allow); shell + custom_tool
      // must remain untouched on disk.
      await notifier.save(
        categoryId: 'read',
        defaultAction: 'allow',
        exceptions: const {},
      );

      final config = await ConfigWriter.readRawConfig(configPath);
      final permission = config['permission'] as Map<String, dynamic>;
      expect(permission['custom_tool'], equals('ask')); // preserved
      expect(permission['shell'], equals('deny')); // preserved
      expect(permission['read'], equals('allow')); // updated
    });

    test('setScope switches scope and reloads from disk', () async {
      final container = ProviderContainer();
      final notifier = container.read(autoApproveProvider.notifier);
      notifier.setConfigPathForTest(configPath);

      final initial = await container.read(autoApproveProvider.future);
      expect(initial.scope, equals(AutoApproveScope.global));

      // With an override path both scopes resolve to the same file, so this
      // verifies the toggle triggers a reload and the active scope is reported.
      await notifier.setScope(AutoApproveScope.project);
      final switched = await container.read(autoApproveProvider.future);
      expect(switched.scope, equals(AutoApproveScope.project));
      expect(switched.categories.length, 14);
    });
  });
}
