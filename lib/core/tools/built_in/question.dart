import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'package:chatorai/shared/utils/logger.dart';

/// Tracks recently asked questions to prevent repeat prompts within cooldown window.
final Map<String, DateTime> _recentlyAsked = {};

/// Cooldown duration before the same question can be asked again.
const _questionCooldown = Duration(minutes: 5);

/// Normalizes question text for deduplication (lowercase, trimmed).
String _normalizeQuestion(String q) => q.trim().toLowerCase();

/// Checks if a similar question was asked recently; if so, logs and returns true.
bool _wasAskedRecently(String question) {
  final key = _normalizeQuestion(question);
  final lastAsked = _recentlyAsked[key];
  if (lastAsked != null &&
      DateTime.now().difference(lastAsked) < _questionCooldown) {
    LogTags.permission.logInfo(
      'QuestionTool: skipping repeat question within cooldown: "$question"',
    );
    return true;
  }
  _recentlyAsked[key] = DateTime.now();
  return false;
}

ToolDef createQuestionTool() {
  return ToolDef(
    id: 'question',
    description:
        'Ask the user a question and wait for their response. '
        'Use ONLY for: (1) blocking decisions that affect the current task, '
        '(2) confirming before irreversible actions, '
        '(3) disambiguation when multiple interpretations exist. '
        'DO NOT use for: small talk, PII collection (name/age/email) unless '
        'explicitly needed, or conversation warmup. '
        'Call ONCE per decision point — if a similar question was asked recently '
        'in this session, return a hint instead of asking again. '
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
          'items': {
            'oneOf': [
              {'type': 'string'},
              {
                'type': 'object',
                'properties': {
                  'label': {'type': 'string'},
                  'description': {'type': 'string'},
                },
                'required': ['label'],
              },
            ],
          },
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
    execute: (input, ctx) async {
      String question;
      List<QuestionOption> options;
      bool multiple;

      // Support both new format (single question) and legacy format (questions array)
      final questionsLegacy = input['questions'] as List?;
      if (questionsLegacy != null && questionsLegacy.isNotEmpty) {
        final first = questionsLegacy.first as Map<String, dynamic>;
        question = first['question'] as String? ?? '';
        options =
            (first['options'] as List?)
                ?.map(QuestionOption.fromJson)
                .toList() ??
            const [];
        multiple = first['multiple'] as bool? ?? false;
      } else {
        question = input['question'] as String? ?? '';
        options =
            (input['options'] as List?)
                ?.map(QuestionOption.fromJson)
                .toList() ??
            const [];
        multiple = input['multiple'] as bool? ?? false;
      }

      if (question.isEmpty) {
        return ToolOutput(
          'Error: question is required and must be non-empty',
          metadata: {'error': true},
        );
      }

      // Skip if a similar question was asked within the cooldown window.
      if (_wasAskedRecently(question)) {
        return ToolOutput(
          'Skipped: similar question was asked recently. '
          'Consider proceeding with one of the previous options or clarifying your intent.',
          metadata: {'skipped': true, 'question': question},
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
