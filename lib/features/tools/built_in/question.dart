import 'package:chatorai/features/tools/data/models/tool.dart';

ToolDef createQuestionTool() {
  return ToolDef(
    id: 'question',
    description:
        'Ask the user a question and wait for their response. Use when you need clarification, confirmation, or a decision from the user.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'question': {
          'type': 'string',
          'description': 'The question to ask the user',
        },
        'options': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'Optional list of predefined options for the user to choose from',
        },
        'multiSelect': {
          'type': 'boolean',
          'description': 'Allow selecting multiple options (default: false)',
        },
      },
      'required': ['question'],
    },
    execute: (input, ctx) async {
      final question = input['question'] as String?;
      final options = (input['options'] as List?)?.cast<String>();
      final multiSelect = input['multiSelect'] as bool? ?? false;

      if (question == null || question.isEmpty) {
        return ToolOutput(
          'Error: question is required',
          metadata: {'error': true},
        );
      }

      await ctx.ask(
        permission: 'question',
        patterns: [question],
        metadata: {
          'question': question,
          'options': options ?? [],
          'multiSelect': multiSelect,
          'awaiting_response': true,
        },
      );

      return ToolOutput(
        question,
        metadata: {
          'question': question,
          'options': options ?? [],
          'multiSelect': multiSelect,
          'awaiting_response': true,
        },
      );
    },
  );
}
