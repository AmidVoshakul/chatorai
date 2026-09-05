import 'message_part.dart';

// ── ToolResultPart ───────────────────────────────────────────

class ToolResultPart extends MessagePart {
  final String toolCallId;
  final String toolName;
  final String? result;
  final String? error;
  final ToolState state;
  final Duration? duration;
  final Map<String, dynamic>? input;
  final bool isStreaming;
  final Map<String, dynamic>? metadata;
  const ToolResultPart({
    required this.toolCallId,
    required this.toolName,
    this.result,
    this.error,
    this.state = ToolState.running,
    this.duration,
    this.input,
    this.isStreaming = false,
    this.metadata,
    super.synthetic,
  });

  ToolResultPart copyWith({
    String? toolCallId,
    String? toolName,
    String? result,
    String? error,
    ToolState? state,
    Duration? duration,
    Map<String, dynamic>? input,
    bool? isStreaming,
    Map<String, dynamic>? metadata,
    bool? synthetic,
  }) {
    return ToolResultPart(
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      result: result ?? this.result,
      error: error ?? this.error,
      state: state ?? this.state,
      duration: duration ?? this.duration,
      input: input ?? this.input,
      isStreaming: isStreaming ?? this.isStreaming,
      metadata: metadata ?? this.metadata,
      synthetic: synthetic ?? this.synthetic,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'tool_result',
    'toolCallId': toolCallId,
    'toolName': toolName,
    'result': result,
    'error': error,
    'state': state.name,
    'duration': duration?.inMilliseconds,
    'input': input,
    'isStreaming': isStreaming,
    'synthetic': synthetic,
    'metadata': metadata,
  };

  factory ToolResultPart.fromJson(Map<String, dynamic> json) {
    return ToolResultPart(
      toolCallId: json['toolCallId'] as String,
      toolName: json['toolName'] as String,
      result: json['result'] as String?,
      error: json['error'] as String?,
      state: (json['state'] as String?) != null
          ? ToolState.values.byName(json['state'] as String)
          : ToolState.completed,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      input: json['input'] as Map<String, dynamic>?,
      isStreaming: json['isStreaming'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      synthetic: json['synthetic'] as bool? ?? false,
    );
  }
}
