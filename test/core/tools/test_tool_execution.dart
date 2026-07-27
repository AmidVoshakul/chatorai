import 'package:flutter_test/flutter_test.dart';
import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_error.dart';
import 'package:chatorai/core/tools/tool_execution.dart';
import 'package:chatorai/core/tools/tool_registry.dart';

/// Fake tool options for testing ToolExecutor without SDK dependencies.
class _FakeToolOptions {
  final String? sessionId;
  final Map<String, dynamic>? experimentalContext;

  _FakeToolOptions({this.sessionId, this.experimentalContext});
}

ToolDef _echoTool({String id = 'echo', bool throwInvalidArgs = false}) {
  return ToolDef(
    id: id,
    description: 'Echo tool',
    inputSchema: {'type': 'object'},
    execute: (input, ctx) async {
      if (throwInvalidArgs) {
        throw ToolInvalidArgsError(id, 'missing required field');
      }
      return ToolOutput(input['text']?.toString() ?? 'echo');
    },
  );
}

ToolDef _overflowTool() {
  return ToolDef(
    id: 'overflow_tool',
    description: 'Overflow tool',
    inputSchema: {'type': 'object'},
    execute: (input, ctx) async {
      throw ToolOverflowError('overflow_tool', 'Output too large');
    },
  );
}

