import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/config_watcher.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ConfigWatcher', () {
    late Directory tempDir;
    late String globalConfigPath;
    late String projectConfigPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('chatorai_watcher_test_');
      final globalDir = '${tempDir.path}/config';
      await Directory(globalDir).create(recursive: true);
      globalConfigPath = '$globalDir/chatorai.json';
      projectConfigPath = '${tempDir.path}/.chatorai/chatorai.json';
      await Directory('${tempDir.path}/.chatorai').create(recursive: true);

      await File(globalConfigPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'version': 1,
          'permission': {'read': 'allow'},
        }),
      );
      await File(projectConfigPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'version': 1,
          'permission': {'shell': 'ask'},
        }),
      );

      setRuntimeCwd(tempDir.path);
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    ConfigWatcher _make(ProviderContainer container) => ConfigWatcher(
      () => container.invalidate(configProvider),
      globalConfigPath: globalConfigPath,
      projectConfigPath: projectConfigPath,
    );

    test('starts and stops without crashing', () async {
      final container = ProviderContainer();
      final watcher = _make(container);
      await expectLater(watcher.start(), completes);
      await expectLater(watcher.stop(), completes);
      container.dispose();
    });

    test('detects global config file change', () async {
      final container = ProviderContainer();
      var invalidations = 0;
      container.listen<dynamic>(configProvider, (_, __) => invalidations++);
      container.read(configProvider);

      final watcher = _make(container);
      await watcher.start();

      // Modify the watched global config file.
      await File(globalConfigPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'version': 1,
          'permission': {'read': 'deny'},
        }),
      );

      // Wait for the file-system event to propagate past the debounce window.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(invalidations, greaterThan(0));

      await watcher.stop();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      container.dispose();
    });

    test('detects project config file change', () async {
      final container = ProviderContainer();
      var invalidations = 0;
      container.listen<dynamic>(configProvider, (_, __) => invalidations++);
      container.read(configProvider);

      final watcher = _make(container);
      await watcher.start();

      await File(projectConfigPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'version': 1,
          'permission': {'shell': 'deny'},
        }),
      );

      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(invalidations, greaterThan(0));

      await watcher.stop();
      container.dispose();
    });

    test('does not crash when global config file is missing', () async {
      await File(globalConfigPath).delete();
      final container = ProviderContainer();
      final watcher = _make(container);
      // The config directory still exists, so the watch is installed but the
      // missing file must not cause a crash.
      await expectLater(watcher.start(), completes);
      await watcher.stop();
      container.dispose();
    });

    test('does not crash when project config file is missing', () async {
      await File(projectConfigPath).delete();
      final container = ProviderContainer();
      final watcher = _make(container);
      await expectLater(watcher.start(), completes);
      await watcher.stop();
      container.dispose();
    });
  });
}
