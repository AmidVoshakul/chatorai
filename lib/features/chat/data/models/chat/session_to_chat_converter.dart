// ── Converter: SessionState → ChatMessage ─────────────────────────────────────
// Bridges Session Core to Chat UI without legacy Message types.

import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    hide ToolState;
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';

/// Converts [SessionMessage] + [AssistantContent] parts to [ChatMessage].
ChatMessage? sessionMessageToChatMessage(
  SessionMessage sessionMsg,
  List<AssistantContent> parts,
) {
  final id = sessionMsg.id;
  final timestamp = sessionMsg.createdAt;

  switch (sessionMsg.role) {
    case MessageRole.user:
      return UserMessage(
        id: id,
        content: sessionMsg.content,
        timestamp: timestamp,
      );

    case MessageRole.assistant:
    case MessageRole.tool:
      return AssistantMessage(
        id: id,
        parts: parts.map(assistantContentToMessagePart).toList(),
        model: sessionMsg.model,
        timestamp: timestamp,
      );
  }
}

/// Converts [AssistantContent] to legacy [MessagePart] for widget compatibility.
MessagePart assistantContentToMessagePart(AssistantContent content) {
  if (content is AssistantText) {
    return TextPart(content: content.text, isStreaming: content.synthetic);
  }
  if (content is AssistantReasoning) {
    return ReasoningPart(
      content: content.text,
      startedAt: content.started,
      durationMs: content.ended != null
          ? content.ended!.millisecondsSinceEpoch -
                content.started.millisecondsSinceEpoch
          : null,
      isStreaming: content.ended == null,
    );
  }
  if (content is AssistantTool) {
    final state = ToolState.values.byName(content.state.name);
    return ToolResultPart(
      toolCallId: content.callId,
      toolName: content.tool,
      result: content.output,
      error: state == ToolState.error ? content.output : null,
      state: state,
      input: content.input,
    );
  }
  if (content is AssistantFile) {
    return TextPart(content: '[File: ${content.filename}]');
  }
  if (content is AssistantImage) {
    return TextPart(content: '[Image]');
  }
  if (content is AssistantAgent) {
    return TextPart(content: '[Agent: ${content.name}]');
  }
  if (content is AssistantTask) {
    final startedAt = content.startedAt;
    final endedAt = content.endedAt;
    final computedDuration = startedAt != null && endedAt != null
        ? endedAt.difference(startedAt).inMilliseconds
        : null;
    return TaskPart(
      description: content.description,
      agent: content.agent,
      status: content.state.name == 'completed'
          ? TaskStatus.completed
          : content.state.name == 'error'
          ? TaskStatus.error
          : TaskStatus.running,
      sessionId: content.taskSessionId,
      error: content.error,
      retryAttempt: content.retryAttempt,
      currentTool: content.currentTool,
      currentToolTitle: content.currentToolTitle,
      toolCallsCount: content.toolCallsCount,
      durationMs: content.durationMs ?? computedDuration,
      startedAt: startedAt,
    );
  }
  if (content is AssistantQuestion) {
    return QuestionPart(
      question: content.question,
      options: content.options,
      answer: content.answer,
    );
  }
  if (content is AssistantTodo) {
    return TodoPart(todos: content.todos);
  }
  if (content is RawText) {
    return TextPart(content: content.text);
  }
  if (content is RawReasoning) {
    return ReasoningPart(content: content.text, title: content.title);
  }
  return TextPart(content: '');
}

/// Converts `List<AssistantContent>` to `List<Map<String, dynamic>>` for legacy Message.
List<Map<String, dynamic>> assistantContentToPartMaps(
  List<AssistantContent> parts,
) {
  return parts
      .map(assistantContentToMessagePart)
      .map((p) => p.toJson())
      .toList();
}

/// Extracts text content from [AssistantContent] parts.
String extractTextFromParts(List<AssistantContent> parts) {
  return parts.whereType<AssistantText>().map((p) => p.text).join('\n');
}

/// Extracts reasoning content from [AssistantContent] parts.
String? extractReasoningFromParts(List<AssistantContent> parts) {
  return parts.whereType<AssistantReasoning>().firstOrNull?.text;
}

/// Filters parts belonging to a specific [messageId].
List<AssistantContent> filterPartsByMessage(
  List<AssistantContent> parts,
  String messageId,
) {
  return parts.where((p) => p.messageId == messageId).toList();
}

/// Groups [AssistantContent] parts by their messageId.
Map<String, List<AssistantContent>> groupPartsByMessage(
  List<AssistantContent> parts,
) {
  final result = <String, List<AssistantContent>>{};
  for (final part in parts) {
    if (part.messageId != null) {
      result.putIfAbsent(part.messageId!, () => []).add(part);
    }
  }
  return result;
}
