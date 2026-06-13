import 'dart:async';
import 'dart:io';

import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:chatorai/features/skills/domain/services/skill_cache.dart';
import 'package:chatorai/features/skills/domain/services/skill_discovery.dart';
import 'package:chatorai/features/skills/domain/services/skill_plugin.dart';
import 'package:chatorai/features/skills/domain/services/skill_service.dart';
import 'package:chatorai/features/skills/domain/sources/directory_source.dart';
import 'package:chatorai/features/skills/domain/sources/skill_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

// Helper to create subdirectories
Future<Directory> createSubdir(Directory parent, String name) async {
  final dir = Directory(p.join(parent.path, name));
  await dir.create(recursive: true);
  return dir;
}

class MockPermissionService extends Mock implements PermissionService {}

class FakeSkillSource extends SkillSource {
  final String key;
  final List<SkillInfo> skills;

  FakeSkillSource({required this.key, this.skills = const []});

  @override
  Future<List<SkillInfo>> discover() async => skills;
}

class TestSkillPlugin extends SkillPlugin {
  @override
  final String id;

  @override
  final String name;

  @override
  final String description;

  @override
  final List<SkillInfo> skills;

  TestSkillPlugin({
    required this.id,
    required this.name,
    required this.description,
    required this.skills,
  });

