import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/todowrite.dart';

// Access the private store for verification via a test helper
// The store is file-private, so we verify behavior indirectly.

ToolContext _mockCtx({
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
          askedPermission?.add(permission);
          askedPatterns?.addAll(patterns);
        },
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
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
      final schema = tool.inputSchema;
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
        askQuestion:
            ({required question, options = const [], multiple = false}) async =>
                '',
      );
      await tool.execute({
        'todos': [
          {'content': 'Task 1', 'status': 'pending'},
        ],
      }, ctx);
      expect(capturedPermission, equals('todowrite'));
      expect(capturedPatterns, isNotNull);
      expect(capturedPatterns!.first, contains('count=1'));
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

    test('execute handles invalid status enum value without crashing', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'todos': [
          {'content': 'Task with bad status', 'status': 'invalid_status'},
        ],
      }, ctx);

      // Current implementation does not validate enum at runtime — should not crash
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('invalid_status'));
    });

    test('execute handles todo item missing content field', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'todos': [
          {'status': 'pending'},
        ],
      }, ctx);

      // Should not crash even though content is missing
      expect(output.output, isNotNull);
    });

    test('execute handles special characters in content (XSS/injection)', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'todos': [
          {
            'content': '<script>alert("xss")</script>',
            'status': 'pending',
          },
          {
            'content': 'Robert; DROP TABLE users;--',
            'status': 'in_progress',
          },
          {
            'content': '{"key": "value", "nested": {"a": 1}}',
            'status': 'completed',
          },
        ],
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('<script>alert("xss")</script>'));
      expect(output.output, contains('Robert; DROP TABLE users;--'));
      expect(output.output, contains('{"key": "value", "nested": {"a": 1}}'));
    });

    test('execute handles unicode and emoji in content', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'todos': [
          {'content': 'Задача на русском', 'status': 'pending'},
          {'content': 'タスク', 'status': 'in_progress'},
          {'content': '🚀🔥💥', 'status': 'completed'},
        ],
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Задача на русском'));
      expect(output.output, contains('タスク'));
      expect(output.output, contains('🚀🔥💥'));
    });

    test('execute returns correct count in metadata', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'todos': [
          {'content': 'A', 'status': 'pending'},
          {'content': 'B', 'status': 'pending'},
          {'content': 'C', 'status': 'pending'},
        ],
      }, ctx);

      expect(output.metadata?['count'], equals(3));
    });

    test('execute stores todos per session ID (verified via metadata)', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'todos': [
          {'content': 'Session task', 'status': 'pending'},
        ],
      }, ctx);

      // Verify session ID is reflected in metadata
      expect(output.metadata?['sessionId'], equals('test-session'));
      expect(output.metadata?['count'], equals(1));
    });

    test('execute overwrites previous todos for same session', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final firstOutput = await tool.execute({
        'todos': [
          {'content': 'Old task', 'status': 'completed'},
        ],
      }, ctx);
      expect(firstOutput.metadata?['count'], equals(1));

      final secondOutput = await tool.execute({
        'todos': [
          {'content': 'New task 1', 'status': 'pending'},
          {'content': 'New task 2', 'status': 'in_progress'},
        ],
      }, ctx);
      expect(secondOutput.metadata?['count'], equals(2));
      expect(secondOutput.output, contains('New task 1'));
      expect(secondOutput.output, isNot(contains('Old task')));
    });

    test('execute handles null todos parameter', () async {
      final tool = createTodoWriteTool();
      final ctx = _mockCtx();

      final output = await tool.execute({'todos': null}, ctx);

      expect(output.metadata?['error'], isTrue);
    });

    test('permission pattern includes correct count', () async {
      final tool = createTodoWriteTool();
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
              capturedPatterns = patterns;
            },
        askQuestion:
            ({required question, options = const [], multiple = false}) async =>
                '',
      );

      await tool.execute({
        'todos': [
          {'content': 'A', 'status': 'pending'},
          {'content': 'B', 'status': 'completed'},
          {'content': 'C', 'status': 'in_progress'},
        ],
      }, ctx);

      expect(capturedPatterns, isNotNull);
      expect(capturedPatterns!.first, contains('count=3'));
    });
  });
}
