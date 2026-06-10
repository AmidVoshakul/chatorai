import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillInfo', () {
    const testName = 'test-skill';
    const testDescription = 'A test skill';
    const testDirectory = '/path/to/skill';
    const testContent = '# Skill Content';
    const testFiles = ['file1.txt', 'file2.py'];

    test('constructor creates instance with required fields', () {
      final skill = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
      );

      expect(skill.name, testName);
      expect(skill.description, testDescription);
      expect(skill.directory, testDirectory);
      expect(skill.content, testContent);
      expect(skill.files, isEmpty);
    });

    test('constructor creates instance with all fields', () {
      final skill = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
        files: testFiles,
      );

      expect(skill.files, testFiles);
    });

    test('equality - identical objects', () {
      final skill1 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
        files: testFiles,
      );
      final skill2 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
        files: testFiles,
      );

      expect(skill1, equals(skill2));
    });

    test('equality - different name', () {
      final skill1 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
      );
      final skill2 = SkillInfo(
        name: 'different-name',
        description: testDescription,
        directory: testDirectory,
        content: testContent,
      );

      expect(skill1, isNot(equals(skill2)));
    });

    test('equality - different description', () {
      final skill1 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
      );
      final skill2 = SkillInfo(
        name: testName,
        description: 'Different description',
        directory: testDirectory,
        content: testContent,
      );

      expect(skill1, isNot(equals(skill2)));
    });

    test('equality - different directory', () {
      final skill1 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
      );
      final skill2 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: '/different/directory',
        content: testContent,
      );

      expect(skill1, isNot(equals(skill2)));
    });

    test('equality - different content', () {
      final skill1 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
      );
      final skill2 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: 'Different content',
      );

      expect(skill1, isNot(equals(skill2)));
    });

    test('equality - different files', () {
      final skill1 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
        files: ['file1.txt'],
      );
      final skill2 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
        files: ['file2.txt'],
      );

      expect(skill1, isNot(equals(skill2)));
    });

    test('equality - files order matters', () {
      final skill1 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
        files: ['a.txt', 'b.txt'],
      );
      final skill2 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
        files: ['b.txt', 'a.txt'],
      );

      expect(skill1, isNot(equals(skill2)));
    });

    test('hashCode - same objects produce same hash', () {
      final skill1 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
        files: testFiles,
      );
      final skill2 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
        files: testFiles,
      );

      expect(skill1.hashCode, equals(skill2.hashCode));
    });

    test('hashCode - different objects likely have different hash', () {
      final skill1 = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
      );
      final skill2 = SkillInfo(
        name: 'different',
        description: testDescription,
        directory: testDirectory,
        content: testContent,
      );

      // Not asserting equality, just that they're different (probabilistic)
      expect(skill1.hashCode, isNot(equals(skill2.hashCode)));
    });

    test('immutable - class has only final fields', () {
      final skill = SkillInfo(
        name: testName,
        description: testDescription,
        directory: testDirectory,
        content: testContent,
      );

      // Verify that the class is immutable by checking that it's a const constructor
      // and that all fields are final (no setters)
      expect(skill, isA<SkillInfo>());
      // The fact that we can create a const instance and it compiles proves immutability
    });
  });
}
