import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';

// ===========================================================================
// PROVIDER
// ===========================================================================
final streamingMessageProvider =
    NotifierProvider<StreamingMessageNotifier, StreamingMessageState>(
      StreamingMessageNotifier.new,
    );

// ===========================================================================
// STATE
// ===========================================================================
class StreamingMessageState {
  final String chatId;
  final List<MessagePart> accumulatedParts;
  final bool isStreaming;
  final bool justEnded;

  const StreamingMessageState({
    this.chatId = '',
    this.accumulatedParts = const [],
    this.isStreaming = false,
    this.justEnded = false,
  });

  StreamingMessageState copyWith({
    String? chatId,
    List<MessagePart>? accumulatedParts,
    bool? isStreaming,
    bool? justEnded,
  }) {
    return StreamingMessageState(
      chatId: chatId ?? this.chatId,
      accumulatedParts: accumulatedParts ?? this.accumulatedParts,
      isStreaming: isStreaming ?? this.isStreaming,
      justEnded: justEnded ?? this.justEnded,
    );
  }

  StreamingMessageState reset() => const StreamingMessageState();
}

// ===========================================================================
// NOTIFIER
// ===========================================================================
class StreamingMessageNotifier extends Notifier<StreamingMessageState> {
  @override
  StreamingMessageState build() => const StreamingMessageState();

  void startStreaming(String chatId) {
    state = StreamingMessageState(
      chatId: chatId,
      accumulatedParts: [],
      isStreaming: true,
    );
  }

  void onChunk(String content) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    _markReasoningAsDone(parts);

    // Find any streaming TextPart (not necessarily last, e.g., after ToolResultPart)
    int? openTextIdx;
    for (int i = parts.length - 1; i >= 0; i--) {
      if (parts[i] is TextPart && (parts[i] as TextPart).isStreaming) {
        openTextIdx = i;
        break;
      }
    }

