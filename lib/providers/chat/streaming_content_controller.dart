import 'package:flutter_riverpod/flutter_riverpod.dart';

final streamingContentProvider =
    NotifierProvider<StreamingContentNotifier, StreamingContentState>(
      StreamingContentNotifier.new,
    );

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

class StreamingContentNotifier extends Notifier<StreamingContentState> {
  static const updateIntervalMs = 250;
  DateTime _lastUiUpdate = DateTime.now();
  String _pendingContent = '';
  String _pendingReasoning = '';

  @override
  StreamingContentState build() {
    return StreamingContentState(lastUpdate: DateTime.now());
  }

  void startStreaming(String chatId) {
    _pendingContent = '';
    _pendingReasoning = '';
    _lastUiUpdate = DateTime.now();
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

    _pendingContent = content;
    if (reasoning != null) {
      _pendingReasoning = reasoning;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_lastUiUpdate).inMilliseconds;

    if (elapsed >= updateIntervalMs) {
      _flushPendingUpdates();
    }
  }

  void _flushPendingUpdates() {
    if (!state.isStreaming) return;

    state = state.copyWith(
      content: _pendingContent,
      reasoning: _pendingReasoning,
      lastUpdate: DateTime.now(),
    );
    _lastUiUpdate = DateTime.now();
  }

  void stopStreaming() {
    _flushPendingUpdates();
    state = state.copyWith(isStreaming: false);
  }

  Future<void> flushAndStop() async {
    _flushPendingUpdates();
    state = state.copyWith(isStreaming: false);
  }

  void reset() {
    _pendingContent = '';
    _pendingReasoning = '';
    _lastUiUpdate = DateTime.now();
    state = StreamingContentState(lastUpdate: DateTime.now());
  }
}
