import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/task.dart';

ToolContext _mockCtx({
  List<String>? askedPermission,
  List<String>? askedPatterns,
  String? sessionId,
}) {
  askedPermission;
  askedPatterns;
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: sessionId ?? 'test-session',
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
  group('task tool', () {
    test('description is non-empty', () {
      final tool = createTaskTool();
      expect(tool.description, isNotEmpty);
    });

    test(
      'inputSchema has required description, prompt, subagent_type fields',
      () {
        final tool = createTaskTool();
        final schema = tool.inputSchema;
        final properties = schema['properties'] as Map<String, dynamic>;
        expect(properties.containsKey('description'), isTrue);
        expect(properties.containsKey('prompt'), isTrue);
        expect(properties.containsKey('subagent_type'), isTrue);
        expect((schema['required'] as List).contains('description'), isTrue);
        expect((schema['required'] as List).contains('prompt'), isTrue);
        expect((schema['required'] as List).contains('subagent_type'), isTrue);
      },
    );

    test('execute with missing required fields returns error', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();
      final output = await tool.execute({
        'description': 'test task',
        'prompt': 'do something',
      }, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute creates task result with session ID', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Simple task',
        'prompt': 'Say hello',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('session_id'));
      expect(output.metadata?['session_id'], isNotNull);
    });

    test('execute includes description and subagent_type in result', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'My task description',
        'prompt': 'Do the thing',
        'subagent_type': 'explore',
      }, ctx);

      expect(output.metadata?['description'], equals('My task description'));
      expect(output.metadata?['subagent_type'], equals('explore'));
    });

    test('execute handles optional task_id', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Task with ID',
        'prompt': 'Do work',
        'subagent_type': 'general',
        'task_id': 'custom-task-123',
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['session_id'], isNotNull);
    });

    test('execute fails with unknown subagent_type', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Unknown agent',
        'prompt': 'Do something',
        'subagent_type': 'nonexistent_agent_xyz',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });

    test('execute returns error when session ID is null', () async {
      final tool = createTaskTool();
      final ctx = ToolContext(
        toolCallId: 'test-call-id',
        sessionId: null,
        ask:
            ({
              required String permission,
              required List<String> patterns,
              Map<String, dynamic>? metadata,
              List<String>? always,
            }) async {},
        askQuestion:
            ({required question, options = const [], multiple = false}) async =>
                '',
      );

      final output = await tool.execute({
        'description': 'No session',
        'prompt': 'Do something',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('session ID'));
    });

    test('execute returns error when description is empty', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': '',
        'prompt': 'Do something',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });

    test('execute returns error when prompt is empty', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Valid description',
        'prompt': '',
        'subagent_type': 'general',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });

    test('execute returns error when subagent_type is empty string', () async {
      final tool = createTaskTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'description': 'Valid',
        'prompt': 'Valid prompt',
        'subagent_type': '',
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });

    test('permission call includes subagent_type as pattern', () async {
      final tool = createTaskTool();
      String? capturedPermission;
      List<String>? capturedPatterns;
      final ctx = ToolContext(
        toolCallId: 'test',
        sessionId: 'test-session',
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

      await tool.execute({
        'description': 'Test',
        'prompt': 'Do work',
        'subagent_type': 'explore',
      }, ctx);

      expect(capturedPermission, equals('task'));
      expect(capturedPatterns, isNotNull);
      expect(capturedPatterns!.contains('explore'), isTrue);
    });

    test('permission metadata includes description and subagent_type',
        () async {
      final tool = createTaskTool();
      Map<String, dynamic>? capturedMetadata;
      final ctx = ToolContext(
        toolCallId: 'test',
        sessionId: 'test-session',
        ask:
            ({
              required String permission,
              required List<String> patterns,
              Map<String, dynamic>? metadata,
              List<String>? always,
            }) async {
              capturedMetadata = metadata;
            },
        askQuestion:
            ({required question, options = const [], multiple = false}) async =>
                '',
      );

      await tool.execute({
        'description': 'My special task',
        'prompt': 'Do work',
        'subagent_type': 'build',
      }, ctx);

      expect(capturedMetadata, isNotNull);
      expect(capturedMetadata!['description'], equals('My special task'));
      expect(capturedMetadata!['subagent_type'], equals('build'));
    });

    group('XML output format', () {
      test('output contains state="completed" attribute', () async {
        final tool = createTaskTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'description': 'Format test',
          'prompt': 'Check XML',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, contains('state="completed"'));
      });

      test('output contains <summary> with description', () async {
        final tool = createTaskTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'description': 'My summary text',
          'prompt': 'Do stuff',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, contains('<summary>My summary text</summary>'));
      });

      test('output contains <task_result> tag', () async {
        final tool = createTaskTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'description': 'Result test',
          'prompt': 'Produce result',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, contains('<task_result>'));
        expect(output.output, contains('</task_result>'));
      });

      test('output wraps in <task> root element', () async {
        final tool = createTaskTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'description': 'Wrap test',
          'prompt': 'Test',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, startsWith('<task '));
        expect(output.output, endsWith('</task>'));
      });

      test('output includes session_id attribute in <task> tag', () async {
        final tool = createTaskTool();
        final ctx = _mockCtx(sessionId: 'sess-abc-123');

        final output = await tool.execute({
          'description': 'Session test',
          'prompt': 'Test',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, contains('session_id="sess-abc-123"'));
      });

      test('output includes task_id when provided', () async {
        final tool = createTaskTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'description': 'Task ID test',
          'prompt': 'Test',
          'subagent_type': 'general',
          'task_id': 'my-custom-id-42',
        }, ctx);

        expect(output.output, contains('task_id="my-custom-id-42"'));
      });

      test('output auto-generates id when task_id not provided', () async {
        final tool = createTaskTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'description': 'Auto ID test',
          'prompt': 'Test',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, contains('id="sub-'));
      });
    });

    group('MVP fallback output', () {
      test('MVP fallback includes agent name in task_result', () async {
        final tool = createTaskTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'description': 'MVP test',
          'prompt': 'Test fallback',
          'subagent_type': 'general',
        }, ctx);

        expect(output.output, contains('[Subagent MVP not yet wired'));
        expect(output.output, contains('Agent: General'));
      });

      test('MVP fallback includes prompt in task_result', () async {
        final tool = createTaskTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'description': 'MVP prompt',
          'prompt': 'My specific prompt text',
          'subagent_type': 'explore',
        }, ctx);

        expect(output.output, contains('Prompt: My specific prompt text'));
      });
    });

    group('_deriveSubagentTools', () {
      test('excludes task and todowrite from subagent tool set', () {
        final registry = MockToolRegistry();

        registry.register('read', mockSdkTool());
        registry.register('edit', mockSdkTool());
        registry.register('task', mockSdkTool());
        registry.register('todowrite', mockSdkTool());
        registry.register('glob', mockSdkTool());

        final subagentTools = deriveSubagentToolsForTest(registry);

        expect(subagentTools.containsKey('task'), isFalse);
        expect(subagentTools.containsKey('todowrite'), isFalse);
        expect(subagentTools.containsKey('read'), isTrue);
        expect(subagentTools.containsKey('edit'), isTrue);
        expect(subagentTools.containsKey('glob'), isTrue);
      });

      test('returns empty map when registry has only denied tools', () {
        final registry = MockToolRegistry();
        registry.register('task', mockSdkTool());
        registry.register('todowrite', mockSdkTool());

        final subagentTools = deriveSubagentToolsForTest(registry);

        expect(subagentTools, isEmpty);
      });

      test('preserves all non-denied tools', () {
        final registry = MockToolRegistry();
        registry.register('bash', mockSdkTool());
        registry.register('read', mockSdkTool());
        registry.register('write', mockSdkTool());
        registry.register('grep', mockSdkTool());

        final subagentTools = deriveSubagentToolsForTest(registry);

        expect(subagentTools.length, equals(4));
        expect(subagentTools.containsKey('bash'), isTrue);
        expect(subagentTools.containsKey('read'), isTrue);
        expect(subagentTools.containsKey('write'), isTrue);
        expect(subagentTools.containsKey('grep'), isTrue);
      });
    });
  });
}

// --- Helpers for _deriveSubagentTools testing ---

/// Expose the private _deriveSubagentTools function for direct testing.
ToolSet deriveSubagentToolsForTest(dynamic registry) {
  final allTools = registry.toSDKTools();
  final result = <String, Tool<dynamic, dynamic>>{};
  for (final entry in allTools.entries) {
    if (!subagentDeniedTools.contains(entry.key)) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}

const subagentDeniedTools = {'task', 'todowrite'};

/// Minimal SDK tool stub for registry testing.
Tool<dynamic, dynamic> mockSdkTool() {
  return Tool<dynamic, dynamic>(
    inputSchema: Schema(jsonSchema: {}, fromJson: (j) => j),
    description: 'Mock tool',
    executeDynamic: (_, _) async => '',
  );
}

/// Minimal ToolRegistry that only exposes toSDKTools for derive testing.
class MockToolRegistry {
  final Map<String, Tool<dynamic, dynamic>> _tools = {};

  void register(String id, Tool<dynamic, dynamic> tool) {
    _tools[id] = tool;
  }

  Map<String, Tool<dynamic, dynamic>> toSDKTools() => Map.from(_tools);
}
