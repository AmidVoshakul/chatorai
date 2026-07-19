import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpClientService.reload', () {
    late McpClientService service;

    setUp(() {
      service = McpClientService.instance;
      // Ensure a clean slate before each test (dispose resets state).
      // ignore: invalid_use_of_visible_for_testing_member
      service.dispose();
    });

    tearDown(() {
      // ignore: invalid_use_of_visible_for_testing_member
      service.dispose();
    });

    test('registers disabled server without connecting', () async {
      await service.reload(
        McpConfig(
          servers: {
            'off': McpServerConfig.local(command: 'nope', enabled: false),
          },
        ),
      );

      final status = service.getStatus('off');
      expect(status.status, McpConnectionStatus.disabled);
      expect(service.getAllStatuses().containsKey('off'), isTrue);
    });

    test('attempts connection for enabled server and records status', () async {
      // A non-MCP binary: connection will fail, but reload must not throw
      // and must record the server in configs/statuses (not "Not configured").
      await service.reload(
        McpConfig(
          servers: {
            'bad': McpServerConfig.local(
              command: 'definitely-not-a-mcp',
              enabled: true,
            ),
          },
        ),
      );

      final status = service.getStatus('bad');
      expect(status.status, isNot(McpConnectionStatus.disabled));
      // Not the "Not configured" sentinel returned for unknown servers.
      expect(status.error, isNot('Not configured'));
    });

    test('drops servers removed from config', () async {
      await service.reload(
        McpConfig(
          servers: {
            'gone': McpServerConfig.local(command: 'x', enabled: false),
          },
        ),
      );
      expect(service.getAllStatuses().containsKey('gone'), isTrue);

      await service.reload(const McpConfig());
      expect(service.getAllStatuses().containsKey('gone'), isFalse);
    });

    test('does not throw and stays usable when called repeatedly', () async {
      final cfg = McpConfig(
        servers: {'a': McpServerConfig.local(command: 'y', enabled: false)},
      );
      await service.reload(cfg);
      await service.reload(cfg);
      expect(service.getStatus('a').status, McpConnectionStatus.disabled);
    });
  });
}
