import 'message_part.dart';

// ── ReasoningPart ────────────────────────────────────────────

class ReasoningPart extends MessagePart {
  final String content;
  final String? title;
  final bool isStreaming;
  final DateTime? startedAt;
  final int? durationMs;
  final bool? isExpanded;
  const ReasoningPart({
    required this.content,
    this.title,
    this.isStreaming = false,
    this.startedAt,
    this.durationMs,
    this.isExpanded,
  });

  ReasoningPart copyWith({
    String? content,
    String? title,
    bool? isStreaming,
    DateTime? startedAt,
    int? durationMs,
    bool? isExpanded,
  }) {
    return ReasoningPart(
      content: content ?? this.content,
      title: title ?? this.title,
      isStreaming: isStreaming ?? this.isStreaming,
      startedAt: startedAt ?? this.startedAt,
      durationMs: durationMs ?? this.durationMs,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'reasoning',
    'content': content,
    'title': title,
    'isStreaming': isStreaming,
    if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
    if (durationMs != null) 'durationMs': durationMs,
    if (isExpanded != null) 'is_expanded': isExpanded,
  };

  factory ReasoningPart.fromJson(Map<String, dynamic> json) {
    return ReasoningPart(
      content: json['content'] as String,
      title: json['title'] as String?,
      isStreaming: json['isStreaming'] as bool? ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      durationMs: json['durationMs'] as int?,
      isExpanded: json['is_expanded'] as bool?,
    );
  }
}
