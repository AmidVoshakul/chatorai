import 'dart:convert';
import 'message_part.dart';
import 'question_option.dart';

// ── QuestionPart ─────────────────────────────────────────────

class QuestionPart extends MessagePart {
  final String question;
  final List<QuestionOption> options;
  final String? answer;
  final bool multiple;

  const QuestionPart({
    required this.question,
    this.options = const [],
    this.answer,
    this.multiple = false,
    super.synthetic,
  });

  /// Returns the parsed answer string.
  /// Handles both plain string answers and JSON-encoded answers
  /// (e.g. `{"output":"Amid","metadata":{...}}`).
  String? get parsedAnswer {
    if (answer == null || answer!.isEmpty) return null;
    // Try to parse as JSON first
    try {
      final decoded = jsonDecode(answer!) as Map<String, dynamic>;
      // If the JSON has an 'output' field at top level, return it
      if (decoded.containsKey('output')) {
        return decoded['output']?.toString();
      }
      // If the JSON has an 'answer' field (from question tool metadata), return it
      if (decoded.containsKey('answer')) {
        return decoded['answer']?.toString();
      }
    } catch (_) {
      // Not JSON, return as plain string
    }
    return answer;
  }

  List<String>? get parsedAnswerList {
    if (answer == null || answer!.isEmpty) return null;
    try {
      final decoded = jsonDecode(answer!) as Map<String, dynamic>;
      final output =
          decoded['output']?.toString() ?? decoded['answer']?.toString();
      if (output == null) return null;
      final list = jsonDecode(output) as List<dynamic>?;
      return list?.cast<String>();
    } catch (_) {}
    return null;
  }

  QuestionPart copyWith({
    String? question,
    List<QuestionOption>? options,
    String? answer,
    bool? multiple,
    bool? synthetic,
  }) {
    return QuestionPart(
      question: question ?? this.question,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      multiple: multiple ?? this.multiple,
      synthetic: synthetic ?? this.synthetic,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'question',
    'question': question,
    'options': options.map((o) => o.toJson()).toList(),
    'multiple': multiple,
    'answer': answer,
    'synthetic': synthetic,
  };

  factory QuestionPart.fromJson(Map<String, dynamic> json) {
    return QuestionPart(
      question: json['question'] as String,
      options:
          (json['options'] as List?)
              ?.map((e) => QuestionOption.fromJson(e))
              .toList() ??
          const [],
      answer: json['answer'] as String?,
      multiple: json['multiple'] as bool? ?? false,
      synthetic: json['synthetic'] as bool? ?? false,
    );
  }
}
