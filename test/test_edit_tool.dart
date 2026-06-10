import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/features/tools/built_in/edit.dart';

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
  );
}

void main() {
  group('edit tool', () {
    test('description is non-empty', () {
      final tool = createEditTool();
      expect(tool.description, isNotEmpty);
    });

    test(
      'inputSchema has required file_path and old_string and new_string fields',
      () {
        final tool = createEditTool();
        final schema = tool.inputSchema as Map<String, dynamic>;
        final properties = schema['properties'] as Map<String, dynamic>;
        expect(properties.containsKey('file_path'), isTrue);
        expect(properties.containsKey('old_string'), isTrue);
        expect(properties.containsKey('new_string'), isTrue);
        expect((schema['required'] as List).contains('file_path'), isTrue);
        expect((schema['required'] as List).contains('old_string'), isTrue);
        expect((schema['required'] as List).contains('new_string'), isTrue);
      },
    );

    test('execute with missing required fields returns error', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'file_path': '/test/file.txt'}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createEditTool();
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
      );
      // Use a temporary file within project to avoid path denial
      final testDir = Directory('test/temp_edit_perm');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_perm.txt');
      await testFile.writeAsString('test');

      await tool.execute({
        'file_path': testFile.path,
        'old_string': 'test',
        'new_string': 'new',
      }, ctx);

      expect(capturedPermission, equals('edit'));
      // Pattern should be 'edit:file_path=<absolute path>'
      expect(
        capturedPatterns,
        contains('edit:file_path=${testFile.absolute.path}'),
      );

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute replaces exact string match', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_edit');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_edit.txt');
      await testFile.writeAsString('Hello old World!');

      final output = await tool.execute({
        'file_path': testFile.path,
        'old_string': 'old',
        'new_string': 'new',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('Hello new World!'));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute handles multiple occurrences by default', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_edit_multi');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_edit_multi.txt');
      await testFile.writeAsString('old old old');

      final output = await tool.execute({
        'file_path': testFile.path,
        'old_string': 'old',
        'new_string': 'new',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('new new new'));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test(
      'execute with replaceAll=false replaces only first occurrence',
      () async {
        final tool = createEditTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_edit_first');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final testFile = File('${testDir.path}/test_edit_first.txt');
        await testFile.writeAsString('old old old');

        final output = await tool.execute({
          'file_path': testFile.path,
          'old_string': 'old',
          'new_string': 'new',
          'replace_all': false,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(await testFile.readAsString(), equals('new old old'));

        testFile.deleteSync();
        testDir.deleteSync(recursive: true);
      },
    );

    test('execute with UTF-8 content works correctly', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_edit_utf8');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_edit_utf8.txt');
      await testFile.writeAsString('Привет, мир! 你好世界');

      final output = await tool.execute({
        'file_path': testFile.path,
        'old_string': 'мир',
        'new_string': 'мир!',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(
        await testFile.readAsString(encoding: utf8),
        equals('Привет, мир!! 你好世界'),
      );

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute returns error when old_string not found', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_edit_notfound');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_edit_notfound.txt');
      await testFile.writeAsString('Hello World!');

      final output = await tool.execute({
        'file_path': testFile.path,
        'old_string': 'NotFound',
        'new_string': 'new',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('not found'));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });
  });
}
