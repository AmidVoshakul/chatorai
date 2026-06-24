import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/grep.dart';

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
  group('grep tool', () {
    test('description is non-empty', () {
      final tool = createGrepTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required pattern and path fields', () {
      final tool = createGrepTool();
      final schema = tool.inputSchema as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('pattern'), isTrue);
      expect(properties.containsKey('path'), isTrue);
      expect((schema['required'] as List).contains('pattern'), isTrue);
    });

    test('execute with missing pattern returns error', () async {
      final tool = createGrepTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'path': '.'}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createGrepTool();
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
      await tool.execute({'pattern': 'test', 'path': '.'}, ctx);
      expect(capturedPermission, equals('grep'));
      expect(capturedPatterns, contains('test'));
    });

    test('execute finds matching lines in files', () async {
      final tool = createGrepTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_grep');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_grep.txt');
      await testFile.writeAsString('line1\nmatch here\nline3\nanother match');

      final output = await tool.execute({
        'pattern': 'match',
        'path': testDir.path,
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('match here'));
      expect(output.output, contains('another match'));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute with no matches returns empty result', () async {
      final tool = createGrepTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_grep_nomatch');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_grep_nomatch.txt');
      await testFile.writeAsString('line1\nline2\nline3');

      final output = await tool.execute({
        'pattern': 'nonexistent',
        'path': testDir.path,
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, isEmpty);

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute respects include pattern', () async {
      final tool = createGrepTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_grep_include');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final dartFile = File('${testDir.path}/test.dart');
      final txtFile = File('${testDir.path}/test.txt');
      await dartFile.writeAsString('dart code\nmatch in dart');
      await txtFile.writeAsString('text file\nno match here');

      final output = await tool.execute({
        'pattern': 'match',
        'path': testDir.path,
        'include': '*.dart',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('match in dart'));
      expect(output.output, isNot(contains('no match here')));

      dartFile.deleteSync();
      txtFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute handles regex pattern correctly', () async {
      final tool = createGrepTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_grep_regex');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final testFile = File('${testDir.path}/test_grep_regex.txt');
      await testFile.writeAsString('cat\nbat\nrat\nmat');

      final output = await tool.execute({
        'pattern': r'^.at$',
        'path': testDir.path,
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('cat'));
      expect(output.output, contains('bat'));
      expect(output.output, contains('rat'));
      expect(output.output, contains('mat'));

      testFile.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute handles file not found error gracefully', () async {
      final tool = createGrepTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'pattern': 'test',
        'path': '${Directory.current.path}/nonexistent/path',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });
  });
}
