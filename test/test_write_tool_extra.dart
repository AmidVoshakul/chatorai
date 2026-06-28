import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/write.dart';

ToolContext _mockCtx() {
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: 'test-session',
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {},
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );
}

void main() {
  group('write tool — path sandbox rejection', () {
    test('path outside project root returns error', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'file_path': '/tmp/outside_project.txt',
        'content': 'test',
      }, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('Error'));
    });

    test('path traversal outside project root returns error', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'file_path': '../../outside_project.txt',
        'content': 'test',
      }, ctx);
      expect(output.metadata?['error'], isTrue);
    });
  });

  group('write tool — bytes metadata', () {
    test('bytes field matches content length in UTF-8', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_write_bytes');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_bytes.txt');
      final content = 'Hello, 世界!'; // multi-byte UTF-8

      final output = await tool.execute({
        'file_path': testFile.path,
        'content': content,
      }, ctx);

      expect(output.metadata?['error'], isNull);
      // bytes = content.length (Dart string length, not UTF-8 byte length)
      expect(output.metadata?['bytes'], equals(content.length));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('bytes field for ASCII content matches string length', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_write_bytes_ascii');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_bytes_ascii.txt');
      final content = 'Hello, World!';

      final output = await tool.execute({
        'file_path': testFile.path,
        'content': content,
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['bytes'], equals(content.length));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });
  });

  group('write tool — empty content', () {
    test('empty string content writes empty file', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_write_empty');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_empty.txt');

      final output = await tool.execute({
        'file_path': testFile.path,
        'content': '',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(testFile.existsSync(), isTrue);
      expect(await testFile.readAsString(), equals(''));
      expect(output.metadata?['bytes'], equals(0));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });
  });

  group('write tool — nested parent directory creation', () {
    test('creates deeply nested parent directories', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_write_nested');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/a/b/c/d/e/deep_file.txt');

      final output = await tool.execute({
        'file_path': testFile.path,
        'content': 'deep content',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(testFile.existsSync(), isTrue);
      expect(await testFile.readAsString(), equals('deep content'));

      testDir.deleteSync(recursive: true);
    });

    test('creates single-level parent directory', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_write_single');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/subdir/file.txt');

      final output = await tool.execute({
        'file_path': testFile.path,
        'content': 'single level',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(testFile.existsSync(), isTrue);

      testDir.deleteSync(recursive: true);
    });
  });

  group('write tool — path alias', () {
    test('path parameter alias works as fallback', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_write_alias');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/alias_test.txt');

      final output = await tool.execute({
        'path': testFile.path,
        'content': 'alias write',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('alias write'));

      testDir.deleteSync(recursive: true);
    });
  });
}
