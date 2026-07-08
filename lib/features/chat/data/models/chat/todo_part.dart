import 'message_part.dart';

// ── TodoPart ─────────────────────────────────────────────────

enum TodoStatus { pending, inProgress, completed, cancelled }

class TodoItem {
  final String id;
  final String description;
  final TodoStatus status;
  const TodoItem({
    required this.id,
    required this.description,
    this.status = TodoStatus.pending,
  });

  TodoItem copyWith({String? description, TodoStatus? status}) {
    return TodoItem(
      id: id,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'status': status.name,
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      description: json['description'] as String,
      status: (json['status'] as String?) != null
          ? TodoStatus.values.byName(json['status'] as String)
          : TodoStatus.pending,
    );
  }
}

class TodoPart extends MessagePart {
  final List<TodoItem> todos;
  final bool isStreaming;
  const TodoPart({
    required this.todos,
    this.isStreaming = false,
    super.synthetic,
  });

  TodoPart copyWith({
    List<TodoItem>? todos,
    bool? isStreaming,
    bool? synthetic,
  }) {
    return TodoPart(
      todos: todos ?? this.todos,
      isStreaming: isStreaming ?? this.isStreaming,
      synthetic: synthetic ?? this.synthetic,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'todo',
    'todos': todos.map((t) => t.toJson()).toList(),
    'isStreaming': isStreaming,
    'synthetic': synthetic,
  };

  factory TodoPart.fromJson(Map<String, dynamic> json) {
    return TodoPart(
      todos:
          (json['todos'] as List?)
              ?.map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isStreaming: json['isStreaming'] as bool? ?? false,
      synthetic: json['synthetic'] as bool? ?? false,
    );
  }
}
