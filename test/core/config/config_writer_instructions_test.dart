import 'dart:io';

import 'package:chatorai/core/config/config_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late String cfgPath;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cfg_writer_instr_test_');
    cfgPath = p.join(tmp.path, 'chatorai.json');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('ConfigWriter instructions', () {
    test('addInstruction creates instructions array and round-trips', () async {
      await ConfigWriter.addInstruction('AGENTS.md', configPath: cfgPath);

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw['instructions'], isA<List>());
      expect(raw['instructions'], contains('AGENTS.md'));
    });

    test('addInstruction is idempotent (no duplicates)', () async {
      await ConfigWriter.addInstruction('AGENTS.md', configPath: cfgPath);
      await ConfigWriter.addInstruction('AGENTS.md', configPath: cfgPath);

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      final list = raw['instructions'] as List;
      expect(list.where((e) => e == 'AGENTS.md').length, 1);
    });

    test('addInstruction appends preserving order', () async {
      await ConfigWriter.addInstruction('a.md', configPath: cfgPath);
      await ConfigWriter.addInstruction('b.md', configPath: cfgPath);

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw['instructions'], ['a.md', 'b.md']);
    });

    test('removeInstruction removes a single entry', () async {
      await ConfigWriter.addInstruction('a.md', configPath: cfgPath);
      await ConfigWriter.addInstruction('b.md', configPath: cfgPath);
      await ConfigWriter.removeInstruction('a.md', configPath: cfgPath);

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw['instructions'], ['b.md']);
    });

    test('removeInstruction drops the key when list becomes empty', () async {
      await ConfigWriter.addInstruction('a.md', configPath: cfgPath);
      await ConfigWriter.removeInstruction('a.md', configPath: cfgPath);

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw.containsKey('instructions'), isFalse);
    });

    test('removeInstruction is a no-op for a missing entry', () async {
      await ConfigWriter.addInstruction('a.md', configPath: cfgPath);
      await ConfigWriter.removeInstruction('missing.md', configPath: cfgPath);

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw['instructions'], ['a.md']);
    });

    test('updateInstruction replaces in place preserving position', () async {
      await ConfigWriter.addInstruction('a.md', configPath: cfgPath);
      await ConfigWriter.addInstruction('b.md', configPath: cfgPath);
      await ConfigWriter.addInstruction('c.md', configPath: cfgPath);

      await ConfigWriter.updateInstruction(
        'b.md',
        'B2.md',
        configPath: cfgPath,
      );

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw['instructions'], ['a.md', 'B2.md', 'c.md']);
    });

    test('updateInstruction dedupes if new value already present', () async {
      await ConfigWriter.addInstruction('a.md', configPath: cfgPath);
      await ConfigWriter.addInstruction('b.md', configPath: cfgPath);

      await ConfigWriter.updateInstruction('b.md', 'a.md', configPath: cfgPath);

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw['instructions'], ['a.md']);
    });

    test('preserves other config keys untouched', () async {
      await ConfigWriter.writeRawConfig(cfgPath, {
        'version': 1,
        'permission': <String, dynamic>{},
        'instructions': <String>['keep.md'],
      });

      await ConfigWriter.addInstruction('new.md', configPath: cfgPath);

      final raw = await ConfigWriter.readRawConfig(cfgPath);
      expect(raw['version'], 1);
      expect(raw['permission'], isA<Map>());
      expect(raw['instructions'], ['keep.md', 'new.md']);
    });
  });
}