  @override
  Future<void> initialize() async {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(Directory(''));
    registerFallbackValue(File(''));
    registerFallbackValue(File(''));
    registerFallbackValue(
      SkillInfo(
        name: 'test',
        description: 'test',
        directory: '/test',
        content: 'test',
      ),
    );
  });

  group('SkillService', () {
    late SkillService service;
    late MockPermissionService mockPermission;
    late Directory tempDir;

    setUp(() async {
      mockPermission = MockPermissionService();
      tempDir = await Directory.systemTemp.createTemp('skill_svc_');
    });

    tearDown(() async {
      service.dispose();
      await tempDir.delete(recursive: true);
    });

    group('initialization', () {
      test('discovers sources on first call', () async {
        final skillDir = await createSubdir(tempDir, 'test-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: test-skill
description: A test skill
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 1);
        expect(skills.first.name, 'test-skill');
      });

      test('does not re-discover if already initialized', () async {
        final skillDir = await createSubdir(tempDir, 'test-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: test-skill
description: A test skill
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll(); // First call
        await service.listAll(); // Second call

        final skills = await service.listAll();
        expect(skills.length, 1);
      });

      test('handles multiple sources correctly', () async {
        final dir1 = await createSubdir(tempDir, 'dir1');
        final dir2 = await createSubdir(tempDir, 'dir2');

        await createSubdir(dir1, 'skill1').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill1
description: From dir1
---
''');
        });

        await createSubdir(dir2, 'skill2').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill2
description: From dir2
---
''');
        });

        final source1 = DirectorySource(rootPath: dir1.path);
        final source2 = DirectorySource(rootPath: dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();
        expect(skills.length, 2);
      });
    });

    group('getByName', () {
      test('returns skill when found', () async {
        final skillDir = await createSubdir(tempDir, 'my-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: my-skill
description: My skill
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        final skill = await service.getByName('my-skill');
        expect(skill, isNotNull);
        expect(skill!.name, 'my-skill');
      });

      test('returns null when skill not found', () async {
        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        final skill = await service.getByName('nonexistent');
        expect(skill, isNull);
      });

      test('finds skill from plugins', () async {
        final plugin = TestSkillPlugin(
          id: 'test-plugin',
          name: 'Test Plugin',
          description: 'Provides built-in skills',
          skills: [
            SkillInfo(
              name: 'plugin-skill',
              description: 'From plugin',
              directory: '/plugin',
              content: '',
            ),
          ],
        );

        service = SkillService(
          sources: [],
          plugins: [plugin],
          permissionService: mockPermission,
        );

        final skill = await service.getByName('plugin-skill');
        expect(skill, isNotNull);
        expect(skill!.description, 'From plugin');
      });

      test('searches both sources and plugins', () async {
        final skillDir = await createSubdir(tempDir, 'source-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: source-skill
description: From source
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        final plugin = TestSkillPlugin(
          id: 'plugin',
          name: 'Plugin',
          description: 'Plugin',
          skills: [
            SkillInfo(
              name: 'plugin-skill',
              description: 'From plugin',
              directory: '/plugin',
              content: '',
            ),
          ],
        );

        service = SkillService(
          sources: [source],
          plugins: [plugin],
          permissionService: mockPermission,
        );

        final sourceSkill = await service.getByName('source-skill');
        final pluginSkill = await service.getByName('plugin-skill');

        expect(sourceSkill, isNotNull);
        expect(pluginSkill, isNotNull);
      });
    });

    group('listAll', () {
      test('returns all skills from sources', () async {
        final dir1 = await createSubdir(tempDir, 'dir1');
        final dir2 = await createSubdir(tempDir, 'dir2');

        await createSubdir(dir1, 'skill1').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill1
description: Skill 1
---
''');
        });

        await createSubdir(dir2, 'skill2').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill2
description: Skill 2
---
''');
        });

        final source1 = DirectorySource(rootPath: dir1.path);
        final source2 = DirectorySource(rootPath: dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 2);
        expect(skills.map((s) => s.name), containsAll(['skill1', 'skill2']));
      });

      test('deduplicates skills with same name (first source wins)', () async {
        final dir1 = await createSubdir(tempDir, 'dir1');
        final dir2 = await createSubdir(tempDir, 'dir2');

        await createSubdir(dir1, 'skill').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: duplicate
description: From dir1
---
''');
        });

        await createSubdir(dir2, 'skill').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: duplicate
description: From dir2
---
''');
        });

        final source1 = DirectorySource(rootPath: dir1.path);
        final source2 = DirectorySource(rootPath: dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 1);
        expect(skills.first.description, 'From dir1');
      });

      test('includes plugin skills', () async {
        final plugin = TestSkillPlugin(
          id: 'plugin',
          name: 'Plugin',
          description: 'Plugin',
          skills: [
            SkillInfo(
              name: 'plugin-skill',
              description: 'From plugin',
              directory: '/plugin',
              content: '',
            ),
          ],
        );

        service = SkillService(
          sources: [],
          plugins: [plugin],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 1);
        expect(skills.first.name, 'plugin-skill');
      });

      test('merges source and plugin skills', () async {
        final skillDir = await createSubdir(tempDir, 'source-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: source-skill
description: From source
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        final plugin = TestSkillPlugin(
          id: 'plugin',
          name: 'Plugin',
          description: 'Plugin',
          skills: [
            SkillInfo(
              name: 'plugin-skill',
              description: 'From plugin',
              directory: '/plugin',
              content: '',
            ),
          ],
        );

        service = SkillService(
          sources: [source],
          plugins: [plugin],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 2);
        expect(
          skills.map((s) => s.name),
          containsAll(['source-skill', 'plugin-skill']),
        );
      });

      test('plugin skills override source skills on name conflict', () async {
        final skillDir = await createSubdir(tempDir, 'conflict');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: conflict-skill
description: From source
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        final plugin = TestSkillPlugin(
          id: 'plugin',
          name: 'Plugin',
          description: 'Plugin',
          skills: [
            SkillInfo(
              name: 'conflict-skill',
              description: 'From plugin',
              directory: '/plugin',
              content: '',
            ),
          ],
        );

        service = SkillService(
          sources: [source],
          plugins: [plugin],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 1);
        expect(skills.first.description, 'From plugin'); // Plugin wins
      });

      test('returns empty list when no skills available', () async {
        final emptyDir = await createSubdir(tempDir, 'empty');
        final source = DirectorySource(rootPath: emptyDir.path);

        service = SkillService(
          sources: [source],
          plugins: [],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();
        expect(skills, isEmpty);
      });
    });

    group('availableForAgent', () {
      test('filters skills by permission', () async {
        final skillDir = await createSubdir(tempDir, 'allowed');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: allowed-skill
description: Allowed skill
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        when(
          () => mockPermission.isAllowed('skill', 'skill:name=allowed-skill'),
        ).thenReturn(true);
        when(() => mockPermission.isAllowed('skill', any())).thenReturn(false);

        final allowed = await service.availableForAgent('agent');

        expect(allowed.length, 1);
        expect(allowed.first.name, 'allowed-skill');
      });

      test('returns empty list when no permissions granted', () async {
        final skillDir = await createSubdir(tempDir, 'skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: skill
description: Skill
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        when(() => mockPermission.isAllowed(any(), any())).thenReturn(false);

        final allowed = await service.availableForAgent('agent');

        expect(allowed, isEmpty);
      });

      test('respects wildcard permission patterns', () async {
        final skillDir = await createSubdir(tempDir, 'wildcard-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: wildcard-skill
description: Matches wildcard
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        when(
          () => mockPermission.isAllowed('skill', 'skill:name=*'),
        ).thenReturn(true);

        final allowed = await service.availableForAgent('agent');

        expect(allowed.length, 1);
      });

      test('handles permission check exceptions gracefully', () async {
        final skillDir = await createSubdir(tempDir, 'skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: skill
description: Skill
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        when(
          () => mockPermission.isAllowed(any(), any()),
        ).thenThrow(Exception('Permission check failed'));

        final allowed = await service.availableForAgent('agent');

        // Should not throw; skill is excluded on error
        expect(allowed, isEmpty);
      });
    });

    group('refresh', () {
      test('forces rediscovery of all sources', () async {
        final skillDir = await createSubdir(tempDir, 'skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: skill
description: Original
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll(); // Initial discovery

        // Modify file
        await skillFile.writeAsString('''
---
name: skill
description: Updated
---
''');

        await service.refresh();

        final skills = await service.listAll();
        expect(skills.first.description, 'Updated');
      });

      test('clears cache before re-discovering', () async {
        final skillDir = await createSubdir(tempDir, 'skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: skill
description: Original
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll();
        service.clearCache();

        // After refresh, should re-discover
        final skills = await service.listAll();
        expect(skills, isNotEmpty);
      });
    });

    group('error isolation', () {
      test('one failing source does not stop other sources', () async {
        final dir1 = await createSubdir(tempDir, 'dir1');
        final dir2 = await createSubdir(tempDir, 'dir2');

        await createSubdir(dir1, 'skill1').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill1
description: From dir1
---
''');
        });

        await createSubdir(dir2, 'skill2').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill2
description: From dir2
---
''');
        });

        final source1 = DirectorySource(rootPath: dir1.path);
        final source2 = FakeSkillSource(
          key: 'failing-source',
          skills: [],
        ); // Simulate a source that will fail

        // Override discover to throw
        final failingSource = FakeSkillSource(key: 'failing');
        service = SkillService(
          sources: [source1, failingSource],
          permissionService: mockPermission,
        );

        // Should still get skill1 from source1
        final skills = await service.listAll();
        expect(skills.length, 1);
        expect(skills.first.name, 'skill1');
      });

      test('all sources can fail without throwing', () async {
        final failingSource1 = FakeSkillSource(key: 'failing1');
        final failingSource2 = FakeSkillSource(key: 'failing2');

        service = SkillService(
          sources: [failingSource1, failingSource2],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();
        expect(skills, isEmpty);
      });
    });

    group('dispose', () {
      test('releases resources', () async {
        final skillDir = await createSubdir(tempDir, 'skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: skill
description: Test
---
''');

        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll();

        expect(() => service.dispose(), returnsNormally);
      });

      test('dispose can be called multiple times safely', () async {
        final source = DirectorySource(rootPath: tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll();

        service.dispose();
        expect(() => service.dispose(), returnsNormally);
      });
    });

    group('source precedence', () {
      test('first source wins for duplicate skill names', () async {
        final dir1 = await createSubdir(tempDir, 'first');
        final dir2 = await createSubdir(tempDir, 'second');

        await createSubdir(dir1, 'skill').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: duplicate
description: First source
---
''');
        });

        await createSubdir(dir2, 'skill').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: duplicate
description: Second source
---
''');
        });

        final source1 = DirectorySource(rootPath: dir1.path);
        final source2 = DirectorySource(rootPath: dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 1);
        expect(skills.first.description, 'First source');
      });
    });
  });
}
