import 'message_part.dart';

// ── TextPart ─────────────────────────────────────────────────

class TextPart extends MessagePart {
  final String content;
  final bool isStreaming;
  const TextPart({required this.content, this.isStreaming = false});

  TextPart copyWith({String? content, bool? isStreaming}) {
    return TextPart(
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'content': content,
    'isStreaming': isStreaming,
  };

  factory TextPart.fromJson(Map<String, dynamic> json) {
    return TextPart(
      content: json['content'] as String? ?? '',
      isStreaming: json['isStreaming'] as bool? ?? false,
    );
  }
}
