import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/logger.dart';

ToolDef createQuestionTool() {
  return ToolDef(
    id: 'question',
    description:
        'Ask the user a question and wait for their response. '
        'Use when you need clarification, confirmation, or a decision from the user. '
        'Provide options for quick selection when possible.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'question': {
          'type': 'string',
          'description': 'The question text to ask the user',
        },
        'options': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'Optional list of predefined options for the user to choose from',
        },
        'multiple': {
          'type': 'boolean',
          'description': 'Allow selecting multiple options (not yet supported)',
        },
      },
      'required': ['question'],
    },
    execute: (input, ctx) async {
      String question;
      List<String> options;
      bool multiple;

      // Support both new format (single question) and legacy format (questions array)
      final questionsLegacy = input['questions'] as List?;
      if (questionsLegacy != null && questionsLegacy.isNotEmpty) {
        final first = questionsLegacy.first as Map<String, dynamic>;
        question = first['question'] as String? ?? '';
        options = (first['options'] as List?)?.cast<String>() ?? [];
        multiple = first['multiple'] as bool? ?? false;
      } else {
        question = input['question'] as String? ?? '';
        options = (input['options'] as List?)?.cast<String>() ?? [];
        multiple = input['multiple'] as bool? ?? false;
      }

      if (question.isEmpty) {
        return ToolOutput(
          'Error: question is required and must be non-empty',
          metadata: {'error': true},
        );
      }

      LogTags.permission.logInfo(
        'QuestionTool: asking user: "$question" options=$options',
      );

      final answer = await ctx.askQuestion(
        question: question,
        options: options,
        multiple: multiple,
      );

      LogTags.permission.logInfo('QuestionTool: user answered: "$answer"');

      return ToolOutput(
        answer,
        metadata: {'question': question, 'options': options, 'answer': answer},
      );
    },
  );
}
