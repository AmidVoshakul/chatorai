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
