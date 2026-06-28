import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/glob.dart';

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
  group('glob tool', () {
    test('description is non-empty', () {
      final tool = createGlobTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required pattern field', () {
      final tool = createGlobTool();
      final schema = tool.inputSchema;
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
        askQuestion:
            ({required question, options = const [], multiple = false}) async =>
                '',
      );
      await tool.execute({'pattern': '**/*.dart'}, ctx);
      expect(capturedPermission, equals('glob'));
      expect(capturedPatterns, contains('**/*.dart'));
    });

    test('execute finds files matching pattern', () async {
      final tool = createGlobTool();
      final ctx = _mockCtx();

      final testDir = Directory('test/glob_test');
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

      final testDir = Directory('test/glob_sort');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final file1 = File('${testDir.path}/a.txt')..writeAsStringSync('a');
      await Future.delayed(Duration(milliseconds: 10));
      final file2 = File('${testDir.path}/b.txt')..writeAsStringSync('b');
      await Future.delayed(Duration(milliseconds: 10));
      final file3 = File('${testDir.path}/c.txt')..writeAsStringSync('c');

      final output = await tool.execute({
        'pattern': '*.txt',
        'path': testDir.path,
      }, ctx);

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

      final testDir = Directory('test/glob_empty');
      if (!testDir.existsSync()) testDir.createSync(recursive: true);
      final file1 = File('${testDir.path}/file.txt')..writeAsStringSync('test');

      final output = await tool.execute({'pattern': '*.nonexistent'}, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, 'No files matching pattern: *.nonexistent');

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

    group('followLinks behavior', () {
      test('does not follow symlinks when followLinks is false', () async {
        final tool = createGlobTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/glob_symlinks');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        // Create a directory with a real file
        final realDir = Directory('${testDir.path}/real_dir')..createSync();
        final realFile = File('${realDir.path}/real.dart')
          ..writeAsStringSync('real');

        // Create a symlink to the real directory
        final linkPath = '${testDir.path}/link_dir';
        try {
          Link(linkPath).createSync('${testDir.path}/real_dir');
        } catch (_) {
          // Skip if symlinks not supported
          realFile.deleteSync();
          realDir.deleteSync(recursive: true);
          testDir.deleteSync(recursive: true);
          return;
        }

        final output = await tool.execute({
          'pattern': '**/*.dart',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        // The real file should be found
        expect(output.output, contains('real.dart'));
        // Symlinked directory contents should NOT be listed separately
        // (followLinks: false means symlinks are not traversed)
        final dartCount = output.output
            .split('\n')
            .where((l) => l.contains('.dart'))
            .length;
        expect(dartCount, 1);

        // Cleanup
        Link(linkPath).deleteSync();
        realFile.deleteSync();
        realDir.deleteSync(recursive: true);
        testDir.deleteSync(recursive: true);
      });

      test('symlink to file is not included in results', () async {
        final tool = createGlobTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/glob_symlink_file');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        // Create a real file
        final realFile = File('${testDir.path}/real.txt')
          ..writeAsStringSync('real content');

        // Create a symlink to the file
        final linkPath = '${testDir.path}/link.txt';
        try {
          Link(linkPath).createSync('${testDir.path}/real.txt');
        } catch (_) {
          realFile.deleteSync();
          testDir.deleteSync(recursive: true);
          return;
        }

        final output = await tool.execute({
          'pattern': '*.txt',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        // Only the real file should be found, not the symlink
        final txtFiles = output.output
            .split('\n')
            .where((l) => l.isNotEmpty)
            .toList();
        expect(txtFiles.length, 1);
        expect(txtFiles.first, contains('real.txt'));

        // Cleanup
        Link(linkPath).deleteSync();
        realFile.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('posix path conversion', () {
      test('outputs use posix path separators', () async {
        final tool = createGlobTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/glob_posix');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final subDir = Directory('${testDir.path}/sub')..createSync();
        final file1 = File('${subDir.path}/file.dart')
          ..writeAsStringSync('test');

        final output = await tool.execute({
          'pattern': '**/*.dart',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        // On all platforms, output should use posix separators (/)
        expect(output.output, isNot(contains('\\')));
        expect(output.output, contains('sub/file.dart'));

        file1.deleteSync();
        subDir.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('gitignore handling', () {
      test('malformed gitignore patterns do not crash', () async {
        final tool = createGlobTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/glob_gitignore');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        // Create a .gitignore with a malformed pattern
        final gitignore = File('${testDir.path}/.gitignore')
          ..writeAsStringSync('valid_pattern\n[invalid\n*.log');
        final file1 = File('${testDir.path}/test.dart')
          ..writeAsStringSync('test');
        final file2 = File('${testDir.path}/test.log')
          ..writeAsStringSync('log');

        final output = await tool.execute({
          'pattern': '*',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        // The valid pattern (*.log) should still be applied
        expect(output.output, contains('test.dart'));
        expect(output.output, isNot(contains('test.log')));

        file1.deleteSync();
        file2.deleteSync();
        gitignore.deleteSync();
        testDir.deleteSync(recursive: true);
      });

      test('empty gitignore does not affect results', () async {
        final tool = createGlobTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/glob_empty_gitignore');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        final gitignore = File('${testDir.path}/.gitignore')
          ..writeAsStringSync('');
        final file1 = File('${testDir.path}/test.dart')
          ..writeAsStringSync('test');

        final output = await tool.execute({
          'pattern': '*.dart',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('test.dart'));

        file1.deleteSync();
        gitignore.deleteSync();
        testDir.deleteSync(recursive: true);
      });

      test('gitignore comments are ignored', () async {
        final tool = createGlobTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/glob_gitignore_comments');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        final gitignore = File('${testDir.path}/.gitignore')
          ..writeAsStringSync('# This is a comment\n*.log\n# Another comment');
        final file1 = File('${testDir.path}/test.dart')
          ..writeAsStringSync('test');
        final file2 = File('${testDir.path}/test.log')
          ..writeAsStringSync('log');

        final output = await tool.execute({
          'pattern': '*',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('test.dart'));
        expect(output.output, isNot(contains('test.log')));

        file1.deleteSync();
        file2.deleteSync();
        gitignore.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('permission denial', () {
      test('propagates exception when ctx.ask throws', () async {
        final tool = createGlobTool();
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
          tool.execute({'pattern': '*.dart'}, ctx),
          throwsA(isA<Exception>()),
        );
      });

      test('throws when path is outside sandbox', () async {
        final tool = createGlobTool();
        final ctx = _mockCtx();

        await expectLater(
          tool.execute({
            'pattern': '*.dart',
            'path': '/tmp/outside_project',
          }, ctx),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('default path behavior', () {
      test('uses Directory.current.path when path is omitted', () async {
        final tool = createGlobTool();
        final ctx = _mockCtx();

        // Create a file in the current directory
        final tempFile = File(
          '${Directory.current.path}/test_glob_default_path.tmp',
        )..writeAsStringSync('test');

        final output = await tool.execute({
          'pattern': 'test_glob_default_path.tmp',
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('test_glob_default_path.tmp'));

        tempFile.deleteSync();
      });

      test('uses explicitly provided path over default', () async {
        final tool = createGlobTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/glob_explicit_path');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);
        final file1 = File('${testDir.path}/explicit.dart')
          ..writeAsStringSync('test');

        final output = await tool.execute({
          'pattern': '*.dart',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('explicit.dart'));

        file1.deleteSync();
        testDir.deleteSync(recursive: true);
      });
    });

    group('result limit', () {
      test('stops collecting after reaching 1000 matches', () async {
        final tool = createGlobTool();
        final ctx = _mockCtx();

        final testDir = Directory('test/glob_limit');
        if (!testDir.existsSync()) testDir.createSync(recursive: true);

        // Create more than 1000 files
        for (var i = 0; i < 1010; i++) {
          File('${testDir.path}/file_$i.txt').writeAsStringSync('content $i');
        }

        final output = await tool.execute({
          'pattern': '*.txt',
          'path': testDir.path,
        }, ctx);

        expect(output.metadata?['error'], isNull);
        final lines = output.output
            .split('\n')
            .where((l) => l.isNotEmpty)
            .toList();
        // Should be capped at 1000
        expect(lines.length, lessThanOrEqualTo(1000));

        // Cleanup
        for (var i = 0; i < 1010; i++) {
          try {
            File('${testDir.path}/file_$i.txt').deleteSync();
          } catch (_) {}
        }
        testDir.deleteSync(recursive: true);
      });
    });
  });
}
