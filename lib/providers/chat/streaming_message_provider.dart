import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/models/chat_message.dart';

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

  StreamingMessageState reset() {
    return const StreamingMessageState();
  }
}

// ===========================================================================
// NOTIFIER
// ===========================================================================

class StreamingMessageNotifier extends Notifier<StreamingMessageState> {
  @override
  StreamingMessageState build() {
    return const StreamingMessageState();
  }

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

  void onToolStart(
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
      parts[existingIdx] = ToolResultPart(
        toolCallId: toolCallId,
        toolName: toolName,
        state: ToolState.running,
        input: input,
      );
    } else {
      parts.add(
        ToolResultPart(
          toolCallId: toolCallId,
          toolName: toolName,
          state: ToolState.running,
          input: input,
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

  void stopStreaming() {
    if (!state.isStreaming) return;
    final parts = List<MessagePart>.from(state.accumulatedParts).map((p) {
      if (p is TextPart)
        return TextPart(content: p.content, isStreaming: false);
      if (p is ReasoningPart)
        return ReasoningPart(content: p.content, isStreaming: false);
      return p;
    }).toList();
    state = state.copyWith(
      accumulatedParts: parts,
      isStreaming: false,
      justEnded: true,
    );
  }

  void flushAndStop() {
    stopStreaming();
  }

  void reset() {
    state = const StreamingMessageState();
  }
}
