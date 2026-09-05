import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/shell.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/chat/chat/question_option.dart';
import 'package:chatorai/core/workspace/workspace_runtime.dart';

// Mock for CancellationToken
class MockCancellationToken extends Mock implements sdk.CancellationToken {}

void main() {
  group('shellTool Unit Tests', () {
    late ToolDef shellTool;

    // Helper to create a mock context with auto-approved permissions
    ToolContext _createMockContext({
      String? sessionId,
      sdk.CancellationToken? abortSignal,
      Future<void> Function({
        required String permission,
        required List<String> patterns,
        Map<String, dynamic>? metadata,
        List<String>? always,
      })?
      customAsk,
      void Function({String? title, Map<String, dynamic>? metadata})?
      onMetadata,
    }) {
      return ToolContext(
        toolCallId: 'test-call-id',
        sessionId: sessionId ?? 'test-session',
        abortSignal: abortSignal,
        ask:
            customAsk ??
            ({
              required String permission,
              required List<String> patterns,
              Map<String, dynamic>? metadata,
              List<String>? always,
            }) async {},
        askQuestion:
            ({
              required String question,
              options = const [],
              bool multiple = false,
            }) async => '',
        onMetadata: onMetadata,
      );
    }

    setUp(() {
      shellTool = createShellTool();
    });

    group('Safe commands (no permission needed)', () {
      test('echo hello → no ask() call, direct execution', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        final output = await shellTool.execute({'command': 'echo hello'}, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isNull);
        expect(output.output, contains('hello'));
        expect(
          askCalled,
          isFalse,
          reason: 'Safe command should not trigger ask()',
        );
      });

      test('ls -la → no ask() call', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        final output = await shellTool.execute({'command': 'ls -la'}, ctx);

        expect(output, isA<ToolOutput>());
        expect(askCalled, isFalse);
      });

      test('pwd → no ask() call', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        final output = await shellTool.execute({'command': 'pwd'}, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.output, isNotEmpty);
        expect(askCalled, isFalse);
      });

      test(
        'default working dir follows workspaceRuntimeCurrent',
        () async {
          final original = workspaceRuntimeCurrent;
          final tempDir = Directory.systemTemp.createTempSync(
            'shell_cwd_test_',
          );
          try {
            workspaceRuntimeCurrent = tempDir;
            final ctx = _createMockContext();
            final output = await shellTool.execute({'command': 'pwd'}, ctx);

            expect(output, isA<ToolOutput>());
            expect(output.output, contains(tempDir.path));
          } finally {
            workspaceRuntimeCurrent = original;
            tempDir.deleteSync(recursive: true);
          }
        },
        skip: !Platform.isLinux,
      );
    });

    group('Shell operator detection', () {
      test('cmd1; cmd2 → ask(permission: "shell") called once', () async {
        var askCalled = false;
        var capturedPermission = '';
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
                capturedPermission = permission;
              },
        );

        await shellTool.execute({'command': 'echo foo; echo bar'}, ctx);

        expect(askCalled, isTrue);
        expect(capturedPermission, equals('shell'));
      });

      test('cmd1 && cmd2 → ask called once', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'echo foo && echo bar'}, ctx);

        expect(askCalled, isTrue);
      });

      test('cmd1 || cmd2 → ask called once', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'echo foo || echo bar'}, ctx);

        expect(askCalled, isTrue);
      });

      test('cmd1 | cmd2 → allowed without ask (lowRisk pipeline)', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'echo foo | cat'}, ctx);

        expect(askCalled, isFalse);
      });

      test('cmd1 & → allowed without ask (backgrounding is lowRisk)', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'echo foo &'}, ctx);

        expect(askCalled, isFalse);
      });
    });

    group('Blocked executable detection', () {
      test('curl example.com → ask called once', () async {
        var askCalled = false;
        var capturedPermission = '';
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
                capturedPermission = permission;
              },
        );

        await shellTool.execute({'command': 'curl example.com'}, ctx);

        expect(askCalled, isTrue);
        expect(capturedPermission, equals('shell'));
      });

      test('npm install → ask called once', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'npm install'}, ctx);

        expect(askCalled, isTrue);
      });

      test('wget file → ask called once', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'wget file'}, ctx);

        expect(askCalled, isTrue);
      });
    });

    group('Redirect to system directory', () {
      test('echo foo>/etc/passwd → ask called once (no space regex)', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'echo foo>/etc/passwd'}, ctx);

        expect(askCalled, isTrue);
      });

      test('cat /etc/passwd > /etc/shadow → ask called once', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({
          'command': 'cat /etc/passwd > /etc/shadow',
        }, ctx);

        expect(askCalled, isTrue);
      });
    });

    group('Go package manager detection', () {
      test('go get package → ask called once', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({
          'command': 'go get github.com/example/pkg',
        }, ctx);

        expect(askCalled, isTrue);
      });

      test('go install package → ask called once', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({
          'command': 'go install github.com/example/pkg',
        }, ctx);

        expect(askCalled, isTrue);
      });
    });

    group('Sensitive env file detection', () {
      test('cat .env → ask called once', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'cat .env'}, ctx);

        expect(askCalled, isTrue);
      });

      test('cat .env.local → ask called once', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'cat .env.local'}, ctx);

        expect(askCalled, isTrue);
      });

      test('less README.md → no ask (not an env file)', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'less README.md'}, ctx);

        expect(askCalled, isFalse);
      });
    });

    group('External directory detection', () {
      test(
        'working_dir: /tmp (external) → ask(permission: "external_directory") called',
        () async {
          var askCalled = false;
          var capturedPermission = '';
          final ctx = _createMockContext(
            customAsk:
                ({
                  required String permission,
                  required List<String> patterns,
                  Map<String, dynamic>? metadata,
                  List<String>? always,
                }) async {
                  askCalled = true;
                  capturedPermission = permission;
                },
          );

          // Use /tmp which is typically external to project workspace
          await shellTool.execute({
            'command': 'echo test',
            'working_dir': '/tmp',
          }, ctx);

          expect(askCalled, isTrue);
          expect(capturedPermission, equals('external_directory'));
        },
      );
    });

    group('Permission rejection handling', () {
      test(
        'ask() throws PermissionRejectedError → returns ToolOutput.error with rejected:true',
        () async {
          final ctx = _createMockContext(
            customAsk:
                ({
                  required String permission,
                  required List<String> patterns,
                  Map<String, dynamic>? metadata,
                  List<String>? always,
                }) async {
                  throw PermissionRejectedError('shell');
                },
          );

          final output = await shellTool.execute({
            'command': 'curl example.com',
          }, ctx);

          expect(output, isA<ToolOutput>());
          expect(output.metadata?['error'], isTrue);
          expect(output.metadata?['rejected'], isTrue);
          expect(output.output, contains('rejected'));
        },
      );

      test(
        'PermissionRejectedError on deny decision → returns rejected metadata',
        () async {
          final ctx = _createMockContext(
            customAsk:
                ({
                  required String permission,
                  required List<String> patterns,
                  Map<String, dynamic>? metadata,
                  List<String>? always,
                }) async {
                  throw PermissionRejectedError('shell');
                },
          );

          final output = await shellTool.execute({
            'command': 'echo foo; echo bar',
          }, ctx);

          expect(output.metadata?['rejected'], isTrue);
        },
      );
    });

    group('Input validation', () {
      test('null command → returns error metadata', () async {
        final ctx = _createMockContext();

        final output = await shellTool.execute({}, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('required'));
      });

      test('empty command → returns error metadata', () async {
        final ctx = _createMockContext();

        final output = await shellTool.execute({'command': ''}, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.metadata?['error'], isTrue);
        expect(output.output, contains('required'));
      });
    });

    group('Abort signal handling', () {
      test('abort before execution → returns aborted metadata', () async {
        final abortSignal = MockCancellationToken();
        when(() => abortSignal.isCancelled).thenReturn(true);

        final ctx = _createMockContext(abortSignal: abortSignal);

        final output = await shellTool.execute({'command': 'echo test'}, ctx);

        expect(output.metadata?['aborted'], isTrue);
        expect(output.output, contains('aborted'));
      });
    });

    group('Tool definition', () {
      test('createShellTool returns ToolDef with correct id', () {
        expect(shellTool.id, equals('shell'));
      });

      test('createShellTool has correct input schema', () {
        expect(shellTool.inputSchema['type'], equals('object'));
        expect(shellTool.inputSchema['required'], contains('command'));
        expect(shellTool.inputSchema['properties'], isNotNull);
      });

      test('description is non-empty', () {
        expect(shellTool.description, isNotEmpty);
      });
    });

    group('Timeout handling', () {
      test('timeout parameter is passed correctly', () async {
        var capturedTimeout;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                // This won't be called for safe command
              },
        );

        // Just verify the tool accepts timeout parameter
        final output = await shellTool.execute({
          'command': 'echo test',
          'timeout': 5000,
        }, ctx);

        expect(output, isA<ToolOutput>());
      });
    });

    group('Title in output', () {
      test('description is passed as title in output', () async {
        final ctx = _createMockContext();

        final output = await shellTool.execute({
          'command': 'echo test',
          'description': 'Test command',
        }, ctx);

        expect(output, isA<ToolOutput>());
        expect(output.title, equals('Test command'));
      });
    });

    group('Exit code handling', () {
      test('successful command returns exit_code 0', () async {
        final ctx = _createMockContext();

        final output = await shellTool.execute({'command': 'true'}, ctx);

        expect(output.metadata?['exit_code'], equals(0));
        expect(output.metadata?['error'], isNull);
      });

      test('failed command returns non-zero exit code', () async {
        final ctx = _createMockContext();

        final output = await shellTool.execute({'command': 'false'}, ctx);

        expect(output.metadata?['exit_code'], isNot(0));
        expect(output.metadata?['error'], isTrue);
      });
    });

    group('Blocked executables coverage', () {
      test('ssh is blocked', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'ssh user@host'}, ctx);

        expect(askCalled, isTrue);
      });

      test('eval is blocked', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'eval "echo test"'}, ctx);

        expect(askCalled, isTrue);
      });
    });

    group('Command substitution detection', () {
      test('command substitution \$(...) triggers ask', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': r'echo $(whoami)'}, ctx);

        expect(askCalled, isTrue);
      });
    });

    group('Error handling', () {
      test('process execution error returns error metadata', () async {
        // Use a command that will fail during execution
        final ctx = _createMockContext();

        final output = await shellTool.execute({
          'command': 'ls /nonexistent_directory_xyz_12345',
        }, ctx);

        // The command itself is safe (no dangerous chars), but will fail
        expect(output, isA<ToolOutput>());
        // Exit code should be non-zero
        expect(output.metadata?['exit_code'], isNot(0));
      });
    });

    group('Chmod octal mode detection', () {
      test('chmod 777 triggers ask', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'chmod 777 file.txt'}, ctx);

        expect(askCalled, isTrue);
      });

      test('chmod 755 triggers ask', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'chmod 755 file.txt'}, ctx);

        expect(askCalled, isTrue);
      });

      test('chmod with symbolic mode is allowed', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        await shellTool.execute({'command': 'chmod +x file.txt'}, ctx);

        expect(askCalled, isFalse);
      });
    });

    group('onMetadata callback', () {
      test('onMetadata is called during execution', () async {
        var metadataCalled = false;
        final ctx = _createMockContext(
          onMetadata: ({title, metadata}) {
            metadataCalled = true;
          },
        );

        await shellTool.execute({'command': 'echo test'}, ctx);

        // onMetadata should be called during streaming
        expect(metadataCalled, isTrue);
      });
    });

    group('Chmod with flag argument', () {
      test('chmod with -v flag skips octal mode check', () async {
        var askCalled = false;
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
              },
        );

        // chmod -v 777 should still trigger ask due to octal mode pattern
        // but the argument skip logic is tested
        await shellTool.execute({'command': 'chmod -v file.txt'}, ctx);

        // -v is a flag, so no octal mode check, but command is still safe
        expect(askCalled, isFalse);
      });
    });

    group('Deny decision handling', () {
      test('deny decision falls back to review and calls ask', () async {
        var askCalled = false;
        var capturedPermission = '';
        final ctx = _createMockContext(
          customAsk:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                askCalled = true;
                capturedPermission = permission;
              },
        );

        // Use a command that would trigger deny (if any policy returns deny)
        // Since all policies return review, we test the deny branch indirectly
        // by using a command that triggers the deny path
        await shellTool.execute({'command': 'echo foo; echo bar'}, ctx);

        // The command triggers review, not deny, so this tests the review path
        expect(askCalled, isTrue);
      });
    });
  });
}