    if (openTextIdx != null) {
      final existing = parts[openTextIdx] as TextPart;
      parts[openTextIdx] = TextPart(
        content: existing.content + content,
        isStreaming: true,
      );
    } else {
      parts.add(TextPart(content: content, isStreaming: true));
    }
    state = state.copyWith(accumulatedParts: parts);
  }

  void onReasoning(String reasoning) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    _markTextAsDone(parts);

    // Find any streaming ReasoningPart (not necessarily last, e.g., after ToolResultPart)
    int? openReasoningIdx;
    for (int i = parts.length - 1; i >= 0; i--) {
      if (parts[i] is ReasoningPart &&
          (parts[i] as ReasoningPart).isStreaming) {
        openReasoningIdx = i;
        break;
      }
    }

    if (openReasoningIdx != null) {
      final existing = parts[openReasoningIdx] as ReasoningPart;
      parts[openReasoningIdx] = ReasoningPart(
        content: existing.content + reasoning,
        isStreaming: true,
        startedAt: existing.startedAt ?? DateTime.now(),
        isExpanded: existing.isExpanded,
      );
    } else {
      parts.add(
        ReasoningPart(
          content: reasoning,
          isStreaming: true,
          startedAt: DateTime.now(),
        ),
      );
    }
    state = state.copyWith(accumulatedParts: parts);
  }

  void _markReasoningAsDone(List<MessagePart> parts) {
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] is ReasoningPart &&
          (parts[i] as ReasoningPart).isStreaming) {
        final existing = parts[i] as ReasoningPart;
        final now = DateTime.now();
        parts[i] = ReasoningPart(
          content: existing.content,
          isStreaming: false,
          startedAt: existing.startedAt,
          durationMs: existing.startedAt != null
              ? now.difference(existing.startedAt!).inMilliseconds
              : null,
          isExpanded: existing.isExpanded,
        );
      }
    }
  }

  void _markTextAsDone(List<MessagePart> parts) {
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] is TextPart && (parts[i] as TextPart).isStreaming) {
        parts[i] = TextPart(
          content: (parts[i] as TextPart).content,
          isStreaming: false,
        );
      }
    }
  }

  void onToolCall(
    String toolCallId,
    String toolName,
    Map<String, dynamic> input,
  ) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    _markReasoningAsDone(parts);
    _markTextAsDone(parts);
    final existingIdx = parts.indexWhere(
      (p) => p is ToolResultPart && p.toolCallId == toolCallId,
    );
    if (existingIdx != -1) {
      // Update existing part (e.g. tool-input-start → tool-call reuse)
      final existing = parts[existingIdx] as ToolResultPart;
      parts[existingIdx] = ToolResultPart(
        toolCallId: toolCallId,
        toolName: toolName,
        state: ToolState.running,
        input: input,
        isStreaming: true,
        metadata: existing.metadata,
      );
    } else {
      parts.add(
        ToolResultPart(
          toolCallId: toolCallId,
          toolName: toolName,
          state: ToolState.running,
          input: input,
          isStreaming: true,
        ),
      );
    }
    state = state.copyWith(accumulatedParts: parts);
  }

  void onToolEnd(String toolCallId, String toolName, String result) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    _markReasoningAsDone(parts);
    _markTextAsDone(parts);
    final idx = parts.indexWhere(
      (p) => p is ToolResultPart && p.toolCallId == toolCallId,
    );
    if (idx != -1) {
      final existing = parts[idx] as ToolResultPart;
      parts[idx] = ToolResultPart(
        toolCallId: toolCallId,
        toolName: toolName,
        result: result,
        state: ToolState.completed,
        input: existing.input,
        isStreaming: false,
        metadata: existing.metadata,
      );
    }
    state = state.copyWith(accumulatedParts: parts);
  }

  void onToolError(String toolCallId, String toolName, String error) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    _markReasoningAsDone(parts);
    final idx = parts.indexWhere(
      (p) => p is ToolResultPart && p.toolCallId == toolCallId,
    );
    if (idx != -1) {
      final existing = parts[idx] as ToolResultPart;
      parts[idx] = ToolResultPart(
        toolCallId: toolCallId,
        toolName: toolName,
        error: error,
        state: ToolState.error,
        input: existing.input,
        isStreaming: false,
        metadata: existing.metadata,
      );
    }
    state = state.copyWith(accumulatedParts: parts);
  }

  void onTodo(List<TodoItem> todos) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    _markReasoningAsDone(parts);
    parts.add(TodoPart(todos: todos));
    state = state.copyWith(accumulatedParts: parts);
  }

  void onQuestion(QuestionPart question) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    _markReasoningAsDone(parts);
    final existingIdx = parts.indexWhere(
      (p) => p is QuestionPart && p.question == question.question,
    );
    if (existingIdx != -1) {
      parts[existingIdx] = question;
    } else {
      parts.add(question);
    }
    state = state.copyWith(accumulatedParts: parts);
  }

  int _findTaskPartIndex(List<MessagePart> parts) {
    for (var i = parts.length - 1; i >= 0; i--) {
      if (parts[i] is TaskPart) return i;
    }
    return -1;
  }

  void onTaskStart({
    required String description,
    required String agent,
    String? sessionId,
  }) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    _markReasoningAsDone(parts);
    _markTextAsDone(parts);

    final idx = _findTaskPartIndex(parts);
    final taskPart = TaskPart(
      description: description,
      agent: agent,
      status: TaskStatus.running,
      sessionId: sessionId,
      startedAt: DateTime.now(),
    );

    if (idx != -1) {
      parts[idx] = taskPart;
    } else {
      parts.add(taskPart);
    }
    state = state.copyWith(accumulatedParts: parts);
  }

  void onTaskToolExecuted(String toolName, String? toolTitle) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    final idx = _findTaskPartIndex(parts);
    if (idx == -1) return;

    final existing = parts[idx] as TaskPart;
    parts[idx] = existing.copyWith(
      currentTool: toolName,
      currentToolTitle: toolTitle,
      toolCallsCount: existing.toolCallsCount + 1,
    );
    state = state.copyWith(accumulatedParts: parts);
  }

  /// Update the TaskPart's sessionId with the real child session ID
  /// once it becomes available from the task tool.
  void updateTaskSessionId(String sessionId) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    final idx = _findTaskPartIndex(parts);
    if (idx == -1) return;

    final existing = parts[idx] as TaskPart;
    parts[idx] = existing.copyWith(sessionId: sessionId);
    state = state.copyWith(accumulatedParts: parts);
  }

  void onTaskError(String error, int? retryAttempt) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    final idx = _findTaskPartIndex(parts);
    if (idx == -1) return;

    final existing = parts[idx] as TaskPart;
    parts[idx] = existing.copyWith(
      error: error,
      retryAttempt: retryAttempt,
      currentTool: null,
      currentToolTitle: null,
    );
    state = state.copyWith(accumulatedParts: parts);
  }

  void onTaskEnd() {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    final idx = _findTaskPartIndex(parts);
    if (idx == -1) return;

    final existing = parts[idx] as TaskPart;
    final now = DateTime.now();
    final startedAt = existing.startedAt ?? now;
    final durationMs = now.difference(startedAt).inMilliseconds;

    parts[idx] = existing.copyWith(
      status: TaskStatus.completed,
      currentTool: null,
      currentToolTitle: null,
      durationMs: durationMs,
    );
    state = state.copyWith(accumulatedParts: parts);
  }

  Future<void> stopStreaming() async {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts).map((p) {
      if (p is TextPart) {
        return TextPart(content: p.content, isStreaming: false);
      }
      if (p is ReasoningPart) {
        final now = DateTime.now();
        return ReasoningPart(
          content: p.content,
          isStreaming: false,
          startedAt: p.startedAt,
          durationMs: p.startedAt != null
              ? now.difference(p.startedAt!).inMilliseconds
              : null,
          isExpanded: p.isExpanded,
        );
      }
      if (p is ToolResultPart) {
        return ToolResultPart(
          toolCallId: p.toolCallId,
          toolName: p.toolName,
          result: p.result,
          error: p.error,
          state: p.state,
          duration: p.duration,
          input: p.input,
          isStreaming: false,
          metadata: p.metadata,
        );
      }
      if (p is TodoPart) return TodoPart(todos: p.todos, isStreaming: false);
      return p;
    }).toList();
    state = state.copyWith(
      accumulatedParts: parts,
      isStreaming: false,
      justEnded: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(justEnded: false);
  }

  void reset() {
    state = const StreamingMessageState();
  }
}
