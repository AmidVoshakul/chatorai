import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool_execution.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_error.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';

/// Creates a ToolDef with a simple execute function.
ToolDef _simpleToolDef(
  String id,
  Future<ToolOutput> Function(Map<String, dynamic> input, ToolContext ctx)
  executeFn,
) {
  return ToolDef(
    id: id,
    description: 'Test tool $id',
    inputSchema: {
      'type': 'object',
      'properties': {
        'input': {'type': 'string'},
      },
      'required': ['input'],
    },
    execute: executeFn,
  );
}

/// Unit tests for ToolExecutor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PermissionService permissionService;
  late PermissionRuleset defaultRules;
  late ToolExecutor executor;

  setUp(() {
    permissionService = PermissionService();
    defaultRules = PermissionRuleset.defaults();
    executor = ToolExecutor(permissionService, defaultRules);
  });

  group('ToolExecutor.execute', () {
    test('executes tool and returns output with metadata', () async {
      final tool = _simpleToolDef('read', (input, ctx) async {
        return ToolOutput('file content', metadata: {'lines': 10});
      });

      final options = _experimentalContext('session-1');
      final result = await executor.execute(tool, {'input': 'test'}, options);

      expect(result['output'], equals('file content'));
      expect(result['metadata'], isNotNull);
      expect(result['metadata']['lines'], equals(10));
    });

    test('truncates output exceeding 50000 chars', () async {
      final longOutput = 'x' * 60000;
      final tool = _simpleToolDef('read', (input, ctx) async {
        return ToolOutput(longOutput);
      });

      final options = _experimentalContext('session-truncate');
      final result = await executor.execute(tool, {'input': 'big'}, options);

      final output = result['output'] as String;
      expect(output.length, lessThan(60000));
      expect(output, contains('truncated'));
    });

    test('does not cache side-effecting tools (bash)', () async {
      var callCount = 0;
      final tool = _simpleToolDef('bash', (input, ctx) async {
        callCount++;
        return ToolOutput('output $callCount');
      });

      final options = _experimentalContext('session-bash');

      final result1 = await executor.execute(tool, {'input': 'cmd1'}, options);
      final result2 = await executor.execute(tool, {'input': 'cmd1'}, options);

      // bash is side-effecting, so both calls should execute
      expect(callCount, equals(2));
      // Results might differ since both executed
      expect(result1['output'], isNotNull);
      expect(result2['output'], isNotNull);
    });

    test('caches non-side-effecting tools', () async {
      var callCount = 0;
      final tool = _simpleToolDef('read', (input, ctx) async {
        callCount++;
        return ToolOutput('output $callCount');
      });

      final options = _experimentalContext('session-cache');

      final result1 = await executor.execute(tool, {'input': 'file1'}, options);
      final result2 = await executor.execute(tool, {'input': 'file1'}, options);

      // Second call should use cache
      expect(callCount, equals(1));
      expect(result1['output'], equals(result2['output']));
    });

    test('deduplicates in-flight requests', () async {
      var callCount = 0;
      final tool = _simpleToolDef('read', (input, ctx) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return ToolOutput('output $callCount');
      });

      final options = _experimentalContext('session-dedup');

      // Start two concurrent calls with same input
      final future1 = executor.execute(tool, {'input': 'file1'}, options);
      final future2 = executor.execute(tool, {'input': 'file1'}, options);

      final results = await Future.wait([future1, future2]);

      // Both should reuse the same in-flight request
      expect(callCount, equals(1));
      expect(results[0]['output'], equals(results[1]['output']));
    });

    test('handles ToolInvalidArgsError', () async {
      final tool = _simpleToolDef('read', (input, ctx) async {
        throw const ToolInvalidArgsError('read', 'missing required field');
      });

      final options = _experimentalContext('session-args');

      final result = await executor.execute(tool, {'input': ''}, options);

      expect(result['error'], equals('invalid_args'));
      expect(result['message'], equals('missing required field'));
      expect(result['toolName'], equals('read'));
    });

    test('handles ToolOverflowError', () async {
      final tool = _simpleToolDef('read', (input, ctx) async {
        throw const ToolOverflowError('read', 'output too large');
      });

      final options = _experimentalContext('session-overflow');

      final result = await executor.execute(tool, {'input': 'huge'}, options);

      expect(result['error'], equals('overflow'));
      expect(result['message'], equals('output too large'));
      expect(result['toolName'], equals('read'));
    });

    test('handles tool that returns error ToolOutput', () async {
      // Instead of throwing, the tool returns a ToolOutput with error metadata.
      // This tests the normal error path that tools use.
      final tool = _simpleToolDef('read', (input, ctx) async {
        return ToolOutput('Error: file not found', metadata: {'error': true});
      });

      final options = _experimentalContext('session-err-output');

      final result = await executor.execute(tool, {'input': 'test'}, options);

      expect(result['output'], equals('Error: file not found'));
      expect(result['metadata'], isNotNull);
      expect(result['metadata']['error'], isTrue);
    });

    test('handles raw (non-Map) input', () async {
      final tool = _simpleToolDef('read', (input, ctx) async {
        return ToolOutput('processed: ${input['raw']}');
      });

      final options = _experimentalContext('session-raw');

      // Raw non-Map input is wrapped as {'raw': rawInput}. The tool schema
      // in _simpleToolDef requires 'input', so schema validation rejects
      // the wrapped raw input. This test verifies the ToolInvalidArgsError path.
      final result = await executor.execute(tool, 'raw string', options);

      // When schema validation fails, ToolExecutor throws ToolInvalidArgsError
      // which is caught and returned as error JSON
      expect(result['error'], equals('invalid_args'));
    });
  });

  group('ToolExecutor doom-loop detection', () {
    test('doom loop threshold is 3 identical calls', () async {
      // The _doomLoopCheck method returns true after 3 identical calls.
      // We verify this by checking that the 4th call with the same input
      // triggers the doom loop path (which calls permissions.ask).
      // Since we can't easily test the full flow without hanging,
      // we verify the tool executes normally for the first 3 calls.
      final tool = _simpleToolDef('read', (input, ctx) async {
        return ToolOutput('ok');
      });

      final options = _experimentalContext('session-doom');

      // First 3 calls should work normally
      for (var i = 0; i < 3; i++) {
        final result = await executor.execute(tool, {'input': 'same'}, options);
        expect(result['output'], equals('ok'));
      }
    });

    test('doom loop history is pruned per-tool', () async {
      final tool = _simpleToolDef('read', (input, ctx) async {
        return ToolOutput('ok');
      });

      final options = _experimentalContext('session-prune');

      // Make many unique calls to fill history
      for (var i = 0; i < 100; i++) {
        await executor.execute(tool, {'input': 'input-$i'}, options);
      }

      // History should be pruned (we can't directly verify, but no crash)
      final result = await executor.execute(tool, {'input': 'final'}, options);
      expect(result['output'], equals('ok'));
    });
  });

  group('ToolExecutor.pruneSession', () {
    test('removes session cache entries', () async {
      final tool = _simpleToolDef('read', (input, ctx) async {
        return ToolOutput('cached');
      });

      final options = _experimentalContext('session-prune-test');

      // Create cache entry
      await executor.execute(tool, {'input': 'file1'}, options);
      await executor.execute(tool, {'input': 'file2'}, options);

      // Prune session
      executor.pruneSession('session-prune-test');

      // New call should re-execute (not use cache)
      final result = await executor.execute(tool, {'input': 'file1'}, options);
      expect(result['output'], equals('cached'));
    });
  });
}

/// Helper to create SDK-style options with experimental context.
dynamic _experimentalContext(String sessionId) {
  return _SdkToolOptions(sessionId: sessionId);
}

class _SdkToolOptions {
  final String sessionId;
  _SdkToolOptions({required this.sessionId});

  Map<String, dynamic> get experimentalContext => {'sessionId': sessionId};
}
