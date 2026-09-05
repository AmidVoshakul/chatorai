import 'dart:io';

import 'package:chatorai/core/skills/skill_marketplace_catalog.dart';
import 'package:chatorai/core/skills/skill_writer.dart';
import 'package:chatorai/gui/features/settings/providers/skills_management_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late Directory projectRoot;
  late String globalRoot;
  late SkillWriter writer;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('skills_mgmt_test');
    projectRoot = Directory(p.join(tmp.path, 'project'))
      ..createSync(recursive: true);
    globalRoot = p.join(tmp.path, 'global', 'skills');
    Directory(globalRoot).createSync(recursive: true);
    writer = SkillWriter(
      globalConfigDir: () async => p.join(tmp.path, 'global'),
    );
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<ProviderContainer> makeContainer({
    bool supportsProject = true,
    Future<String> Function(String)? assetLoader,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(skillsManagementProvider.notifier);
    notifier.configureForTest(
      writer: writer,
      projectRoot: projectRoot,
      globalRoot: globalRoot,
      supportsProjectScope: supportsProject,
      assetLoader: assetLoader,
    );
    await container.read(skillsManagementProvider.future);
    await notifier.refresh();
    return container;
  }

  void writeSkill(String root, String slug, String name) {
    final dir = Directory(p.join(root, slug))..createSync(recursive: true);
    File(p.join(dir.path, 'SKILL.md')).writeAsStringSync(
      '---\nname: $name\ndescription: desc of $name\n---\nbody',
    );
  }

  SkillsManagementState current(ProviderContainer c) =>
      c.read(skillsManagementProvider).requireValue;

  group('reload', () {
    test('loads global and project scopes separately', () async {
      writeSkill(globalRoot, 'g1', 'Global One');
      writeSkill(p.join(projectRoot.path, '.chatorai', 'skills'), 'p1', 'Proj');

      final c = await makeContainer();
      final state = current(c);

      expect(state.global.skills.map((s) => s.name), ['Global One']);
      expect(state.project.skills.map((s) => s.name), ['Proj']);
      expect(state.supportsProjectScope, isTrue);
      expect(state.projectRootPath, projectRoot.path);
    });

    test('project scope aggregates all default project paths', () async {
      writeSkill(p.join(projectRoot.path, '.chatorai', 'skills'), 'a', 'A');
      writeSkill(p.join(projectRoot.path, '.agents', 'skills'), 'b', 'B');
      writeSkill(p.join(projectRoot.path, '.claude', 'skills'), 'c', 'C');

      final c = await makeContainer();
      final state = current(c);

      expect(state.project.skills.map((s) => s.name), ['A', 'B', 'C']);
    });

    test('classifies managed vs read-only by canonical root', () async {
      // .chatorai/skills is managed; .agents/skills is read-only for project.
      writeSkill(p.join(projectRoot.path, '.chatorai', 'skills'), 'm', 'M');
      writeSkill(p.join(projectRoot.path, '.agents', 'skills'), 'r', 'R');

      final c = await makeContainer();
      final state = current(c);

      expect(state.project.managed.map((s) => s.name), ['M']);
      expect(state.project.readOnly.map((s) => s.name), ['R']);
    });

    test('hides project scope when unsupported (mobile)', () async {
      writeSkill(globalRoot, 'g1', 'Global One');
      final c = await makeContainer(supportsProject: false);
      final state = current(c);

      expect(state.supportsProjectScope, isFalse);
      expect(state.project.skills, isEmpty);
      expect(state.projectRootPath, isNull);
      expect(state.global.skills.map((s) => s.name), ['Global One']);
    });
  });

  group('createSkill', () {
    test(
      'writes a managed skill into the scope root and appears in state',
      () async {
        final c = await makeContainer();

        await c
            .read(skillsManagementProvider.notifier)
            .createSkill(
              scope: SkillsScope.project,
              name: 'New Skill',
              description: 'a new one',
              content: 'hello body',
            );

        final state = c.read(skillsManagementProvider).requireValue;
        expect(state.project.managed.map((s) => s.name), contains('New Skill'));
        final onDisk = File(
          p.join(
            projectRoot.path,
            '.chatorai',
            'skills',
            'new-skill',
            'SKILL.md',
          ),
        );
        expect(onDisk.existsSync(), isTrue);
      },
    );

    test('creates global skills in the global root', () async {
      final c = await makeContainer();

      await c
          .read(skillsManagementProvider.notifier)
          .createSkill(
            scope: SkillsScope.global,
            name: 'G Skill',
            description: 'global',
          );

      final onDisk = File(p.join(globalRoot, 'g-skill', 'SKILL.md'));
      expect(onDisk.existsSync(), isTrue);
    });
  });

  group('deleteSkill', () {
    test('removes a managed skill from disk and state', () async {
      writeSkill(p.join(projectRoot.path, '.chatorai', 'skills'), 'del', 'Del');
      final c = await makeContainer();
      var state = current(c);
      final skill = state.project.managed.firstWhere((s) => s.name == 'Del');

      await c
          .read(skillsManagementProvider.notifier)
          .deleteSkill(scope: SkillsScope.project, skill: skill);

      state = c.read(skillsManagementProvider).requireValue;
      expect(state.project.managed.where((s) => s.name == 'Del'), isEmpty);
      expect(Directory(skill.directory).existsSync(), isFalse);
    });
  });

  group('saveSkillFile', () {
    test('rewrites SKILL.md content', () async {
      final c = await makeContainer();
      await c
          .read(skillsManagementProvider.notifier)
          .createSkill(
            scope: SkillsScope.global,
            name: 'Editable',
            description: 'd',
            content: 'v1',
          );
      var state = c.read(skillsManagementProvider).requireValue;
      final skill = state.global.managed.firstWhere(
        (s) => s.name == 'Editable',
      );

      const updated = '---\nname: Editable\ndescription: d2\n---\nv2';
      await c
          .read(skillsManagementProvider.notifier)
          .saveSkillFile(skill, updated);

      state = c.read(skillsManagementProvider).requireValue;
      final reread = state.global.managed.firstWhere(
        (s) => s.name == 'Editable',
      );
      expect(reread.description, 'd2');
      expect(reread.content, contains('v2'));
    });
  });

  group('marketplace', () {
    SkillMarketplaceEntry bundledEntry() =>
        skillMarketplaceCatalog.firstWhere((e) => e.isBundled);

    test('installBundled loads asset and writes managed skill', () async {
      final entry = bundledEntry();
      final md =
          '---\nname: ${entry.displayName}\ndescription: d\n---\nbundled body';
      final loaded = <String>[];
      final c = await makeContainer(
        assetLoader: (path) async {
          loaded.add(path);
          return md;
        },
      );

      await c
          .read(skillsManagementProvider.notifier)
          .installBundled(scope: SkillsScope.global, entry: entry);

      expect(loaded, [entry.assetPath]);
      final onDisk = File(p.join(globalRoot, entry.id, 'SKILL.md'));
      expect(onDisk.existsSync(), isTrue);
      expect(onDisk.readAsStringSync(), md);
    });

    test('isInstalled reflects installed bundled skill', () async {
      final entry = bundledEntry();
      final md = '---\nname: ${entry.displayName}\ndescription: d\n---\nx';
      final c = await makeContainer(assetLoader: (_) async => md);
      final notifier = c.read(skillsManagementProvider.notifier);

      expect(
        notifier.isInstalled(scope: SkillsScope.global, entry: entry),
        isFalse,
      );

      await notifier.installBundled(scope: SkillsScope.global, entry: entry);

      expect(
        notifier.isInstalled(scope: SkillsScope.global, entry: entry),
        isTrue,
      );
      expect(
        notifier.isInstalled(scope: SkillsScope.project, entry: entry),
        isFalse,
      );
    });

    test('loadEntryContent returns the raw asset body for preview', () async {
      final entry = bundledEntry();
      final md = '---\nname: ${entry.displayName}\ndescription: d\n---\nbody';
      final loaded = <String>[];
      final c = await makeContainer(
        assetLoader: (path) async {
          loaded.add(path);
          return md;
        },
      );

      final content = await c
          .read(skillsManagementProvider.notifier)
          .loadEntryContent(entry);

      expect(content, md);
      expect(loaded, [entry.assetPath]);
    });

    test(
      'loadEntryDescription parses description from asset frontmatter',
      () async {
        final entry = bundledEntry();
        const desc = 'Parsed from frontmatter';
        final md =
            '---\nname: ${entry.displayName}\ndescription: $desc\n---\nbody';
        final c = await makeContainer(assetLoader: (_) async => md);

        final parsed = await c
            .read(skillsManagementProvider.notifier)
            .loadEntryDescription(entry);

        expect(parsed, desc);
      },
    );

    test('loadEntryDescription returns null when asset load fails', () async {
      final entry = bundledEntry();
      final c = await makeContainer(
        assetLoader: (_) async => throw Exception('missing asset'),
      );

      final parsed = await c
          .read(skillsManagementProvider.notifier)
          .loadEntryDescription(entry);

      expect(parsed, isNull);
    });
  });
}
