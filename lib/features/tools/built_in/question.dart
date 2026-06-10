import 'package:chatorai/features/tools/data/models/tool.dart';

ToolDef createQuestionTool() {
  return ToolDef(
    id: 'question',
    description:
        'Ask the user a question and wait for their response. Use when you need clarification, confirmation, or a decision from the user.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'questions': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'question': {
                'type': 'string',
                'description': 'The question text',
              },
              'options': {
                'type': 'array',
                'items': {'type': 'string'},
                'description':
                    'Optional list of predefined options for the user to choose from',
              },
              'multiple': {
                'type': 'boolean',
                'description': 'Allow selecting multiple options',
              },
            },
            'required': ['question'],
          },
          'description': 'List of questions to ask the user',
        },
      },
      'required': ['questions'],
    },
    execute: (input, ctx) async {
      final questions = input['questions'] as List?;
      if (questions == null || questions.isEmpty) {
        return ToolOutput(
          'Error: questions is required and must be a non-empty list',
          metadata: {'error': true},
        );
      }

      // Validate each question has required 'question' field
      for (final q in questions) {
        if (q is! Map<String, dynamic>) {
          return ToolOutput(
            'Error: each question must be an object',
            metadata: {'error': true},
          );
        }
        final questionText = q['question'] as String?;
        if (questionText == null || questionText.isEmpty) {
          return ToolOutput(
            'Error: each question must have a non-empty "question" field',
            metadata: {'error': true},
          );
        }
      }

      // Build prompt for user
      final prompt = _buildPrompt(questions);

      // Call ctx.ask with the required pattern
      await ctx.ask(
        permission: 'question',
        patterns: ['question:count=${questions.length}'],
        metadata: {'questions': questions, 'awaiting_response': true},
      );

      return ToolOutput(
        prompt,
        metadata: {'questions': questions, 'awaiting_response': true},
      );
    },
  );
}

String _buildPrompt(List<dynamic> questions) {
  final buffer = StringBuffer();
  for (int i = 0; i < questions.length; i++) {
    final q = questions[i] as Map<String, dynamic>;
    final questionText = q['question'] as String;
    final options = (q['options'] as List?)?.cast<String>();
    final multiple = q['multiple'] as bool? ?? false;

    buffer.writeln('${i + 1}. $questionText');
    if (options != null && options.isNotEmpty) {
      buffer.write('   Options: ${options.join(', ')}');
      if (multiple) {
        buffer.write(' (multiple selection allowed)');
      }
      buffer.writeln();
    } else {
      buffer.writeln();
    }
  }
  return buffer.toString().trim();
}
