import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/features/tools/built_in/glob.dart';

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
  group('glob tool', () {
    test('description is non-empty', () {
      final tool = createGlobTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required pattern field', () {
      final tool = createGlobTool();
      final schema = tool.inputSchema as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('pattern'), isTrue);
      expect(properties['pattern']['type'], equals('string'));
      expect((schema['required'] as List).contains('pattern'), isTrue);
    });

    test('execute with missing pattern returns error', () async {
      final tool = createGlobTool();
      final ctx = _mockCtx();
      final output = await tool.execute({}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createGlobTool();
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
      await tool.execute({'pattern': '**/*.dart'}, ctx);
      expect(capturedPermission, equals('glob'));
      expect(capturedPatterns, contains('**/*.dart'));
    });

    test('execute finds files matching pattern', () async {
      final tool = createGlobTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_glob');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final dir1 = Directory('${testDir.path}/subdir')..createSync();
      final file1 = File('${testDir.path}/file1.txt')
        ..writeAsStringSync('test1');
      final file2 = File('${testDir.path}/file2.dart')
        ..writeAsStringSync('test2');
      final file3 = File('${dir1.path}/nested.dart')
        ..writeAsStringSync('test3');

      final output = await tool.execute({'pattern': '**/*.dart'}, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('file2.dart'));
      expect(output.output, contains('nested.dart'));
      expect(output.output, isNot(contains('file1.txt')));

      file1.deleteSync();
      file2.deleteSync();
      file3.deleteSync();
      dir1.deleteSync(recursive: true);
      testDir.deleteSync(recursive: true);
    });

    test('execute returns sorted by modification time', () async {
      final tool = createGlobTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_glob_sort');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final file1 = File('${testDir.path}/a.txt')..writeAsStringSync('a');
      await Future.delayed(Duration(milliseconds: 10));
      final file2 = File('${testDir.path}/b.txt')..writeAsStringSync('b');
      await Future.delayed(Duration(milliseconds: 10));
      final file3 = File('${testDir.path}/c.txt')..writeAsStringSync('c');

      final output = await tool.execute({'pattern': '*.txt'}, ctx);

      final lines = output.output
          .split('\n')
          .where((l) => l.isNotEmpty)
          .toList();
      // The most recent file should appear first (because sorted by mod time desc)
      expect(lines.first, contains('c.txt'));

      file1.deleteSync();
      file2.deleteSync();
      file3.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute handles empty result set', () async {
      final tool = createGlobTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/temp_glob_empty');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final file1 = File('${testDir.path}/file.txt')..writeAsStringSync('test');

      final output = await tool.execute({'pattern': '*.nonexistent'}, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, isEmpty);

      file1.deleteSync();
      testDir.deleteSync(recursive: true);
    });

    test('execute with non-existent base directory returns error', () async {
      final tool = createGlobTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'pattern': '*.dart',
        'path': '${Directory.current.path}/nonexistent/path',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });
  });
}
