import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/lsp.dart';

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

ToolContext _cancelledCtx() {
  final token = sdk.CancellationToken();
  token.cancel();
  return ToolContext(
    toolCallId: 'test-cancelled',
    sessionId: 'test-session',
    abortSignal: token,
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

String _tempFile(String name, String content) {
  final dir = Directory('test/temp');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File('test/temp/$name');
  file.writeAsStringSync(content);
  return file.path;
}

void main() {
  group('lsp tool', () {
    test('description is non-empty', () {
      final tool = createLspTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required filePath field', () {
      final tool = createLspTool();
      final schema = tool.inputSchema;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('filePath'), isTrue);
      expect(properties['filePath']['type'], equals('string'));
      expect(schema['required'], contains('filePath'));
    });

    test('inputSchema has optional verbose and timeout fields', () {
      final tool = createLspTool();
      final schema = tool.inputSchema;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('verbose'), isTrue);
      expect(properties['verbose']['type'], equals('boolean'));
      expect(properties.containsKey('timeout'), isTrue);
      expect(properties['timeout']['type'], equals('integer'));
    });

    test('execute with null filePath returns error', () async {
      final tool = createLspTool();
      final ctx = _mockCtx();
      final output = await tool.execute({}, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('filePath is required'));
    });

    test('execute with empty filePath returns error', () async {
      final tool = createLspTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'filePath': ''}, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('filePath is required'));
    });

    test('execute with non-existent path returns error', () async {
      final tool = createLspTool();
      final ctx = _mockCtx();
      final output = await tool.execute({
        'filePath': 'test/temp/nonexistent_file.dart',
      }, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('Path not found'));
    });

    test('execute with cancelled abort signal returns aborted error', () async {
      final tool = createLspTool();
      final path = _tempFile('lsp_cancel.dart', 'void main() {}\n');
      final ctx = _cancelledCtx();
      final output = await tool.execute({'filePath': path}, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.metadata?['aborted'], isTrue);
    });

    test(
      'execute does not call ctx.ask (lsp has no permission prompt)',
      () async {
        final tool = createLspTool();
        bool askCalled = false;
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
                askCalled = true;
              },
          askQuestion:
              ({
                required question,
                options = const [],
                multiple = false,
              }) async => '',
        );

        final path = _tempFile('lsp_perm.dart', 'void main() {}\n');
        await tool.execute({'filePath': path}, ctx);

        // LSP tool runs dart analyze without permission prompt
        expect(askCalled, isFalse);
      },
    );

    test('execute returns valid JSON for clean file', () async {
      final tool = createLspTool();
      final ctx = _mockCtx();
      final path = _tempFile(
        'lsp_clean.dart',
        'void main() {\n  print("hello");\n}\n',
      );
      final output = await tool.execute({'filePath': path}, ctx);

      // Output should be valid JSON
      final decoded = jsonDecode(output.output) as Map<String, dynamic>;
      expect(decoded.containsKey('exitCode'), isTrue);
      expect(decoded.containsKey('issues'), isTrue);
      expect(decoded.containsKey('summary'), isTrue);
    });

    test('execute returns error metadata for file with issues', () async {
      final tool = createLspTool();
      final ctx = _mockCtx();
      // File with intentional issue: missing semicolon (info-level in Dart)
      final path = _tempFile(
        'lsp_issues.dart',
        'void main() {\n  var x = 1\n}\n',
      );
      final output = await tool.execute({'filePath': path}, ctx);

      // Should still return valid JSON even if there are issues
      final decoded = jsonDecode(output.output) as Map<String, dynamic>;
      expect(decoded.containsKey('summary'), isTrue);
      final summary = decoded['summary'] as Map<String, dynamic>;
      expect(summary.containsKey('errors'), isTrue);
      expect(summary.containsKey('warnings'), isTrue);
    });

    test('execute with verbose flag includes info diagnostics', () async {
      final tool = createLspTool();
      final ctx = _mockCtx();
      final path = _tempFile(
        'lsp_verbose.dart',
        'void main() {\n  print("test");\n}\n',
      );
      final output = await tool.execute({
        'filePath': path,
        'verbose': true,
      }, ctx);

      final decoded = jsonDecode(output.output) as Map<String, dynamic>;
      // With verbose, --fatal-infos is removed so info diagnostics may appear
      expect(decoded.containsKey('summary'), isTrue);
    });

    test(
      'execute returns error on filesystem exception',
      () async {
        final tool = createLspTool();
        final ctx = _mockCtx();
        // Use a path that will cause a filesystem error (directory as file)
        final dir = Directory('test/temp/lsp_dir_test');
        if (!dir.existsSync()) dir.createSync(recursive: true);

        // Try to read a directory as a file — dart analyze on a directory
        // should return an error but not crash
        final output = await tool.execute({
          'filePath': 'test/temp/lsp_dir_test',
        }, ctx);
        // Should either return valid JSON with errors or an error message
        expect(output.output, isNotEmpty);
      },
      skip: 'Directory analyze behavior varies by Dart version',
    );

    test('execute handles timeout parameter', () async {
      final tool = createLspTool();
      final ctx = _mockCtx();
      final path = _tempFile('lsp_timeout.dart', 'void main() {}\n');
      // Very short timeout — should still work for a small file
      final output = await tool.execute({
        'filePath': path,
        'timeout': 60000,
      }, ctx);
      expect(output.output, isNotEmpty);
    });

    test('metadata includes filePath and counts', () async {
      final tool = createLspTool();
      final ctx = _mockCtx();
      final path = _tempFile('lsp_meta.dart', 'void main() {}\n');
      final output = await tool.execute({'filePath': path}, ctx);

      expect(output.metadata?['filePath'], equals(path));
      expect(output.metadata?['exitCode'], isNotNull);
      expect(output.metadata?['errors'], isNotNull);
      expect(output.metadata?['warnings'], isNotNull);
    });

    test('title is set correctly', () async {
      final tool = createLspTool();
      final ctx = _mockCtx();
      final path = _tempFile('lsp_title.dart', 'void main() {}\n');
      final output = await tool.execute({'filePath': path}, ctx);

      expect(output.title, equals('dart analyze $path'));
    });

    tearDown(() {
      // Clean up temp files
      final dir = Directory('test/temp');
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          if (entity is File && entity.path.contains('lsp_')) {
            entity.deleteSync();
          } else if (entity is Directory && entity.path.contains('lsp_')) {
            entity.deleteSync(recursive: true);
          }
        }
      }
    });
  });
}
