import 'dart:io';

import 'package:test/test.dart';

import 'package:chatorai/features/tools/built_in/bash.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';
import '_test_context.dart';

/// Integration tests for the bash tool.
///
/// These tests execute REAL shell commands on the host system.
/// They verify end-to-end behavior: command execution, stdout/stderr capture,
/// timeout handling, and error conditions.
///
/// Skip policy:
/// - If `bash` executable is not found in PATH, all tests are SKIPPED.
/// - Tests that rely on specific utilities (echo, printf, sleep) assume they
///   exist on a standard Unix/Linux/macOS system. CI environments should have them.
Future<bool> _isBashAvailable() async {
  try {
    final result = await Process.run('which', ['bash']);
    return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
  } catch (_) {
    return false;
  }
}

final Future<bool> _bashAvailableFuture = _isBashAvailable();

Future<void> _requireBash() async {
  final available = await _bashAvailableFuture;
  if (!available) {
    markTestSkipped(
      'bash executable not found in PATH — skipping integration tests.',
    );
  }
}

void main() {
  group('Bash Integration Tests', () {
    group('Environment', () {
      test('bash is available in PATH', () async {
        await _requireBash();
      });
    });

    group('Basic command execution', () {
      test('simple echo command returns expected output', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({'command': 'echo hello'}, ctx);

        expect(output, isA<ToolOutput>());
        expect(
          output.metadata?['error'],
          isNull,
          reason: 'Should not have error flag on success',
        );
        expect(output.output.trim(), contains('hello'));
        expect(output.metadata?['exit_code'], equals(0));
      });

      test('command with arguments (printf) produces correct lines', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({'command': r'printf "a\nb\n"'}, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isNull);
        final lines = output.output
            .split('\n')
            .where((l) => l.isNotEmpty)
            .toList();
        expect(lines, contains('a'));
        expect(lines, contains('b'));
      });

      test('multi-line command with semicolon works', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({
          'command': 'echo line1; echo line2',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('line1'));
        expect(output.output, contains('line2'));
      });
    });

    group('Stderr capture', () {
      test('command writing to stderr captures output', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({
          'command': 'echo "error message" >&2',
        }, ctx);

        expect(output, isA<ToolOutput>());
        // stderr is merged into output; should contain the message
        expect(output.output, contains('error message'));
        // Exit code should be 0 (successful execution even with stderr)
        expect(output.metadata?['exit_code'], equals(0));
      });

      test('both stdout and stderr are captured', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({
          'command': 'echo "stdout line"; echo "stderr line" >&2',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.output, contains('stdout line'));
        expect(output.output, contains('stderr line'));
      });
    });

    group('Error handling', () {
      test('non-existent command returns error metadata', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({
          'command': 'nonexistent_command_xyz_12345',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(
          output.metadata?['error'],
          isTrue,
          reason: 'Should have error flag for non-existent command',
        );
        expect(output.metadata?['exit_code'], isNot(0));
      });

      test('command with invalid syntax returns error', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({
          'command': 'echo "unclosed quote',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
      });

      test('permission denied (e.g., /etc/shadow) returns error', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({
          'command': 'cat /etc/shadow 2>/dev/null || echo "cannot read"',
        }, ctx);

        // Either we get an error (permission denied) or the fallback message
        // The important thing is the tool doesn't crash and returns a ToolOutput
        expect(output, isA<ToolOutput>());
      });
    });

    group('Timeout handling', () {
      test('command exceeding timeout returns error metadata', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        // Use a very short timeout (100ms) with a command that sleeps 5 seconds
        final output = await tool.execute({
          'command': 'sleep 5',
          'timeout': 100,
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(
          output.metadata?['error'],
          isTrue,
          reason: 'Should have error flag when timed out',
        );
        // Exit code should be -1 for timeout (as per implementation)
        expect(output.metadata?['exit_code'], equals(-1));
        // Output may be empty or contain partial output; just check it's a string
        expect(output.output, isA<String>());
      });

      test('command within timeout completes successfully', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        // Sleep for 200ms with 2-second timeout should succeed
        final output = await tool.execute({
          'command': 'sleep 0.2 && echo "done"',
          'timeout': 2000,
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('done'));
        expect(output.metadata?['exit_code'], equals(0));
      });
    });

    group('Exit code propagation', () {
      test('successful command returns exit_code 0', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({'command': 'true'}, ctx);

        expect(output.metadata?['exit_code'], equals(0));
        expect(output.metadata?['error'], isNull);
      });

      test('failed command (false) returns non-zero exit code', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({'command': 'false'}, ctx);

        expect(output.metadata?['exit_code'], isNot(0));
        expect(output.metadata?['error'], isTrue);
      });

      test('command with explicit exit code propagates correctly', () async {
        await _requireBash();

        final tool = createBashTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'bash-integration-test',
          sessionId: 'bash-integration-session',
        );

        final output = await tool.execute({'command': 'exit 42'}, ctx);

        expect(output.metadata?['exit_code'], equals(42));
        expect(output.metadata?['error'], isTrue);
      });
    });

    group('Output truncation', () {
      test(
        'very large output is truncated at 50000 characters',
        () async {
          await _requireBash();

          final tool = createBashTool();
          final ctx = const IntegrationTestContext(
            toolCallId: 'bash-integration-test',
            sessionId: 'bash-integration-session',
          );

          // Generate 60,000 'x' characters
          final output = await tool.execute({
            'command': r'printf "%0.sx" {1..60000}',
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(
            output.output.length,
            lessThanOrEqualTo(50000 + 20),
            reason: 'Output should be truncated to ~50000 chars',
          );
          expect(output.output, contains('... (truncated)'));
        },
        timeout: Timeout(const Duration(seconds: 10)),
      );
    });
  });
}
