import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/features/settings/screens/mcp_add_server_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the pure parsing/validation helpers used by the
/// "Add MCP server" dialog. Keeping this logic in free functions makes the
/// dialog thin and lets the parsing rules be verified without a widget tree.
void main() {
  group('parseEnvJson', () {
    test('returns empty map for blank input', () {
      expect(parseEnvJson(''), isEmpty);
      expect(parseEnvJson('   '), isEmpty);
    });

    test('parses a flat key/value object', () {
      final env = parseEnvJson('{"GITHUB_TOKEN":"ghp_abc","X":"1"}');
      expect(env, {'GITHUB_TOKEN': 'ghp_abc', 'X': '1'});
    });

    test('throws on non-object JSON', () {
      expect(
        () => parseEnvJson('[1,2,3]'),
        throwsA(isA<McpDialogParseError>()),
      );
      expect(() => parseEnvJson('"nope"'), throwsA(isA<McpDialogParseError>()));
    });

    test('throws on malformed JSON', () {
      expect(
        () => parseEnvJson('{bad json}'),
        throwsA(isA<McpDialogParseError>()),
      );
    });

    test('throws when values are not strings', () {
      expect(
        () => parseEnvJson('{"KEY":123}'),
        throwsA(isA<McpDialogParseError>()),
      );
    });

    test('error message names the field', () {
      final error = mcpDialogErrorLabel;
      expect(error, isNotEmpty);
    });

    test(
      'mcpRawExample is a multi-line, indented, valid whole-object example',
      () {
        expect(mcpRawExample, contains('\n'));
        expect(mcpRawExample, contains('  "searxng": {'));
        // The example must itself parse into a valid local server config with
        // the outer key used as the server name.
        final (name, config) = parseRawServerJson(mcpRawExample);
        expect(name, 'searxng');
        expect(config.isLocal, isTrue);
        expect(config.environment['SEARXNG_URL'], 'http://localhost:8081');
      },
    );
  });

  group('buildAuthHeaders', () {
    test('returns empty map for blank token', () {
      expect(buildAuthHeaders('', AuthType.noAuth), isEmpty);
      expect(buildAuthHeaders('   ', AuthType.token), isEmpty);
    });

    test('token wraps with Authorization: Bearer', () {
      expect(buildAuthHeaders('abc', AuthType.token), {
        'Authorization': 'Bearer abc',
      });
    });

    test('oauth returns empty headers', () {
      expect(buildAuthHeaders('abc', AuthType.oauth), isEmpty);
    });
  });

  group('parseHeadersJson', () {
    test('returns empty map for blank input', () {
      expect(parseHeadersJson(''), isEmpty);
    });

    test('parses authorization header', () {
      final headers = parseHeadersJson('{"Authorization":"Bearer tok"}');
      expect(headers, {'Authorization': 'Bearer tok'});
    });

    test('throws on malformed JSON', () {
      expect(
        () => parseHeadersJson('{not valid}'),
        throwsA(isA<McpDialogParseError>()),
      );
    });
  });

  group('parseRawServerJson', () {
    test('parses the whole-object form with the outer key as name', () {
      final (name, config) = parseRawServerJson(
        '{"searxng":{"type":"local","command":"npx",'
        '"args":["-y","@modelcontextprotocol/server-github"],'
        '"environment":{"GITHUB_PERSONAL_ACCESS_TOKEN":"ghp_x"}}}',
      );
      expect(name, 'searxng');
      expect(config.isLocal, isTrue);
      expect(config.command, 'npx');
      expect(config.args, ['-y', '@modelcontextprotocol/server-github']);
      expect(config.environment['GITHUB_PERSONAL_ACCESS_TOKEN'], 'ghp_x');
    });

    test('parses the short form copied straight from docs (no wrapper)', () {
      final (name, config) = parseRawServerJson(
        '{"sequential-thinking":{"command":"npx",'
        '"args":["-y","@modelcontextprotocol/server-sequential-thinking"]}}',
      );
      expect(name, 'sequential-thinking');
      expect(config.isLocal, isTrue);
      expect(config.command, 'npx');
      expect(config.args, [
        '-y',
        '@modelcontextprotocol/server-sequential-thinking',
      ]);
    });

    test('unwraps the mcpServers wrapper from the docs example', () {
      final (name, config) = parseRawServerJson(
        '{"mcpServers":{"sequential-thinking":{"command":"npx",'
        '"args":["-y","@modelcontextprotocol/server-sequential-thinking"]}}}',
      );
      expect(name, 'sequential-thinking');
      expect(config.isLocal, isTrue);
      expect(config.command, 'npx');
      expect(config.args, [
        '-y',
        '@modelcontextprotocol/server-sequential-thinking',
      ]);
    });

    test('parses a remote server with headers', () {
      final (name, config) = parseRawServerJson(
        '{"myremote":{"type":"remote","url":"https://example.com/mcp",'
        '"headers":{"Authorization":"Bearer tok"}}}',
      );
      expect(name, 'myremote');
      expect(config.isRemote, isTrue);
      expect(config.url, 'https://example.com/mcp');
      expect(config.headers, {'Authorization': 'Bearer tok'});
    });

    test('supports legacy form with name inside the object', () {
      final (name, config) = parseRawServerJson(
        '{"name":"legacy","type":"local","command":"uvx","args":["x"]}',
      );
      expect(name, 'legacy');
      expect(config.command, 'uvx');
    });

    test('throws when more than one server is pasted (no wrapper)', () {
      expect(
        () => parseRawServerJson(
          '{"a":{"type":"local","command":"x"},"b":{"type":"local","command":"y"}}',
        ),
        throwsA(isA<McpDialogParseError>()),
      );
    });

    test('throws when the mcpServers wrapper contains several servers', () {
      expect(
        () => parseRawServerJson(
          '{"mcpServers":{"a":{"type":"local","command":"x"},'
          '"b":{"type":"local","command":"y"}}}',
        ),
        throwsA(isA<McpDialogParseError>()),
      );
    });

    test('throws on malformed JSON', () {
      expect(
        () => parseRawServerJson('{broken}'),
        throwsA(isA<McpDialogParseError>()),
      );
    });

    test('throws on structurally invalid server config', () {
      expect(
        () => parseRawServerJson('{"srv":{"type":"local","url":"x"}}'),
        throwsA(isA<McpDialogParseError>()),
      );
    });
  });
}
