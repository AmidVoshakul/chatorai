import 'dart:convert';
import 'message_part.dart';

// ── QuestionPart ─────────────────────────────────────────────

class QuestionPart extends MessagePart {
  final String question;
  final List<String> options;
  final String? answer;
  const QuestionPart({
    required this.question,
    this.options = const [],
    this.answer,
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

  QuestionPart copyWith({
    String? question,
    List<String>? options,
    String? answer,
  }) {
    return QuestionPart(
      question: question ?? this.question,
      options: options ?? this.options,
      answer: answer ?? this.answer,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'question',
    'question': question,
    'options': options,
    'answer': answer,
  };

  factory QuestionPart.fromJson(Map<String, dynamic> json) {
    return QuestionPart(
      question: json['question'] as String,
      options: (json['options'] as List?)?.cast<String>() ?? [],
      answer: json['answer'] as String?,
    );
  }
}
