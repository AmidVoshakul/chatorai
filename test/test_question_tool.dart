import 'package:chatorai/core/chat/chat/question_option.dart'
    show QuestionOption;
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/question.dart';

ToolContext _mockCtx({String answer = ''}) {
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: 'test-session',
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {},
    askQuestion:
        ({required question, options = const [], multiple = false}) async =>
            answer,
  );
}

void main() {
  group('question tool', () {
    test('description is non-empty', () {
      final tool = createQuestionTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required question field', () {
      final tool = createQuestionTool();
      final schema = tool.inputSchema as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('question'), isTrue);
      expect((schema['required'] as List).contains('question'), isTrue);
    });

    test('execute with missing question returns error', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx();
      final output = await tool.execute({}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute with empty question returns error', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx();
      final output = await tool.execute({'question': ''}, ctx);
      expect(output.metadata?['error'], isTrue);
    });

    test('execute returns user answer', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx(answer: 'Alice');

      final output = await tool.execute({
        'question': 'What is your name?',
        'options': ['Alice', 'Bob'],
      }, ctx);

      expect(output.output, equals('Alice'));
      expect(output.metadata?['question'], equals('What is your name?'));
      expect(
        (output.metadata?['options'] as List)
            .map((o) => (o as QuestionOption).label)
            .toList(),
        equals(['Alice', 'Bob']),
      );
      expect(output.metadata?['answer'], equals('Alice'));
    });

    test('execute handles legacy questions array format', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx(answer: 'Blue');

      final output = await tool.execute({
        'questions': [
          {
            'question': 'Favorite color?',
            'options': ['Red', 'Green', 'Blue'],
          },
        ],
      }, ctx);

      expect(output.output, equals('Blue'));
      expect(output.metadata?['question'], equals('Favorite color?'));
      expect(
        (output.metadata?['options'] as List)
            .map((o) => (o as QuestionOption).label)
            .toList(),
        equals(['Red', 'Green', 'Blue']),
      );
      expect(output.metadata?['answer'], equals('Blue'));
    });

    test('execute handles single question without options', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx(answer: '42');

      final output = await tool.execute({'question': 'How old are you?'}, ctx);

      expect(output.output, equals('42'));
      expect(output.metadata?['question'], equals('How old are you?'));
      expect(output.metadata?['answer'], equals('42'));
    });

    test('execute handles multiple flag in legacy format', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx(answer: 'A');

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
      expect(output.output, equals('A'));
    });

    test(
      'execute validates required question field in legacy format',
      () async {
        final tool = createQuestionTool();
        final ctx = _mockCtx();

        final output = await tool.execute({
          'questions': [
            {
              'options': ['A', 'B'],
            },
          ],
        }, ctx);

        expect(output.metadata?['error'], isTrue);
      },
    );

    test('execute handles empty questions list', () async {
      final tool = createQuestionTool();
      final ctx = _mockCtx();

      final output = await tool.execute({'questions': []}, ctx);

      expect(output.metadata?['error'], isTrue);
    });
  });
}
