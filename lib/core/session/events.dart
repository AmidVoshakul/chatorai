import 'package:chatorai/core/permission/ruleset.dart';

import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'package:chatorai/features/chat/data/models/chat/todo_part.dart';
import 'session_id.dart';

sealed class SessionEvent {
  final SessionID sessionId;
  final DateTime timestamp;
  final int sequence;

  const SessionEvent({
    required this.sessionId,
    required this.timestamp,
    this.sequence = 0,
  });
}

class SessionCreated extends SessionEvent {
  final SessionID? parentId;
  final String title;
  final String agent;
  final String? modelRef;
  final PermissionRuleset? permission;

  const SessionCreated({
    required super.sessionId,
    this.parentId,
    this.title = '',
    this.agent = 'general',
    this.modelRef,
    this.permission,
    required super.timestamp,
    super.sequence,
  });
}

class SessionArchived extends SessionEvent {
  const SessionArchived({
    required super.sessionId,
    required super.timestamp,
    super.sequence,
  });
}

class SessionAgentSwitched extends SessionEvent {
  final String agent;

  const SessionAgentSwitched({
    required super.sessionId,
    required this.agent,
    required super.timestamp,
    super.sequence,
  });
}

class SessionModelSwitched extends SessionEvent {
  final String modelRef;

  const SessionModelSwitched({
    required super.sessionId,
    required this.modelRef,
    required super.timestamp,
    super.sequence,
  });
}

class MessageAdded extends SessionEvent {
  final String messageId;
  final String role;
  final String content;

  const MessageAdded({
    required super.sessionId,
    required this.messageId,
    required this.role,
    required this.content,
    required super.timestamp,
    super.sequence,
  });
}

class TextStarted extends SessionEvent {
  final String messageId;
  final String? partId;

  const TextStarted({
    required super.sessionId,
    required this.messageId,
    this.partId,
    required super.timestamp,
    super.sequence,
  });
}

class TextDelta extends SessionEvent {
  final String messageId;
  final String delta;
  final String? partId;

  const TextDelta({
    required super.sessionId,
    required this.messageId,
    required this.delta,
    this.partId,
    required super.timestamp,
    super.sequence,
  });
}

class TextEnded extends SessionEvent {
  final String messageId;
  final String fullText;
  final String? model;
  final String? partId;

  const TextEnded({
    required super.sessionId,
    required this.messageId,
    required this.fullText,
    this.model,
    this.partId,
    required super.timestamp,
    super.sequence,
  });
}

class ReasoningStarted extends SessionEvent {
  final String messageId;
  final String? partId;

  const ReasoningStarted({
    required super.sessionId,
    required this.messageId,
    this.partId,
    required super.timestamp,
    super.sequence,
  });
}

class ReasoningDelta extends SessionEvent {
  final String messageId;
  final String delta;
  final String? partId;

  const ReasoningDelta({
    required super.sessionId,
    required this.messageId,
    required this.delta,
    this.partId,
    required super.timestamp,
    super.sequence,
  });
}

class ReasoningEnded extends SessionEvent {
  final String messageId;
  final String fullReasoning;
  final String? partId;

  const ReasoningEnded({
    required super.sessionId,
    required this.messageId,
    required this.fullReasoning,
    this.partId,
    required super.timestamp,
    super.sequence,
  });
}

class ToolInputStarted extends SessionEvent {
  final String toolCallId;

  const ToolInputStarted({
    required super.sessionId,
    required this.toolCallId,
    required super.timestamp,
    super.sequence,
  });
}

class ToolInputDelta extends SessionEvent {
  final String toolCallId;
  final String delta;

  const ToolInputDelta({
    required super.sessionId,
    required this.toolCallId,
    required this.delta,
    required super.timestamp,
    super.sequence,
  });
}

class ToolInputEnded extends SessionEvent {
  final String toolCallId;
  final String fullInput;

  const ToolInputEnded({
    required super.sessionId,
    required this.toolCallId,
    required this.fullInput,
    required super.timestamp,
    super.sequence,
  });
}

class ToolCalled extends SessionEvent {
  final String toolCallId;
  final String toolName;
  final Map<String, dynamic> input;
  final String? partId;

  const ToolCalled({
    required super.sessionId,
    required this.toolCallId,
    required this.toolName,
    required this.input,
    this.partId,
    required super.timestamp,
    super.sequence,
  });
}

class ToolSuccess extends SessionEvent {
  final String toolCallId;
  final String outputText;
  final String? partId;
  final int durationMs;
  final Map<String, dynamic>? input;

  const ToolSuccess({
    required super.sessionId,
    required this.toolCallId,
    required this.outputText,
    this.partId,
    this.durationMs = 0,
    this.input,
    required super.timestamp,
    super.sequence,
  });
}

