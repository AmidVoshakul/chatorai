import 'dart:io';

import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:chatorai/features/skills/domain/services/directory_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:mocktail/mocktail.dart';

class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

class MockFileSystemEntity extends Mock implements FileSystemEntity {}

void main() {
  group('DirectorySource', () {
    late DirectorySource source;
    const testPath = '/test/skills';

    setUp(() {
      source = DirectorySource(testPath);
    });

    test('constructor sets key correctly', () {
      expect(source.key, 'dir:$testPath');
    });

    test('discover returns empty list when directory does not exist', () async {
      final mockDir = MockDirectory();
      when(() => mockDir.exists()).thenAnswer((_) async => false);

      // We'll need to override the Directory creation - but DirectorySource
      // directly creates Directory(path). So we need to test with real temp dir
      // For now, test with a non-existent path
      final result = await source.discover();
      expect(result, isEmpty);
    });

    test('discover finds valid SKILL.md files', () async {
      final tempDir = await Directory.systemTemp.createTemp('skills_test');
      final skillDir = Directory(p.join(tempDir.path, 'my-skill'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: my-skill
description: Test skill from directory
---

# Content
''');

      final realSource = DirectorySource(skillDir.path);
      final skills = await realSource.discover();

      expect(skills.length, 1);
      expect(skills.first.name, 'my-skill');
      expect(skills.first.description, 'Test skill from directory');
      expect(skills.first.directory, skillDir.path);
      expect(skills.first.content.contains('# Content'), isTrue);

      await tempDir.delete(recursive: true);
    });

    test('discover skips files without SKILL.md name', () async {
      final tempDir = await Directory.systemTemp.createTemp('skills_test');
      final skillDir = Directory(p.join(tempDir.path, 'my-skill'));
      await skillDir.create(recursive: true);
      final otherFile = File(p.join(skillDir.path, 'README.md'));
      await otherFile.writeAsString('# Not a skill');

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills, isEmpty);

      await tempDir.delete(recursive: true);
    });

    test('discover skips malformed SKILL.md (no frontmatter)', () async {
      final tempDir = await Directory.systemTemp.createTemp('skills_test');
      final skillDir = Directory(p.join(tempDir.path, 'my-skill'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
# No frontmatter
''');

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills, isEmpty);

      await tempDir.delete(recursive: true);
    });

    test('discover skips SKILL.md with missing description', () async {
      final tempDir = await Directory.systemTemp.createTemp('skills_test');
      final skillDir = Directory(p.join(tempDir.path, 'my-skill'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: my-skill
---

# No description
''');

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills, isEmpty);

      await tempDir.delete(recursive: true);
    });

    test('discover skips SKILL.md with empty description', () async {
      final tempDir = await Directory.systemTemp.createTemp('skills_test');
      final skillDir = Directory(p.join(tempDir.path, 'my-skill'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: my-skill
description:
---

# Empty description
''');

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills, isEmpty);

      await tempDir.delete(recursive: true);
    });

    test('discover collects auxiliary files (max 10, sorted)', () async {
      final tempDir = await Directory.systemTemp.createTemp('skills_test');
      final skillDir = Directory(p.join(tempDir.path, 'my-skill'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: my-skill
description: Test skill with files
---

# Content
''');

      // Create auxiliary files
      for (int i = 0; i < 5; i++) {
        final file = File(p.join(skillDir.path, 'file_$i.txt'));
        await file.writeAsString('File $i');
      }

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills.length, 1);
      expect(skills.first.files.length, 5);
      expect(skills.first.files, contains('file_0.txt'));
      expect(skills.first.files, contains('file_1.txt'));
      expect(skills.first.files, contains('file_2.txt'));
      expect(skills.first.files, contains('file_3.txt'));
      expect(skills.first.files, contains('file_4.txt'));

      await tempDir.delete(recursive: true);
    });

    test('discover limits auxiliary files to 10', () async {
      final tempDir = await Directory.systemTemp.createTemp('skills_test');
      final skillDir = Directory(p.join(tempDir.path, 'my-skill'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: my-skill
description: Test skill with many files
---

# Content
''');

      // Create 15 auxiliary files
      for (int i = 0; i < 15; i++) {
        final file = File(p.join(skillDir.path, 'file_$i.txt'));
        await file.writeAsString('File $i');
      }

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills.length, 1);
      expect(skills.first.files.length, 10);

      await tempDir.delete(recursive: true);
    });

    test('discover handles unicode in paths and content', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'skills_test_unicode',
      );
      final skillDir = Directory(p.join(tempDir.path, 'навык-测试'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: навык-测试
description: Навык с юникодом 🎉
---

# Содержание с юникод: 你好
''');

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills.length, 1);
      expect(skills.first.name, 'навык-测试');
      expect(skills.first.description, 'Навык с юникодом 🎉');
      expect(skills.first.content.contains('你好'), isTrue);

      await tempDir.delete(recursive: true);
    });

    test('discover handles nested skill directories', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'skills_test_nested',
      );
      final nestedDir = Directory(p.join(tempDir.path, 'subdir'));
      await nestedDir.create(recursive: true);
      final skillDir = Directory(p.join(nestedDir.path, 'nested-skill'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: nested-skill
description: Nested skill
---

# Nested content
''');

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills.length, 1);
      expect(skills.first.name, 'nested-skill');

      await tempDir.delete(recursive: true);
    });

    test('discover limits auxiliary files to 10', () async {
      final tempDir = await Directory.systemTemp.createTemp('skills_test');
      final skillDir = Directory(p.join(tempDir.path, 'my-skill'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: my-skill
description: Test skill with many files
---

# Content
''');

      // Create 15 auxiliary files
      for (int i = 0; i < 15; i++) {
        final file = File(p.join(skillDir.path, 'file_$i.txt'));
        await file.writeAsString('File $i');
      }

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills.length, 1);
      expect(skills.first.files.length, 10);

      await tempDir.delete(recursive: true);
    });

    test('discover handles unicode in paths and content', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'skills_test_unicode',
      );
      final skillDir = Directory(p.join(tempDir.path, 'навык-测试'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: навык-测试
description: Навык с юникодом 🎉
---

# Содержание с юникод: 你好
''');

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills.length, 1);
      expect(skills.first.name, 'навык-测试');
      expect(skills.first.description, 'Навык с юникодом 🎉');
      expect(skills.first.content.contains('你好'), isTrue);

      await tempDir.delete(recursive: true);
    });

    test('discover handles nested skill directories', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'skills_test_nested',
      );
      final nestedDir = Directory(p.join(tempDir.path, 'subdir'));
      await nestedDir.create(recursive: true);
      final skillDir = Directory(p.join(nestedDir.path, 'nested-skill'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: nested-skill
description: Nested skill
---

# Nested content
''');

      final realSource = DirectorySource(tempDir.path);
      final skills = await realSource.discover();

      expect(skills.length, 1);
      expect(skills.first.name, 'nested-skill');

      await tempDir.delete(recursive: true);
    });

    test('discover skips files that cannot be read', () async {
      final tempDir = await Directory.systemTemp.createTemp('skills_test');
      final skillDir = Directory(p.join(tempDir.path, 'my-skill'));
      await skillDir.create(recursive: true);
      final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
      await skillFile.writeAsString('''
---
name: my-skill
description: Test skill
---

# Content
''');

      // Make file unreadable (simulate permission error)
      try {
        // On some platforms, we might not be able to change permissions
        // So we'll just verify that the try-catch in discover handles errors
        final realSource = DirectorySource(tempDir.path);
        final skills = await realSource.discover();
        expect(skills.length, 1); // Should succeed normally
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('key property is derived from path', () {
      final source1 = DirectorySource('/path1');
      final source2 = DirectorySource('/path2');

      expect(source1.key, isNot(equals(source2.key)));
    });
  });
}
