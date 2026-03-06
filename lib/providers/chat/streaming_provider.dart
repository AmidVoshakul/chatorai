import 'package:flutter_riverpod/flutter_riverpod.dart';

class StreamingState {
  final bool isStreaming;
  final String currentContent;
  final String currentReasoning;
  final String? activeChatId;

  const StreamingState({
    this.isStreaming = false,
    this.currentContent = '',
    this.currentReasoning = '',
    this.activeChatId,
  });

  StreamingState copyWith({
    bool? isStreaming,
    String? currentContent,
    String? currentReasoning,
    String? activeChatId,
  }) {
    return StreamingState(
      isStreaming: isStreaming ?? this.isStreaming,
      currentContent: currentContent ?? this.currentContent,
      currentReasoning: currentReasoning ?? this.currentReasoning,
      activeChatId: activeChatId ?? this.activeChatId,
    );
  }

  StreamingState reset() {
    return const StreamingState();
  }
}

final streamingStateProvider =
    NotifierProvider<StreamingStateNotifier, StreamingState>(
      StreamingStateNotifier.new,
    );

class StreamingStateNotifier extends Notifier<StreamingState> {
  @override
  StreamingState build() {
    return const StreamingState();
  }

  void startStreaming(String chatId) {
    state = StreamingState(
      isStreaming: true,
      currentContent: '',
      currentReasoning: '',
      activeChatId: chatId,
    );
  }

  void updateContent(String content) {
    if (state.isStreaming) {
      state = state.copyWith(currentContent: content);
    }
  }

  void updateReasoning(String reasoning) {
    if (state.isStreaming) {
      state = state.copyWith(currentReasoning: reasoning);
    }
  }

  void stopStreaming() {
    state = state.copyWith(isStreaming: false);
  }

  void reset() {
    state = const StreamingState();
  }
}