class ToolFailed extends SessionEvent {
  final String toolCallId;
  final String error;
  final String? partId;
  final int durationMs;
  final Map<String, dynamic>? input;

  const ToolFailed({
    required super.sessionId,
    required this.toolCallId,
    required this.error,
    this.partId,
    this.durationMs = 0,
    this.input,
    required super.timestamp,
    super.sequence,
  });
}

class StepStarted extends SessionEvent {
  final int stepNumber;

  const StepStarted({
    required super.sessionId,
    required this.stepNumber,
    required super.timestamp,
    super.sequence,
  });
}

class StepEnded extends SessionEvent {
  final int stepNumber;
  final int tokensInput;
  final int tokensOutput;
  final int tokensReasoning;
  final int tokensCacheRead;
  final int tokensCacheWrite;

  const StepEnded({
    required super.sessionId,
    required this.stepNumber,
    required this.tokensInput,
    required this.tokensOutput,
    required this.tokensReasoning,
    this.tokensCacheRead = 0,
    this.tokensCacheWrite = 0,
    required super.timestamp,
    super.sequence,
  });
}

class StepFailed extends SessionEvent {
  final int stepNumber;
  final String error;

  const StepFailed({
    required super.sessionId,
    required this.stepNumber,
    required this.error,
    required super.timestamp,
    super.sequence,
  });
}

class CompactionStarted extends SessionEvent {
  const CompactionStarted({
    required super.sessionId,
    required super.timestamp,
    super.sequence,
  });
}

class CompactionEnded extends SessionEvent {
  final String summary;

  const CompactionEnded({
    required super.sessionId,
    required this.summary,
    required super.timestamp,
    super.sequence,
  });
}

class ChildSessionCreated extends SessionEvent {
  final SessionID parentSessionId;
  final SessionID childSessionId;
  final String title;
  final String agent;
  final String? modelRef;

  const ChildSessionCreated({
    required super.sessionId,
    required this.parentSessionId,
    required this.childSessionId,
    required this.title,
    this.agent = 'general',
    this.modelRef,
    required super.timestamp,
    super.sequence,
  });
}

class TaskStarted extends SessionEvent {
  final String taskId;
  final String description;

  const TaskStarted({
    required super.sessionId,
    required this.taskId,
    required this.description,
    required super.timestamp,
    super.sequence,
  });
}

class TaskCompleted extends SessionEvent {
  final String taskId;
  final String output;

  const TaskCompleted({
    required super.sessionId,
    required this.taskId,
    required this.output,
    required super.timestamp,
    super.sequence,
  });
}

class TaskPartStarted extends SessionEvent {
  final String partId;
  final String description;
  final String agent;
  final String? taskSessionId;

  const TaskPartStarted({
    required super.sessionId,
    required this.partId,
    required this.description,
    required this.agent,
    this.taskSessionId,
    required super.timestamp,
    super.sequence,
  });
}

class TaskPartCompleted extends SessionEvent {
  final String partId;

  const TaskPartCompleted({
    required super.sessionId,
    required this.partId,
    required super.timestamp,
    super.sequence,
  });
}

class TaskPartError extends SessionEvent {
  final String partId;
  final String error;

  const TaskPartError({
    required super.sessionId,
    required this.partId,
    required this.error,
    required super.timestamp,
    super.sequence,
  });
}

class QuestionPartStarted extends SessionEvent {
  final String partId;
  final String questionText;
  final List<QuestionOption> options;
  final bool multiple;

  const QuestionPartStarted({
    required super.sessionId,
    required this.partId,
    required this.questionText,
    this.options = const [],
    this.multiple = false,
    required super.timestamp,
    super.sequence,
  });
}

class QuestionPartAnswered extends SessionEvent {
  final String partId;
  final String answer;

  const QuestionPartAnswered({
    required super.sessionId,
    required this.partId,
    required this.answer,
    required super.timestamp,
    super.sequence,
  });
}

class TodoPartStarted extends SessionEvent {
  final String partId;
  final List<TodoItem> todos;

  const TodoPartStarted({
    required super.sessionId,
    required this.partId,
    required this.todos,
    required super.timestamp,
    super.sequence,
  });
}

class TodoPartCompleted extends SessionEvent {
  final String partId;

  const TodoPartCompleted({
    required super.sessionId,
    required this.partId,
    required super.timestamp,
    super.sequence,
  });
}

/// Returns `true` for ephemeral delta events that should be skipped during
/// durable event store replay. Deltas are live-only streaming fragments;
/// only their corresponding `*Ended` events carry the final value.
bool isDeltaEvent(SessionEvent event) => switch (event) {
  TextDelta _ => true,
  ReasoningDelta _ => true,
  ToolInputDelta _ => true,
  _ => false,
};
