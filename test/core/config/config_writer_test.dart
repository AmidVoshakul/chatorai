import 'dart:io';

import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/core/config/config_loader.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  late String cfgPath;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('config_writer_test_');
    cfgPath = p.join(tmp.path, 'chatorai.json');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  McpServerConfig localServer({
    bool enabled = true,
    List<String> args = const [],
  }) => McpServerConfig.local(
    command: '/usr/bin/echo',
    args: args,
    enabled: enabled,
  );

  group('ConfigWriter upsert/remove/enable', () {
    test('upsert creates mcp section and round-trips', () async {
      await ConfigWriter.upsertMcpServer(
        'echo',
        localServer(),
        global: false,
        configPath: cfgPath,
      );

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw['mcp'], isA<Map>());
      final mcp = raw['mcp'] as Map;
      expect(mcp.containsKey('echo'), isTrue);
      expect(mcp['echo']['type'], 'local');
      expect(mcp['echo']['command'], '/usr/bin/echo');
      expect(mcp['echo']['enabled'], isTrue);
    });

    test('upsert twice updates the same server (no duplicate keys)', () async {
      await ConfigWriter.upsertMcpServer(
        'echo',
        localServer(args: ['a']),
        global: false,
        configPath: cfgPath,
      );
      await ConfigWriter.upsertMcpServer(
        'echo',
        localServer(args: ['a', 'b']),
        global: false,
        configPath: cfgPath,
      );

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      final mcp = raw['mcp'] as Map;
      expect(mcp.length, 1);
      expect((mcp['echo']['args'] as List).length, 2);
    });

    test('upsert a second server coexists', () async {
      await ConfigWriter.upsertMcpServer(
        'one',
        localServer(),
        global: false,
        configPath: cfgPath,
      );
      await ConfigWriter.upsertMcpServer(
        'two',
        McpServerConfig.remote(url: 'https://example.com/mcp'),
        global: false,
        configPath: cfgPath,
      );

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      final mcp = raw['mcp'] as Map;
      expect(mcp.length, 2);
      expect(mcp['two']['type'], 'remote');
      expect(mcp['two']['url'], 'https://example.com/mcp');
    });

    test(
      'upsert preserves pre-existing flat-layout servers (no data loss)',
      () async {
        await ConfigWriter.writeRawConfig(cfgPath, {
          'mcp': {
            'codegraph': {
              'type': 'local',
              'enabled': true,
              'command': 'npx',
              'args': ['-y', '@colbymchenry/codegraph'],
            },
            'time': {
              'type': 'local',
              'enabled': false,
              'command': 'uvx',
              'args': ['mcp-server-time'],
            },
          },
        });

        await ConfigWriter.upsertMcpServer(
          'echo',
          localServer(),
          global: false,
          configPath: cfgPath,
        );

        final raw = await ConfigWriter.readRawConfig(cfgPath);
        final mcp = raw['mcp'] as Map;
        expect(
          mcp.length,
          3,
          reason: 'flat-layout servers must be preserved on upsert',
        );
        expect(mcp.containsKey('codegraph'), isTrue);
        expect(mcp.containsKey('time'), isTrue);
        expect(mcp.containsKey('echo'), isTrue);
      },
    );

    test('setMcpEnabled preserves other flat-layout servers', () async {
      await ConfigWriter.writeRawConfig(cfgPath, {
        'mcp': {
          'codegraph': {'type': 'local', 'enabled': true, 'command': 'npx'},
          'time': {'type': 'local', 'enabled': false, 'command': 'uvx'},
        },
      });

      await ConfigWriter.setMcpEnabled(
        'codegraph',
        false,
        global: false,
        configPath: cfgPath,
      );

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      final mcp = raw['mcp'] as Map;
      expect(mcp.length, 2);
      expect(mcp['codegraph']['enabled'], isFalse);
      expect(mcp.containsKey('time'), isTrue);
    });

    test('removeMcpServer preserves other flat-layout servers', () async {
      await ConfigWriter.writeRawConfig(cfgPath, {
        'mcp': {
          'codegraph': {'type': 'local', 'enabled': true, 'command': 'npx'},
          'time': {'type': 'local', 'enabled': false, 'command': 'uvx'},
        },
      });

      await ConfigWriter.removeMcpServer(
        'codegraph',
        global: false,
        configPath: cfgPath,
      );

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      final mcp = raw['mcp'] as Map;
      expect(mcp.length, 1);
      expect(mcp.containsKey('time'), isTrue);
    });

    test('setMcpEnabled toggles enabled flag', () async {
      await ConfigWriter.upsertMcpServer(
        'echo',
        localServer(enabled: true),
        global: false,
        configPath: cfgPath,
      );
      await ConfigWriter.setMcpEnabled(
        'echo',
        false,
        global: false,
        configPath: cfgPath,
      );

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect((raw['mcp'] as Map)['echo']['enabled'], isFalse);

      await ConfigWriter.setMcpEnabled(
        'echo',
        true,
        global: false,
        configPath: cfgPath,
      );
      final raw2 = await ConfigWriter.readRawConfig(cfgPath);
      expect((raw2['mcp'] as Map)['echo']['enabled'], isTrue);
    });

    test('setMcpEnabled throws for missing server', () async {
      await ConfigWriter.upsertMcpServer(
        'echo',
        localServer(),
        global: false,
        configPath: cfgPath,
      );
      expect(
        () => ConfigWriter.setMcpEnabled(
          'ghost',
          false,
          global: false,
          configPath: cfgPath,
        ),
        throwsA(isA<ConfigValidationError>()),
      );
    });

    test(
      'removeMcpServer deletes the server and drops empty mcp section',
      () async {
        await ConfigWriter.upsertMcpServer(
          'echo',
          localServer(),
          global: false,
          configPath: cfgPath,
        );
        await ConfigWriter.removeMcpServer(
          'echo',
          global: false,
          configPath: cfgPath,
        );

        final raw = await ConfigWriter.readRawConfig(cfgPath);
        expect(raw.containsKey('mcp'), isFalse);
      },
    );

    test('removeMcpServer no-ops when server absent', () async {
      await ConfigWriter.upsertMcpServer(
        'echo',
        localServer(),
        global: false,
        configPath: cfgPath,
      );
      await ConfigWriter.removeMcpServer(
        'ghost',
        global: false,
        configPath: cfgPath,
      );
      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect((raw['mcp'] as Map).length, 1);
    });

    test('preserves unrelated config keys (permission, etc.)', () async {
      await ConfigWriter.writeRawConfig(cfgPath, {
        'permission': {'fs_read': 'allow'},
      });
      await ConfigWriter.upsertMcpServer(
        'echo',
        localServer(),
        global: false,
        configPath: cfgPath,
      );
      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect((raw['permission'] as Map)['fs_read'], 'allow');
    });
  });

  group('ConfigWriter validation + rollback', () {
    test('writeRawConfig rejects invalid server type and rolls back', () async {
      // Seed a valid config first.
      await ConfigWriter.upsertMcpServer(
        'echo',
        localServer(),
        global: false,
        configPath: cfgPath,
      );
      final before = await File(cfgPath).readAsString();

      // Attempt to write an invalid mcp server type.
      final broken = await ConfigWriter.readRawConfig(cfgPath);
      (broken['mcp'] as Map)['bad'] = {'type': 'bogus'};
      expect(
        () => ConfigWriter.writeRawConfig(cfgPath, broken),
        throwsA(isA<ConfigValidationError>()),
      );

      // File content must be unchanged (rolled back).
      final after = await File(cfgPath).readAsString();
      expect(after, before);
      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect((raw['mcp'] as Map).containsKey('echo'), isTrue);
      expect((raw['mcp'] as Map).containsKey('bad'), isFalse);
    });

    test('writeRawConfig accepts an empty config', () async {
      await ConfigWriter.writeRawConfig(cfgPath, {});
      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw.isEmpty, isTrue);
    });

    test('writeRawConfig rejects negative timeout', () async {
      await ConfigWriter.upsertMcpServer(
        'echo',
        localServer(),
        global: false,
        configPath: cfgPath,
      );
      final broken = await ConfigWriter.readRawConfig(cfgPath);
      (broken['mcp'] as Map)['echo'] = {
        'type': 'local',
        'command': '/usr/bin/echo',
        'timeout': -1,
      };
      expect(
        () => ConfigWriter.writeRawConfig(cfgPath, broken),
        throwsA(isA<ConfigValidationError>()),
      );
    });

    test('writeRawConfig creates parent directory when missing', () async {
      final nestedPath = p.join(tmp.path, 'nested', 'dir', 'chatorai.json');
      await ConfigWriter.writeRawConfig(nestedPath, {});
      expect(await File(nestedPath).exists(), isTrue);
    });

    test('readRawConfig throws on pre-existing malformed JSON', () async {
      await File(cfgPath).writeAsString('not valid json {{{');
      expect(
        () => ConfigWriter.readRawConfig(cfgPath),
        throwsA(isA<ConfigValidationError>()),
      );
    });

    test('writeRawConfig is atomic (no .tmp left behind)', () async {
      await ConfigWriter.writeRawConfig(cfgPath, {});
      final dir = Directory(tmp.path);
      final leftover = await dir
          .list()
          .where((e) => e.path.endsWith('.tmp'))
          .toList();
      expect(leftover, isEmpty);
    });

    test('writeRawConfig recovers a pre-corrupted file', () async {
      await File(cfgPath).writeAsString('[1,2,3]');
      await ConfigWriter.writeRawConfig(cfgPath, {});
      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw.isEmpty, isTrue);
    });
  });
}
