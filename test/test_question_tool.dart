import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/question.dart';

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
  group('question tool', () {
    test('description is non-empty', () {
      final tool = createQuestionTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required questions field', () {
      final tool = createQuestionTool();
      final schema = tool.inputSchema as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('questions'), isTrue);
      expect((schema['required'] as List).contains('questions'), isTrue);
    });

    test('execute with missing questions returns error', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx();
      final output = await tool.execute({}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute calls ctx.ask with correct permission and pattern', () async {
      final tool = createQuestionTool();
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
        'questions': [
          {
            'question': 'What is your name?',
            'options': ['Alice', 'Bob'],
          },
        ],
      }, ctx);
      expect(capturedPermission, equals('question'));
    });

    test('execute returns question prompt for user', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'questions': [
          {
            'question': 'Favorite color?',
            'options': ['Red', 'Green', 'Blue'],
          },
          {'question': 'Age?', 'type': 'number'},
        ],
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Favorite color?'));
      expect(output.output, contains('Age?'));
    });

    test('execute handles single choice questions', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'questions': [
          {
            'question': 'Select one',
            'options': ['Option A', 'Option B', 'Option C'],
          },
        ],
      }, ctx);

      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Option A'));
      expect(output.output, contains('Option B'));
      expect(output.output, contains('Option C'));
    });

    test('execute handles multi-select questions', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'questions': [
          {
            'question': 'Select all that apply',
            'options': ['A', 'B', 'C'],
            'multiple': true,
          },
        ],
      }, ctx);

      expect(output.metadata?['error'], isNull);
    });

    test('execute validates required question field', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx();

      final output = await tool.execute({
        'questions': [
          {
            'options': ['A', 'B'],
          }, // missing question
        ],
      }, ctx);

      expect(output.metadata?['error'], isTrue);
    });

    test('execute handles empty questions list', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx();

      final output = await tool.execute({'questions': []}, ctx);

      expect(output.metadata?['error'], isTrue);
    });
  });
}
