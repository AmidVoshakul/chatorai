import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chatorai/core/config/config_manager.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/gui/features/settings/providers/mcp_management_provider.dart';

void main() {
  group('McpManagementNotifier', () {
    late ProviderContainer container;
    late File tempFile;

    setUp(() {
      tempFile = File(
        '${Directory.systemTemp.path}/mcp_mgmt_${DateTime.now().microsecondsSinceEpoch}.json',
      );
      container = ProviderContainer();
    });

    // Disable live McpClientService reconciliation: these tests assert on
    // persistence/UI state only, not real subprocess connections.
    void _disableServiceSync() => container
        .read(mcpManagementProvider.notifier)
        .setServiceSyncEnabledForTest(false);

    tearDown(() {
      container.dispose();
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    McpManagementNotifier _notifier() =>
        container.read(mcpManagementProvider.notifier)
          ..setConfigPathForTest(tempFile.path)
          ..setServiceSyncEnabledForTest(false);

    McpManagementState _state() => container.read(mcpManagementProvider).value!;

    test('starts empty and loads declared servers', () async {
      final notifier = _notifier();
      // Seed the config directly.
      await ConfigWriter.writeRawConfig(tempFile.path, {
        'mcp': {
          'servers': {
            'seed': {'type': 'local', 'command': 'echo', 'enabled': true},
          },
        },
      });
      await notifier.refresh();
      expect(_state().servers.containsKey('seed'), isTrue);
    });

    test('addServer persists a local server', () async {
      final notifier = _notifier();
      await notifier.addServer(
        'tool',
        McpServerConfig.local(command: 'mytool', args: ['--x']),
      );
      expect(_state().servers.containsKey('tool'), isTrue);
      expect(_state().servers['tool']!.command, 'mytool');
      // Confirmed on disk.
      final reloaded = await ConfigManager.loadConfig(path: tempFile.path);
      expect(reloaded.mcp?.servers.containsKey('tool'), isTrue);
    });

    test('addServer persists a remote server', () async {
      final notifier = _notifier();
      await notifier.addServer(
        'remote1',
        McpServerConfig.remote(url: 'https://example.com/mcp'),
      );
      expect(_state().servers['remote1']!.url, 'https://example.com/mcp');
    });

    test('setEnabled toggles the enabled flag', () async {
      final notifier = _notifier();
      await notifier.addServer(
        'tool',
        McpServerConfig.local(command: 'mytool'),
      );
      expect(_state().servers['tool']!.enabled, isTrue);
      await notifier.setEnabled('tool', false);
      expect(_state().servers['tool']!.enabled, isFalse);
    });

    test('removeServer deletes the server', () async {
      final notifier = _notifier();
      await notifier.addServer(
        'tool',
        McpServerConfig.local(command: 'mytool'),
      );
      await notifier.removeServer('tool');
      expect(_state().servers.containsKey('tool'), isFalse);
    });

    test(
      'updateServer edits a remote server token without losing fields',
      () async {
        final notifier = _notifier();
        await notifier.addServer(
          'api',
          McpServerConfig.remote(
            url: 'https://api.example.com/mcp',
            headers: {'Authorization': 'Bearer old-token'},
          ),
        );
        final before = _state().servers['api']!;
        expect(before.url, 'https://api.example.com/mcp');

        final updated = before.copyWith(
          headers: {'Authorization': 'Bearer new-token'},
        );
        await notifier.updateServer('api', updated);

        final after = _state().servers['api']!;
        expect(after.url, 'https://api.example.com/mcp');
        expect(after.headers, {'Authorization': 'Bearer new-token'});
      },
    );

    test(
      'updateServer keeps other fields when editing a local server',
      () async {
        final notifier = _notifier();
        await notifier.addServer(
          'tool',
          McpServerConfig.local(
            command: 'mytool',
            args: ['--a'],
            environment: {'K': 'V'},
          ),
        );
        final before = _state().servers['tool']!;
        final updated = before.copyWith(command: 'mytool2');
        await notifier.updateServer('tool', updated);

        final after = _state().servers['tool']!;
        expect(after.command, 'mytool2');
        expect(after.args, ['--a']);
        expect(after.environment, {'K': 'V'});
      },
    );

    test('refresh() picks up external file changes', () async {
      final notifier = _notifier();
      // Start from a known-empty config, then force a re-read from the
      // overridden (temp) path — the initial build runs before the override
      // is set, so it may have loaded the real global config.
      await ConfigWriter.writeRawConfig(tempFile.path, const {});
      await notifier.refresh();
      expect(_state().servers, isEmpty);

      // Change the config on disk directly, bypassing the notifier API.
      await ConfigWriter.writeRawConfig(tempFile.path, {
        'mcp': {
          'servers': {
            'added-elsewhere': {'type': 'local', 'command': 'echo'},
          },
        },
      });

      await notifier.refresh();
      expect(_state().servers.containsKey('added-elsewhere'), isTrue);
    });
  });
}
