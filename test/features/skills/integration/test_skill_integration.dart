import 'dart:io';

import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:chatorai/features/skills/domain/services/directory_source.dart';
import 'package:chatorai/features/skills/domain/services/skill_service.dart';
import 'package:chatorai/features/skills/domain/services/skill_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<Directory> createSubdir(Directory parent, String name) async {
  final dir = Directory(p.join(parent.path, name));
  await dir.create(recursive: true);
  return dir;
}

void main() {
  group('SkillService Integration', () {
    late Directory tempProjectRoot;
    late Directory tempGlobalDir;
    late SkillService service;
    late PermissionService permissionService;

    setUp(() async {
      tempProjectRoot = await Directory.systemTemp.createTemp('proj_');
      tempGlobalDir = await Directory.systemTemp.createTemp('global_');

      // Create project-local skills directory
      final projectSkills = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills',
      );

      // Create global skills directory
      await createSubdir(tempGlobalDir, 'skills');

      permissionService = PermissionService();

      // Seed permission to allow all skills for testing
      permissionService.seedRules(
        PermissionRuleset(
          rules: [
            PermissionRule(
              permission: 'skill',
              pattern: 'skill:name=*',
              action: PermissionAction.allow,
            ),
          ],
        ),
      );

      final sources = <SkillSource>[
        DirectorySource(projectSkills.path),
        DirectorySource(p.join(tempGlobalDir.path, 'skills')),
      ];

      service = SkillService(
        sources: sources,
        permissionService: permissionService,
      );
    });

    tearDown(() async {
      service.dispose();
      await tempProjectRoot.delete(recursive: true);
      await tempGlobalDir.delete(recursive: true);
    });

    test('discovers skills from multiple directories', () async {
      // Create skill in project directory
      final projectSkillDir = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills/project-skill',
      );
      final projectFile = File(p.join(projectSkillDir.path, 'SKILL.md'));
      await projectFile.writeAsString('''
---
name: project-skill
description: Project-local skill
---
''');

      // Create skill in global directory
      final globalSkillDir = await createSubdir(
        tempGlobalDir,
        'skills/global-skill',
      );
      final globalFile = File(p.join(globalSkillDir.path, 'SKILL.md'));
      await globalFile.writeAsString('''
---
name: global-skill
description: Global skill
---
''');

      final skills = await service.listAll();

      expect(skills.length, 2);
      expect(
        skills.map((s) => s.name),
        containsAll(['project-skill', 'global-skill']),
      );
    });

    test('availableForAgent returns only permitted skills', () async {
      // Create two skills
      final allowedDir = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills/allowed',
      );
      final allowedFile = File(p.join(allowedDir.path, 'SKILL.md'));
      await allowedFile.writeAsString('''
---
name: allowed
description: Allowed skill
---
''');

      final deniedDir = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills/denied',
      );
      final deniedFile = File(p.join(deniedDir.path, 'SKILL.md'));
      await deniedFile.writeAsString('''
---
name: denied
description: Denied skill
---
''');

      // Update permission to allow only 'allowed' (last-match-wins: specific after general)
      permissionService.seedRules(
        PermissionRuleset(
          rules: [
            PermissionRule(
              permission: 'skill',
              pattern: 'skill:name=*',
              action: PermissionAction.deny,
            ),
            PermissionRule(
              permission: 'skill',
              pattern: 'skill:name=allowed',
              action: PermissionAction.allow,
            ),
          ],
        ),
      );

      final available = await service.availableForAgent('test-agent');

      expect(available.length, 1);
      expect(available.first.name, 'allowed');
    });

    test('cache invalidation on SKILL.md change', () async {
      final skillDir = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills/dynamic-skill',
      );
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: dynamic-skill
description: Original description
---
''');

      // Initial discovery
      var skills = await service.listAll();
      expect(skills.first.description, 'Original description');

      // Modify the SKILL.md file
      await skillFile.writeAsString('''
---
name: dynamic-skill
description: Updated description
---
''');

      // Wait for debounce (250ms) + buffer
      await Future.delayed(const Duration(milliseconds: 500));

      // Next discovery should see the update
      skills = await service.listAll();
      expect(skills.first.description, 'Updated description');
    });

    test('handles large number of skills efficiently', () async {
      // Create 50 skills
      for (int i = 0; i < 50; i++) {
        final dir = await createSubdir(
          tempProjectRoot,
          '.chatorai/skills/skill_$i',
        );
        final file = File(p.join(dir.path, 'SKILL.md'));
        await file.writeAsString('''
---
name: skill_$i
description: Skill number $i
---
''');
      }

      final skills = await service.listAll();

      expect(skills.length, 50);
    });

    test('handles skills with many auxiliary files', () async {
      final skillDir = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills/many-files-skill',
      );
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: many-files-skill
description: Skill with 20 files
---
''');

      // Create 20 auxiliary files
      for (int i = 0; i < 20; i++) {
        final file = File(p.join(skillDir.path, 'file_$i.txt'));
        await file.writeAsString('Content $i');
      }

      final skills = await service.listAll();

      expect(skills.length, 1);
      expect(skills.first.files.length, 10); // Limited to 10
    });

    test('handles unicode in skill names and descriptions', () async {
      final skillDir = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills/навык-测试',
      );
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: навык-测试
description: Навык с юникодом 🎉 и 你好
---

# Содержание
''');

      final skills = await service.listAll();

      expect(skills.length, 1);
      expect(skills.first.name, 'навык-测试');
      expect(skills.first.description, 'Навык с юникодом 🎉 и 你好');
    });

    test('clearCache forces re-discovery', () async {
      final skillDir = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills/clear-test',
      );
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: clear-test
description: Before clear
---
''');

      // Initial discovery
      await service.listAll();

      // Clear cache
      service.clearCache();

      // Modify file
      await skillFile.writeAsString('''
---
name: clear-test
description: After clear
---
''');

      // Should see updated content
      final skills = await service.listAll();
      expect(skills.first.description, 'After clear');
    });

    test('getByName returns correct skill across sources', () async {
      final dir1 = await createSubdir(tempProjectRoot, '.chatorai/skills/dir1');
      final dir2 = await createSubdir(tempProjectRoot, '.chatorai/skills/dir2');

      final skill1Dir = await createSubdir(dir1, 'skill1');
      final file1 = File(p.join(skill1Dir.path, 'SKILL.md'));
      await file1.writeAsString('''
---
name: skill1
description: From dir1
---
''');

      final skill2Dir = await createSubdir(dir2, 'skill2');
      final file2 = File(p.join(skill2Dir.path, 'SKILL.md'));
      await file2.writeAsString('''
---
name: skill2
description: From dir2
---
''');

      final skill1 = await service.getByName('skill1');
      final skill2 = await service.getByName('skill2');

      expect(skill1!.description, 'From dir1');
      expect(skill2!.description, 'From dir2');
    });

    test('getByName returns null for non-existent skill', () async {
      final skill = await service.getByName('non-existent');
      expect(skill, isNull);
    });

    test('dispose cleans up resources', () async {
      final skillDir = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills/dispose-test',
      );
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: dispose-test
description: Dispose test
---
''');

      await service.listAll();

      expect(() => service.dispose(), returnsNormally);
    });

    test('handles directory that cannot be read', () async {
      // Create a valid skill in tempProjectRoot
      final validSkillDir = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills/valid-skill',
      );
      final validFile = File(p.join(validSkillDir.path, 'SKILL.md'));
      await validFile.writeAsString('''
---
name: valid-skill
description: Valid skill
---
''');

      // Create sources: one non-existent, one valid
      final sources = <SkillSource>[
        DirectorySource('/non/existent/path'),
        DirectorySource(tempProjectRoot.path),
      ];

      final failingService = SkillService(
        sources: sources,
        permissionService: permissionService,
      );

      final skills = await failingService.listAll();

      // Should still get skills from the valid path
      expect(skills.isNotEmpty, isTrue);
      expect(skills.any((s) => s.name == 'valid-skill'), isTrue);
    });

    test('skill files are sorted alphabetically', () async {
      final skillDir = await createSubdir(
        tempProjectRoot,
        '.chatorai/skills/sorted-skill',
      );
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: sorted-skill
description: Test sorting
---
''');

      // Create files in reverse order
      final files = ['z.txt', 'a.txt', 'm.txt', 'b.txt'];
      for (final fileName in files) {
        final file = File(p.join(skillDir.path, fileName));
        await file.writeAsString('Content');
      }

      final skills = await service.listAll();

      expect(
        skills.first.files,
        orderedEquals(['a.txt', 'b.txt', 'm.txt', 'z.txt']),
      );
    });
  });
}
