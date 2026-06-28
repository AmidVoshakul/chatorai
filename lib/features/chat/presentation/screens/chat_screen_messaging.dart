part of 'chat_screen.dart';

extension _ChatScreenMessagingExt on _ChatScreenState {
  List<Map<String, dynamic>> _buildApiMessages(
    Chat chat, {
    String? delegateAgentId,
  }) {
    const int maxHistoryMessages = 20;
    final recentMessages = chat.messages.length > maxHistoryMessages
        ? chat.messages.sublist(chat.messages.length - maxHistoryMessages)
        : chat.messages;

    final messages = recentMessages.where((m) => !m.isError).map((msg) {
      final result = <String, dynamic>{'role': msg.role.name};
      if (msg.imageData != null && msg.imageType != null) {
        result['content'] = [
          {'type': 'text', 'text': msg.content},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:${msg.imageType};base64,${msg.imageData}',
            },
          },
        ];
      } else {
        result['content'] = msg.content;
      }
      return result;
    }).toList();

    if (delegateAgentId != null) {
      final agent = AgentRegistry().get(delegateAgentId);
      if (agent != null && agent.systemPrompt != null) {
        messages.insert(0, {'role': 'system', 'content': agent.systemPrompt!});
      }
    } else {
      final currentAgent = ref.read(currentAgentProvider);
      final isDefault = currentAgent.id == 'build';
      if (!isDefault && currentAgent.systemPrompt != null) {
        messages.insert(0, {
          'role': 'system',
          'content': currentAgent.systemPrompt!,
        });
      }
    }
    return messages;
  }

  Future<void> _initiateStream({
    required Chat chat,
    required List<Map<String, dynamic>> messages,
    required bool isContinuation,
    String? delegateAgentId,
  }) async {
    final repo = await _sessionRepositoryFuture;
    final toolRegistry = await ref.read(toolRegistryProvider.future);
    final sessionRunner = SessionRunner(repo, toolRegistry);
    final runnerSession = await sessionRunner.startInitializedSession(
      agent: ref.read(currentAgentProvider).name,
      modelRef: selectedModelId,
    );
    _sessionRunner = runnerSession;
    ref.read(currentSessionRunnerProvider.notifier).set(sessionRunner);

    if (!isContinuation) {
      final userMessages =
          chat.messages.where((m) => m.role == MessageRole.user).toList();
      if (userMessages.isNotEmpty) {
        final lastUserMsg = userMessages.last;
        try {
          await runnerSession.publishUserMessage(
            content: lastUserMsg.content,
            messageId: lastUserMsg.id,
          );
        } catch (e) {
          LogTags.chatService.logError(
            'Failed to publish user message to session core',
            e,
          );
        }
      }
    }

    try {
      final modelSettingsNotifier = ref.read(modelSettingsProvider.notifier);
      final settings = await modelSettingsNotifier.getSettings(selectedModelId);

      if (delegateAgentId == null &&
          settings.systemPrompt != null &&
          messages.isNotEmpty &&
          messages.first['role'] != 'system') {
        messages.insert(0, {
          'role': 'system',
          'content': settings.systemPrompt!,
        });
      }

      await _handleStreamingResponse(
        chat: chat,
        messages: messages,
        isContinuation: isContinuation,
        modelId: selectedModelId,
        modelSettings: settings,
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
      ref.read(currentSessionRunnerProvider.notifier).clear();
    }
  }
  Future<void> _handleSendMessage(MessageData messageData) async {
    ref.read(chatScreenProvider.notifier).hideAllSuggestions();
    Chat chat;
    if (currentChat == null) {
      chat = await ref.read(chatListProvider.notifier).createNewChat();
      ref.read(currentChatIdProvider.notifier).setChatId(chat.id);
    } else {
      chat = currentChat!;
    }

    final userMessage = _createUserMessage(
      messageData.text,
      base64Data: messageData.base64Data,
      imageType: messageData.imageType,
    );
    await _chatStorageService.addMessageToChat(chat.id, userMessage);
    var streamChat = await _chatStorageService.getChat(chat.id);
    if (streamChat == null) return;

    final assistantMessage = _createAssistantMessage();
    await _chatStorageService.addMessageToChat(streamChat.id, assistantMessage);
    streamChat = await _chatStorageService.getChat(streamChat.id) ?? streamChat;
    ref.read(chatListProvider.notifier).updateChat(streamChat);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollEnabled = true;
      _scrollToBottom(force: true);
    });

    final messages = _buildApiMessages(
      streamChat,
      delegateAgentId: messageData.delegateAgentId,
    );
    await _initiateStream(
      chat: streamChat,
      messages: messages,
      isContinuation: false,
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
    int? tokensInput,
    int? tokensOutput,
    int? tokensReasoning,
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
      tokensInput: tokensInput,
      tokensOutput: tokensOutput,
      tokensReasoning: tokensReasoning,
      contextLength: contextLength,
      partsJson: partsJson,
    );
  }

  void _stopStreaming() async {
    final aiService = ref.read(chatAiServiceProvider);
    aiService.cancelAllRequests();

    // Brief yield so any in‑flight stream event can be captured
    // before we snapshot the streaming state.
    await Future<void>.delayed(const Duration(milliseconds: 50));

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
          tokensInput: aiService.tokenCounter.totalTokens,
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
          tokensInput: aiService.tokenCounter.totalTokens,
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
