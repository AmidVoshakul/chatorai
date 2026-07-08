import 'message_part.dart';

// ── TextPart ─────────────────────────────────────────────────

class TextPart extends MessagePart {
  final String content;
  final bool isStreaming;
  const TextPart({
    required this.content,
    this.isStreaming = false,
    super.synthetic,
  });

  TextPart copyWith({String? content, bool? isStreaming, bool? synthetic}) {
    return TextPart(
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
      synthetic: synthetic ?? this.synthetic,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'content': content,
    'isStreaming': isStreaming,
    'synthetic': synthetic,
  };

  factory TextPart.fromJson(Map<String, dynamic> json) {
    return TextPart(
      content: json['content'] as String? ?? '',
      isStreaming: json['isStreaming'] as bool? ?? false,
      synthetic: json['synthetic'] as bool? ?? false,
    );
  }
}
