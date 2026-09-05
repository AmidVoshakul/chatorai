import 'package:chatorai/gui/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_layout_content.dart';
import 'package:chatorai/gui/features/chat/services/speech_ui_state.dart';
import 'package:flutter/material.dart';

class ChatDesktopLayout extends StatelessWidget {
  final Widget chatInput;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool Function() hasHeadings;
  final VoidCallback onToggleNavigator;
  final Function(String, dynamic) onModelSelected;
  final VoidCallback onOpenModelSelector;
  final VoidCallback onMenuPressed;
  final Widget drawer;
  final SpeechUiState speechUiState;
  final String speechStatusMessage;
  final double speechSoundLevel;
  final String speechRecognizedText;
  final Widget chatMessagesArea;
  final double screenWidth;
  final bool isNavigatorVisible;
  final bool wideScreenMode;
  final String selectedModel;
  final dynamic selectedModelObject;
  final bool isInputPopupVisible;

  const ChatDesktopLayout({
    super.key,
    required this.chatInput,
    required this.scaffoldKey,
    required this.hasHeadings,
    required this.onToggleNavigator,
    required this.onModelSelected,
    required this.onOpenModelSelector,
    required this.onMenuPressed,
    required this.drawer,
    required this.speechUiState,
    required this.speechStatusMessage,
    required this.speechSoundLevel,
    required this.speechRecognizedText,
    required this.chatMessagesArea,
    required this.screenWidth,
    required this.isNavigatorVisible,
    required this.wideScreenMode,
    required this.selectedModel,
    required this.selectedModelObject,
    required this.isInputPopupVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: ChatAppBar(
        selectedModel: selectedModel,
        selectedModelObject: selectedModelObject,
        hasHeadings: hasHeadings,
        onToggleNavigator: onToggleNavigator,
        onModelSelected: onModelSelected,
        onOpenModelSelector: onOpenModelSelector,
        onMenuPressed: onMenuPressed,
      ),
      drawer: drawer,
      body: ChatLayoutContent(
        chatMessagesArea: chatMessagesArea,
        speechUiState: speechUiState,
        speechStatusMessage: speechStatusMessage,
        speechSoundLevel: speechSoundLevel,
        speechRecognizedText: speechRecognizedText,
        chatInput: chatInput,
        screenWidth: screenWidth,
        isNavigatorVisible: isNavigatorVisible,
        wideScreenMode: wideScreenMode,
        hasHeadings: hasHeadings,
        toggleNavigator: onToggleNavigator,
        isInputPopupVisible: isInputPopupVisible,
      ),
    );
  }
}
