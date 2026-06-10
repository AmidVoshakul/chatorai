import 'package:test/test.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:chatorai/features/tools/built_in/task.dart';

ToolContext _mockCtx({
  bool askResult = true,
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
        final schema = tool.inputSchema as Map<String, dynamic>;
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

    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createTaskTool();
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
      await tool.execute({
        'description': 'Test task',
        'prompt': 'Analyze code',
        'subagent_type': 'code-reviewer',
      }, ctx);
      expect(capturedPermission, equals('task'));
      expect(capturedPatterns, contains('code-reviewer'));
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
  });
}
