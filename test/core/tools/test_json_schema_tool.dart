import 'package:chatorai/core/chat/chat/question_option.dart'
    show QuestionOption;
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/built_in/json_schema.dart';
import 'package:chatorai/core/tools/tool.dart';

void main() {
  group('createJsonSchemaTool', () {
    late ToolDef tool;

    setUp(() {
      tool = createJsonSchemaTool();
    });

    test('returns ToolDef with correct id and description', () {
      expect(tool.id, equals('json_schema'));
      expect(tool.description, contains('Validate JSON data'));
      expect(tool.inputSchema, containsPair('type', 'object'));
    });

    test('inputSchema requires schema and data fields', () {
      final required = tool.inputSchema['required'] as List<dynamic>;
      expect(required, contains('schema'));
      expect(required, contains('data'));
    });

    test('returns success for valid data matching schema', () async {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'age': {'type': 'integer'},
        },
        'required': ['name'],
      };

      final output = await tool.execute(
        {
          'schema': schema,
          'data': {'name': 'Alice', 'age': 30},
        },
        ToolContext(
          toolCallId: 'test',
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
              }) async => '',
        ),
      );

      expect(output.output, contains('Validation passed'));
      expect(output.metadata?['valid'], equals(true));
    });

    test('returns failure for missing required fields', () async {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
        'required': ['name'],
      };

      final output = await tool.execute(
        {
          'schema': schema,
          'data': {'age': 30},
        },
        ToolContext(
          toolCallId: 'test',
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
              }) async => '',
        ),
      );

      expect(output.output, contains('Validation failed'));
      expect(output.metadata?['valid'], equals(false));
      expect((output.metadata?['errors'] as List).length, greaterThan(0));
    });

    test('returns error when schema is null', () async {
      final output = await tool.execute(
        {
          'data': {'key': 'value'},
        },
        ToolContext(
          toolCallId: 'test',
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
              }) async => '',
        ),
      );

      expect(output.output, contains('Error'));
      expect(output.metadata?['error'], equals(true));
    });

    test('returns error when data is null', () async {
      final output = await tool.execute(
        {
          'schema': {'type': 'object'},
        },
        ToolContext(
          toolCallId: 'test',
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
              }) async => '',
        ),
      );

      expect(output.output, contains('Error'));
      expect(output.metadata?['error'], equals(true));
    });

    test('handles nested object validation', () async {
      final schema = {
        'type': 'object',
        'properties': {
          'user': {
            'type': 'object',
            'properties': {
              'email': {'type': 'string', 'format': 'email'},
            },
          },
        },
      };

      final output = await tool.execute(
        {
          'schema': schema,
          'data': {
            'user': {'email': 'invalid-email'},
          },
        },
        ToolContext(
          toolCallId: 'test',
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
              }) async => '',
        ),
      );

      expect(output.output, contains('Validation failed'));
      expect(output.metadata?['valid'], equals(false));
    });

    test('handles array type validation', () async {
      final schema = {
        'type': 'object',
        'properties': {
          'items': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
      };

      final output = await tool.execute(
        {
          'schema': schema,
          'data': {
            'items': ['a', 'b', 'c'],
          },
        },
        ToolContext(
          toolCallId: 'test',
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
              }) async => '',
        ),
      );

      expect(output.output, contains('Validation passed'));
      expect(output.metadata?['valid'], equals(true));
    });

    test('reports specific schemaPath in errors', () async {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'minLength': 5},
        },
        'required': ['name'],
      };

      final output = await tool.execute(
        {
          'schema': schema,
          'data': {'name': 'ab'},
        },
        ToolContext(
          toolCallId: 'test',
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
              }) async => '',
        ),
      );

      expect(output.output, contains('Validation failed'));
      expect(output.output, contains('minLength'));
    });
  });
}
