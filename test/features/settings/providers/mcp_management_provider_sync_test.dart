import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chatorai/core/config/config_manager.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/features/settings/providers/mcp_management_provider.dart';

void main() {
  group('McpManagementNotifier service sync', () {
    late ProviderContainer container;
    late File tempFile;

    setUp(() {
      tempFile = File(
        '${Directory.systemTemp.path}/mcp_mgmt_sync_'
        '${DateTime.now().microsecondsSinceEpoch}.json',
      );
      container = ProviderContainer();
      // ignore: invalid_use_of_visible_for_testing_member
      McpClientService.instance.dispose();
    });

    tearDown(() {
      container.dispose();
      // ignore: invalid_use_of_visible_for_testing_member
      McpClientService.instance.dispose();
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    McpManagementNotifier _notifier() =>
        container.read(mcpManagementProvider.notifier)
          ..setConfigPathForTest(tempFile.path);

    test('addServer registers a disabled server in McpClientService', () async {
      final notifier = _notifier();
      await notifier.addServer(
        'tool',
        McpServerConfig.local(command: 'mytool', enabled: false),
      );
      // The live service learns about the server so the chat status bar
      // reflects it without an app restart.
      expect(
        McpClientService.instance.getStatus('tool').status,
        McpConnectionStatus.disabled,
      );
    });

    test('removeServer drops the server from McpClientService', () async {
      final notifier = _notifier();
      await notifier.addServer(
        'tool',
        McpServerConfig.local(command: 'mytool', enabled: false),
      );
      await notifier.removeServer('tool');
      expect(
        McpClientService.instance.getAllStatuses().containsKey('tool'),
        isFalse,
      );
    });

    test(
      'setEnabled(false) keeps the server registered but disabled',
      () async {
        final notifier = _notifier();
        await notifier.addServer(
          'tool',
          McpServerConfig.local(command: 'mytool', enabled: false),
        );
        await notifier.setEnabled('tool', false);
        expect(
          McpClientService.instance.getStatus('tool').status,
          McpConnectionStatus.disabled,
        );
        // Confirmed on disk too.
        final reloaded = await ConfigManager.loadConfig(path: tempFile.path);
        expect(reloaded.mcp?.servers['tool']!.enabled, isFalse);
      },
    );
  });
}
