import 'dart:io';

import 'package:test/test.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/tools/data/models/tool_registry.dart';
import 'package:chatorai/features/tools/built_in/built_in_tools.dart';
import '_test_context.dart';

/// Integration tests for file-related tools (read, write, edit, glob, grep).
///
/// These tests use a real temporary directory within the project sandbox
/// and exercise the actual file system operations. Each test runs in its own
/// isolated subdirectory to avoid interference.
///
/// Run with: flutter test test/integration/file_tools_integration_test.dart
void main() {
  late Directory testRoot;
  late ToolRegistry registry;

  setUpAll(() async {
    // Create shared temporary directory within project root
    final tempDir = Directory('test/integration_temp');
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }
    // Clean any previous files
    if (tempDir.existsSync()) {
      for (final entity in tempDir.listSync(recursive: true)) {
        try {
          if (entity is File) entity.deleteSync();
          if (entity is Directory) entity.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
    testRoot = Directory('test/integration_temp/files');
    testRoot.createSync(recursive: true);

    // Initialize ToolRegistry with built-in tools
    registry = ToolRegistry(PermissionService(), PermissionRuleset(rules: []));
    registerBuiltInTools(registry);
  });

  tearDownAll(() async {
    // Clean up entire integration_temp directory
    final tempDir = Directory('test/integration_temp');
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  // Helper to create a unique test directory for each test
  Directory createTestDir() {
    final dir = Directory(
      '${testRoot.path}/test_${DateTime.now().microsecondsSinceEpoch}',
    );
    dir.createSync(recursive: true);
    return dir;
  }

  group('Read Tool Integration', () {
    late Directory currentTestDir;

    setUp(() {
      currentTestDir = createTestDir();
    });

    tearDown(() {
      if (currentTestDir.existsSync()) {
        currentTestDir.deleteSync(recursive: true);
      }
    });

    test('reads small text file correctly', () async {
      final tool = registry.get('read')!;
      final testFile = File('${currentTestDir.path}/small.txt');
      testFile.createSync(recursive: true);
      testFile.writeAsStringSync('Hello, World!');

      final output = await tool.execute({
        'file_path': testFile.path,
      }, const IntegrationTestContext());

      expect(output.output, 'Hello, World!');
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['lines'], equals(1));
      expect(output.metadata?['binary'], isFalse);
    });

    test('reads UTF-8 content with multiple languages', () async {
      final tool = registry.get('read')!;
      final testFile = File('${currentTestDir.path}/utf8.txt');
      testFile.createSync(recursive: true);
      testFile.writeAsStringSync('Привет, мир! 你好世界 مرحبا');

      final output = await tool.execute({
        'file_path': testFile.path,
      }, const IntegrationTestContext());

      expect(output.output, contains('Привет, мир!'));
      expect(output.output, contains('你好世界'));
      expect(output.output, contains('مرحبا'));
      expect(output.metadata?['binary'], isFalse);
    });

    test('detects binary file and returns error metadata', () async {
      final tool = registry.get('read')!;
      final testFile = File('${currentTestDir.path}/binary.bin');
      testFile.createSync(recursive: true);
      testFile.writeAsBytesSync([0x00, 0x01, 0x02, 0xFF, 0xFE, 0x00]);

      final output = await tool.execute({
        'file_path': testFile.path,
      }, const IntegrationTestContext());

      expect(output.metadata?['binary'], isTrue);
      expect(output.output, contains('Binary file'));
      expect(output.metadata?['error'], isTrue);
      expect(output.metadata?['size'], equals(6));
    });

    test('respects offset and limit', () async {
      final tool = registry.get('read')!;
      final testFile = File('${currentTestDir.path}/lines.txt');
      testFile.createSync(recursive: true);
      final lines = List.generate(10, (i) => 'Line $i');
      testFile.writeAsStringSync(lines.join('\n'));

      final output = await tool.execute({
        'file_path': testFile.path,
        'offset': 3,
        'limit': 2,
      }, const IntegrationTestContext());

      expect(output.output, contains('Line 3'));
      expect(output.output, contains('Line 4'));
      expect(output.output, isNot(contains('Line 2')));
      expect(output.metadata?['offset'], equals(3));
      expect(output.metadata?['limit'], equals(2));
    });

    test('returns error for non-existent file', () async {
      final tool = registry.get('read')!;
      final nonexistent = '${currentTestDir.path}/does_not_exist.txt';

      final output = await tool.execute({
        'file_path': nonexistent,
      }, const IntegrationTestContext());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file not found'));
    });

    test('handles empty file', () async {
      final tool = registry.get('read')!;
      final testFile = File('${currentTestDir.path}/empty.txt');
      testFile.createSync(recursive: true);
      testFile.writeAsStringSync('');

      final output = await tool.execute({
        'file_path': testFile.path,
      }, const IntegrationTestContext());

      expect(output.output, isEmpty);
      expect(output.metadata?['lines'], equals(1)); // split gives ['']
      expect(output.metadata?['error'], isNull);
    });

    test('default limit is 2000 lines', () async {
      final tool = registry.get('read')!;
      final testFile = File('${currentTestDir.path}/many_lines.txt');
      testFile.createSync(recursive: true);
      final lines = List.generate(3000, (i) => 'Line $i');
      testFile.writeAsStringSync(lines.join('\n'));

      final output = await tool.execute({
        'file_path': testFile.path,
      }, const IntegrationTestContext());

      expect(output.metadata?['limit'], equals(2000));
      final outputLines = output.output.split('\n');
      expect(outputLines.length, equals(2000));
    });
  });

  group('Write Tool Integration', () {
    late Directory currentTestDir;

    setUp(() {
      currentTestDir = createTestDir();
    });

    tearDown(() {
      if (currentTestDir.existsSync()) {
        currentTestDir.deleteSync(recursive: true);
      }
    });

    test('creates new file with content', () async {
      final tool = registry.get('write')!;
      final filePath = '${currentTestDir.path}/new_file.txt';
      final content = 'Test content\nSecond line';

      final output = await tool.execute({
        'file_path': filePath,
        'content': content,
      }, const IntegrationTestContext());

      expect(output.output, contains('File written successfully'));
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['bytes'], equals(content.length));
      expect(File(filePath).existsSync(), isTrue);
      expect(File(filePath).readAsStringSync(), equals(content));
    });

    test('creates nested directories automatically', () async {
      final tool = registry.get('write')!;
      final filePath = '${currentTestDir.path}/deep/nested/dir/file.txt';
      final content = 'Deep content';

      final output = await tool.execute({
        'file_path': filePath,
        'content': content,
      }, const IntegrationTestContext());

      expect(output.output, contains('File written successfully'));
      expect(output.metadata?['error'], isNull);
      expect(File(filePath).existsSync(), isTrue);
    });

    test('overwrites existing file', () async {
      final tool = registry.get('write')!;
      final filePath = '${currentTestDir.path}/existing.txt';
      File(filePath).createSync(recursive: true);
      File(filePath).writeAsStringSync('Old content');

      final output = await tool.execute({
        'file_path': filePath,
        'content': 'New content',
      }, const IntegrationTestContext());

      expect(output.output, contains('File written successfully'));
      expect(File(filePath).readAsStringSync(), equals('New content'));
    });

    test('writes UTF-8 content correctly', () async {
      final tool = registry.get('write')!;
      final filePath = '${currentTestDir.path}/utf8_write.txt';
      final content = 'Привет, мир! 你好世界';

      final output = await tool.execute({
        'file_path': filePath,
        'content': content,
      }, const IntegrationTestContext());

      expect(output.metadata?['error'], isNull);
      expect(File(filePath).readAsStringSync(), equals(content));
    });

    test('returns error when file_path is missing', () async {
      final tool = registry.get('write')!;

      final output = await tool.execute({
        'content': 'some content',
      }, const IntegrationTestContext());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file_path is required'));
    });

    test('returns error when content is missing', () async {
      final tool = registry.get('write')!;
      final filePath = '${currentTestDir.path}/no_content.txt';

      final output = await tool.execute({
        'file_path': filePath,
      }, const IntegrationTestContext());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('content is required'));
    });

    test('handles path outside project root safely', () async {
      final tool = registry.get('write')!;
      // Try to write outside the sandbox using absolute path trick
      final filePath = '/tmp/outside_project.txt';
      final content = 'Should not be written';

      final output = await tool.execute({
        'file_path': filePath,
        'content': content,
      }, const IntegrationTestContext());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('Path denied'));
      expect(File(filePath).existsSync(), isFalse);
    });
  });

  group('Edit Tool Integration', () {
    late Directory currentTestDir;

    setUp(() {
      currentTestDir = createTestDir();
    });

    tearDown(() {
      if (currentTestDir.existsSync()) {
        currentTestDir.deleteSync(recursive: true);
      }
    });

    test('simple replacement modifies file correctly', () async {
      final tool = registry.get('edit')!;
      final filePath = '${currentTestDir.path}/edit_simple.txt';
      File(filePath).createSync(recursive: true);
      File(filePath).writeAsStringSync('Hello World, Hello Universe');

      final output = await tool.execute({
        'file_path': filePath,
        'old_string': 'Hello',
        'new_string': 'Hi',
      }, const IntegrationTestContext());

      expect(output.output, contains('File edited successfully'));
      expect(output.metadata?['error'], isNull);
      expect(
        File(filePath).readAsStringSync(),
        equals('Hi World, Hi Universe'),
      );
    });

    test('replace_all=false replaces only first occurrence', () async {
      final tool = registry.get('edit')!;
      final filePath = '${currentTestDir.path}/edit_first.txt';
      File(filePath).createSync(recursive: true);
      File(filePath).writeAsStringSync('foo foo foo');

      final output = await tool.execute({
        'file_path': filePath,
        'old_string': 'foo',
        'new_string': 'bar',
        'replace_all': false,
      }, const IntegrationTestContext());

      expect(output.metadata?['error'], isNull);
      expect(File(filePath).readAsStringSync(), equals('bar foo foo'));
    });

    test('replace_all=true replaces all occurrences (default)', () async {
      final tool = registry.get('edit')!;
      final filePath = '${currentTestDir.path}/edit_all.txt';
      File(filePath).createSync(recursive: true);
      File(filePath).writeAsStringSync('foo foo foo');

      final output = await tool.execute({
        'file_path': filePath,
        'old_string': 'foo',
        'new_string': 'bar',
        'replace_all': true,
      }, const IntegrationTestContext());

      expect(output.metadata?['error'], isNull);
      expect(File(filePath).readAsStringSync(), equals('bar bar bar'));
    });

    test('returns error when old_string not found', () async {
      final tool = registry.get('edit')!;
      final filePath = '${currentTestDir.path}/edit_missing.txt';
      File(filePath).createSync(recursive: true);
      File(filePath).writeAsStringSync('Hello World');

      final output = await tool.execute({
        'file_path': filePath,
        'old_string': 'Goodbye',
        'new_string': 'Hi',
      }, const IntegrationTestContext());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('old_string not found'));
    });

    test('returns error for non-existent file', () async {
      final tool = registry.get('edit')!;
      final filePath = '${currentTestDir.path}/edit_nonexistent.txt';

      final output = await tool.execute({
        'file_path': filePath,
        'old_string': 'foo',
        'new_string': 'bar',
      }, const IntegrationTestContext());

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file not found'));
    });

    test('handles UTF-8 content correctly', () async {
      final tool = registry.get('edit')!;
      final filePath = '${currentTestDir.path}/edit_utf8.txt';
      File(filePath).createSync(recursive: true);
      File(filePath).writeAsStringSync('Привет мир');

      final output = await tool.execute({
        'file_path': filePath,
        'old_string': 'Привет',
        'new_string': 'Здравствуй',
      }, const IntegrationTestContext());

      expect(output.metadata?['error'], isNull);
      expect(File(filePath).readAsStringSync(), equals('Здравствуй мир'));
    });

    test(
      'accepts alternate parameter names (path, oldString, newString)',
      () async {
        final tool = registry.get('edit')!;
        final filePath = '${currentTestDir.path}/edit_alt_names.txt';
        File(filePath).createSync(recursive: true);
        File(filePath).writeAsStringSync('alpha beta gamma');

        final output = await tool.execute({
          'path': filePath,
          'oldString': 'beta',
          'newString': 'delta',
        }, const IntegrationTestContext());

        expect(output.metadata?['error'], isNull);
        expect(File(filePath).readAsStringSync(), equals('alpha delta gamma'));
      },
    );
  });

  group('Glob Tool Integration', () {
    late Directory currentTestDir;

    setUp(() {
      currentTestDir = createTestDir();
      // Create a directory structure for glob tests
      final dirs = [
        '${currentTestDir.path}/a',
        '${currentTestDir.path}/a/sub',
        '${currentTestDir.path}/b',
        '${currentTestDir.path}/b/sub',
        '${currentTestDir.path}/c',
      ];
      for (final d in dirs) {
        Directory(d).createSync(recursive: true);
      }
      // Create files with different extensions
      final files = [
        '${currentTestDir.path}/a/file1.dart',
        '${currentTestDir.path}/a/file2.txt',
        '${currentTestDir.path}/a/sub/file3.dart',
        '${currentTestDir.path}/a/sub/file4.md',
        '${currentTestDir.path}/b/file5.dart',
        '${currentTestDir.path}/b/sub/file6.dart',
        '${currentTestDir.path}/c/file7.txt',
        '${currentTestDir.path}/root.dart',
        // Add root-level txt files for *.txt test
        '${currentTestDir.path}/root1.txt',
        '${currentTestDir.path}/root2.txt',
      ];
      for (final f in files) {
        File(f).createSync(recursive: true);
        File(f).writeAsStringSync('content');
      }
    });

    tearDown(() {
      if (currentTestDir.existsSync()) {
        currentTestDir.deleteSync(recursive: true);
      }
    });

    test('matches files recursively with **/*.dart', () async {
      final tool = registry.get('glob')!;
      final output = await tool.execute({
        'pattern': '**/*.dart',
        'path': currentTestDir.path,
      }, const IntegrationTestContext());

      final lines = output.output.split('\n');
      // root.dart is not matched by **/*.dart because it requires at least one slash
      // So we expect 4: a/file1.dart, a/sub/file3.dart, b/file5.dart, b/sub/file6.dart
      expect(lines.length, equals(4));
      expect(lines, contains('a/file1.dart'));
      expect(lines, contains('a/sub/file3.dart'));
      expect(lines, contains('b/file5.dart'));
      expect(lines, contains('b/sub/file6.dart'));
      expect(output.metadata?['count'], equals(4));
    });

    test('matches single-level pattern *.txt (root only)', () async {
      final tool = registry.get('glob')!;
      final output = await tool.execute({
        'pattern': '*.txt',
        'path': currentTestDir.path,
      }, const IntegrationTestContext());

      final lines = output.output.split('\n');
      // Should only match root1.txt and root2.txt, not the ones in subdirectories
      expect(lines.length, equals(2));
      expect(lines, contains('root1.txt'));
      expect(lines, contains('root2.txt'));
      // Ensure subdirectory txt files are not included
      expect(lines, isNot(contains('a/file2.txt')));
      expect(lines, isNot(contains('c/file7.txt')));
    });

    test('returns "No files matching" for pattern with no matches', () async {
      final tool = registry.get('glob')!;
      final output = await tool.execute({
        'pattern': '**/*.nonexistent',
        'path': currentTestDir.path,
      }, const IntegrationTestContext());

      expect(output.output, contains('No files matching pattern'));
      expect(output.metadata?['count'], isNull);
    });

    test('respects custom root path', () async {
      final tool = registry.get('glob')!;
      // Search within 'a' directory only
      final output = await tool.execute({
        'pattern': '**/*.dart',
        'path': '${currentTestDir.path}/a',
      }, const IntegrationTestContext());

      final lines = output.output.split('\n');
      // In a: file1.dart (root of a) and a/sub/file3.dart
      // **/*.dart matches only a/sub/file3.dart (requires slash)
      expect(lines.length, equals(1));
      expect(lines, contains('sub/file3.dart'));
    });

    test('limits results to 1000 files automatically', () async {
      final tool = registry.get('glob')!;
      // Create many files to test limit
      final manyDir = Directory('${currentTestDir.path}/many');
      manyDir.createSync(recursive: true);
      for (int i = 0; i < 1500; i++) {
        File('${manyDir.path}/file_$i.txt').createSync();
      }

      final output = await tool.execute({
        'pattern': '**/*.txt',
        'path': currentTestDir.path,
      }, const IntegrationTestContext());

      final lines = output.output.split('\n');
      expect(lines.length, equals(1000));
      expect(output.metadata?['count'], equals(1000));
    });

    test('respects .gitignore patterns', () async {
      final tool = registry.get('glob')!;
      final gitignorePath = '${currentTestDir.path}/.gitignore';
      File(gitignorePath).createSync(recursive: true);
      // Use pattern that works with current Glob implementation
      File(gitignorePath).writeAsStringSync('ignored.txt\nignored_dir/**');

      // Create files that should be ignored
      File('${currentTestDir.path}/ignored.txt').createSync();
      final ignoredDir = Directory('${currentTestDir.path}/ignored_dir');
      ignoredDir.createSync(recursive: true);
      File('${ignoredDir.path}/file.txt').createSync();
      // Create an allowed file in a subdirectory
      final allowedDir = Directory('${currentTestDir.path}/allowed_dir');
      allowedDir.createSync(recursive: true);
      File('${allowedDir.path}/allowed.txt').createSync();

      final output = await tool.execute({
        'pattern': '**/*.txt',
        'path': currentTestDir.path,
      }, const IntegrationTestContext());

      final lines = output.output.split('\n');
      expect(lines, contains('allowed_dir/allowed.txt'));
      expect(lines, isNot(contains('ignored.txt')));
      expect(lines, isNot(contains('ignored_dir/file.txt')));
    });

    test('handles empty directory gracefully', () async {
      final tool = registry.get('glob')!;
      final emptyDir = Directory('${currentTestDir.path}/empty');
      emptyDir.createSync(recursive: true);

      final output = await tool.execute({
        'pattern': '**/*.dart',
        'path': emptyDir.path,
      }, const IntegrationTestContext());

      expect(output.output, contains('No files matching pattern'));
    });
  });

  group('Grep Tool Integration', () {
    late Directory currentTestDir;

    setUp(() {
      currentTestDir = createTestDir();
      // Create test files with various content
      final files = {
        '${currentTestDir.path}/file1.dart': 'void main() { print("Hello"); }',
        '${currentTestDir.path}/file2.dart': 'class Foo { void bar() {} }',
        '${currentTestDir.path}/file3.txt':
            'This is a test file\nAnother line with test',
        // file4.dart should not contain 'test' to avoid affecting case-insensitive tests
        '${currentTestDir.path}/sub/file4.dart':
            'import "package:example"; // some comment',
        '${currentTestDir.path}/sub/file5.txt': 'No matches here',
      };
      for (final entry in files.entries) {
        File(entry.key).createSync(recursive: true);
        File(entry.key).writeAsStringSync(entry.value);
      }
    });

    tearDown(() {
      if (currentTestDir.existsSync()) {
        currentTestDir.deleteSync(recursive: true);
      }
    });

    test('finds lines matching pattern', () async {
      final tool = registry.get('grep')!;
      final output = await tool.execute({
        'pattern': 'test',
        'path': currentTestDir.path,
      }, const IntegrationTestContext());

      final lines = output.output.split('\n');
      // file3.txt has 2 lines with 'test'
      expect(lines.length, equals(2));
      expect(lines, contains('file3.txt:1: This is a test file'));
      expect(lines, contains('file3.txt:2: Another line with test'));
      expect(output.metadata?['count'], equals(2));
    });

    test('case sensitive search works', () async {
      final tool = registry.get('grep')!;
      final output = await tool.execute({
        'pattern': 'Test',
        'path': currentTestDir.path,
        'case_sensitive': true,
      }, const IntegrationTestContext());

      // No lines contain uppercase 'Test'
      expect(output.output, isEmpty);
      expect(output.metadata?['count'], equals(0));
    });

    test('case insensitive search (default)', () async {
      final tool = registry.get('grep')!;
      final output = await tool.execute({
        'pattern': 'Test',
        'path': currentTestDir.path,
      }, const IntegrationTestContext());

      final lines = output.output.split('\n');
      // Should match the two lines in file3.txt (contain 'test' lowercase)
      expect(lines.length, equals(2));
      expect(lines, contains('file3.txt:1: This is a test file'));
      expect(lines, contains('file3.txt:2: Another line with test'));
    });

    test('respects include filter (glob)', () async {
      final tool = registry.get('grep')!;
      final output = await tool.execute({
        'pattern': 'void',
        'path': currentTestDir.path,
        'include': '*.dart',
      }, const IntegrationTestContext());

      final lines = output.output.split('\n');
      // file1.dart: 'void main()' -> 1 line
      // file2.dart: 'void bar()' -> 1 line
      // sub/file4.dart: no 'void'
      expect(lines.length, equals(2));
      expect(lines, contains('file1.dart:1: void main() { print("Hello"); }'));
      expect(lines, contains('file2.dart:1: class Foo { void bar() {} }'));
    });

    test('limits results with max_matches', () async {
      final tool = registry.get('grep')!;
      // Create many matching lines
      final manyFile = File('${currentTestDir.path}/many_matches.txt');
      manyFile.createSync(recursive: true);
      final lines = List.generate(100, (i) => 'match line $i');
      manyFile.writeAsStringSync(lines.join('\n'));

      final output = await tool.execute({
        'pattern': 'match',
        'path': currentTestDir.path,
        'max_matches': 10,
      }, const IntegrationTestContext());

      final resultLines = output.output.split('\n');
      expect(resultLines.length, equals(10));
      expect(output.metadata?['count'], equals(10));
    });

    test('handles UTF-8 content correctly', () async {
      final tool = registry.get('grep')!;
      final utf8File = File('${currentTestDir.path}/utf8.txt');
      utf8File.createSync(recursive: true);
      utf8File.writeAsStringSync('Привет мир\nHello world\n你好世界');

      final output = await tool.execute({
        'pattern': 'Привет',
        'path': currentTestDir.path,
      }, const IntegrationTestContext());

      expect(output.output, contains('Привет мир'));
    });

    test('returns empty result when no matches', () async {
      final tool = registry.get('grep')!;
      final output = await tool.execute({
        'pattern': 'nonexistent_pattern_xyz',
        'path': currentTestDir.path,
      }, const IntegrationTestContext());

      expect(output.output, isEmpty);
      expect(output.metadata?['count'], equals(0));
    });

    test('handles binary files gracefully (skips them)', () async {
      final tool = registry.get('grep')!;
      final binFile = File('${currentTestDir.path}/binary.bin');
      binFile.createSync(recursive: true);
      binFile.writeAsBytesSync([0x00, 0x01, 0x02]);

      final output = await tool.execute({
        'pattern': 'anything',
        'path': currentTestDir.path,
      }, const IntegrationTestContext());

      // Should not crash; binary file read will throw and be caught, resulting in 0 matches
      expect(output.metadata?['count'], equals(0));
    });

    test('respects custom root path', () async {
      final tool = registry.get('grep')!;
      // Search only within the 'sub' directory
      final output = await tool.execute({
        'pattern': 'No matches',
        'path': '${currentTestDir.path}/sub',
      }, const IntegrationTestContext());

      // The output will include the relative path from the subdirectory root,
      // which is just the filename.
      expect(output.output, contains('file5.txt:1: No matches here'));
    });
  });
}
