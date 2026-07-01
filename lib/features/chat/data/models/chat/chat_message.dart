import 'message_part.dart';
import 'text_part.dart';
import 'reasoning_part.dart';
import 'tool_result_part.dart';
import 'task_part.dart';
import 'question_part.dart';
import 'todo_part.dart';

export 'message_part.dart';
export 'text_part.dart';
export 'reasoning_part.dart';
export 'tool_result_part.dart';
export 'task_part.dart';
export 'question_part.dart';
export 'todo_part.dart';

// ── Part deserialization helper ──────────────────────────────

MessagePart partFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;

  // Normalize tool_call → tool_result for unified handling
  // ToolCallPart is deprecated; use ToolResultPart with state field
  final normalizedType = type == 'tool_call' ? 'tool_result' : type;

  return switch (normalizedType) {
    'text' => TextPart.fromJson(json),
    'reasoning' => ReasoningPart.fromJson(json),
    'tool_result' => ToolResultPart.fromJson(json),
    'task' => TaskPart.fromJson(json),
    'question' => QuestionPart.fromJson(json),
    'todo' => TodoPart.fromJson(json),
    _ => throw ArgumentError('Unknown part type: $type'),
  };
}

// ── ChatMessage sealed hierarchy ─────────────────────────────

// Note: Using `abstract` instead of `sealed` to allow subclasses
// across multiple files (split architecture).
// Existing switch-by-type patterns remain exhaustive.
abstract class ChatMessage {
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
  final int? tokensInput;
  final int? tokensOutput;
  final int? tokensReasoning;
  final int? contextLength;

  const AssistantMessage({
    required super.id,
    this.parts = const [],
    this.model,
    this.isStreaming = false,
    this.continuationSuggestions = const [],
    this.tokensInput,
    this.tokensOutput,
    this.tokensReasoning,
    required super.timestamp,
    this.contextLength,
  });

  AssistantMessage copyWith({
    List<MessagePart>? parts,
    String? model,
    bool? isStreaming,
    List<String>? continuationSuggestions,
    int? tokensInput,
    int? tokensOutput,
    int? tokensReasoning,
    int? contextLength,
  }) {
    return AssistantMessage(
      id: id,
      timestamp: timestamp,
      parts: parts ?? this.parts,
      model: model ?? this.model,
      isStreaming: isStreaming ?? this.isStreaming,
      continuationSuggestions:
          continuationSuggestions ?? this.continuationSuggestions,
      tokensInput: tokensInput ?? this.tokensInput,
      tokensOutput: tokensOutput ?? this.tokensOutput,
      tokensReasoning: tokensReasoning ?? this.tokensReasoning,
      contextLength: contextLength ?? this.contextLength,
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
    'tokensInput': tokensInput,
    'tokensOutput': tokensOutput,
    'tokensReasoning': tokensReasoning,
    'contextLength': contextLength,
  };

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    return AssistantMessage(
      id: json['id'] as String,
      parts:
          (json['parts'] as List?)
              ?.map((e) => partFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      model: json['model'] as String?,
      isStreaming: json['isStreaming'] as bool? ?? false,
      continuationSuggestions:
          (json['continuationSuggestions'] as List?)?.cast<String>() ?? [],
      timestamp: DateTime.parse(json['timestamp'] as String),
      tokensInput: json['tokensInput'] as int?,
      tokensOutput: json['tokensOutput'] as int?,
      tokensReasoning: json['tokensReasoning'] as int?,
      contextLength: json['contextLength'] as int?,
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
