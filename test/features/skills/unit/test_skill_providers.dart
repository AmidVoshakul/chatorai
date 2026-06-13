import 'dart:io';

import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/features/skills/domain/sources/directory_source.dart';
import 'package:chatorai/features/skills/domain/sources/url_source.dart';
import 'package:chatorai/features/skills/presentation/providers/skill_providers.dart';
import 'package:chatorai/features/skills/domain/services/skill_service.dart';
import 'package:chatorai/core/permission/permission_service.dart';
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

void main() {
  setUpAll(() {
    registerFallbackValue(Directory(''));
    registerFallbackValue(File(''));
    registerFallbackValue(File(''));
    registerFallbackValue(<String, dynamic>{});
  });

  group('Skill Providers', () {
    test('defaultSkillPaths returns expected defaults', () {
      final paths = defaultSkillPaths();

      expect(paths, contains('.chatorai/skills'));
      expect(paths, contains('.opencode/skills'));
      expect(paths, contains('.agents/skills'));
      expect(paths, contains('.claude/skills'));
    });

    test('globalSkillPath returns correct path on Unix', () {
      final originalHome = Platform.environment['HOME'];
      Platform.environment['HOME'] = '/home/testuser';

      final path = globalSkillPath();

      expect(path, '/home/testuser/.config/chatorai/skills');

      if (originalHome != null) {
        Platform.environment['HOME'] = originalHome;
      } else {
        Platform.environment.remove('HOME');
      }
    }, skip: true);

    test('globalSkillPath returns correct path on Windows', () {
      final originalUserProfile = Platform.environment['USERPROFILE'];
      Platform.environment['USERPROFILE'] = 'C:\\Users\\TestUser';

      final originalHome = Platform.environment['HOME'];
      Platform.environment.remove('HOME');

      final path = globalSkillPath();

      expect(path, 'C:\\Users\\TestUser\\.config\\chatorai\\skills');

      if (originalUserProfile != null) {
        Platform.environment['USERPROFILE'] = originalUserProfile;
      } else {
        Platform.environment.remove('USERPROFILE');
      }
      if (originalHome != null) {
        Platform.environment['HOME'] = originalHome;
      }
    }, skip: true);

    test('buildSkillSources includes default paths', () {
      final config = ChatOrAIConfig(
        version: 1,
        permission: {},
        skills: const SkillConfig(paths: [], urls: []),
      );

      final sources = buildSkillSources(config);

      // Should have at least the default paths + global path
      expect(sources.length, greaterThanOrEqualTo(5));
      expect(sources.whereType<DirectorySource>().length, sources.length);
    });

    test('buildSkillSources adds configured paths', () {
      final config = ChatOrAIConfig(
        version: 1,
        permission: {},
        skills: const SkillConfig(
          paths: ['/custom/path1', '/custom/path2'],
          urls: [],
        ),
      );

      final sources = buildSkillSources(config);

      final pathSources = sources.whereType<DirectorySource>().toList();
      final paths = pathSources
          .map((s) => s.rootPath)
          .where((path) => path.startsWith('/custom'))
          .toList();

      expect(paths, contains('/custom/path1'));
      expect(paths, contains('/custom/path2'));
    });

    test('buildSkillSources combines both paths and urls', () {
      final config = ChatOrAIConfig(
        version: 1,
        permission: {},
        skills: const SkillConfig(
          paths: ['/custom/path'],
          urls: [
            {'url': 'https://example.com/.well-known/skills/'},
          ],
        ),
      );

      final sources = buildSkillSources(config);

      expect(
        sources.whereType<DirectorySource>().any(
          (s) => s.rootPath == '/custom/path',
        ),
        isTrue,
      );
      expect(
        sources.whereType<UrlSource>().any(
          (s) => s.config.baseUrl == 'https://example.com/.well-known/skills/',
        ),
        isTrue,
      );
    });

    test('buildSkillSources skips malformed URL config gracefully', () {
      final config = ChatOrAIConfig(
        version: 1,
        permission: {},
        skills: const SkillConfig(
          paths: [],
          urls: [
            {'invalid': 'config'}, // Missing 'url' key
          ],
        ),
      );

      // Should not throw; malformed config is skipped with warning
      final sources = buildSkillSources(config);

      // Should have directory sources but no URL source from malformed config
      expect(sources.whereType<UrlSource>().toList(), isEmpty);
    });

    test('SkillService discovers skills from sources', () async {
      final tempDir = await Directory.systemTemp.createTemp('service_test');
      final skillDir = await createSubdir(tempDir, 'skills');
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: test-skill
description: Test skill
---
Content
''');

      final config = ChatOrAIConfig(
        version: 1,
        permission: {},
        skills: SkillConfig(paths: [skillDir.path], urls: const []),
      );

      final sources = buildSkillSources(config);
      final service = SkillService(
        sources: sources,
        permissionService: MockPermissionService(),
      );

      // Service auto-initializes on first use
      final skills = await service.listAll();

      expect(skills, isNotEmpty);
      expect(skills.any((s) => s.name == 'test-skill'), isTrue);

      await tempDir.delete(recursive: true);
    });

    test('SkillService clearCache forces re-discovery', () async {
      final tempDir = await Directory.systemTemp.createTemp('cache_test');
      final skillDir = await createSubdir(tempDir, 'skills');
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: cache-test
description: Before clear
---
''');

      final config = ChatOrAIConfig(
        version: 1,
        permission: {},
        skills: SkillConfig(paths: [skillDir.path], urls: const []),
      );

      final sources = buildSkillSources(config);
      final service = SkillService(
        sources: sources,
        permissionService: MockPermissionService(),
      );

      // Initial discovery
      var skills = await service.listAll();
      var skill = skills.firstWhere((s) => s.name == 'cache-test');
      expect(skill.description, 'Before clear');

      // Modify file
      await skillFile.writeAsString('''
---
name: cache-test
description: After clear
---
''');

      // Clear cache
      service.clearCache();

      // Should see updated content
      skills = await service.listAll();
      skill = skills.firstWhere((s) => s.name == 'cache-test');
      expect(skill.description, 'After clear');

      await tempDir.delete(recursive: true);
    });
  });
}
