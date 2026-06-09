import 'message_part.dart';

// ── TaskPart ─────────────────────────────────────────────────

enum TaskStatus { running, completed, error }

class TaskPart extends MessagePart {
  final String description;
  final String agent;
  final TaskStatus status;
  final int subtaskCount;
  final int completedCount;
  const TaskPart({
    required this.description,
    required this.agent,
    this.status = TaskStatus.running,
    this.subtaskCount = 0,
    this.completedCount = 0,
  });

  TaskPart copyWith({
    String? description,
    String? agent,
    TaskStatus? status,
    int? subtaskCount,
    int? completedCount,
  }) {
    return TaskPart(
      description: description ?? this.description,
      agent: agent ?? this.agent,
      status: status ?? this.status,
      subtaskCount: subtaskCount ?? this.subtaskCount,
      completedCount: completedCount ?? this.completedCount,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'task',
    'description': description,
    'agent': agent,
    'status': status.name,
    'subtaskCount': subtaskCount,
    'completedCount': completedCount,
  };

  factory TaskPart.fromJson(Map<String, dynamic> json) {
    return TaskPart(
      description: json['description'] as String,
      agent: json['agent'] as String,
      status: (json['status'] as String?) != null
          ? TaskStatus.values.byName(json['status'] as String)
          : TaskStatus.running,
      subtaskCount: json['subtaskCount'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
    );
  }
}
