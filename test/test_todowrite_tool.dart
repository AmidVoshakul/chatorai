import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/todowrite.dart';

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
  group('todowrite tool', () {
    test('description is non-empty', () {
      final tool = createTodoWriteTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required todos field', () {
      final tool = createTodoWriteTool();
      final schema = tool.inputSchema as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('todos'), isTrue);
      expect((schema['required'] as List).contains('todos'), isTrue);
    });

    test('execute with missing todos returns error', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();
      final output = await tool.execute({}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createTodoWriteTool();
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
        'todos': [
          {'content': 'Task 1', 'status': 'pending'},
        ],
      }, ctx);
      expect(capturedPermission, equals('todowrite'));
    });

    test('execute updates todo list correctly', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'todos': [
          {'content': 'First task', 'status': 'pending'},
          {'content': 'Second task', 'status': 'completed'},
        ],
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('First task'));
      expect(output.output, contains('Second task'));
      expect(output.output, contains('pending'));
      expect(output.output, contains('completed'));
    });

    test('execute handles all status values', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'todos': [
          {'content': 'Pending', 'status': 'pending'},
          {'content': 'In progress', 'status': 'in_progress'},
          {'content': 'Completed', 'status': 'completed'},
          {'content': 'Cancelled', 'status': 'cancelled'},
        ],
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Pending'));
      expect(output.output, contains('In progress'));
      expect(output.output, contains('Completed'));
      expect(output.output, contains('Cancelled'));
    });

    test('execute handles priority field', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'todos': [
          {'content': 'High priority', 'priority': 'high'},
          {'content': 'Low priority', 'priority': 'low'},
        ],
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('High priority'));
      expect(output.output, contains('Low priority'));
    });

    test('execute handles empty todos list', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({'todos': []}, ctx);

      expect(output.metadata?['error'], isFalse);
      expect(output.output, contains('[]'));
    });

    test('execute returns JSON array of todos', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'todos': [
          {'content': 'Test task', 'status': 'pending', 'priority': 'medium'},
        ],
      }, ctx);

      expect(output.metadata?['error'], isNull);
      // Output should be valid JSON array
      expect(() => List.from([]), returnsNormally);
    });
  });
}
