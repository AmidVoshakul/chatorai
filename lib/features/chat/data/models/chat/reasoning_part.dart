import 'message_part.dart';

// ── ReasoningPart ────────────────────────────────────────────

class ReasoningPart extends MessagePart {
  final String content;
  final String? title;
  final bool isStreaming;
  final DateTime? startedAt;
  const ReasoningPart({
    required this.content,
    this.title,
    this.isStreaming = false,
    this.startedAt,
  });

  ReasoningPart copyWith({
    String? content,
    String? title,
    bool? isStreaming,
    DateTime? startedAt,
  }) {
    return ReasoningPart(
      content: content ?? this.content,
      title: title ?? this.title,
      isStreaming: isStreaming ?? this.isStreaming,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'reasoning',
    'content': content,
    'title': title,
    'isStreaming': isStreaming,
    if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
  };

  factory ReasoningPart.fromJson(Map<String, dynamic> json) {
    return ReasoningPart(
      content: json['content'] as String,
      title: json['title'] as String?,
      isStreaming: json['isStreaming'] as bool? ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
    );
  }
}
