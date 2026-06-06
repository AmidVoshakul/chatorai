// ── Part Types ──────────────────────────────────────────────

enum ToolState { pending, running, completed, error }

enum TaskStatus { running, completed, error }

sealed class MessagePart {
  const MessagePart();
}

class TextPart extends MessagePart {
  final String content;
  final bool isStreaming;
  const TextPart({required this.content, this.isStreaming = false});
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
}

class ToolResultPart extends MessagePart {
  final String toolCallId;
  final String toolName;
  final String? result;
  final String? error;
  final ToolState state;
  final Duration? duration;
  final Map<String, dynamic>? input;
  const ToolResultPart({
    required this.toolCallId,
    required this.toolName,
    this.result,
    this.error,
    this.state = ToolState.running,
    this.duration,
    this.input,
  });
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
}

// ── Message Types ───────────────────────────────────────────

sealed class ChatMessage {
  final String id;
  final DateTime timestamp;
  const ChatMessage({required this.id, required this.timestamp});
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
}

class AssistantMessage extends ChatMessage {
  final List<MessagePart> parts;
  final String? model;
  final bool isStreaming;
  const AssistantMessage({
    required super.id,
    this.parts = const [],
    this.model,
    this.isStreaming = false,
    required super.timestamp,
  });

  AssistantMessage copyWith({
    List<MessagePart>? parts,
    String? model,
    bool? isStreaming,
  }) {
    return AssistantMessage(
      id: id,
      timestamp: timestamp,
      parts: parts ?? this.parts,
      model: model ?? this.model,
      isStreaming: isStreaming ?? this.isStreaming,
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
}
