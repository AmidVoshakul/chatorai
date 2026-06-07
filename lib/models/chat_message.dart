import 'chat_models.dart';

// ── Enums ───────────────────────────────────────────────────

enum ToolState { pending, running, completed, error }

enum TaskStatus { running, completed, error }

enum TodoStatus { pending, inProgress, completed, cancelled }

// ── Part Types ──────────────────────────────────────────────

sealed class MessagePart {
  const MessagePart();

  Map<String, dynamic> toJson();
}

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
      content: json['content'] as String,
      isStreaming: json['isStreaming'] as bool? ?? false,
    );
  }
}

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

class ToolResultPart extends MessagePart {
  final String toolCallId;
  final String toolName;
  final String? result;
  final String? error;
  final ToolState state;
  final Duration? duration;
  final Map<String, dynamic>? input;
  final bool isStreaming;
  const ToolResultPart({
    required this.toolCallId,
    required this.toolName,
    this.result,
    this.error,
    this.state = ToolState.running,
    this.duration,
    this.input,
    this.isStreaming = false,
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
    );
  }
}

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

class QuestionPart extends MessagePart {
  final String question;
  final List<String> options;
  final String? answer;
  const QuestionPart({
    required this.question,
    this.options = const [],
    this.answer,
  });

  QuestionPart copyWith({
    String? question,
    List<String>? options,
    String? answer,
  }) {
    return QuestionPart(
      question: question ?? this.question,
      options: options ?? this.options,
      answer: answer ?? this.answer,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'question',
    'question': question,
    'options': options,
    'answer': answer,
  };

  factory QuestionPart.fromJson(Map<String, dynamic> json) {
    return QuestionPart(
      question: json['question'] as String,
      options: (json['options'] as List?)?.cast<String>() ?? [],
      answer: json['answer'] as String?,
    );
  }
}

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
  const TodoPart({required this.todos, this.isStreaming = false});

  TodoPart copyWith({List<TodoItem>? todos, bool? isStreaming}) {
    return TodoPart(
      todos: todos ?? this.todos,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'todo',
    'todos': todos.map((t) => t.toJson()).toList(),
    'isStreaming': isStreaming,
  };

  factory TodoPart.fromJson(Map<String, dynamic> json) {
    return TodoPart(
      todos: (json['todos'] as List?)
              ?.map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isStreaming: json['isStreaming'] as bool? ?? false,
    );
  }
}

// ── Message Types ───────────────────────────────────────────

sealed class ChatMessage {
  final String id;
  final DateTime timestamp;
  const ChatMessage({required this.id, required this.timestamp});

  Map<String, dynamic> toJson();
}

class UserMessage extends ChatMessage {
  final String content;
  final List<String> files;
  const UserMessage({
    required super.id,
    required this.content,
    this.files = const [],
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'user',
    'id': id,
    'content': content,
    'files': files,
    'timestamp': timestamp.toIso8601String(),
  };

  factory UserMessage.fromJson(Map<String, dynamic> json) {
    return UserMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      files: (json['files'] as List?)?.cast<String>() ?? [],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class AssistantMessage extends ChatMessage {
  final List<MessagePart> parts;
  final String? model;
  final bool isStreaming;
  final List<String> continuationSuggestions;
  const AssistantMessage({
    required super.id,
    this.parts = const [],
    this.model,
    this.isStreaming = false,
    this.continuationSuggestions = const [],
    required super.timestamp,
  });

  AssistantMessage copyWith({
    List<MessagePart>? parts,
    String? model,
    bool? isStreaming,
    List<String>? continuationSuggestions,
  }) {
    return AssistantMessage(
      id: id,
      timestamp: timestamp,
      parts: parts ?? this.parts,
      model: model ?? this.model,
      isStreaming: isStreaming ?? this.isStreaming,
      continuationSuggestions:
          continuationSuggestions ?? this.continuationSuggestions,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'assistant',
    'id': id,
    'parts': parts.map((p) => p.toJson()).toList(),
    'model': model,
    'isStreaming': isStreaming,
    'continuationSuggestions': continuationSuggestions,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    return AssistantMessage(
      id: json['id'] as String,
      parts: (json['parts'] as List?)
              ?.map((e) => _partFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      model: json['model'] as String?,
      isStreaming: json['isStreaming'] as bool? ?? false,
      continuationSuggestions:
          (json['continuationSuggestions'] as List?)?.cast<String>() ?? [],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class SystemMessage extends ChatMessage {
  final String content;
  const SystemMessage({
    required super.id,
    required this.content,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'system',
    'id': id,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SystemMessage.fromJson(Map<String, dynamic> json) {
    return SystemMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ErrorMessage extends ChatMessage {
  final String content;
  final String? code;
  final String? type;
  const ErrorMessage({
    required super.id,
    required this.content,
    this.code,
    this.type,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'error',
    'id': id,
    'content': content,
    'code': code,
    'errorType': type,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      code: json['code'] as String?,
      type: json['errorType'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

MessagePart _partFromJson(Map<String, dynamic> json) {
  return switch (json['type'] as String) {
    'text' => TextPart.fromJson(json),
    'reasoning' => ReasoningPart.fromJson(json),
    'tool_call' => ToolCallPart.fromJson(json),
    'tool_result' => ToolResultPart.fromJson(json),
    'task' => TaskPart.fromJson(json),
    'question' => QuestionPart.fromJson(json),
    'todo' => TodoPart.fromJson(json),
    _ => throw ArgumentError('Unknown part type: ${json['type']}'),
  };
}

// ── Conversion from legacy Message ─────────────────────────────────────────

ChatMessage messageToChatMessage(Message message) {
  final id = message.id;
  final timestamp = message.timestamp;

  if (message.isError == true) {
    return ErrorMessage(
      id: id,
      content: message.content,
      code: null,
      type: null,
      timestamp: timestamp,
    );
  }

  switch (message.role.toString().split('.').last) {
    case 'user':
      final imageData = message.imageData;
      final files = <String>[];
      if (imageData != null && imageData.isNotEmpty) {
        files.add(
          imageData.length > 50
              ? '${imageData.substring(0, 47)}...'
              : imageData,
        );
      }
      return UserMessage(
        id: id,
        content: message.content,
        files: files,
        timestamp: timestamp,
      );

    case 'assistant':
      final content = message.content;
      final reasoning = message.reasoning;

      final parts = <MessagePart>[];
      if (reasoning != null && reasoning.isNotEmpty) {
        parts.add(ReasoningPart(content: reasoning));
      }
      if (content.isNotEmpty) {
        parts.add(TextPart(content: content));
      }

      return AssistantMessage(
        id: id,
        parts: parts,
        model: message.model,
        timestamp: timestamp,
      );

    case 'system':
      return SystemMessage(
        id: id,
        content: message.content,
        timestamp: timestamp,
      );

    default:
      return ErrorMessage(
        id: id,
        content: message.content,
        code: 'UNKNOWN_ROLE',
        type: message.role.toString(),
        timestamp: timestamp,
      );
  }
}
