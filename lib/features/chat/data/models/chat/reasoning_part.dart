import 'message_part.dart';

// ── ReasoningPart ────────────────────────────────────────────

class ReasoningPart extends MessagePart {
  final String content;
  final String? title;
  final bool isStreaming;
  const ReasoningPart({
    required this.content,
    this.title,
    this.isStreaming = false,
  });

  ReasoningPart copyWith({String? content, String? title, bool? isStreaming}) {
    return ReasoningPart(
      content: content ?? this.content,
      title: title ?? this.title,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'reasoning',
    'content': content,
    'title': title,
    'isStreaming': isStreaming,
  };

  factory ReasoningPart.fromJson(Map<String, dynamic> json) {
    return ReasoningPart(
      content: json['content'] as String,
      title: json['title'] as String?,
      isStreaming: json['isStreaming'] as bool? ?? false,
    );
  }
}
