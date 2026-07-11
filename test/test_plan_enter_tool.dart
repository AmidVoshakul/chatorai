import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/plan.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';

void main() {
  group('createPlanEnterTool', () {
    late ToolDef tool;
    late bool switchAgentCalled;
    late String? switchAgentTarget;
    late String? switchAgentMessage;

    setUp(() {
      switchAgentCalled = false;
      switchAgentTarget = null;
      switchAgentMessage = null;
      tool = createPlanEnterTool();
    });

    ToolContext _context({String? answer}) {
      return ToolContext(
        toolCallId: 'call-1',
        sessionId: 'session-1',
        ask:
            ({
              required String permission,
              required List<String> patterns,
              Map<String, dynamic>? metadata,
              List<String>? always,
            }) async {},
        askQuestion:
            ({
              required String question,
              List<QuestionOption> options = const [],
              bool multiple = false,
            }) async {
              return answer ?? 'Yes, switch to plan agent';
            },
        switchAgent: (String agentId, {String? messageText}) {
          switchAgentCalled = true;
          switchAgentTarget = agentId;
          switchAgentMessage = messageText;
        },
      );
    }

    test('creates a tool with id plan_enter', () {
      expect(tool.id, 'plan_enter');
    });

    test('description contains plan agent guidance', () {
      expect(tool.description, contains('plan agent'));
      expect(tool.description, contains('planning'));
    });

    test('inputSchema is empty object', () {
      expect(tool.inputSchema['type'], 'object');
      expect(tool.inputSchema['properties'], {});
      expect(tool.inputSchema['required'], []);
    });

    test('execute returns ToolOutput', () async {
      final result = await tool.execute(
        {},
        _context(answer: 'Yes, switch to plan agent'),
      );
      expect(result, isA<ToolOutput>());
    });

    test('execute calls switchAgent with plan on yes answer', () async {
      final result = await tool.execute(
        {},
        _context(answer: 'Yes, switch to plan agent'),
      );

      expect(switchAgentCalled, isTrue);
      expect(switchAgentTarget, 'plan');
      expect(switchAgentMessage, 'Switched to plan agent. Create a plan.');
      expect(result.metadata?['approved'], isTrue);
    });

    test('execute does not call switchAgent on no answer', () async {
      final result = await tool.execute(
        {},
        _context(answer: 'No, continue with current agent'),
      );

      expect(switchAgentCalled, isFalse);
      expect(result.metadata?['approved'], isFalse);
    });

    test('execute output mentions plan agent for approved', () async {
      final result = await tool.execute({}, _context(answer: 'Yes'));

      expect(result.output, contains('plan agent'));
    });

    test('execute output mentions continuing for rejected', () async {
      final result = await tool.execute({}, _context(answer: 'No'));

      expect(result.output, contains('continue'));
    });

    test('execute metadata includes answer', () async {
      final result = await tool.execute({}, _context(answer: 'YES!'));

      expect(result.metadata?['answer'], 'YES!');
      expect(result.metadata?['approved'], isTrue);
    });

    test('accepts empty input without validation errors', () async {
      final result = await tool.execute({}, _context(answer: 'Yes'));
      expect(result, isNotNull);
    });

    test('tool has formatValidationError callback', () {
      expect(tool.formatValidationError, isNotNull);
      expect(tool.formatValidationError, isA<Function>());
    });

    test('formatValidationError returns formatted message', () {
      final errors = [
        SchemaValidationError(path: r'$.param', message: 'unknown parameter'),
      ];

      final formatted = tool.formatValidationError?.call({}, errors);
      expect(formatted, contains('unknown parameter'));
      expect(formatted, contains('plan_enter'));
    });

    test('schema requires no properties', () {
      expect(tool.inputSchema['required'], []);
      expect(tool.inputSchema['properties'], {});
    });

    test('approved is true for case-insensitive yes answers', () async {
      final result = await tool.execute({}, _context(answer: 'YES'));
      expect(result.metadata?['approved'], isTrue);
      expect(switchAgentCalled, isTrue);
    });

    test('approved is false for no-answers not starting with yes', () async {
      final result = await tool.execute({}, _context(answer: 'Nope'));
      expect(result.metadata?['approved'], isFalse);
      expect(switchAgentCalled, isFalse);
    });
  });
}
