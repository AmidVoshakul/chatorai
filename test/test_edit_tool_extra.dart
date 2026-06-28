import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/edit.dart';

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
  late Directory testDir;

  setUp(() {
    testDir = Directory('test/temp_edit_extra');
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

  group('edit tool — staleness guard', () {
    test('edit succeeds on first-time file (no prior read recorded)', () async {
      // Without a prior read, FileEditGuard.checkStale returns null
      // and the edit proceeds normally
      final tool = createEditTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_first_access.txt');
      await testFile.writeAsString('Hello old World');

      final output = await tool.execute({
        'file_path': testFile.path,
        'old_string': 'old',
        'new_string': 'new',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('Hello new World'));
    });

    test('edit on file that was read by read tool succeeds', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_after_read.txt');
      await testFile.writeAsString('Hello old World');

      // Read the file first (simulates what the read tool does)
      await testFile.readAsString();

      final output = await tool.execute({
        'file_path': testFile.path,
        'old_string': 'old',
        'new_string': 'new',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('Hello new World'));
    });
  });

  group('edit tool — same old_string and new_string', () {
    test('same old_string and new_string produces no-op', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_noop.txt');
      await testFile.writeAsString('Hello World');

      final output = await tool.execute({
        'file_path': testFile.path,
        'old_string': 'World',
        'new_string': 'World',
      }, ctx);

      // replaceAll with same string is a no-op but succeeds
      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('Hello World'));
    });
  });

  group('edit tool — empty old_string', () {
    test(
      'empty old_string produces no-op (replaceAll inserts between chars)',
      () async {
        final tool = createEditTool();
        final ctx = _mockCtx();
        final testFile = File('${testDir.path}/test_empty_old.txt');
        await testFile.writeAsString('Hello World');

        final output = await tool.execute({
          'file_path': testFile.path,
          'old_string': '',
          'new_string': 'replacement',
        }, ctx);

        // content.contains('') is always true, replaceAll('', 'replacement')
        // inserts between every character. This documents current behavior.
        expect(output.metadata?['error'], isNull);
      },
    );
  });

  group('edit tool — path alias', () {
    test('path parameter alias works as fallback', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_alias.txt');
      await testFile.writeAsString('Hello old World');

      final output = await tool.execute({
        'path': testFile.path,
        'old_string': 'old',
        'new_string': 'new',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('Hello new World'));
    });

    test('oldString parameter alias works as fallback', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_oldstring_alias.txt');
      await testFile.writeAsString('Hello old World');

      final output = await tool.execute({
        'file_path': testFile.path,
        'oldString': 'old',
        'newString': 'new',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('Hello new World'));
    });
  });

  group('edit tool — edge cases', () {
    test('edit with non-existent file returns error', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'file_path': '${testDir.path}/nonexistent.txt',
        'old_string': 'old',
        'new_string': 'new',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('not found'));
    });

    test('edit with empty new_string deletes old_string', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_delete.txt');
      await testFile.writeAsString('Hello old World');

      final output = await tool.execute({
        'file_path': testFile.path,
        'old_string': ' old',
        'new_string': '',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('Hello World'));
    });

    test('edit with multiline old_string', () async {
      final tool = createEditTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_multiline.txt');
      await testFile.writeAsString('Line 1\nLine 2\nLine 3');

      final output = await tool.execute({
        'file_path': testFile.path,
        'old_string': 'Line 2\nLine 3',
        'new_string': 'Replaced',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(await testFile.readAsString(), equals('Line 1\nReplaced'));
    });

    test(
      'edit preserves file content when old_string appears multiple times',
      () async {
        final tool = createEditTool();
        final ctx = _mockCtx();
        final testFile = File('${testDir.path}/test_multiple.txt');
        await testFile.writeAsString('abc abc abc');

        final output = await tool.execute({
          'file_path': testFile.path,
          'old_string': 'abc',
          'new_string': 'xyz',
          'replace_all': false,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(await testFile.readAsString(), equals('xyz abc abc'));
      },
    );
  });
}
