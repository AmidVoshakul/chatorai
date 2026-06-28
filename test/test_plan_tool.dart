import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/plan.dart';
import 'package:chatorai/core/tools/json_schema_validator.dart';

ToolDef _planTool() => createPlanExitTool();

ToolContext _contextForQuestion(String answer) {
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
          List<String>? options,
          bool? multiple,
        }) async {
          return answer;
        },
    onMetadata: ({Map<String, dynamic>? metadata, String? title}) {},
  );
}

void main() {
  group('createPlanExitTool', () {
    test('creates a tool with id plan_exit', () {
      final tool = _planTool();
      expect(tool.id, 'plan_exit');
    });

    test('description contains plan phase guidance', () {
      final tool = _planTool();
      expect(tool.description, contains('planning phase'));
      expect(tool.description, contains('build agent'));
    });

    test('inputSchema is empty object', () {
      final tool = _planTool();
      expect(tool.inputSchema['type'], 'object');
      expect(tool.inputSchema['properties'], {});
      expect(tool.inputSchema['required'], []);
    });

    test('execute returns ToolOutput', () async {
      final tool = _planTool();
      final result = await tool.execute(
        {},
        _contextForQuestion('Yes, switch to build agent'),
      );
      expect(result, isA<ToolOutput>());
    });

    test('execute sets approved=true for yes answer', () async {
      final tool = _planTool();
      final result = await tool.execute(
        {},
        _contextForQuestion('Yes, switch to build agent'),
      );

      expect(result.metadata?['approved'], isTrue);
      expect(result.metadata?['answer'], 'Yes, switch to build agent');
    });

    test('execute sets approved=false for no answer', () async {
      final tool = _planTool();
      final result = await tool.execute(
        {},
        _contextForQuestion('No, continue with plan agent'),
      );

      expect(result.metadata?['approved'], isFalse);
    });

    test('execute output mentions building for approved plan', () async {
      final tool = _planTool();
      final result = await tool.execute(
        {},
        _contextForQuestion('Yes, switch to build agent'),
      );

      expect(result.output, contains('build agent'));
    });

    test('execute output mentions continuing for rejected plan', () async {
      final tool = _planTool();
      final result = await tool.execute(
        {},
        _contextForQuestion('No, continue with plan agent'),
      );

      expect(result.output, contains('continue'));
    });

    test('formatValidationError returns formatted message', () {
      final tool = _planTool();
      final errors = [
        SchemaValidationError(path: r'$.param', message: 'unknown parameter'),
      ];

      final formatted = tool.formatValidationError?.call({}, errors);
      expect(formatted, contains('unknown parameter'));
      expect(formatted, contains('plan_exit'));
    });

    test('accepts empty input without validation errors', () async {
      final tool = _planTool();
      final validation = JsonSchemaValidator.validate({}, tool.inputSchema);
      expect(validation.isValid, isTrue);
    });

    test('schema requires no properties', () {
      final tool = _planTool();
      expect(tool.inputSchema['required'], []);
      expect(tool.inputSchema['properties'], {});
    });

    test('no extra required parameters', () async {
      final tool = _planTool();
      final result = await tool.execute(
        {},
        _contextForQuestion('Yes, switch to build agent'),
      );
      expect(result, isNotNull);
    });

    test('tool outputs metadata with answer', () async {
      final tool = _planTool();
      final result = await tool.execute({}, _contextForQuestion('YES!'));

      expect(result.metadata?['answer'], 'YES!');
      expect(result.metadata?['approved'], isTrue);
    });

    test('execute returns ToolOutput for yes response', () async {
      final tool = _planTool();
      final result = await tool.execute({}, _contextForQuestion('YES!'));
      expect(result, isA<ToolOutput>());
    });

    test('execute returns ToolOutput for no response', () async {
      final tool = _planTool();
      final result = await tool.execute({}, _contextForQuestion('No'));
      expect(result, isA<ToolOutput>());
    });

    test('tool has formatValidationError callback', () {
      final tool = _planTool();
      expect(tool.formatValidationError, isNotNull);
      expect(tool.formatValidationError, isA<Function>());
    });
  });
}
