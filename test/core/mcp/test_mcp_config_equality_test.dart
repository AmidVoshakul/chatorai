import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpServerConfig equality', () {
    test('local configs with equal fields are equal', () {
      final a = McpServerConfig.local(
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server'],
        cwd: '/tmp',
        environment: const {'A': '1'},
      );
      final b = McpServerConfig.local(
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server'],
        cwd: '/tmp',
        environment: const {'A': '1'},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs on command', () {
      final a = McpServerConfig.local(command: 'npx');
      final b = McpServerConfig.local(command: 'npx2');
      expect(a, isNot(b));
    });

    test('differs on args order', () {
      final a = McpServerConfig.local(command: 'npx', args: const ['-a', '-b']);
      final b = McpServerConfig.local(command: 'npx', args: const ['-b', '-a']);
      expect(a, isNot(b));
    });

    test('differs on cwd', () {
      final a = McpServerConfig.local(command: 'npx', cwd: '/a');
      final b = McpServerConfig.local(command: 'npx', cwd: '/b');
      expect(a, isNot(b));
    });

    test('differs on environment', () {
      final a = McpServerConfig.local(
        command: 'npx',
        environment: const {'A': '1'},
      );
      final b = McpServerConfig.local(
        command: 'npx',
        environment: const {'A': '2'},
      );
      expect(a, isNot(b));
    });

    test('differs on enabled', () {
      final a = McpServerConfig.local(command: 'npx', enabled: true);
      final b = McpServerConfig.local(command: 'npx', enabled: false);
      expect(a, isNot(b));
    });

    test('differs on timeout', () {
      final a = McpServerConfig.local(command: 'npx', timeout: 1000);
      final b = McpServerConfig.local(command: 'npx', timeout: 2000);
      expect(a, isNot(b));
    });

    test('remote configs with equal fields are equal', () {
      final a = McpServerConfig.remote(
        url: 'https://example.com/mcp',
        headers: const {'Authorization': 'Bearer x'},
        timeout: 5000,
      );
      final b = McpServerConfig.remote(
        url: 'https://example.com/mcp',
        headers: const {'Authorization': 'Bearer x'},
        timeout: 5000,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('remote differs on url', () {
      final a = McpServerConfig.remote(url: 'https://a.example.com');
      final b = McpServerConfig.remote(url: 'https://b.example.com');
      expect(a, isNot(b));
    });

    test('remote differs on headers', () {
      final a = McpServerConfig.remote(
        url: 'https://example.com',
        headers: const {'A': '1'},
      );
      final b = McpServerConfig.remote(
        url: 'https://example.com',
        headers: const {'A': '2'},
      );
      expect(a, isNot(b));
    });

    test('remote differs on oauth', () {
      final a = McpServerConfig.remote(
        url: 'https://example.com',
        oauth: const McpOAuthConfig(clientId: 'a'),
      );
      final b = McpServerConfig.remote(
        url: 'https://example.com',
        oauth: const McpOAuthConfig(clientId: 'b'),
      );
      expect(a, isNot(b));
    });

    test('local and remote with same display fields are not equal', () {
      final a = McpServerConfig.local(command: 'npx');
      final b = McpServerConfig.remote(url: 'npx');
      expect(a, isNot(b));
    });
  });

  group('McpOAuthConfig equality', () {
    test('equal fields are equal', () {
      const a = McpOAuthConfig(
        clientId: 'id',
        clientSecret: 'secret',
        scope: 'scope',
        callbackPort: 8080,
        redirectUri: 'http://localhost:8080',
      );
      const b = McpOAuthConfig(
        clientId: 'id',
        clientSecret: 'secret',
        scope: 'scope',
        callbackPort: 8080,
        redirectUri: 'http://localhost:8080',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs on clientId', () {
      const a = McpOAuthConfig(clientId: 'a');
      const b = McpOAuthConfig(clientId: 'b');
      expect(a, isNot(b));
    });

    test('differs on callbackPort', () {
      const a = McpOAuthConfig(clientId: 'a', callbackPort: 1);
      const b = McpOAuthConfig(clientId: 'a', callbackPort: 2);
      expect(a, isNot(b));
    });
  });
}
