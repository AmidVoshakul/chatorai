import 'dart:io';

import 'package:chatorai/core/config/agents_file_service.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/features/settings/providers/instructions_management_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late Directory projectRoot;
  late Directory globalDir;
  late String projectCfgPath;
  late String globalCfgPath;
  late ProviderContainer container;
  late InstructionsManagementNotifier notifier;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('instr_mgmt_test_');
    projectRoot = Directory(p.join(tmp.path, 'project'));
    globalDir = Directory(p.join(tmp.path, 'global'));
    await projectRoot.create(recursive: true);
    await globalDir.create(recursive: true);
    projectCfgPath = p.join(projectRoot.path, '.chatorai', 'chatorai.json');
    globalCfgPath = p.join(globalDir.path, 'chatorai.json');

    container = ProviderContainer();
    notifier = container.read(instructionsManagementProvider.notifier);
    notifier.configureForTest(
      agentsFiles: AgentsFileService(
        globalConfigDir: () async => globalDir.path,
      ),
      globalConfigPath: globalCfgPath,
      projectRoot: projectRoot,
      supportsProjectScope: true,
    );
    await container.read(instructionsManagementProvider.future);
    await notifier.refresh();
  });

  tearDown(() async {
    container.dispose();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  InstructionsManagementState read() =>
      container.read(instructionsManagementProvider).requireValue;

  Future<InstructionsManagementState> refreshed() async {
    await notifier.refresh();
    return read();
  }

  group('scope wiring', () {
    test('reports desktop project scope with the working directory', () {
      expect(read().supportsProjectScope, isTrue);
      expect(read().projectRootPath, projectRoot.path);
    });

    test('mobile hides the project scope entirely', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(instructionsManagementProvider.notifier);
      n.configureForTest(
        agentsFiles: AgentsFileService(
          globalConfigDir: () async => globalDir.path,
        ),
        globalConfigPath: globalCfgPath,
        projectRoot: projectRoot,
        supportsProjectScope: false,
      );
      await c.read(instructionsManagementProvider.future);
      await n.refresh();
      final s = c.read(instructionsManagementProvider).requireValue;
      expect(s.supportsProjectScope, isFalse);
      expect(s.projectRootPath, isNull);
      expect(s.project.discovered, isEmpty);
      expect(s.project.entries, isEmpty);
    });
  });

  group('discovered files', () {
    test('global scope always shows the global AGENTS.md card', () async {
      // Even when the file does not exist yet, the global card is present so
      // the user can create it.
      expect(read().global.discovered, hasLength(1));
      final card = read().global.discovered.single;
      expect(card.name, 'AGENTS.md');
      expect(card.isGlobal, isTrue);
      expect(card.editable, isTrue);
      expect(card.exists, isFalse);
    });

    test('project scope lists only files that exist on disk', () async {
      // Nothing on disk => no project cards (fixes the phantom-card bug).
      expect(read().project.discovered, isEmpty);

      await File(p.join(projectRoot.path, 'AGENTS.md')).writeAsString('PROJ');
      await File(p.join(projectRoot.path, 'CLAUDE.md')).writeAsString('CL');

      final s = await refreshed();
      final names = s.project.discovered.map((f) => f.name).toList();
      expect(names, containsAll(['AGENTS.md', 'CLAUDE.md']));
      expect(s.project.discovered.every((f) => f.exists), isTrue);
      final claude = s.project.discovered.firstWhere(
        (f) => f.name == 'CLAUDE.md',
      );
      expect(claude.editable, isFalse);
    });

    test('readDiscoveredFile returns file contents', () async {
      final path = p.join(projectRoot.path, 'AGENTS.md');
      await File(path).writeAsString('BODY');
      expect(await notifier.readDiscoveredFile(path), 'BODY');
    });

    test(
      'saveDiscoveredAgents writes file and reload reflects exists',
      () async {
        final path = p.join(projectRoot.path, 'AGENTS.md');
        await notifier.saveDiscoveredAgents(path, '# Project rules');
        expect(await File(path).readAsString(), '# Project rules');

        final card = read().project.discovered.firstWhere(
          (f) => f.path == path,
        );
        expect(card.exists, isTrue);
      },
    );

    test('createProjectAgents creates <root>/AGENTS.md', () async {
      await notifier.createProjectAgents('# Hello');
      final file = File(p.join(projectRoot.path, 'AGENTS.md'));
      expect(await file.readAsString(), '# Hello');
      expect(
        read().project.discovered.any((f) => f.name == 'AGENTS.md'),
        isTrue,
      );
    });
  });

  group('inline instructions (project scope)', () {
    test('addInlineInstruction writes file and config entry', () async {
      await notifier.addInlineInstruction('My Style', 'Always test first.');

      expect(read().project.entries.length, 1);
      final entry = read().project.entries.first;
      expect(entry, p.join('.chatorai', 'instructions', 'my-style.md'));

      final file = File(p.join(projectRoot.path, entry));
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), 'Always test first.');

      final raw = await ConfigWriter.readRawConfig(projectCfgPath);
      expect(raw['instructions'], contains(entry));
    });

    test('removeInstruction deletes managed file and config entry', () async {
      await notifier.addInlineInstruction('Doc', 'body');
      final entry = read().project.entries.first;
      final file = File(p.join(projectRoot.path, entry));
      expect(await file.exists(), isTrue);

      await notifier.removeInstruction(entry);

      expect(read().project.entries, isEmpty);
      expect(await file.exists(), isFalse);
    });

    test('removeInstruction keeps externally-referenced files', () async {
      await ConfigWriter.addInstruction(
        'AGENTS.md',
        configPath: projectCfgPath,
      );
      final external = File(p.join(projectRoot.path, 'AGENTS.md'));
      await external.writeAsString('keep me');

      final s = await refreshed();
      expect(s.project.entries, contains('AGENTS.md'));

      await notifier.removeInstruction('AGENTS.md');

      expect(
        await external.exists(),
        isTrue,
        reason: 'external file must not be deleted',
      );
      expect(read().project.entries, isNot(contains('AGENTS.md')));
    });
  });

  group('inline instructions (global scope)', () {
    test('addInlineInstruction targets the global config', () async {
      await notifier.addInlineInstruction(
        'Global Style',
        'global body',
        scope: InstructionsScope.global,
      );

      final entry = read().global.entries.first;
      expect(entry, p.join('.chatorai', 'instructions', 'global-style.md'));
      expect(read().project.entries, isEmpty);

      final raw = await ConfigWriter.readRawConfig(globalCfgPath);
      expect(raw['instructions'], contains(entry));
    });

    test(
      'global inline instruction file lives under the global config dir, '
      'never under the project root',
      () async {
        await notifier.addInlineInstruction(
          'Global Style',
          'global body',
          scope: InstructionsScope.global,
        );

        final entry = read().global.entries.first;

        // The on-disk file must sit inside the global config dir, not in the
        // project folder (this used to resolve relative to Directory.current).
        final globalFile = File(p.join(globalDir.path, entry));
        expect(await globalFile.exists(), isTrue);
        expect(await globalFile.readAsString(), 'global body');

        // And it must NOT have leaked into the project root.
        expect(
          await File(p.join(projectRoot.path, entry)).exists(),
          isFalse,
        );
      },
    );

    test(
      'removeInstruction deletes the global managed file from the global dir',
      () async {
        await notifier.addInlineInstruction(
          'Global Style',
          'global body',
          scope: InstructionsScope.global,
        );
        final entry = read().global.entries.first;
        final globalFile = File(p.join(globalDir.path, entry));
        expect(await globalFile.exists(), isTrue);

        await notifier.removeInstruction(entry, scope: InstructionsScope.global);

        expect(read().global.entries, isEmpty);
        expect(await globalFile.exists(), isFalse);
      },
    );
  });

  group('workspace switch', () {
    test('project tab reloads after the active workspace changes', () async {
      // Seed a project AGENTS.md in the initial root.
      await File(p.join(projectRoot.path, 'AGENTS.md'))
          .writeAsString('initial rules');
      await refreshed();
      expect(read().project.discovered.map((f) => f.name), contains('AGENTS.md'));

      // Simulate a workspace switch by pointing the notifier at a fresh root
      // that has no AGENTS.md, then reloading (mirrors the ref.listen trigger
      // that fires on workspaceProvider changes in the real app).
      final other = Directory(p.join(tmp.path, 'other'));
      await other.create(recursive: true);
      notifier.configureForTest(projectRoot: other);
      await refreshed();

      expect(read().project.discovered, isEmpty);
      expect(read().projectRootPath, other.path);
    });
  });

  group('uploaded file instructions', () {
    test(
      'addFileInstruction copies file into .chatorai/instructions',
      () async {
        final src = File(p.join(tmp.path, 'external_rules.md'));
        await src.writeAsString('external content');

        await notifier.addFileInstruction(src.path);

        final entry = read().project.entries.first;
        expect(entry, p.join('.chatorai', 'instructions', 'external_rules.md'));
        final copied = File(p.join(projectRoot.path, entry));
        expect(await copied.exists(), isTrue);
        expect(await copied.readAsString(), 'external content');
      },
    );
  });

  group('update', () {
    test('updateInstruction replaces the project config entry', () async {
      await ConfigWriter.addInstruction('a.md', configPath: projectCfgPath);
      await refreshed();

      await notifier.updateInstruction('a.md', 'b.md');

      final raw = await ConfigWriter.readRawConfig(projectCfgPath);
      expect(raw['instructions'], ['b.md']);
    });
  });

  group('instruction entry content edit', () {
    test('saveInstructionEntry writes file and reload reflects content', () async {
      await notifier.addInlineInstruction('Foo', 'original');
      final entry = read().project.entries.first;
      final file = File(p.join(projectRoot.path, entry));
      expect(await file.exists(), isTrue);

      await notifier.saveInstructionEntry(entry, 'updated', scope: InstructionsScope.project);

      expect(await file.readAsString(), 'updated');
      expect(read().project.entries, contains(entry));
    });

    test('readInstructionEntry returns written content', () async {
      await notifier.addInlineInstruction('Bar', 'hello world');
      final entry = read().project.entries.first;

      expect(await notifier.readInstructionEntry(entry, scope: InstructionsScope.project), 'hello world');
    });

    test('edit does not remove entry from instructions[] or chatorai.json', () async {
      await notifier.addInlineInstruction('Baz', 'body');
      final entry = read().project.entries.first;

      await notifier.saveInstructionEntry(entry, 'new body', scope: InstructionsScope.project);

      final state = await refreshed();
      expect(state.project.entries, contains(entry));
      final raw = await ConfigWriter.readRawConfig(projectCfgPath);
      expect(raw['instructions'], contains(entry));
    });
  });
}
