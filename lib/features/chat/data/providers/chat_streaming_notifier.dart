import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatStreamingState {
  final bool isStreaming;
  final StringBuffer pendingContent;
  final StringBuffer pendingReasoning;
  final StringBuffer fullContent;
  final StringBuffer fullReasoning;
  final int lastInputTokens;
  final int lastOutputTokens;
  final DateTime? reasoningStartTime;

  ChatStreamingState({
    this.isStreaming = false,
    StringBuffer? pendingContent,
    StringBuffer? pendingReasoning,
    StringBuffer? fullContent,
    StringBuffer? fullReasoning,
    this.lastInputTokens = 0,
    this.lastOutputTokens = 0,
    this.reasoningStartTime,
  }) : pendingContent = pendingContent ?? StringBuffer(),
       pendingReasoning = pendingReasoning ?? StringBuffer(),
       fullContent = fullContent ?? StringBuffer(),
       fullReasoning = fullReasoning ?? StringBuffer();

  ChatStreamingState copyWith({
    bool? isStreaming,
    int? lastInputTokens,
    int? lastOutputTokens,
    DateTime? reasoningStartTime,
  }) {
    return ChatStreamingState(
      isStreaming: isStreaming ?? this.isStreaming,
      pendingContent: pendingContent,
      pendingReasoning: pendingReasoning,
      fullContent: fullContent,
      fullReasoning: fullReasoning,
      lastInputTokens: lastInputTokens ?? this.lastInputTokens,
      lastOutputTokens: lastOutputTokens ?? this.lastOutputTokens,
      reasoningStartTime: reasoningStartTime ?? this.reasoningStartTime,
    );
  }

  ChatStreamingState reset() => ChatStreamingState();
}

class ChatStreamingNotifier extends Notifier<ChatStreamingState> {
  @override
  ChatStreamingState build() => ChatStreamingState();

  void startStreaming() {
    state = ChatStreamingState(isStreaming: true);
  }

  void reset() {
    state = ChatStreamingState();
  }

  void onChunk(String content) {
    state.pendingContent.write(content);
  }

  void onReasoning(String reasoning) {
    state = state.copyWith(
      reasoningStartTime: state.reasoningStartTime ?? DateTime.now(),
    );
    state.pendingReasoning.write(reasoning);
  }

  void setTokens(int input, int output) {
    state = state.copyWith(lastInputTokens: input, lastOutputTokens: output);
  }

  void clearPending() {
    state.pendingContent.clear();
    state.pendingReasoning.clear();
  }

  void flushPending() {
    state.fullContent.write(state.pendingContent);
    state.fullReasoning.write(state.pendingReasoning);
    state.pendingContent.clear();
    state.pendingReasoning.clear();
  }

  int? getReasoningDurationMs() {
    final start = state.reasoningStartTime;
    if (start == null) return null;
    return DateTime.now().difference(start).inMilliseconds;
  }

  void stopStreaming() {
    state = state.copyWith(isStreaming: false);
  }
}

final chatStreamingNotifierProvider =
    NotifierProvider<ChatStreamingNotifier, ChatStreamingState>(
      ChatStreamingNotifier.new,
    );
