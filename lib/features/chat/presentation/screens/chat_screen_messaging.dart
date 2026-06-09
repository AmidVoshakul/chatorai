part of 'chat_screen.dart';

extension _ChatScreenMessagingExt on _ChatScreenState {
  void _handleSendMessage(MessageData messageData) async {
    ref.read(chatScreenProvider.notifier).hideAllSuggestions();
    if (currentChat == null) {
      final newChat = await ref.read(chatListProvider.notifier).createNewChat();
      ref.read(currentChatIdProvider.notifier).setChatId(newChat.id);
      await _handleAddMessagesAndStream(
        newChat,
        messageData.text,
        delegateAgentId: messageData.delegateAgentId,
      );
      return;
    }
    await _handleAddMessagesAndStream(
      currentChat!,
      messageData.text,
      delegateAgentId: messageData.delegateAgentId,
    );
  }

  Future<void> _handleAddMessagesAndStream(
    Chat chat,
    String text, {
    String? delegateAgentId,
  }) async {
    final userMessage = _createUserMessage(
      text,
      base64Data: null,
      imageType: null,
    );
    await _chatStorageService.addMessageToChat(chat.id, userMessage);
    final chatFromStorage = await _chatStorageService.getChat(chat.id);
    if (chatFromStorage == null) return;
    final assistantMessage = _createAssistantMessage();
    await _chatStorageService.addMessageToChat(
      chatFromStorage.id,
      assistantMessage,
    );
    ref.read(chatListProvider.notifier).updateChat(chatFromStorage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollUtils?.scrollToIndicator();
    });
    _sendToAI(
      text,
      providedChat: chatFromStorage,
      delegateAgentId: delegateAgentId,
    );
  }

  Message _createUserMessage(
    String content, {
    String? base64Data,
    String? imageType,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      isComplete: true,
      imageData: base64Data,
      imageType: imageType,
    );
  }

  Message _createAssistantMessage({
    String content = '',
    bool isComplete = false,
    String? model,
    String? reasoning,
    int? cumulativeTokens,
    int? contextLength,
    List<Map<String, dynamic>>? partsJson,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      isComplete: isComplete,
      model: model ?? selectedModelId,
      reasoning: reasoning,
      cumulativeTokens: cumulativeTokens,
      contextLength: contextLength,
      partsJson: partsJson,
    );
  }

  void _stopStreaming() {
    final aiService = ref.read(chatAiServiceProvider);
    aiService.cancelAllRequests();
    ref.read(chatScreenProvider.notifier).setStreaming(false);
    ref.read(streamingMessageProvider.notifier).reset();
  }

  void _refreshChatMessages() async {
    FocusScope.of(context).unfocus();
    if (currentChat != null) {
      final updatedChat = await _chatStorageService.getChat(currentChat!.id);
      if (updatedChat != null) {
        ref.read(chatListProvider.notifier).updateChat(updatedChat);
        ref.read(chatScreenProvider.notifier).hideSuggestions();
        if (updatedChat.messages.isEmpty) {
          ref.read(chatScreenProvider.notifier).hideAllSuggestions();
          _showWelcomeSuggestions();
        }
      }
    }
  }
}
