import 'dart:io';

import 'package:chatorai/core/config/agents_file_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late Directory globalDir;
  late AgentsFileService service;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('agents_file_test_');
    globalDir = Directory(p.join(tmp.path, 'global'));
    await globalDir.create(recursive: true);
    service = AgentsFileService(globalConfigDir: () async => globalDir.path);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('AgentsFileService global scope', () {
    test('read returns empty string when file is absent', () async {
      expect(await service.read(), '');
    });

    test('write then read round-trips', () async {
      await service.write('# Global rules\nBe concise.');
      expect(await service.read(), '# Global rules\nBe concise.');
    });

    test('resolvePath targets the global config dir', () async {
      expect(await service.resolvePath(), p.join(globalDir.path, 'AGENTS.md'));
    });

    test('write empty content removes an existing file', () async {
      await service.write('something');
      expect(await service.exists(), isTrue);
      await service.write('   ');
      expect(await service.exists(), isFalse);
    });

    test('write creates missing parent directories', () async {
      final nested = Directory(p.join(tmp.path, 'a', 'b', 'c'));
      final s = AgentsFileService(globalConfigDir: () async => nested.path);
      await s.write('deep');
      expect(await s.read(), 'deep');
    });
  });

  group('AgentsFileService project scope', () {
    late Directory projectRoot;

    setUp(() async {
      projectRoot = Directory(p.join(tmp.path, 'project'));
      await projectRoot.create(recursive: true);
    });

    test('resolvePath targets the project root', () async {
      expect(
        await service.resolvePath(projectRoot: projectRoot.path),
        p.join(projectRoot.path, 'AGENTS.md'),
      );
    });

    test('write/read round-trips independently of global', () async {
      await service.write('global-content');
      await service.write('project-content', projectRoot: projectRoot.path);

      expect(await service.read(), 'global-content');
      expect(
        await service.read(projectRoot: projectRoot.path),
        'project-content',
      );
    });

    test('exists reflects the project file only', () async {
      expect(await service.exists(projectRoot: projectRoot.path), isFalse);
      await service.write('x', projectRoot: projectRoot.path);
      expect(await service.exists(projectRoot: projectRoot.path), isTrue);
      expect(await service.exists(), isFalse);
    });

    test('readAt returns empty string for missing file', () async {
      final path = p.join(projectRoot.path, 'nested', 'CLAUDE.md');
      expect(await service.readAt(path), '');
    });

    test('writeAt/readAt round-trip at an arbitrary path', () async {
      final path = p.join(projectRoot.path, 'deep', 'AGENTS.md');
      await service.writeAt(path, 'hello');
      expect(await File(path).exists(), isTrue);
      expect(await service.readAt(path), 'hello');
    });

    test('writeAt with empty content deletes the file', () async {
      final path = p.join(projectRoot.path, 'AGENTS.md');
      await service.writeAt(path, 'x');
      expect(await File(path).exists(), isTrue);
      await service.writeAt(path, '   ');
      expect(await File(path).exists(), isFalse);
    });
  });
}
