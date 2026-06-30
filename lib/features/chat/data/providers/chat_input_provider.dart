import 'package:chatorai/features/chat/services/speech_to_text_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// STATE
// ===========================================================================

class _Unset {
  const _Unset();
}

class ChatInputState {
  static const _unset = _Unset();

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
    Object? attachedFilePath = _unset,
    Object? attachedFileName = _unset,
    Object? attachedImageType = _unset,
    Object? attachedBase64Data = _unset,
  }) {
    return ChatInputState(
      speechUiState: speechUiState ?? this.speechUiState,
      speechStatusMessage: speechStatusMessage ?? this.speechStatusMessage,
      isSending: isSending ?? this.isSending,
      plusActive: plusActive ?? this.plusActive,
      attachedFilePath: identical(attachedFilePath, _unset)
          ? this.attachedFilePath
          : attachedFilePath as String?,
      attachedFileName: identical(attachedFileName, _unset)
          ? this.attachedFileName
          : attachedFileName as String?,
      attachedImageType: identical(attachedImageType, _unset)
          ? this.attachedImageType
          : attachedImageType as String?,
      attachedBase64Data: identical(attachedBase64Data, _unset)
          ? this.attachedBase64Data
          : attachedBase64Data as String?,
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
