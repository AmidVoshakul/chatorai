import 'session_id.dart';

sealed class MessageRole {
  const MessageRole();
}

class UserRole extends MessageRole {
  const UserRole();
  @override
  String toString() => 'user';
}

class AssistantRole extends MessageRole {
  const AssistantRole();
  @override
  String toString() => 'assistant';
}

class ToolRole extends MessageRole {
  const ToolRole();
  @override
  String toString() => 'tool';
}

class SessionMessage {
  final String id;
  final MessageRole role;
  final String content;
  final int seq;
  final String? model;
  final String? reasoning;
  final String? error;
  final DateTime createdAt;

  const SessionMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.seq,
    this.model,
    this.reasoning,
    this.error,
    required this.createdAt,
  });

  SessionMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    int? seq,
    String? model,
    String? reasoning,
    String? error,
    DateTime? createdAt,
  }) {
    return SessionMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      seq: seq ?? this.seq,
      model: model ?? this.model,
      reasoning: reasoning ?? this.reasoning,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionMessage &&
          id == other.id &&
          role.runtimeType == other.role.runtimeType &&
          content == other.content &&
          seq == other.seq &&
          model == other.model &&
          reasoning == other.reasoning &&
          error == other.error &&
          createdAt == other.createdAt);

  @override
  int get hashCode => Object.hash(
    id,
    role.runtimeType,
    content,
    seq,
    model,
    reasoning,
    error,
    createdAt,
  );
}

class ToolResult {
  final String id;
  final String toolName;
  final Map<String, dynamic> input;
  final String outputText;
  final int durationMs;
  final String status;
  final DateTime createdAt;

  const ToolResult({
    required this.id,
    required this.toolName,
    required this.input,
    required this.outputText,
    required this.durationMs,
    required this.status,
    required this.createdAt,
  });
}

class SessionState {
  final SessionID id;
  final SessionID? parentId;
  final String title;
  final String agent;
  final String? modelRef;
  final double cost;
  final int tokensInput;
  final int tokensOutput;
  final int tokensReasoning;
  final List<SessionMessage> messages;
  final List<ToolResult> toolResults;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  const SessionState({
    required this.id,
    this.parentId,
    this.title = '',
    this.agent = 'general',
    this.modelRef,
    this.cost = 0,
    this.tokensInput = 0,
    this.tokensOutput = 0,
    this.tokensReasoning = 0,
    this.messages = const [],
    this.toolResults = const [],
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  SessionState copyWith({
    SessionID? id,
    SessionID? parentId,
    String? title,
    String? agent,
    String? modelRef,
    double? cost,
    int? tokensInput,
    int? tokensOutput,
    int? tokensReasoning,
    List<SessionMessage>? messages,
    List<ToolResult>? toolResults,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    bool clearParentId = false,
    bool clearArchivedAt = false,
  }) {
    return SessionState(
      id: id ?? this.id,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      title: title ?? this.title,
      agent: agent ?? this.agent,
      modelRef: modelRef ?? this.modelRef,
      cost: cost ?? this.cost,
      tokensInput: tokensInput ?? this.tokensInput,
      tokensOutput: tokensOutput ?? this.tokensOutput,
      tokensReasoning: tokensReasoning ?? this.tokensReasoning,
      messages: messages ?? this.messages,
      toolResults: toolResults ?? this.toolResults,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }
}
