import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// STATE
// ===========================================================================

class ChatMessageState {
  final bool isEditing;
  final String editingText;

  const ChatMessageState({this.isEditing = false, this.editingText = ''});

  ChatMessageState copyWith({bool? isEditing, String? editingText}) {
    return ChatMessageState(
      isEditing: isEditing ?? this.isEditing,
      editingText: editingText ?? this.editingText,
    );
  }
}

// ===========================================================================
// NOTIFIER
// ===========================================================================

class ChatMessageNotifier extends Notifier<ChatMessageState> {
  @override
  ChatMessageState build() {
    return const ChatMessageState();
  }

  void startEditing(String text) {
    state = state.copyWith(isEditing: true, editingText: text);
  }

  void cancelEditing() {
    state = state.copyWith(isEditing: false, editingText: '');
  }

  void saveEditing() {
    state = state.copyWith(isEditing: false);
  }

  void setEditingText(String text) {
    state = state.copyWith(editingText: text);
  }
}

// ===========================================================================
// PROVIDER
// ===========================================================================

final chatMessageProvider =
    NotifierProvider<ChatMessageNotifier, ChatMessageState>(
      ChatMessageNotifier.new,
    );
