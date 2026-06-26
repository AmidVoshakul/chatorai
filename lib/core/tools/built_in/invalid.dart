import 'package:chatorai/core/tools/tool.dart';

ToolDef createInvalidTool() {
  return ToolDef(
    id: 'invalid',
    description: 'Do not use',
    inputSchema: {
      'type': 'object',
      'properties': {
        'tool': {
          'type': 'string',
          'description': 'The name of the tool that received invalid arguments',
        },
        'error': {
          'type': 'string',
          'description': 'Description of the validation error',
        },
      },
      'required': ['tool', 'error'],
    },
    execute: (input, ctx) async {
      final toolName = input['tool'] as String? ?? 'unknown';
      final error = input['error'] as String? ?? '';
      return ToolOutput(
        'The arguments provided to the tool are invalid: $error',
        title: 'Invalid Tool',
        metadata: {'tool': toolName},
      );
    },
  );
}
