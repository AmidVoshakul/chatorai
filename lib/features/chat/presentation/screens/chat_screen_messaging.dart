part of 'chat_screen.dart';

extension _ChatScreenMessagingExt on _ChatScreenState {
  Future<void> _handleSendMessage(MessageData messageData) async {
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

  Future<void> _handleQuestionAnswer(String messageId, String answer) async {
    final chat = currentChat;
    if (chat == null) return;
    final messageIndex = chat.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    final message = chat.messages[messageIndex];

    // Only assistant messages can have QuestionPart
    if (message.role != MessageRole.assistant) return;

    // Deserialize parts from partsJson
    List<MessagePart> parts = [];
    if (message.partsJson != null && message.partsJson!.isNotEmpty) {
      parts = message.partsJson!.map((j) => partFromJson(j)).toList();
    }

    // Find the first unanswered QuestionPart
    bool found = false;
    for (int i = 0; i < parts.length; i++) {
      if (parts[i] is QuestionPart) {
        final qp = parts[i] as QuestionPart;
        if (qp.answer == null) {
          parts[i] = qp.copyWith(answer: answer);
          found = true;
          break;
        }
      }
    }
    if (!found) return;

    // Serialize back
    final updatedPartsJson = parts.map((p) => p.toJson()).toList();

    // Update storage message
    final updatedMessage = message.copyWith(
      partsJson: updatedPartsJson,
      timestamp: DateTime.now(),
    );

    await _chatStorageService.updateMessageInChat(
      chat.id,
      updatedMessage.id,
      updatedMessage,
    );

    // Update provider
    final updatedChat = chat.copyWith(
      messages: List.of(chat.messages)..[messageIndex] = updatedMessage,
      updatedAt: DateTime.now(),
    );
    ref.read(chatListProvider.notifier).updateChat(updatedChat);

    // Send answer as a new user message
    await _handleSendMessage(MessageData(text: answer));
  }

  Future<void> _handleAddMessagesAndStream(
    Chat chat,
    String text, {
    String? delegateAgentId,
  }) async {
    // Ensure session repository is ready
    final repo = await _sessionRepositoryFuture;
    
    // Create and initialize session runner BEFORE publishing user message
    final sessionRunner = SessionRunner(repo);
    final runnerSession = sessionRunner.startSession(
      agent: ref.read(currentAgentProvider).name,
      modelRef: selectedModelId,
    );
    await runnerSession.initialize();
    _sessionRunner = runnerSession;

    final userMessage = _createUserMessage(
      text,
      base64Data: null,
      imageType: null,
    );

    // Publish user message to Session Core (with error logging)
    try {
      await runnerSession.publishUserMessage(
        content: text,
        messageId: userMessage.id,
      );
    } catch (e) {
      LogTags.chatService.logError(
        'Failed to publish user message to session core',
        e,
      );
    }

    // Store in legacy ChatStorageService (still needed for UI until migration complete)
    await _chatStorageService.addMessageToChat(chat.id, userMessage);

    final chatFromStorage = await _chatStorageService.getChat(chat.id);
    if (chatFromStorage == null) return;
    
    final assistantMessage = _createAssistantMessage();
    await _chatStorageService.addMessageToChat(
      chatFromStorage.id,
      assistantMessage,
    );
    ref.read(chatListProvider.notifier).updateChat(chatFromStorage);
    
    LogTags.chatService.logInfo(
      'ChatScreen._handleAddMessagesAndStream: after storage update, scheduling scroll',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollEnabled = true;
      LogTags.chatService.logInfo(
        'ChatScreen._handleAddMessagesAndStream: _autoScrollEnabled set to true',
      );
      _scrollToBottom(force: true);
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
      }
    } finally {
      runnerSession.dispose();
      if (_sessionRunner == runnerSession) {
        _sessionRunner = null;
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
