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
    try {
      await _sendToAI(
        text,
        providedChat: chatFromStorage,
        delegateAgentId: delegateAgentId,
      );
    } catch (e, s) {
      ref.read(chatScreenProvider.notifier).setStreaming(false);
      ref.read(streamingMessageProvider.notifier).reset();
      try {
        await _handleStreamingError(e);
      } catch (e2) {
        LogTags.chatService.logError(
          '_handleStreamingError threw after main exception',
          e2,
          s,
        );
        // Even if error handling fails, we still reset state above.
      }
    }
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

  void _stopStreaming() async {
    _userStopped = true;
    final aiService = ref.read(chatAiServiceProvider);
    aiService.cancelAllRequests();

    final streamingState = ref.read(streamingMessageProvider);
    if (!streamingState.isStreaming) {
      return;
    }

    final chat = currentChat;
    if (chat != null && chat.messages.isNotEmpty) {
      final content = streamingState.accumulatedParts
          .whereType<TextPart>()
          .map((p) => (p).content)
          .join();
      final reasoning = streamingState.accumulatedParts
          .whereType<ReasoningPart>()
          .map((p) => (p).content)
          .join();
      final toolParts = streamingState.accumulatedParts
          .where((p) => p is ToolResultPart || p is TodoPart || p is TaskPart)
          .toList();
      final partsJson = toolParts.isNotEmpty
          ? toolParts.map((p) => p.toJson()).toList()
          : null;

      final lastMessage = chat.messages.last;
      Message completedMessage;
      List<Message> newMessages;

      if (lastMessage.role == MessageRole.assistant &&
          !lastMessage.isComplete) {
        completedMessage = lastMessage.copyWith(
          content: content,
          reasoning: reasoning.isNotEmpty ? reasoning : null,
          isComplete: true,
          partsJson: partsJson,
          cumulativeTokens: aiService.tokenCounter.totalTokens,
          contextLength: ref
              .read(modelProvider)
              .selectedModelObject
              ?.contextLength,
        );
        newMessages = [
          for (int i = 0; i < chat.messages.length - 1; i++) chat.messages[i],
          completedMessage,
        ];
      } else {
        completedMessage = _createAssistantMessage(
          content: content,
          reasoning: reasoning.isNotEmpty ? reasoning : null,
          isComplete: true,
          cumulativeTokens: aiService.tokenCounter.totalTokens,
          partsJson: partsJson,
          contextLength: ref
              .read(modelProvider)
              .selectedModelObject
              ?.contextLength,
        );
        newMessages = [...chat.messages, completedMessage];
      }

      final newChat = chat.copyWith(
        messages: newMessages,
        updatedAt: DateTime.now(),
      );
      ref.read(chatListProvider.notifier).updateChat(newChat);
      if (lastMessage.role == MessageRole.assistant &&
          !lastMessage.isComplete) {
        await _chatStorageService.updateMessageInChat(
          newChat.id,
          lastMessage.id,
          completedMessage,
        );
      } else {
        await _chatStorageService.addMessageToChat(
          newChat.id,
          completedMessage,
        );
      }
      _showContinuationSuggestions(completedMessage);
    }

    ref.read(chatScreenProvider.notifier).setStreaming(false);
    await ref.read(streamingMessageProvider.notifier).stopStreaming();
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
