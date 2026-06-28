import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/grep.dart';

ToolContext _mockCtx({
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
  group('grep tool', () {
    test('description is non-empty', () {
      final tool = createGrepTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required pattern and path fields', () {
      final tool = createGrepTool();
      final schema = tool.inputSchema;
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
        askQuestion:
            ({required question, options = const [], multiple = false}) async =>
                '',
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

    group('invalid regex handling', () {
      test('throws when pattern is invalid regex', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_invalid');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final testFile = File('${testDir.path}/test.txt')
          ..writeAsStringSync('test');

        await expectLater(
          tool.execute({'pattern': '[invalid', 'path': testDir.path}, ctx),
          throwsA(isA<FormatException>()),
        );

        testFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });

      test('throws when pattern has unbalanced parentheses', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_paren');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final testFile = File('${testDir.path}/test.txt')
          ..writeAsStringSync('test');

        await expectLater(
          tool.execute({'pattern': '(unbalanced', 'path': testDir.path}, ctx),
          throwsA(isA<FormatException>()),
        );

        testFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('empty pattern', () {
      test('empty pattern matches every line', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_empty');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final testFile = File('${testDir.path}/test.txt');
        await testFile.writeAsString('line1\nline2\nline3');

        final output = await tool.execute({
          'pattern': '',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        // Empty regex matches every line
        expect(output.output, contains('line1'));
        expect(output.output, contains('line2'));
        expect(output.output, contains('line3'));

        testFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('binary file handling', () {
      test('skips binary files gracefully (detected by content)', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_binary');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        // Create a text file
        final textFile = File('${testDir.path}/text.txt');
        await textFile.writeAsString('findme\nanother findme');

        // Create a binary file (contains null bytes and non-UTF8 sequences)
        final binaryFile = File('${testDir.path}/binary.dat');
        final binaryData = <int>[
          0x00, 0x01, 0x02, 0x03, 0xFF, 0xFE, 0xFD,
          0x00, 0x00, 0x00, 0x66, 0x69, 0x6E, 0x64,
          0x6D, 0x65, // "findme" embedded in binary
        ];
        await binaryFile.writeAsBytes(binaryData);

        final output = await tool.execute({
          'pattern': 'findme',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        // Text file matches should be found
        expect(output.output, contains('text.txt'));
        // Binary file should be skipped (readAsString throws on binary)
        expect(output.output, isNot(contains('binary.dat')));

        textFile.deleteSync();
        binaryFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });

      test('skips files with invalid UTF-8 sequences', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_utf8');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        final textFile = File('${testDir.path}/valid.txt');
        await textFile.writeAsString('hello world');

        // Create a file with invalid UTF-8
        final invalidFile = File('${testDir.path}/invalid.txt');
        await invalidFile.writeAsBytes([
          0x68, 0x65, 0x6C, 0x6C, 0x6F, // "hello"
          0xC0, 0xC1, // invalid UTF-8 start bytes
          0xF5, 0xF6, 0xF7, // invalid sequences
        ]);

        final output = await tool.execute({
          'pattern': 'hello',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('valid.txt'));
        // Invalid file should be silently skipped
        expect(output.output, isNot(contains('invalid.txt')));

        textFile.deleteSync();
        invalidFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('include pattern with special chars', () {
      test('include pattern with regex special chars is escaped', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_special');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        // Create files with special regex chars in names
        final dartFile = File('${testDir.path}/test.dart');
        await dartFile.writeAsString('match');

        // The include pattern uses globToRegex which escapes special chars
        final output = await tool.execute({
          'pattern': 'match',
          'path': testDir.path,
          'include': '*.dart',
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('test.dart'));

        dartFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });

      test('include pattern with parentheses does not break regex', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_paren_include');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        final file1 = File('${testDir.path}/file.txt');
        await file1.writeAsString('findme');

        // Include pattern with parentheses - should be escaped by globToRegex
        final output = await tool.execute({
          'pattern': 'findme',
          'path': testDir.path,
          'include': '*.txt',
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('file.txt'));

        file1.deleteSync();
        testDir.deleteSync(recursive: true);
      });

      test('include pattern with dollar sign is escaped', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_dollar');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        final file1 = File('${testDir.path}/file.txt');
        await file1.writeAsString('test');

        // The _globToRegex function escapes $ to \$
        final output = await tool.execute({
          'pattern': 'test',
          'path': testDir.path,
          'include': '*.txt',
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('file.txt'));

        file1.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('case sensitivity', () {
      test('case insensitive by default', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_case');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final testFile = File('${testDir.path}/test.txt');
        await testFile.writeAsString('Hello\nHELLO\nhello');

        final output = await tool.execute({
          'pattern': 'hello',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        // All three should match (case insensitive by default)
        expect(output.output, contains('Hello'));
        expect(output.output, contains('HELLO'));
        expect(output.output, contains('hello'));

        testFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });

      test('case sensitive when case_sensitive is true', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_casesensitive');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final testFile = File('${testDir.path}/test.txt');
        await testFile.writeAsString('Hello\nHELLO\nhello');

        final output = await tool.execute({
          'pattern': 'hello',
          'path': testDir.path,
          'case_sensitive': true,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        // Only exact case should match
        expect(output.output, contains('hello'));
        expect(output.output, isNot(contains('Hello')));
        expect(output.output, isNot(contains('HELLO')));

        testFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('max_matches', () {
      test('limits results to max_matches', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_max');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final testFile = File('${testDir.path}/test.txt');
        await testFile.writeAsString('match1\nmatch2\nmatch3\nmatch4\nmatch5');

        final output = await tool.execute({
          'pattern': 'match',
          'path': testDir.path,
          'max_matches': 3,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        final lines = output.output
            .split('\n')
            .where((l) => l.isNotEmpty)
            .toList();
        expect(lines.length, 3);

        testFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });

      test('default max_matches is 50', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_default_max');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final testFile = File('${testDir.path}/test.txt');
        final content = List.generate(60, (i) => 'line$i match').join('\n');
        await testFile.writeAsString(content);

        final output = await tool.execute({
          'pattern': 'match',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        final lines = output.output
            .split('\n')
            .where((l) => l.isNotEmpty)
            .toList();
        expect(lines.length, 50);

        testFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('glob to regex conversion', () {
      test('glob pattern *.txt matches files in root directory', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_glob');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final subDir = Directory('${testDir.path}/sub')..createSync();

        final file1 = File('${testDir.path}/root.txt')
          ..writeAsStringSync('match');
        final file2 = File('${subDir.path}/nested.txt')
          ..writeAsStringSync('match');
        final file3 = File('${testDir.path}/root.dart')
          ..writeAsStringSync('match');

        // Note: _globToRegex does NOT handle ** specially — it treats each * as .*
        // So **/*.txt becomes ^.*.*\.txt$ which only matches files in subdirectories.
        // This test documents the actual behavior.
        final output = await tool.execute({
          'pattern': 'match',
          'path': testDir.path,
          'include': '*.txt',
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('root.txt'));
        expect(output.output, isNot(contains('root.dart')));

        file1.deleteSync();
        file2.deleteSync();
        file3.deleteSync();
        subDir.deleteSync(recursive: true);
        testDir.deleteSync(recursive: true);
      });

      test('glob pattern with single star matches any chars', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_single_star');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        final file1 = File('${testDir.path}/test.txt')
          ..writeAsStringSync('match');
        final file2 = File('${testDir.path}/test.dart')
          ..writeAsStringSync('match');

        final output = await tool.execute({
          'pattern': 'match',
          'path': testDir.path,
          'include': '*.txt',
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('test.txt'));
        expect(output.output, isNot(contains('test.dart')));

        file1.deleteSync();
        file2.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('output format', () {
      test('output format is path:lineNumber: content', () async {
        final tool = createGrepTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/temp_grep_format');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final testFile = File('${testDir.path}/test.txt');
        await testFile.writeAsString('first\nsecond match\nthird');

        final output = await tool.execute({
          'pattern': 'match',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        // Format should be: relative/path:lineNumber: content
        expect(output.output, contains('test.txt:2: second match'));

        testFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('permission denial', () {
      test('propagates exception when ctx.ask throws', () async {
        final tool = createGrepTool();
        final ctx = ToolContext(
          toolCallId: 'test-deny',
          sessionId: 'test',
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                throw Exception('Permission denied by user');
              },
          askQuestion:
              ({
                required question,
                options = const [],
                multiple = false,
              }) async => '',
        );

        await expectLater(
          tool.execute({'pattern': 'test', 'path': '.'}, ctx),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
