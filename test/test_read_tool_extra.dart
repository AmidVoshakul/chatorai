import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/read.dart';

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
    testDir = Directory('test/temp_read_extra');
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

  group('read tool — binary extension detection', () {
    test('file with .exe extension is detected as binary', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_binary.exe');
      await testFile.writeAsBytes([0x4D, 0x5A]); // MZ header

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['binary'], isTrue);
      expect(output.output, contains('Binary file'));
    });

    test('file with .dll extension is detected as binary', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_binary.dll');
      await testFile.writeAsBytes([0x4D, 0x5A]);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['binary'], isTrue);
    });

    test('file with .so extension is detected as binary', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_binary.so');
      await testFile.writeAsBytes([0x7F, 0x45, 0x4C, 0x46]); // ELF header

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['binary'], isTrue);
    });

    test('file with .pyc extension is detected as binary', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_binary.pyc');
      await testFile.writeAsBytes([0xA7, 0x0D, 0x0A, 0x0A]);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['binary'], isTrue);
    });

    test(
      'file with .DS_Store in name is detected via binary content',
      () async {
        // .DS_Store is NOT in the extension list, but its content is binary
        // This tests the content-based detection, not extension
        final tool = createReadTool();
        final ctx = _mockCtx();
        final testFile = File('${testDir.path}/regular_name.txt');
        // Write binary content that exceeds 30% non-printable threshold
        final binaryBytes = List.filled(1000, 0x00);
        await testFile.writeAsBytes(binaryBytes);

        final output = await tool.execute({'file_path': testFile.path}, ctx);
        expect(output.metadata?['binary'], isTrue);
      },
    );

    test('file with .gitignore name but text content is not binary', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/.gitignore');
      await testFile.writeAsString('node_modules/\n*.log');

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['binary'], isFalse);
      expect(output.output, contains('node_modules/'));
    });
  });

  group('read tool — offset clamping', () {
    test('offset beyond file length returns empty content', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_offset_beyond.txt');
      await testFile.writeAsString('Line 1\nLine 2\nLine 3');

      final output = await tool.execute({
        'file_path': testFile.path,
        'offset': 100,
      }, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, isEmpty);
      expect(output.metadata?['offset'], equals(3)); // clamped to lines.length
    });

    test('negative offset clamps to 0', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_offset_negative.txt');
      await testFile.writeAsString('Line 1\nLine 2\nLine 3');

      final output = await tool.execute({
        'file_path': testFile.path,
        'offset': -5,
      }, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['offset'], equals(0));
      expect(output.output, contains('Line 1'));
    });
  });

  group('read tool — large file 2000 line limit', () {
    test('file with exactly 2000 lines returns all 2000', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_exact_2000.txt');
      final lines = List.generate(2000, (i) => 'Line $i');
      await testFile.writeAsString(lines.join('\n'));

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['limit'], equals(2000));
      final outputLines = output.output.split('\n').length;
      expect(outputLines, equals(2000));
    });

    test('file with 2500 lines returns only first 2000', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_2500_lines.txt');
      final lines = List.generate(2500, (i) => 'Line $i');
      await testFile.writeAsString(lines.join('\n'));

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['limit'], equals(2000));
      expect(output.output, contains('Line 0'));
      expect(output.output, contains('Line 1999'));
      expect(output.output, isNot(contains('Line 2000')));
    });

    test('offset with limit spanning beyond file end is clamped', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_offset_limit_clamp.txt');
      final lines = List.generate(10, (i) => 'Line $i');
      await testFile.writeAsString(lines.join('\n'));

      final output = await tool.execute({
        'file_path': testFile.path,
        'offset': 5,
        'limit': 100,
      }, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['limit'], equals(5)); // only lines 5-9 available
      expect(output.output, contains('Line 5'));
      expect(output.output, contains('Line 9'));
    });
  });

  group('read tool — malformed UTF-8', () {
    test('malformed UTF-8 bytes are replaced, not throwing', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_malformed_utf8.txt');
      // Write invalid UTF-8 sequence: 0xFF is not valid in UTF-8
      await testFile.writeAsBytes([0x68, 0x65, 0x6C, 0x6C, 0x6F, 0xFF, 0xFE]);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['binary'], isFalse);
      // Should contain 'hello' (the valid part)
      expect(output.output, contains('hello'));
    });
  });

  group('read tool — path alias', () {
    test('path parameter alias works as fallback', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test_path_alias.txt');
      await testFile.writeAsString('path alias content');

      // Use 'path' instead of 'file_path'
      final output = await tool.execute({'path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('path alias content'));
    });

    test('file_path takes precedence over path', () async {
      final tool = createReadTool();
      final ctx = _mockCtx();
      final testFile1 = File('${testDir.path}/test_priority1.txt');
      final testFile2 = File('${testDir.path}/test_priority2.txt');
      await testFile1.writeAsString('primary');
      await testFile2.writeAsString('secondary');

      final output = await tool.execute({
        'file_path': testFile1.path,
        'path': testFile2.path,
      }, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('primary'));
    });
  });

  group('read tool android storage', () {
    test(
      'FileSystemException path asks nothing when all-files access ok',
      () async {
        final tool = createReadTool();
        int askCount = 0;
        final ctx = ToolContext(
          toolCallId: 't',
          sessionId: 's',
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCount++;
              },
          askQuestion:
              ({
                required question,
                options = const [],
                multiple = false,
              }) async => '',
        );
        final file = File('test/temp/noaccess.txt');
        await file.writeAsString('secret');
        Process.runSync('chmod', ['000', file.path]);
        try {
          final output = await tool.execute({'file_path': file.path}, ctx);
          expect(askCount, 0);
          expect(output.metadata?['error'], isTrue);
          expect(output.metadata?['os_permission'], isTrue);
          expect(output.output, contains('All files access'));
        } finally {
          Process.runSync('chmod', ['644', file.path]);
        }
      },
    );
  });
}
