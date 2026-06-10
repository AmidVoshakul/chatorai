import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/shared/utils/logger.dart';

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
    if (parts.isNotEmpty && parts.last is TextPart) {
      final last = parts.last as TextPart;
      parts[parts.length - 1] = TextPart(
        content: last.content + content,
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
    if (parts.isNotEmpty && parts.last is ReasoningPart) {
      final last = parts.last as ReasoningPart;
      parts[parts.length - 1] = ReasoningPart(
        content: last.content + reasoning,
        isStreaming: true,
      );
    } else {
      parts.add(ReasoningPart(content: reasoning, isStreaming: true));
    }
    state = state.copyWith(accumulatedParts: parts);
  }

  void _markReasoningAsDone(List<MessagePart> parts) {
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] is ReasoningPart &&
          (parts[i] as ReasoningPart).isStreaming) {
        parts[i] = ReasoningPart(
          content: (parts[i] as ReasoningPart).content,
          isStreaming: false,
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
    final existingIdx = parts.indexWhere(
      (p) => p is ToolResultPart && p.toolCallId == toolCallId,
    );
    if (existingIdx != -1) {
      // Update existing part (e.g. tool-input-start → tool-call reuse)
      LogTags.chatService.logDebug(
        'onToolCall: duplicate toolCallId=$toolCallId, updating existing',
      );
      parts[existingIdx] = ToolResultPart(
        toolCallId: toolCallId,
        toolName: toolName,
        state: ToolState.running,
        input: input,
        isStreaming: true,
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
      );
    }
    state = state.copyWith(accumulatedParts: parts);
  }

  void onToolError(String toolCallId, String toolName, String error) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
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
      );
    }
    state = state.copyWith(accumulatedParts: parts);
  }

  void onTodo(List<TodoItem> todos) {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts);
    parts.add(TodoPart(todos: todos));
    state = state.copyWith(accumulatedParts: parts);
  }

  Future<void> stopStreaming() async {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts).map((p) {
      if (p is TextPart) {
        return TextPart(content: p.content, isStreaming: false);
      }
      if (p is ReasoningPart) {
        return ReasoningPart(content: p.content, isStreaming: false);
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
