import 'package:chatorai/features/chat/presentation/widgets/chat_content_wrapper.dart';
import 'package:chatorai/features/chat/presentation/widgets/speech_overlay.dart';
import 'package:chatorai/features/chat/services/speech_ui_state.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ChatLayoutContent extends StatelessWidget {
  final Widget chatMessagesArea;
  final SpeechUiState speechUiState;
  final String speechStatusMessage;
  final double speechSoundLevel;
  final String speechRecognizedText;
  final Widget chatInput;
  final double screenWidth;
  final bool isNavigatorVisible;
  final bool wideScreenMode;
  final bool Function() hasHeadings;
  final VoidCallback toggleNavigator;
  final bool isInputPopupVisible;

  const ChatLayoutContent({
    super.key,
    required this.chatMessagesArea,
    required this.speechUiState,
    required this.speechStatusMessage,
    required this.speechSoundLevel,
    required this.speechRecognizedText,
    required this.chatInput,
    required this.screenWidth,
    required this.isNavigatorVisible,
    required this.wideScreenMode,
    required this.hasHeadings,
    required this.toggleNavigator,
    required this.isInputPopupVisible,
  });

  @override
  Widget build(BuildContext context) {
    return ChatContentWrapper(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                chatMessagesArea,
                if (isInputPopupVisible) PopupItemDefaults.buildDimOverlay(),
                if (speechUiState != SpeechUiState.idle)
                  SpeechOverlayWidget(
                    state: speechUiState,
                    message: speechStatusMessage,
                    soundLevel: speechSoundLevel,
                    recognizedText: speechRecognizedText,
                    bottomInset: 0,
                  ),
              ],
            ),
          ),
          chatInput,
        ],
      ),
      screenWidth: screenWidth,
      isNavigatorVisible: isNavigatorVisible,
      wideScreenMode: wideScreenMode,
      hasHeadings: hasHeadings,
      toggleNavigator: toggleNavigator,
    );
  }
}
