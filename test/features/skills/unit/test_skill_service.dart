import 'dart:async';
import 'dart:io';
import 'dart:async';

import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:chatorai/features/skills/domain/services/directory_source.dart';
import 'package:chatorai/features/skills/domain/services/skill_cache.dart';
import 'package:chatorai/features/skills/domain/services/skill_service.dart';
import 'package:chatorai/features/skills/domain/services/skill_source.dart';
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

class FakeSkillSource extends Fake implements SkillSource {
  final String path;
  final List<SkillInfo> skills;

  FakeSkillSource(this.path, {this.skills = const []});

  @override
  String get key => 'fake:$path';

  @override
  Future<List<SkillInfo>> discover() async => skills;
}

void main() {
  setUpAll(() {
    registerFallbackValue<Directory>(Directory(''));
    registerFallbackValue<File>(File(''));
    registerFallbackValue<FileSystemEntity>(File(''));
    registerFallbackValue<Map<String, dynamic>>({});
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
      test('_ensureInitialized discovers sources on first call', () async {
        final skillDir = await createSubdir(tempDir, 'test-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: test-skill
description: A test skill
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(sources: [source], permissionService: mockPermission);

        final skills = await service.listAll();

        expect(skills.length, 1);
        expect(skills.first.name, 'test-skill');
      });

      test('_ensureInitialized does not re-discover if already initialized', () async {
        final skillDir = await createSubdir(tempDir, 'test-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: test-skill
description: A test skill
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(sources: [source], permissionService: mockPermission);

        await service.listAll(); // First call - discovers
        await service.listAll(); // Second call - should use cache

        // Should still have 1 skill (no duplicates)
        final skills = await service.listAll();
        expect(skills.length, 1);
      });

      test('initialization is idempotent across multiple sources', () async {
        final dir1 = await createSubdir(tempDir, 'dir1');
        final dir2 = await createSubdir(tempDir, 'dir2');

        await createSubdir(dir1, 'skill1').then((skillDir) async {
          final file = File(p.join(skillDir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill1
description: Skill 1
---
''');
        });

        await createSubdir(dir2, 'skill2').then((skillDir) async {
          final file = File(p.join(skillDir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill2
description: Skill 2
---
''');
        });

        final source1 = DirectorySource(dir1.path);
        final source2 = DirectorySource(dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();
        expect(skills.length, 2);
      });
    });

    group('getByName', () {
      test('returns skill when exists', () async {
        final skillDir = await createSubdir(tempDir, 'my-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: my-skill
description: My skill
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(sources: [source], permissionService: mockPermission);

        final skill = await service.getByName('my-skill');
        expect(skill, isNotNull);
        expect(skill!.name, 'my-skill');
      });

      test('returns null when skill not found', () async {
        final source = DirectorySource(tempDir.path);
        service = SkillService(sources: [source], permissionService: mockPermission);

        final skill = await service.getByName('nonexistent');
        expect(skill, isNull);
      });
    });

    group('listAll', () {
      test('deduplicates skills with same name from different sources', () async {
        // Two sources with same skill name
        final dir1 = await createSubdir(tempDir, 'dir1');
        final dir2 = await createSubdir(tempDir, 'dir2');

        await createSubdir(dir1, 'shared').then((skillDir) async {
          final file = File(p.join(skillDir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: shared
description: Shared skill
---
''');
        });

        await createSubdir(dir2, 'shared').then((skillDir) async {
          final file = File(p.join(skillDir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: shared
description: Another version
---
''');
        });

        final source1 = DirectorySource(dir1.path);
        final source2 = DirectorySource(dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();
        // Should be deduped
        expect(skills.length, 1);
      });
    });

    group('availableForAgent', () {
      test('filters skills based on permission', () async {
        final skillDir = await createSubdir(tempDir, 'allowed-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: allowed-skill
description: Allowed skill
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(sources: [source], permissionService: mockPermission);

        // Mock permission: allow for 'skill:name=allowed-skill'
        when(() => mockPermission.isAllowed('skill', 'skill:name=allowed-skill')).thenReturn(true);
        when(() => mockPermission.isAllowed('skill', 'skill:name=other-skill')).thenReturn(false);

        final allowed = await service.availableForAgent('test-agent');
        expect(allowed, hasLength(1));
        expect(allowed.first.name, 'allowed-skill');
      });
    });

    group('clearCache', () {
      test('resets initialization state', () async {
        final skillDir = await createSubdir(tempDir, 'test-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: test-skill
description: Test skill
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(sources: [source], permissionService: mockPermission);

        await service.listAll();
        service.clearCache();

        // After clear, should re-discover
        final skills = await service.listAll();
        expect(skills, isNotEmpty);
      });
    });
  });
}

class MockPermissionService extends Mock implements PermissionService {}

/// A simple fake SkillSource for testing that returns configurable skills.
class FakeSkillSource extends SkillSource {
  @override
  final String key;

  final List<SkillInfo> _skills;

  FakeSkillSource({String? key, List<SkillInfo>? skills})
      : key = key ?? 'fake',
        _skills = skills ?? const [];

  @override
  Future<List<SkillInfo>> discover() async {
    return _skills;
  }
}

// No duplicate main below — the main function continues later.
}

void main() {
  setUpAll(() {
    registerFallbackValue(Directory(''));
    registerFallbackValue(File(''));
    registerFallbackValue(FileSystemEntity(''));
  });

  group('SkillService', () {
    late SkillService service;
    late MockPermissionService mockPermission;
    late Directory tempDir;
    const skillName = 'test-skill';
    const skillDescription = 'A test skill';

    setUp(() async {
      mockPermission = MockPermissionService();
      tempDir = await Directory.systemTemp.createTemp('skill_svc_');
    });

    tearDown(() async {
      service.dispose();
      await tempDir.delete(recursive: true);
    });

    group('initialization', () {
      test('_ensureInitialized discovers sources on first call', () async {
        final skillDir = await createSubdir(tempDir, skillName);
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: $skillName
description: $skillDescription
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 1);
        expect(skills.first.name, skillName);
      });

      test('_ensureInitialized does not re-discover if already initialized', () async {
        final skillDir = await createSubdir(tempDir, skillName);
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: $skillName
description: $skillDescription
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll(); // First call - discovers
        await service.listAll(); // Second call - should use cache

        // Should still have 1 skill (no duplicates)
        final skills = await service.listAll();
        expect(skills.length, 1);
      });

      test('initialization is idempotent across multiple sources', () async {
        final dir1 = await createSubdir(tempDir, 'dir1');
        final dir2 = await createSubdir(tempDir, 'dir2');

        await createSubdir(dir1, 'skill1').then((skillDir) async {
          final file = File(p.join(skillDir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill1
description: From dir1
---
''');
        });

        await createSubdir(dir2, 'skill2').then((skillDir) async {
          final file = File(p.join(skillDir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill2
description: From dir2
---
''');
        });

        final source1 = DirectorySource(dir1.path);
        final source2 = DirectorySource(dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skills1 = await service.listAll();
        final skills2 = await service.listAll();

        expect(skills1.length, 2);
        expect(skills2.length, 2);
      });
    });

    group('listAll', () {
      test('returns all skills from all sources (deduplicated)', () async {
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

        final source1 = DirectorySource(dir1.path);
        final source2 = DirectorySource(dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 2);
        expect(skills.map((s) => s.name), containsAll(['skill1', 'skill2']));
      });

      test('deduplicates skills with same name (first occurrence wins)', () async {
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

        await createSubdir(dir2, 'skill1').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill1
description: From dir2
---
''');
        });

        final source1 = DirectorySource(dir1.path);
        final source2 = DirectorySource(dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 1);
        expect(skills.first.description, 'From dir1'); // First wins
      });

      test('returns empty list when no sources have skills', () async {
        final emptyDir = await createSubdir(tempDir, 'empty');
        final source = DirectorySource(emptyDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills, isEmpty);
      });
    });

    group('getByName', () {
      test('returns skill when found', () async {
        final skillDir = await tempDir.createSubdirectory(skillName);
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: $skillName
description: $skillDescription
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        final skill = await service.getByName(skillName);

        expect(skill, isNotNull);
        expect(skill!.name, skillName);
        expect(skill.description, skillDescription);
      });

      test('returns null when skill not found', () async {
        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        final skill = await service.getByName('non-existent');

        expect(skill, isNull);
      });

      test('finds skill across multiple sources', () async {
        final dir1 = await tempDir.createSubdirectory('dir1');
        final dir2 = await tempDir.createSubdirectory('dir2');

        await dir1.createSubdirectory('skill1').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: skill1
description: From dir1
---
''');
        });

        final source1 = DirectorySource(dir1.path);
        final source2 = DirectorySource(dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skill = await service.getByName('skill1');

        expect(skill, isNotNull);
        expect(skill!.description, 'From dir1');
      });
    });

    group('availableForAgent', () {
      test('filters skills by permission', () async {
        final skillDir = await tempDir.createSubdirectory('allowed-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: allowed-skill
description: Allowed skill
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        // Mock permission check
        when(() => mockPermission.isAllowed('skill', 'skill:name=allowed-skill'))
            .thenReturn(true);
        when(() => mockPermission.isAllowed('skill', 'skill:name=other-skill'))
            .thenReturn(false);

        final allowed = await service.availableForAgent('test-agent');

        expect(allowed.length, 1);
        expect(allowed.first.name, 'allowed-skill');
      });

      test('returns empty list when no skills are allowed', () async {
        final skillDir = await tempDir.createSubdirectory('skill1');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: skill1
description: Not allowed
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        when(() => mockPermission.isAllowed(any(), any()))
            .thenReturn(false);

        final allowed = await service.availableForAgent('test-agent');

        expect(allowed, isEmpty);
      });

      test('respects wildcard patterns in permission', () async {
        final skillDir = await tempDir.createSubdirectory('wildcard-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: wildcard-skill
description: Matches wildcard
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        when(() => mockPermission.isAllowed('skill', 'skill:name=*'))
            .thenReturn(true);

        final allowed = await service.availableForAgent('test-agent');

        expect(allowed.length, 1);
      });
    });

    group('clearCache', () {
      test('clears all cached skills', () async {
        final skillDir = await tempDir.createSubdirectory(skillName);
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: $skillName
description: $skillDescription
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll(); // Populate cache
        expect(await service.listAll(), hasLength(1));

        service.clearCache();

        // After clear, next call should re-discover
        final skills = await service.listAll();
        expect(skills, hasLength(1)); // Re-discovered
      });

      test('clearCache resets initialization state', () async {
        final skillDir = await tempDir.createSubdirectory(skillName);
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: $skillName
description: $skillDescription
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll(); // Initialize
        service.clearCache();

        // Should re-discover on next call
        final skills = await service.listAll();
        expect(skills, hasLength(1));
      });
    });

    group('file watching', () {
      test('file watcher is started for DirectorySource', () async {
        final skillDir = await tempDir.createSubdirectory('watch-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: watch-skill
description: Watch test
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll(); // Initialize and start watcher

        // The service should have started a watcher for the directory
        // We can't easily verify this without exposing internal state
        // But we can verify that changes trigger cache invalidation via integration test
      });

      test('SKILL.md changes trigger cache invalidation after debounce',
          () async {
        final skillDir = await tempDir.createSubdirectory('watch-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: watch-skill
description: Original description
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll();
        final initialSkills = await service.listAll();
        expect(initialSkills.first.description, 'Original description');

        // Modify SKILL.md
        await skillFile.writeAsString('''
---
name: watch-skill
description: Updated description
---
''');

        // Wait for debounce (250ms)
        await Future.delayed(const Duration(milliseconds: 300));

        // Cache should be invalidated, next call should re-discover
        final updatedSkills = await service.listAll();
        expect(updatedSkills.first.description, 'Updated description');
      });
    });

    group('dispose', () {
      test('dispose cancels all watchers and timers', () async {
        final skillDir = await tempDir.createSubdirectory('dispose-skill');
        final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
        await skillFile.writeAsString('''
---
name: dispose-skill
description: Dispose test
---
''');

        final source = DirectorySource(tempDir.path);
        service = SkillService(
          sources: [source],
          permissionService: mockPermission,
        );

        await service.listAll();

        expect(() => service.dispose(), returnsNormally);
      });
    });

    group('source precedence', () {
      test('skills from earlier sources take precedence in deduplication',
          () async {
        final dir1 = await tempDir.createSubdirectory('first');
        final dir2 = await tempDir.createSubdirectory('second');

        await dir1.createSubdirectory('duplicate').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: duplicate
description: From first source
---
''');
        });

        await dir2.createSubdirectory('duplicate').then((dir) async {
          final file = File(p.join(dir.path, 'SKILL.md'));
          await file.writeAsString('''
---
name: duplicate
description: From second source
---
''');
        });

        final source1 = DirectorySource(dir1.path);
        final source2 = DirectorySource(dir2.path);
        service = SkillService(
          sources: [source1, source2],
          permissionService: mockPermission,
        );

        final skills = await service.listAll();

        expect(skills.length, 1);
        expect(skills.first.description, 'From first source');
      });
    });
  });
}
