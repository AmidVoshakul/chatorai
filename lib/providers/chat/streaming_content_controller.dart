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
  final bool justEnded;
  final bool hasReceivedContentChunk;
  final DateTime? lastUpdate;

  StreamingContentState({
    this.currentChatId = '',
    this.content = '',
    this.reasoning = '',
    this.isStreaming = false,
    this.justEnded = false,
    this.hasReceivedContentChunk = false,
    this.lastUpdate,
  });

  DateTime get effectiveLastUpdate => lastUpdate ?? DateTime.now();

  StreamingContentState copyWith({
    String? currentChatId,
    String? content,
    String? reasoning,
    bool? isStreaming,
    bool? justEnded,
    bool? hasReceivedContentChunk,
    DateTime? lastUpdate,
  }) {
    return StreamingContentState(
      currentChatId: currentChatId ?? this.currentChatId,
      content: content ?? this.content,
      reasoning: reasoning ?? this.reasoning,
      isStreaming: isStreaming ?? this.isStreaming,
      justEnded: justEnded ?? this.justEnded,
      hasReceivedContentChunk:
          hasReceivedContentChunk ?? this.hasReceivedContentChunk,
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

    state = state.copyWith(
      content: content,
      reasoning: reasoning,
      hasReceivedContentChunk: true,
      lastUpdate: DateTime.now(),
    );
  }

  void stopStreaming() {
    if (!state.isStreaming) return;
    state = state.copyWith(
      isStreaming: false,
      justEnded: true,
      lastUpdate: DateTime.now(),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      reset();
    });
  }

  Future<void> flushAndStop() async {
    if (!state.isStreaming) return;
    state = state.copyWith(
      isStreaming: false,
      justEnded: true,
      lastUpdate: DateTime.now(),
    );
    await Future.delayed(const Duration(milliseconds: 100));
    reset();
  }

  void clearJustEnded() {
    if (state.justEnded) {
      state = state.copyWith(justEnded: false);
    }
  }

  void reset() {
    state = StreamingContentState(lastUpdate: DateTime.now());
  }
}
