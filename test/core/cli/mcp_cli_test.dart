import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/cli/mcp_cli.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<String> _capturePrint(Future<void> Function() body) async {
  final buffer = StringBuffer();
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => buffer.writeln(line),
    ),
  );
  return buffer.toString();
}

void main() {
  group('runMcp', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('mcp_cli_test_');
      await McpClientService.instance.dispose();
    });

    tearDown(() async {
      await McpClientService.instance.dispose();
      await tmp.delete(recursive: true);
    });

    test('help prints usage and does not throw.', () async {
      final out = await _capturePrint(() => runMcp(['help']));
      expect(out, contains('Usage: chatorai mcp'));
      expect(out, contains('list'));
    });

    test('explicit --help prints help.', () async {
      final out = await _capturePrint(() => runMcp(['--help']));
      expect(out, contains('Usage: chatorai mcp'));
    });

    test('list --help prints list help.', () async {
      final out = await _capturePrint(() => runMcp(['list', '--help']));
      expect(out, contains('Status markers'));
    });

    test('list shows disabled server without connecting', () async {
      final configFile = File(p.join(tmp.path, 'chatorai.json'));
      await configFile.writeAsString(
        '{"mcp":{"demo":{"type":"local",'
        '"command":"/usr/bin/echo","enabled":false}}}',
      );
      final out = await _capturePrint(
        () => runMcp(['list'], configPath: configFile.path),
      );
      expect(out, contains('demo'));
      expect(out, contains('○'));
    });

    test('list reports when no servers are configured', () async {
      final configFile = File(p.join(tmp.path, 'chatorai.json'));
      await configFile.writeAsString('{}');
      final out = await _capturePrint(
        () => runMcp(['list'], configPath: configFile.path),
      );
      expect(out, contains('No MCP servers configured'));
    });

    test('add creates a local server', () async {
      final configFile = File(p.join(tmp.path, 'chatorai.json'));
      await configFile.writeAsString('{}');
      final out = await _capturePrint(
        () => runMcp([
          'add',
          'tool',
          '--',
          '/usr/bin/tool',
          '--flag',
        ], configPath: configFile.path),
      );
      expect(out, contains('Added MCP server "tool"'));

      final raw = jsonDecode(await configFile.readAsString()) as Map;
      final server = (raw['mcp']['tool'] as Map);
      expect(server['type'], 'local');
      expect(server['command'], '/usr/bin/tool');
      expect(server['args'], ['--flag']);
    });

    test('add creates a remote server with --url', () async {
      final configFile = File(p.join(tmp.path, 'chatorai.json'));
      await configFile.writeAsString('{}');
      final out = await _capturePrint(
        () => runMcp([
          'add',
          'srv',
          '--url',
          'https://example.com/mcp',
        ], configPath: configFile.path),
      );
      expect(out, contains('Added MCP server "srv"'));
      final raw = jsonDecode(await configFile.readAsString()) as Map;
      final server = (raw['mcp']['srv'] as Map);
      expect(server['type'], 'remote');
      expect(server['url'], 'https://example.com/mcp');
    });

    test('add supports --url= and --timeout= and --disabled', () async {
      final configFile = File(p.join(tmp.path, 'chatorai.json'));
      await configFile.writeAsString('{}');
      await _capturePrint(
        () => runMcp([
          'add',
          'srv',
          '--url=https://example.com/mcp',
          '--timeout=5000',
          '--disabled',
        ], configPath: configFile.path),
      );
      final raw = jsonDecode(await configFile.readAsString()) as Map;
      final server = (raw['mcp']['srv'] as Map);
      expect(server['url'], 'https://example.com/mcp');
      expect(server['timeout'], 5000);
      expect(server['enabled'], false);
    });

    test('remove deletes a server', () async {
      final configFile = File(p.join(tmp.path, 'chatorai.json'));
      await configFile.writeAsString(
        '{"mcp":{"demo":{"type":"local",'
        '"command":"/usr/bin/echo"}}}',
      );
      final out = await _capturePrint(
        () => runMcp(['remove', 'demo'], configPath: configFile.path),
      );
      expect(out, contains('Removed MCP server "demo"'));
      final raw = jsonDecode(await configFile.readAsString()) as Map;
      expect(raw.containsKey('mcp'), isFalse);
    });

    test('enable and disable toggle the enabled flag', () async {
      final configFile = File(p.join(tmp.path, 'chatorai.json'));
      await configFile.writeAsString(
        '{"mcp":{"demo":{"type":"local",'
        '"command":"/usr/bin/echo","enabled":false}}}',
      );
      final enableOut = await _capturePrint(
        () => runMcp(['enable', 'demo'], configPath: configFile.path),
      );
      expect(enableOut, contains('Enabled MCP server "demo"'));
      var raw = jsonDecode(await configFile.readAsString()) as Map;
      expect((raw['mcp']['demo'] as Map)['enabled'], true);

      final disableOut = await _capturePrint(
        () => runMcp(['disable', 'demo'], configPath: configFile.path),
      );
      expect(disableOut, contains('Disabled MCP server "demo"'));
      raw = jsonDecode(await configFile.readAsString()) as Map;
      expect((raw['mcp']['demo'] as Map)['enabled'], false);
    });
  });
}
