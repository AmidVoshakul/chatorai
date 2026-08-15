import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';

void main() {
  group('McpServerType', () {
    test('local has correct value', () {
      expect(McpServerType.local.value, 'local');
    });

    test('remote has correct value', () {
      expect(McpServerType.remote.value, 'remote');
    });

    test('fromValue returns local for "local"', () {
      expect(McpServerType.fromValue('local'), McpServerType.local);
    });

    test('fromValue returns remote for "remote"', () {
      expect(McpServerType.fromValue('remote'), McpServerType.remote);
    });

    test('fromValue aliases "http" to remote', () {
      expect(McpServerType.fromValue('http'), McpServerType.remote);
    });

    test('fromValue aliases "https" to remote', () {
      expect(McpServerType.fromValue('https'), McpServerType.remote);
    });

    test('fromValue aliases "sse" to remote', () {
      expect(McpServerType.fromValue('sse'), McpServerType.remote);
    });

    test('fromValue aliases "stdio" to local', () {
      expect(McpServerType.fromValue('stdio'), McpServerType.local);
    });

    test('fromValue is case-insensitive', () {
      expect(McpServerType.fromValue('HTTP'), McpServerType.remote);
      expect(McpServerType.fromValue('Local'), McpServerType.local);
    });

    test('fromValue throws ArgumentError for unknown value', () {
      expect(
        () => McpServerType.fromValue('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromValue throws for empty string', () {
      expect(() => McpServerType.fromValue(''), throwsA(isA<ArgumentError>()));
    });
  });

  group('McpOAuthConfig', () {
    test('default constructor creates empty config', () {
      const oauth = McpOAuthConfig();
      expect(oauth.clientId, isNull);
      expect(oauth.clientSecret, isNull);
      expect(oauth.scope, isNull);
      expect(oauth.callbackPort, isNull);
      expect(oauth.redirectUri, isNull);
    });

    test('constructor with values sets all fields', () {
      const oauth = McpOAuthConfig(
        clientId: 'my-client',
        clientSecret: 'secret',
        scope: 'read write',
        callbackPort: 8080,
        redirectUri: 'http://localhost:8080/callback',
      );
      expect(oauth.clientId, 'my-client');
      expect(oauth.clientSecret, 'secret');
      expect(oauth.scope, 'read write');
      expect(oauth.callbackPort, 8080);
      expect(oauth.redirectUri, 'http://localhost:8080/callback');
    });

    test('toJson returns empty map when all fields null', () {
      const oauth = McpOAuthConfig();
      final json = oauth.toJson();
      expect(json, isEmpty);
    });

    test('toJson includes all non-null fields', () {
      const oauth = McpOAuthConfig(
        clientId: 'id',
        clientSecret: 'secret',
        scope: 's',
        callbackPort: 443,
        redirectUri: 'https://example.com',
      );
      final json = oauth.toJson();
      expect(json['client_id'], 'id');
      expect(json['client_secret'], 'secret');
      expect(json['scope'], 's');
      expect(json['callback_port'], 443);
      expect(json['redirect_uri'], 'https://example.com');
    });

    test('fromJson with snake_case keys', () {
      final json = {
        'client_id': 'id',
        'client_secret': 'secret',
        'scope': 'read',
        'callback_port': 3000,
        'redirect_uri': 'http://localhost',
      };
      final oauth = McpOAuthConfig.fromJson(json);
      expect(oauth.clientId, 'id');
      expect(oauth.clientSecret, 'secret');
      expect(oauth.scope, 'read');
      expect(oauth.callbackPort, 3000);
      expect(oauth.redirectUri, 'http://localhost');
    });

    test('fromJson with camelCase keys', () {
      final json = {
        'clientId': 'id',
        'clientSecret': 'secret',
        'scope': 'read',
        'callbackPort': 3000,
        'redirectUri': 'http://localhost',
      };
      final oauth = McpOAuthConfig.fromJson(json);
      expect(oauth.clientId, 'id');
      expect(oauth.clientSecret, 'secret');
      expect(oauth.scope, 'read');
      expect(oauth.callbackPort, 3000);
      expect(oauth.redirectUri, 'http://localhost');
    });

    test('fromJson with missing keys returns null fields', () {
      final json = <String, dynamic>{};
      final oauth = McpOAuthConfig.fromJson(json);
      expect(oauth.clientId, isNull);
      expect(oauth.clientSecret, isNull);
      expect(oauth.scope, isNull);
      expect(oauth.callbackPort, isNull);
      expect(oauth.redirectUri, isNull);
    });

    test('roundtrip: toJson → fromJson preserves all fields', () {
      const original = McpOAuthConfig(
        clientId: 'round',
        clientSecret: 'trip',
        scope: 'both',
        callbackPort: 9999,
        redirectUri: 'https://roundtrip.test',
      );
      final restored = McpOAuthConfig.fromJson(original.toJson());
      expect(restored.clientId, original.clientId);
      expect(restored.clientSecret, original.clientSecret);
      expect(restored.scope, original.scope);
      expect(restored.callbackPort, original.callbackPort);
      expect(restored.redirectUri, original.redirectUri);
    });
  });

  group('McpServerConfig.local', () {
    test('creates local config with required command', () {
      final config = McpServerConfig.local(command: 'echo');
      expect(config.type, McpServerType.local);
      expect(config.command, 'echo');
      expect(config.args, isEmpty);
      expect(config.cwd, isNull);
      expect(config.environment, isEmpty);
      expect(config.enabled, isTrue);
      expect(config.timeout, isNull);
      expect(config.isLocal, true);
      expect(config.isRemote, false);
    });

    test('creates local config with all parameters', () {
      final config = McpServerConfig.local(
        command: 'node',
        args: ['server.js', '--port', '3000'],
        cwd: '/home/user',
        environment: {'NODE_ENV': 'production'},
        enabled: false,
        timeout: 60000,
      );
      expect(config.command, 'node');
      expect(config.args, ['server.js', '--port', '3000']);
      expect(config.cwd, '/home/user');
      expect(config.environment, {'NODE_ENV': 'production'});
      expect(config.enabled, false);
      expect(config.timeout, 60000);
    });

    test('toJson includes local-specific fields', () {
      final config = McpServerConfig.local(
        command: 'python',
        args: ['-m', 'server'],
        cwd: '/app',
        environment: {'PYTHONPATH': '/lib'},
        timeout: 45000,
      );
      final json = config.toJson();
      expect(json['type'], 'local');
      expect(json['command'], 'python');
      expect(json['args'], ['-m', 'server']);
      expect(json['cwd'], '/app');
      expect(json['environment'], {'PYTHONPATH': '/lib'});
      expect(json['timeout'], 45000);
      expect(json['enabled'], true);
    });

    test('toJson omits null optional fields', () {
      final config = McpServerConfig.local(command: 'echo');
      final json = config.toJson();
      expect(json.containsKey('cwd'), false);
      expect(json.containsKey('timeout'), false);
    });

    test('fromJson creates local config', () {
      final json = {
        'type': 'local',
        'command': 'node',
        'args': ['index.js'],
        'cwd': '/workspace',
        'environment': {'KEY': 'val'},
        'enabled': false,
        'timeout': 30000,
      };
      final config = McpServerConfig.fromJson(json);
      expect(config.type, McpServerType.local);
      expect(config.command, 'node');
      expect(config.args, ['index.js']);
      expect(config.cwd, '/workspace');
      expect(config.environment, {'KEY': 'val'});
      expect(config.enabled, false);
      expect(config.timeout, 30000);
    });

    test('fromJson defaults enabled to true', () {
      final json = {'type': 'local', 'command': 'echo'};
      final config = McpServerConfig.fromJson(json);
      expect(config.enabled, true);
    });

    test('fromJson defaults args to empty list', () {
      final json = {'type': 'local', 'command': 'echo'};
      final config = McpServerConfig.fromJson(json);
      expect(config.args, isEmpty);
    });

    test('fromJson with empty environment', () {
      final json = {
        'type': 'local',
        'command': 'echo',
        'environment': <String, String>{},
      };
      final config = McpServerConfig.fromJson(json);
      expect(config.environment, isEmpty);
    });

    test('roundtrip: toJson → fromJson preserves local config', () {
      final original = McpServerConfig.local(
        command: 'dart',
        args: ['run', 'server.dart'],
        cwd: '/app',
        environment: {'DEBUG': '1'},
        enabled: false,
        timeout: 15000,
      );
      final restored = McpServerConfig.fromJson(original.toJson());
      expect(restored.type, original.type);
      expect(restored.command, original.command);
      expect(restored.args, original.args);
      expect(restored.cwd, original.cwd);
      expect(restored.environment, original.environment);
      expect(restored.enabled, original.enabled);
      expect(restored.timeout, original.timeout);
    });
  });

  group('McpServerConfig.remote', () {
    test('creates remote config with required url', () {
      final config = McpServerConfig.remote(url: 'https://api.example.com');
      expect(config.type, McpServerType.remote);
      expect(config.url, 'https://api.example.com');
      expect(config.headers, isEmpty);
      expect(config.oauth, isNull);
      expect(config.enabled, true);
      expect(config.timeout, isNull);
      expect(config.isLocal, false);
      expect(config.isRemote, true);
    });

    test('creates remote config with all parameters', () {
      const oauth = McpOAuthConfig(clientId: 'abc');
      final config = McpServerConfig.remote(
        url: 'https://api.example.com/sse',
        headers: {'Authorization': 'Bearer token'},
        oauth: oauth,
        enabled: false,
        timeout: 60000,
      );
      expect(config.url, 'https://api.example.com/sse');
      expect(config.headers, {'Authorization': 'Bearer token'});
      expect(config.oauth, oauth);
      expect(config.enabled, false);
      expect(config.timeout, 60000);
    });

    test('toJson includes remote-specific fields', () {
      final config = McpServerConfig.remote(
        url: 'https://api.test.com',
        headers: {'X-Custom': 'value'},
        timeout: 20000,
      );
      final json = config.toJson();
      expect(json['type'], 'remote');
      expect(json['url'], 'https://api.test.com');
      expect(json['headers'], {'X-Custom': 'value'});
      expect(json['timeout'], 20000);
      expect(json['enabled'], true);
    });

    test('toJson omits empty headers', () {
      final config = McpServerConfig.remote(url: 'https://api.test.com');
      final json = config.toJson();
      expect(json.containsKey('headers'), false);
    });

    test('toJson includes oauth when present', () {
      const oauth = McpOAuthConfig(clientId: 'test');
      final config = McpServerConfig.remote(
        url: 'https://api.test.com',
        oauth: oauth,
      );
      final json = config.toJson();
      expect(json['oauth'], isNotNull);
      expect(json['oauth']['client_id'], 'test');
    });

    test('fromJson creates remote config', () {
      final json = {
        'type': 'remote',
        'url': 'https://remote.example.com',
        'headers': {'Accept': 'application/json'},
        'enabled': false,
        'timeout': 5000,
      };
      final config = McpServerConfig.fromJson(json);
      expect(config.type, McpServerType.remote);
      expect(config.url, 'https://remote.example.com');
      expect(config.headers, {'Accept': 'application/json'});
      expect(config.enabled, false);
      expect(config.timeout, 5000);
    });

    test('fromJson accepts spec "http" type as remote', () {
      final config = McpServerConfig.fromJson({
        'type': 'http',
        'url': 'https://mcp.context7.com/mcp',
      });
      expect(config.type, McpServerType.remote);
      expect(config.isRemote, isTrue);
      expect(config.url, 'https://mcp.context7.com/mcp');
    });

    test('fromJson accepts "sse" type as remote', () {
      final config = McpServerConfig.fromJson({
        'type': 'sse',
        'url': 'https://example.com/sse',
      });
      expect(config.type, McpServerType.remote);
      expect(config.url, 'https://example.com/sse');
    });

    test('fromJson with oauth sub-object', () {
      final json = {
        'type': 'remote',
        'url': 'https://secure.example.com',
        'oauth': {
          'client_id': 'my-app',
          'client_secret': 'super-secret',
          'scope': 'tools:read',
        },
      };
      final config = McpServerConfig.fromJson(json);
      expect(config.oauth, isNotNull);
      expect(config.oauth!.clientId, 'my-app');
      expect(config.oauth!.clientSecret, 'super-secret');
      expect(config.oauth!.scope, 'tools:read');
    });

    test('roundtrip: toJson → fromJson preserves remote config', () {
      const oauth = McpOAuthConfig(clientId: 'round', scope: 'all');
      final original = McpServerConfig.remote(
        url: 'https://roundtrip.test',
        headers: {'X-Test': '1'},
        oauth: oauth,
        enabled: false,
        timeout: 25000,
      );
      final restored = McpServerConfig.fromJson(original.toJson());
      expect(restored.type, original.type);
      expect(restored.url, original.url);
      expect(restored.headers, original.headers);
      expect(restored.enabled, original.enabled);
      expect(restored.timeout, original.timeout);
      expect(restored.oauth!.clientId, original.oauth!.clientId);
      expect(restored.oauth!.scope, original.oauth!.scope);
    });
  });

  group('McpConfig', () {
    test('default constructor creates empty config', () {
      const config = McpConfig();
      expect(config.servers, isEmpty);
      expect(config.defaultTimeout, isNull);
    });

    test('constructor with parameters', () {
      final server = McpServerConfig.local(command: 'echo');
      final config = McpConfig(
        servers: {'test': server},
        defaultTimeout: 30000,
      );
      expect(config.servers, hasLength(1));
      expect(config.servers['test'], server);
      expect(config.defaultTimeout, 30000);
    });

    test('fromJson with null returns empty config', () {
      final config = McpConfig.fromJson(null);
      expect(config.servers, isEmpty);
      expect(config.defaultTimeout, isNull);
    });

    test('fromJson with empty map returns empty config', () {
      final config = McpConfig.fromJson({});
      expect(config.servers, isEmpty);
    });

    test('fromJson parses servers', () {
      final json = {
        'servers': {
          'local-server': {
            'type': 'local',
            'command': 'node',
            'args': ['server.js'],
          },
          'remote-server': {'type': 'remote', 'url': 'https://api.example.com'},
        },
        'default_timeout': 45000,
      };
      final config = McpConfig.fromJson(json);
      expect(config.servers, hasLength(2));
      expect(config.servers['local-server']!.command, 'node');
      expect(config.servers['remote-server']!.url, 'https://api.example.com');
      expect(config.defaultTimeout, 45000);
    });

    test('fromJson with camelCase defaultTimeout', () {
      final json = {'defaultTimeout': 60000};
      final config = McpConfig.fromJson(json);
      expect(config.defaultTimeout, 60000);
    });

    test('fromJson skips invalid server entries', () {
      final json = {
        'servers': {
          'valid': {'type': 'local', 'command': 'echo'},
          'invalid': 'not-a-map',
          'also-invalid': 42,
        },
      };
      final config = McpConfig.fromJson(json);
      expect(config.servers, hasLength(1));
      expect(config.servers.containsKey('valid'), true);
    });

    test('fromJson with empty servers map', () {
      final json = {'servers': <String, dynamic>{}};
      final config = McpConfig.fromJson(json);
      expect(config.servers, isEmpty);
    });

    test('fromJson accepts flat format without servers wrapper', () {
      final json = {
        'sequential-thinking': {
          'type': 'local',
          'enabled': true,
          'command': '/home/amid/.local/bin/uvx',
          'args': ['sequential-thinking-mcp'],
        },
        'time': {
          'type': 'local',
          'enabled': true,
          'command': ['/home/amid/.local/bin/uvx', 'mcp-server-time'],
        },
        'default_timeout': 30000,
      };
      final config = McpConfig.fromJson(json);
      expect(config.servers, hasLength(2));
      expect(
        config.servers['sequential-thinking']!.command,
        '/home/amid/.local/bin/uvx',
      );
      expect(config.servers['sequential-thinking']!.args, [
        'sequential-thinking-mcp',
      ]);
      expect(config.servers['time']!.command, '/home/amid/.local/bin/uvx');
      expect(config.servers['time']!.args, ['mcp-server-time']);
      expect(config.defaultTimeout, 30000);
    });

    test('toJson omits empty servers', () {
      const config = McpConfig();
      final json = config.toJson();
      expect(json.containsKey('servers'), false);
    });

    test('toJson omits null defaultTimeout', () {
      final config = McpConfig(
        servers: {'s': McpServerConfig.local(command: 'echo')},
      );
      final json = config.toJson();
      expect(json.containsKey('default_timeout'), false);
    });

    test('roundtrip: toJson → fromJson preserves full config', () {
      final original = McpConfig(
        servers: {
          'local': McpServerConfig.local(
            command: 'python',
            args: ['server.py'],
            timeout: 10000,
          ),
          'remote': McpServerConfig.remote(
            url: 'https://api.test.com',
            headers: {'X-Key': 'val'},
            oauth: const McpOAuthConfig(clientId: 'test'),
          ),
        },
        defaultTimeout: 60000,
      );
      final restored = McpConfig.fromJson(original.toJson());
      expect(restored.servers, hasLength(2));
      expect(restored.defaultTimeout, 60000);
      expect(restored.servers['local']!.command, 'python');
      expect(restored.servers['remote']!.url, 'https://api.test.com');
      expect(restored.servers['remote']!.oauth!.clientId, 'test');
    });

    test('fromJson with mixed valid and invalid server entries', () {
      final json = {
        'servers': {
          'good-local': {'type': 'local', 'command': 'echo'},
          'good-remote': {'type': 'remote', 'url': 'https://x.com'},
          'bad-string': 'invalid',
          'bad-number': 123,
          'bad-list': [1, 2, 3],
        },
      };
      final config = McpConfig.fromJson(json);
      expect(config.servers, hasLength(2));
      expect(config.servers.containsKey('good-local'), true);
      expect(config.servers.containsKey('good-remote'), true);
    });

    group('Chatorai-compatible command format', () {
      test('fromJson accepts command as array', () {
        final json = {
          'type': 'local',
          'command': ['/home/amid/.local/bin/uvx', 'sequential-thinking-mcp'],
        };
        final config = McpServerConfig.fromJson(json);
        expect(config.type, McpServerType.local);
        expect(config.command, '/home/amid/.local/bin/uvx');
        expect(config.args, ['sequential-thinking-mcp']);
      });

      test(
        'fromJson accepts command as string with separate args (ChatORAI format)',
        () {
          final json = {
            'type': 'local',
            'command': '/home/amid/.local/bin/uvx',
            'args': ['sequential-thinking-mcp'],
          };
          final config = McpServerConfig.fromJson(json);
          expect(config.type, McpServerType.local);
          expect(config.command, '/home/amid/.local/bin/uvx');
          expect(config.args, ['sequential-thinking-mcp']);
        },
      );

      test('fromJson with command array and extra args uses array args', () {
        final json = {
          'type': 'local',
          'command': ['npx', '-y', 'my-mcp'],
          'args': ['ignored'],
        };
        final config = McpServerConfig.fromJson(json);
        expect(config.command, 'npx');
        expect(config.args, ['-y', 'my-mcp']);
      });

      test('fromJson throws on empty command array', () {
        expect(
          () => McpServerConfig.fromJson({
            'type': 'local',
            'command': <String>[],
          }),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
