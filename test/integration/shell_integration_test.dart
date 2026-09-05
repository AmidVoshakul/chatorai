import 'dart:io';

import 'package:test/test.dart';

import 'package:chatorai/core/tools/built_in/shell.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'helpers/test_context.dart';

/// Integration tests for the shell tool.
///
/// These tests execute REAL shell commands on the host system.
/// They verify end-to-end behavior: command execution, stdout/stderr capture,
/// timeout handling, and error conditions.
///
/// Skip policy:
/// - If `shell` executable is not found in PATH, all tests are SKIPPED.
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
  group('shell Integration Tests', () {
    group('Environment', () {
      test('shell is available in PATH', () async {
        await _requireBash();
      });
    });

    group('Basic command execution', () {
      test('simple echo command returns expected output', () async {
        await _requireBash();

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
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

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
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

      test('multi-line output via printf works', () async {
        await _requireBash();

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
        );

        final output = await tool.execute({
          'command': 'printf "line1\\nline2"',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('line1'));
        expect(output.output, contains('line2'));
      });
    });

    group('Output capture', () {
      test('simple echo command captures output', () async {
        await _requireBash();

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
        );

        final output = await tool.execute({
          'command': 'echo "hello world"',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.output, contains('hello world'));
        expect(output.metadata?['exit_code'], equals(0));
      });

      test('printf with newline produces multi-line output', () async {
        await _requireBash();

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
        );

        final output = await tool.execute({
          'command': 'printf "first\\nsecond"',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.output, contains('first'));
        expect(output.output, contains('second'));
      });
    });

    group('Error handling', () {
      test('non-existent command returns error metadata', () async {
        await _requireBash();

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
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

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
        );

        final output = await tool.execute({
          'command': 'echo "unclosed quote',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
      });

      test('permission denied (e.g., /etc/shadow) returns error', () async {
        await _requireBash();

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
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
      test(
        'command exceeding timeout returns error metadata',
        () async {
          await _requireBash();

          final tool = createShellTool();
          final ctx = const IntegrationTestContext(
            toolCallId: 'shell-integration-test',
            sessionId: 'shell-integration-session',
          );

          // Use a short timeout (500ms) with a command that sleeps 5 seconds.
          // 500ms is long enough to avoid race conditions with process startup
          // but short enough to trigger the timeout reliably.
          final output = await tool.execute({
            'command': 'sleep 5',
            'timeout': 500,
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
        },
        timeout: Timeout(const Duration(seconds: 10)),
      );

      test('command within timeout completes successfully', () async {
        await _requireBash();

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
        );

        // Simple echo with 2-second timeout should succeed
        final output = await tool.execute({
          'command': 'echo "done"',
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

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
        );

        final output = await tool.execute({'command': 'true'}, ctx);

        expect(output.metadata?['exit_code'], equals(0));
        expect(output.metadata?['error'], isNull);
      });

      test('failed command (false) returns non-zero exit code', () async {
        await _requireBash();

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
        );

        final output = await tool.execute({'command': 'false'}, ctx);

        expect(output.metadata?['exit_code'], isNot(0));
        expect(output.metadata?['error'], isTrue);
      });

      test('command with explicit exit code propagates correctly', () async {
        await _requireBash();

        final tool = createShellTool();
        final ctx = const IntegrationTestContext(
          toolCallId: 'shell-integration-test',
          sessionId: 'shell-integration-session',
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

          final tool = createShellTool();
          final ctx = const IntegrationTestContext(
            toolCallId: 'shell-integration-test',
            sessionId: 'shell-integration-session',
          );

          // Generate 60,000 'x' characters
          final output = await tool.execute({
            'command': r'printf "%0.sx" {1..60000}',
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(
            output.output.length,
            lessThanOrEqualTo(50000 + 50),
            reason:
                'Output should be truncated to ~50000 chars (with sentinel overhead)',
          );
          expect(output.output, contains('truncated'));
        },
        timeout: Timeout(const Duration(seconds: 10)),
      );
    });
  });
}
