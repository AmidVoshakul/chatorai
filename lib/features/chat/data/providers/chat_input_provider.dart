import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/chat/domain/services/speech_to_text_service.dart';

// ===========================================================================
// STATE
// ===========================================================================

class ChatInputState {
  final SpeechUiState speechUiState;
  final String speechStatusMessage;
  final bool isSending;
  final bool plusActive;
  final String? attachedFilePath;
  final String? attachedFileName;
  final String? attachedImageType;
  final String? attachedBase64Data;

  const ChatInputState({
    this.speechUiState = SpeechUiState.idle,
    this.speechStatusMessage = '',
    this.isSending = false,
    this.plusActive = false,
    this.attachedFilePath,
    this.attachedFileName,
    this.attachedImageType,
    this.attachedBase64Data,
  });

  ChatInputState copyWith({
    SpeechUiState? speechUiState,
    String? speechStatusMessage,
    bool? isSending,
    bool? plusActive,
    String? attachedFilePath,
    String? attachedFileName,
    String? attachedImageType,
    String? attachedBase64Data,
  }) {
    return ChatInputState(
      speechUiState: speechUiState ?? this.speechUiState,
      speechStatusMessage: speechStatusMessage ?? this.speechStatusMessage,
      isSending: isSending ?? this.isSending,
      plusActive: plusActive ?? this.plusActive,
      attachedFilePath: attachedFilePath ?? this.attachedFilePath,
      attachedFileName: attachedFileName ?? this.attachedFileName,
      attachedImageType: attachedImageType ?? this.attachedImageType,
      attachedBase64Data: attachedBase64Data ?? this.attachedBase64Data,
    );
  }
}

// ===========================================================================
// NOTIFIER
// ===========================================================================

class ChatInputNotifier extends Notifier<ChatInputState> {
  @override
  ChatInputState build() {
    return const ChatInputState();
  }

  void setSpeechUiState(SpeechUiState uiState) {
    state = state.copyWith(speechUiState: uiState);
  }

  void setSpeechStatusMessage(String message) {
    state = state.copyWith(speechStatusMessage: message);
  }

  void setIsSending(bool isSending) {
    state = state.copyWith(isSending: isSending);
  }

  void setPlusActive(bool plusActive) {
    state = state.copyWith(plusActive: plusActive);
  }

  void setAttachedFile({
    String? path,
    String? name,
    String? imageType,
    String? base64Data,
  }) {
    state = state.copyWith(
      attachedFilePath: path ?? state.attachedFilePath,
      attachedFileName: name ?? state.attachedFileName,
      attachedImageType: imageType ?? state.attachedImageType,
      attachedBase64Data: base64Data ?? state.attachedBase64Data,
    );
  }

  void clearAttachedFile() {
    state = state.copyWith(
      attachedFilePath: null,
      attachedFileName: null,
      attachedImageType: null,
      attachedBase64Data: null,
    );
  }
}

// ===========================================================================
// PROVIDER
// ===========================================================================

final chatInputProvider = NotifierProvider<ChatInputNotifier, ChatInputState>(
  ChatInputNotifier.new,
);
