import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// PROVIDER
// ===========================================================================

final streamingContentProvider =
    NotifierProvider<StreamingContentNotifier, StreamingContentState>(
      StreamingContentNotifier.new,
    );

// ===========================================================================
// STATE
// ===========================================================================

class StreamingContentState {
  final String currentChatId;
  final String content;
  final String reasoning;
  final bool isStreaming;
  final DateTime? lastUpdate;

  StreamingContentState({
    this.currentChatId = '',
    this.content = '',
    this.reasoning = '',
    this.isStreaming = false,
    this.lastUpdate,
  });

  DateTime get effectiveLastUpdate => lastUpdate ?? DateTime.now();

  StreamingContentState copyWith({
    String? currentChatId,
    String? content,
    String? reasoning,
    bool? isStreaming,
    DateTime? lastUpdate,
  }) {
    return StreamingContentState(
      currentChatId: currentChatId ?? this.currentChatId,
      content: content ?? this.content,
      reasoning: reasoning ?? this.reasoning,
      isStreaming: isStreaming ?? this.isStreaming,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  StreamingContentState reset() {
    return StreamingContentState(lastUpdate: DateTime.now());
  }
}

// ===========================================================================
// NOTIFIER
// ===========================================================================

class StreamingContentNotifier extends Notifier<StreamingContentState> {
  @override
  StreamingContentState build() {
    return StreamingContentState(lastUpdate: DateTime.now());
  }

  void startStreaming(String chatId) {
    state = StreamingContentState(
      currentChatId: chatId,
      content: '',
      reasoning: '',
      isStreaming: true,
      lastUpdate: DateTime.now(),
    );
  }

  void updateContent(String content, {String? reasoning}) {
    if (!state.isStreaming) return;

    // Immediately update state - throttling is handled in chat_screen
    state = state.copyWith(
      content: content,
      reasoning: reasoning,
      lastUpdate: DateTime.now(),
    );
  }

  void stopStreaming() {
    state = state.copyWith(isStreaming: false);
  }

  Future<void> flushAndStop() async {
    state = state.copyWith(isStreaming: false);
  }

  void reset() {
    state = StreamingContentState(lastUpdate: DateTime.now());
  }
}
