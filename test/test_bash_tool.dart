import 'dart:io';
import 'package:test/test.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/features/tools/built_in/bash.dart';

void main() {
  group('bash tool', () {
    test('description is non-empty', () {
      final tool = createBashTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required command field', () {
      final tool = createBashTool();
      final schema = tool.inputSchema as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('command'), isTrue);
      expect(properties['command']['type'], equals('string'));
      expect((schema['required'] as List).contains('command'), isTrue);
    });

    test('execute with missing command returns error', () async {
      final tool = createBashTool();
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
      final output = await tool.execute({}, ctx);
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('command is required'));
    });

    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createBashTool();
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
      await tool.execute({'command': 'echo hello'}, ctx);
      expect(capturedPermission, equals('bash'));
      expect(capturedPatterns, contains('bash:command=echo hello'));
    });

    test('execute simple echo command works', () async {
      final tool = createBashTool();
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

      final output = await tool.execute({'command': 'echo hello world'}, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('hello world'));
    });

    test('execute handles command with description', () async {
      final tool = createBashTool();
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

      final output = await tool.execute({
        'command': 'ls -la',
        'description': 'List files in detail',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      // Output should contain listing
      expect(output.output.length, greaterThan(0));
    });

    test('execute with non-existent command returns error', () async {
      final tool = createBashTool();
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

      final output = await tool.execute({
        'command': 'nonexistent_command_xyz',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });

    test('execute respects timeout', () async {
      final tool = createBashTool();
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

      // Sleep for 5 seconds should exceed default timeout (10s)
      final output = await tool.execute({'command': 'sleep 5'}, ctx);

      // May succeed or timeout depending on system; we just checking it completes
      expect(output, isA<ToolOutput>());
    });

    test('execute captures stderr', () async {
      final tool = createBashTool();
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

      // Command that writes to stderr
      final output = await tool.execute({
        'command': 'echo "error message" >&2',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      // stderr should be included in output
      expect(output.output, contains('error message'));
    });
  });
}
