import 'package:chatorai/core/chat/chat/question_option.dart'
    show QuestionOption;
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/invalid.dart';

ToolDef _tool() => createInvalidTool();

ToolContext _ctx() {
  return ToolContext(
    toolCallId: 'test-invalid',
    sessionId: 'ses_test',
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
  );
}

void main() {
  group('InvalidTool', () {
    test('returns formatted message with error text', () async {
      final result = await _tool().execute({
        'tool': 'read',
        'error': 'missing file_path',
      }, _ctx());
      expect(
        result.output,
        'The arguments provided to the tool are invalid: missing file_path',
      );
    });

    test('returns title "Invalid Tool"', () async {
      final result = await _tool().execute({
        'tool': 'write',
        'error': 'path must be absolute',
      }, _ctx());
      expect(result.title, 'Invalid Tool');
    });

    test('handles empty error string', () async {
      final result = await _tool().execute({
        'tool': 'read',
        'error': '',
      }, _ctx());
      expect(result.output, 'The arguments provided to the tool are invalid: ');
    });

    test('stores tool name in metadata', () async {
      final result = await _tool().execute({
        'tool': 'shell',
        'error': 'command not found',
      }, _ctx());
      expect(result.metadata, isNotNull);
      expect(result.metadata!['tool'], 'shell');
    });

    test('inputSchema requires tool and error fields', () async {
      final schema = _tool().inputSchema;
      final required = schema['required'] as List;
      expect(required, contains('tool'));
      expect(required, contains('error'));
    });

    test('inputSchema defines tool and error as string type', () async {
      final schema = _tool().inputSchema;
      final props = schema['properties'] as Map;
      expect((props['tool'] as Map)['type'], 'string');
      expect((props['error'] as Map)['type'], 'string');
    });
  });
}
