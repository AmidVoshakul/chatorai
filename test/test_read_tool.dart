import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/features/tools/built_in/read.dart';

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
  late Directory testDir;

  setUp(() {
    testDir = Directory('test/temp');
    if (!testDir.existsSync()) testDir.createSync(recursive: true);
  });

  tearDown(() {
    if (testDir.existsSync()) {
      for (final entity in testDir.listSync(recursive: true)) {
        if (entity is File) entity.deleteSync();
        if (entity is Directory) entity.deleteSync(recursive: true);
      }
    }
  });

  group('read tool', () {
    test('description is non-empty', () {
      final tool = createReadTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required file_path field', () {
      final tool = createReadTool();
      final schema = tool.inputSchema as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('file_path'), isTrue);
      expect(properties['file_path']['type'], equals('string'));
      expect((schema['required'] as List).contains('file_path'), isTrue);
    });

    test('execute with missing file_path returns error', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final output = await tool.execute({}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createReadTool();
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
      final testFile = File('${testDir.path}/test_file.txt');
      await testFile.writeAsString('test');
      await tool.execute({'file_path': testFile.path}, ctx);
      expect(capturedPermission, equals('read'));
      expect(capturedPatterns, contains(testFile.absolute.path));
    });

    test('execute with non-existent file returns error', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final output = await tool.execute({
        'file_path': '${testDir.path}/nonexistent.txt',
      }, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file not found'));
    });

    test('execute with valid file returns content', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_read.txt');
      await testFile.writeAsString('Line 1\nLine 2\nLine 3');

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Line 1'));
      expect(output.output, contains('Line 2'));
      expect(output.metadata?['lines'], equals(3));
    });

    test('execute with offset and limit returns correct slice', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_read_slice.txt');
      await testFile.writeAsString('Line 1\nLine 2\nLine 3\nLine 4\nLine 5');

      final output = await tool.execute({
        'file_path': testFile.path,
        'offset': 1,
        'limit': 2,
      }, ctx);
      expect(output.metadata?['offset'], equals(1));
      expect(output.metadata?['limit'], equals(2));
      expect(output.output, contains('Line 2'));
      expect(output.output, contains('Line 3'));
      expect(output.output, isNot(contains('Line 1')));
    });

    test('execute with binary file returns error message', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_binary.bin');
      await testFile.writeAsBytes([0x00, 0x01, 0x02, 0xFF, 0xFE]);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['binary'], isTrue);
      expect(output.output, contains('Binary file'));
    });

    test('execute handles UTF-8 content correctly', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_utf8.txt');
      // Russian and Chinese text
      await testFile.writeAsString('Привет, мир! 你好世界');

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Привет, мир!'));
      expect(output.output, contains('你好世界'));
    });

    test('execute respects max_lines limit of 2000 by default', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_large.txt');
      final lines = List.generate(3000, (i) => 'Line $i');
      await testFile.writeAsString(lines.join('\n'));

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['limit'], equals(2000));

      // Verify we got exactly 2000 lines
      final outputLines = output.output.split('\n').length;
      expect(outputLines, equals(2000));
    });
  });
}