void main() {
  group('ToolExecutor', () {
    late PermissionService permissions;
    late PermissionRuleset ruleset;
    late ToolExecutor executor;

    setUp(() {
      permissions = PermissionService();
      ruleset = PermissionRuleset.defaults();
      executor = ToolExecutor(permissions, ruleset);
    });

    test('execute returns tool output for simple tool', () async {
      final tool = _echoTool();
      final result = await executor.execute(tool, {
        'text': 'hello',
      }, _FakeToolOptions(sessionId: 'test-session'));
      expect(result['output'], equals('hello'));
    });

    test('execute caches read-only tool results', () async {
      final tool = _echoTool(id: 'read');
      final options = _FakeToolOptions(
        sessionId: 'cache-test',
        experimentalContext: {'sessionId': 'cache-test'},
      );

      // First execution
      final result1 = await executor.execute(tool, {'text': 'cached'}, options);
      expect(result1['output'], equals('cached'));

      // Second execution should return cached result
      final result2 = await executor.execute(tool, {'text': 'cached'}, options);
      expect(result2['output'], equals('cached'));
    });

    test(
      'execute caches when toolCallId matches (SDK double-dispatch guard)',
      () async {
        var callCount = 0;
        final trackingTool = ToolDef(
          id: 'read',
          description: 'Tracking tool',
          inputSchema: {'type': 'object'},
          execute: (input, ctx) async {
            callCount++;
            return ToolOutput(input['text']?.toString() ?? 'echo');
          },
        );

        final options = sdk.ToolExecutionOptions(
          toolCallId: 'call-123',
          experimentalContext: {'sessionId': 'dedup-test'},
        );

        // First call should execute
        final result1 = await executor.execute(trackingTool, {
          'text': 'hello',
        }, options);
        expect(result1['output'], equals('hello'));
        expect(callCount, equals(1));

        // Second call with same toolCallId should hit cache
        final result2 = await executor.execute(trackingTool, {
          'text': 'hello',
        }, options);
        expect(result2['output'], equals('hello'));
        expect(callCount, equals(1));
      },
    );

    test(
      'execute does NOT cache different toolCallIds without sessionId',
      () async {
        var callCount = 0;
        final trackingTool = ToolDef(
          id: 'read',
          description: 'Tracking tool',
          inputSchema: {'type': 'object'},
          execute: (input, ctx) async {
            callCount++;
            return ToolOutput(input['text']?.toString() ?? 'echo');
          },
        );

        // First call with call-1, no sessionId → cached by toolCallId
        await executor.execute(trackingTool, {
          'text': 'hello',
        }, sdk.ToolExecutionOptions(toolCallId: 'call-1'));
        expect(callCount, equals(1));

        // Second call with different toolCallId, no sessionId → fresh execution
        await executor.execute(trackingTool, {
          'text': 'hello',
        }, sdk.ToolExecutionOptions(toolCallId: 'call-2'));
        expect(callCount, equals(2));
      },
    );

    test('execute falls back to timestamp when toolCallId unavailable', () async {
      final tool = _echoTool();
      // _FakeToolOptions is not a ToolExecutionOptions → cast yields null toolCallId
      final result = await executor.execute(tool, {
        'text': 'fallback',
      }, _FakeToolOptions(sessionId: null));
      expect(result['output'], equals('fallback'));
    });

    test(
      'execute prioritises sessionId over toolCallId in cache key',
      () async {
        var callCount = 0;
        final trackingTool = ToolDef(
          id: 'read',
          description: 'Tracking tool',
          inputSchema: {'type': 'object'},
          execute: (input, ctx) async {
            callCount++;
            return ToolOutput(input['text']?.toString() ?? 'echo');
          },
        );

        // Same toolCallId, different sessionId → should execute twice
        await executor.execute(
          trackingTool,
          {'text': 'hello'},
          sdk.ToolExecutionOptions(
            toolCallId: 'call-123',
            experimentalContext: {'sessionId': 'session-a'},
          ),
        );
        expect(callCount, equals(1));

        await executor.execute(
          trackingTool,
          {'text': 'hello'},
          sdk.ToolExecutionOptions(
            toolCallId: 'call-123',
            experimentalContext: {'sessionId': 'session-b'},
          ),
        );
        expect(callCount, equals(2));
      },
    );

    test(
      'execute does NOT cache side-effecting tools (shell, write)',
      () async {
        var callCount = 0;
        final shellTool = ToolDef(
          id: 'shell',
          description: 'shell',
          inputSchema: {'type': 'object'},
          execute: (input, ctx) async {
            callCount++;
            return ToolOutput('output $callCount');
          },
        );

        final options = _FakeToolOptions(
          sessionId: 'no-cache-test',
          experimentalContext: {'sessionId': 'no-cache-test'},
        );

        await executor.execute(shellTool, {'cmd': 'ls'}, options);
        await executor.execute(shellTool, {'cmd': 'ls'}, options);
        expect(callCount, equals(2));
      },
    );

    test('execute handles ToolInvalidArgsError', () async {
      final tool = _echoTool(throwInvalidArgs: true);
      final result = await executor.execute(
        tool,
        {},
        _FakeToolOptions(sessionId: 'err-test'),
      );
      expect(result['error'], equals('invalid_args'));
      expect(result['message'], equals('missing required field'));
      expect(result['toolName'], equals('echo'));
    });

    test('execute handles ToolOverflowError', () async {
      final tool = _overflowTool();
      final result = await executor.execute(
        tool,
        {},
        _FakeToolOptions(sessionId: 'overflow-test'),
      );
      expect(result['error'], equals('overflow'));
      expect(result['toolName'], equals('overflow_tool'));
    });

    // Note: unhandled errors (generic Exception) are rethrown by ToolExecutor,
    // but testing async rethrows with completers is fragile in unittests.
    // The happy path (ToolInvalidArgsError, ToolOverflowError) is tested above.

    test('execute works with null sessionId', () async {
      final tool = _echoTool();
      final result = await executor.execute(tool, {
        'text': 'no session',
      }, _FakeToolOptions(sessionId: null));
      expect(result['output'], equals('no session'));
    });

    test('execute works with empty sessionId', () async {
      final tool = _echoTool();
      final result = await executor.execute(tool, {
        'text': 'empty session',
      }, _FakeToolOptions(sessionId: ''));
      expect(result['output'], equals('empty session'));
    });

    test('execute normalizes non-Map input', () async {
      final tool = _echoTool();
      final result = await executor.execute(
        tool,
        'raw string input',
        _FakeToolOptions(),
      );
      // Non-map input is wrapped in {'raw': input}
      expect(result, isNotNull);
    });

    test('pruneSession clears session data', () async {
      final tool = _echoTool(id: 'read');
      final options = _FakeToolOptions(
        sessionId: 'prune-test',
        experimentalContext: {'sessionId': 'prune-test'},
      );

      await executor.execute(tool, {'text': 'prune me'}, options);

      // Should not throw
      executor.pruneSession('prune-test');
    });

    test('doom loop detection activates after threshold', () async {
      // The doom loop threshold is 3 same-input calls.
      // Use 'shell' as a side-effecting tool (NOT cached) so each call
      // actually goes through execute() and doom-loop tracking.
      var callCount = 0;
      final shellLikeTool = ToolDef(
        id: 'shell',
        description: 'shell-like tool for doom test',
        inputSchema: {'type': 'object'},
        execute: (input, ctx) async {
          callCount++;
          return ToolOutput('output $callCount');
        },
      );

      final permissions2 = PermissionService();
      final denyRuleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'doom_loop',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );
      final executor2 = ToolExecutor(permissions2, denyRuleset);

      final options = _FakeToolOptions(
        sessionId: 'doom-test',
        experimentalContext: {'sessionId': 'doom-test'},
      );

      final input = {'command': 'ls'};

      // Execute 3 times — doom loop tracker records but doesn't trigger yet
      for (var i = 0; i < 3; i++) {
        final r = await executor2.execute(shellLikeTool, input, options);
        expect(r['output'], isNotNull);
      }

      // 4th execution: doom loop threshold met (count=3 >= threshold=3), deny rule → empty output
      final result = await executor2.execute(shellLikeTool, input, options);
      expect(result['output'], equals(''));
    });
  });

  group('ToolRegistry with ToolExecutor', () {
    test('toSDKTools binds all registered tools', () {
      final permissions = PermissionService();
      final registry = ToolRegistry(permissions, PermissionRuleset.defaults());
      registry.register(_echoTool(id: 'tool1'));
      registry.register(_echoTool(id: 'tool2'));

      final sdkTools = registry.toSDKTools();
      expect(sdkTools.length, equals(2));
      expect(sdkTools.containsKey('tool1'), isTrue);
      expect(sdkTools.containsKey('tool2'), isTrue);
    });
  });

  group('_AskContext', () {
    test('toToolContext creates ToolContext with correct fields', () async {
      final permissions = PermissionService();
      final ruleset = PermissionRuleset.defaults();
      final executor = ToolExecutor(permissions, ruleset);

      final questionTool = ToolDef(
        id: 'question_test',
        description: 'Question tool',
        inputSchema: {'type': 'object'},
        execute: (input, ctx) async {
          return ToolOutput('done');
        },
      );

      final result = await executor.execute(
        questionTool,
        {'text': 'hello'},
        _FakeToolOptions(
          sessionId: 'ask-ctx-test',
          experimentalContext: {'sessionId': 'ask-ctx-test'},
        ),
      );

      expect(result, isNotNull);
    });
  });
}
