import 'package:chatorai/core/permission/ruleset.dart';

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

  const TextStarted({
    required super.sessionId,
    required this.messageId,
    required super.timestamp,
    super.sequence,
  });
}

class TextDelta extends SessionEvent {
  final String messageId;
  final String delta;

  const TextDelta({
    required super.sessionId,
    required this.messageId,
    required this.delta,
    required super.timestamp,
    super.sequence,
  });
}

class TextEnded extends SessionEvent {
  final String messageId;
  final String fullText;
  final String? model;

  const TextEnded({
    required super.sessionId,
    required this.messageId,
    required this.fullText,
    this.model,
    required super.timestamp,
    super.sequence,
  });
}

class ReasoningStarted extends SessionEvent {
  final String messageId;

  const ReasoningStarted({
    required super.sessionId,
    required this.messageId,
    required super.timestamp,
    super.sequence,
  });
}

class ReasoningDelta extends SessionEvent {
  final String messageId;
  final String delta;

  const ReasoningDelta({
    required super.sessionId,
    required this.messageId,
    required this.delta,
    required super.timestamp,
    super.sequence,
  });
}

class ReasoningEnded extends SessionEvent {
  final String messageId;
  final String fullReasoning;

  const ReasoningEnded({
    required super.sessionId,
    required this.messageId,
    required this.fullReasoning,
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

  const ToolCalled({
    required super.sessionId,
    required this.toolCallId,
    required this.toolName,
    required this.input,
    required super.timestamp,
    super.sequence,
  });
}

class ToolSuccess extends SessionEvent {
  final String toolCallId;
  final String outputText;
  final int durationMs;

  const ToolSuccess({
    required super.sessionId,
    required this.toolCallId,
    required this.outputText,
    required this.durationMs,
    required super.timestamp,
    super.sequence,
  });
}

class ToolFailed extends SessionEvent {
  final String toolCallId;
  final String error;

  const ToolFailed({
    required super.sessionId,
    required this.toolCallId,
    required this.error,
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

  const StepEnded({
    required super.sessionId,
    required this.stepNumber,
    required this.tokensInput,
    required this.tokensOutput,
    required this.tokensReasoning,
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
