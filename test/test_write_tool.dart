import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/write.dart';

ToolContext _mockCtx({
  bool askResult = true,
  List<String>? askedPermission,
  List<String>? askedPatterns,
}) {
  askedPermission = askedPermission;
  askedPatterns = askedPatterns;
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: 'test-session',
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {
          askedPermission = [permission];
          askedPatterns = patterns;
        },
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );
}

void main() {
  group('write tool', () {
    test('description is non-empty', () {
      final tool = createWriteTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required file_path and content fields', () {
      final tool = createWriteTool();
      final schema = tool.inputSchema as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('file_path'), isTrue);
      expect(properties.containsKey('content'), isTrue);
      expect((schema['required'] as List).contains('file_path'), isTrue);
      expect((schema['required'] as List).contains('content'), isTrue);
    });

    test('execute with missing file_path returns error', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'content': 'test'}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute with missing content returns error', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'file_path': '/test/file.txt'}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createWriteTool();
      String? capturedPermission;
      List<String>? capturedPatterns;
      final ctx = ToolContext(
        toolCallId: 'test',
        sessionId: 'test',
        ask:
            ({
              required String permission,
              required List<String> patterns,
              Map<String, dynamic>? metadata,
              List<String>? always,
            }) async {
              capturedPermission = permission;
              capturedPatterns = patterns;
            },
        askQuestion:
            ({required question, options = const [], multiple = false}) async =>
                '',
      );
      // Use a path within the project root (test directory)
      final testDir = Directory('test/temp_write_pattern');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/pattern_test.txt');
      final userPath = testFile.path; // This is within project root

      await tool.execute({
        'file_path': userPath,
        'content': 'Hello, World!',
      }, ctx);
      expect(capturedPermission, equals('write'));
      expect(capturedPatterns, contains('write:file_path=$userPath'));

      // Cleanup
      if (testFile.existsSync()) testFile.deleteSync();
      if (testDir.existsSync()) testDir.deleteSync(recursive: true);
    });

    test('execute creates file with correct content', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_write');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_write.txt');
      final content = 'Hello, World! 你好世界';

      final output = await tool.execute({
        'file_path': testFile.path,
        'content': content,
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(testFile.existsSync(), isTrue);
      expect(await testFile.readAsString(), equals(content));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute overwrites existing file', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_write_overwrite');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_overwrite.txt');
      await testFile.writeAsString('Old content');

      final output = await tool.execute({
        'file_path': testFile.path,
        'content': 'New content',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('New content'));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute handles UTF-8 content correctly', () async {
      final tool = createWriteTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_write_utf8');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_utf8_write.txt');
      final content = 'Привет, мир! 你好世界';

      final output = await tool.execute({
        'file_path': testFile.path,
        'content': content,
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(encoding: utf8), equals(content));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test(
      'execute fails to write to read-only location',
      () async {
        final tool = createWriteTool();
        final ctx = _mockCtx();

        // Try to write to a system directory that likely requires permissions
        final output = await tool.execute({
          'file_path': '/root/test.txt',
          'content': 'test',
        }, ctx);

        // Should return an error (permission denied or similar)
        expect(output.metadata?['error'], isTrue);
      },
      skip: 'Might succeed on some systems, skip if permissions allow',
    );
  });
}
