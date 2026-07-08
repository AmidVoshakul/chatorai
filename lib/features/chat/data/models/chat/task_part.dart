import 'message_part.dart';

// ── TaskPart ─────────────────────────────────────────────────

enum TaskStatus { running, completed, error }

class TaskPart extends MessagePart {
  final String description;
  final String agent;
  final TaskStatus status;
  final String? sessionId;
  final String? error;
  final int? retryAttempt;
  final String? currentTool;
  final String? currentToolTitle;
  final int toolCallsCount;
  final int? durationMs;
  final DateTime? startedAt;

  const TaskPart({
    required this.description,
    required this.agent,
    this.status = TaskStatus.running,
    this.sessionId,
    this.error,
    this.retryAttempt,
    this.currentTool,
    this.currentToolTitle,
    this.toolCallsCount = 0,
    this.durationMs,
    this.startedAt,
    super.synthetic,
  });

  TaskPart copyWith({
    String? description,
    String? agent,
    TaskStatus? status,
    String? sessionId,
    String? error,
    int? retryAttempt,
    String? currentTool,
    String? currentToolTitle,
    int? toolCallsCount,
    int? durationMs,
    DateTime? startedAt,
    bool? synthetic,
  }) {
    return TaskPart(
      description: description ?? this.description,
      agent: agent ?? this.agent,
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      error: error ?? this.error,
      retryAttempt: retryAttempt ?? this.retryAttempt,
      currentTool: currentTool ?? this.currentTool,
      currentToolTitle: currentToolTitle ?? this.currentToolTitle,
      toolCallsCount: toolCallsCount ?? this.toolCallsCount,
      durationMs: durationMs ?? this.durationMs,
      startedAt: startedAt ?? this.startedAt,
      synthetic: synthetic ?? this.synthetic,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'task',
    'description': description,
    'agent': agent,
    'status': status.name,
    'synthetic': synthetic,
    if (sessionId != null) 'sessionId': sessionId,
    if (error != null) 'error': error,
    if (retryAttempt != null) 'retryAttempt': retryAttempt,
    if (currentTool != null) 'currentTool': currentTool,
    if (currentToolTitle != null) 'currentToolTitle': currentToolTitle,
    'toolCallsCount': toolCallsCount,
    if (durationMs != null) 'durationMs': durationMs,
    if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
  };

  factory TaskPart.fromJson(Map<String, dynamic> json) {
    return TaskPart(
      description: json['description'] as String,
      agent: json['agent'] as String,
      status: (json['status'] as String?) != null
          ? TaskStatus.values.byName(json['status'] as String)
          : TaskStatus.running,
      sessionId: json['sessionId'] as String?,
      error: json['error'] as String?,
      retryAttempt: json['retryAttempt'] as int?,
      currentTool: json['currentTool'] as String?,
      currentToolTitle: json['currentToolTitle'] as String?,
      toolCallsCount: json['toolCallsCount'] as int? ?? 0,
      durationMs: json['durationMs'] as int?,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      synthetic: json['synthetic'] as bool? ?? false,
    );
  }
}
