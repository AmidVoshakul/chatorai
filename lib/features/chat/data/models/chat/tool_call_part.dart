import 'message_part.dart';

// ── ToolCallPart ─────────────────────────────────────────────

class ToolCallPart extends MessagePart {
  final String toolCallId;
  final String toolName;
  final Map<String, dynamic> input;
  final DateTime createdAt;
  const ToolCallPart({
    required this.toolCallId,
    required this.toolName,
    required this.input,
    required this.createdAt,
  });

  ToolCallPart copyWith({
    String? toolCallId,
    String? toolName,
    Map<String, dynamic>? input,
    DateTime? createdAt,
  }) {
    return ToolCallPart(
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      input: input ?? this.input,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'tool_call',
    'toolCallId': toolCallId,
    'toolName': toolName,
    'input': input,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ToolCallPart.fromJson(Map<String, dynamic> json) {
    return ToolCallPart(
      toolCallId: json['toolCallId'] as String,
      toolName: json['toolName'] as String,
      input: (json['input'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
