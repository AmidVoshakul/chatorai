part of 'chat_screen.dart';

extension _ChatScreenAiExt on _ChatScreenState {
  Future<void> _regenerateResponse(String messageId) async {
    final chat = currentChat;
    if (chat == null || chat.messages.isEmpty) return;
    ref.read(chatScreenProvider.notifier).hideSuggestions();

    final messageIndex = chat.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    final targetMessage = chat.messages[messageIndex];
    if (targetMessage.role != MessageRole.assistant) return;

    int userMessageIndex = -1;
    for (int i = messageIndex - 1; i >= 0; i--) {
      if (chat.messages[i].role == MessageRole.user) {
        userMessageIndex = i;
        break;
      }
    }
    if (userMessageIndex == -1) return;
    final userMessage = chat.messages[userMessageIndex];

    final messagesToDelete = chat.messages
        .sublist(messageIndex)
        .map((m) => m.id)
        .toList();
    for (final msgId in messagesToDelete) {
      await _chatStorageService.deleteMessageFromChat(chat.id, msgId);
    }

    final updatedMessages = chat.messages.sublist(0, messageIndex);
    final updatedChat = chat.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
    final newAssistantMessage = _createAssistantMessage();
    final chatWithNewPlaceholder = updatedChat.copyWith(
      messages: [...updatedMessages, newAssistantMessage],
      updatedAt: DateTime.now(),
    );

    _chatStorageService.addMessageToChat(chat.id, newAssistantMessage);
    ref.read(chatListProvider.notifier).updateChat(chatWithNewPlaceholder);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: true);
    });
    _sendToAI(userMessage.content, providedChat: chatWithNewPlaceholder);
  }

  Future<void> _sendToAI(
    String userMessage, {
    Chat? providedChat,
    String? delegateAgentId,
  }) async {
    final chat = providedChat ?? currentChat;
    if (chat == null) return;
    try {
      await _streamAIResponse(chat, delegateAgentId: delegateAgentId);
    } catch (e) {
      if (_userStopped) {
        _userStopped = false;
        return;
      }
      final errorMessage = Message(
        role: MessageRole.assistant,
        content: ChatScreenConstants.defaultErrorMessage,
        timestamp: DateTime.now(),
        isComplete: true,
      );
      await _chatStorageService.addMessageToChat(chat.id, errorMessage);
      final chatFromStorage = await _chatStorageService.getChat(chat.id);
      if (chatFromStorage != null) {
        // Chat is already updated in chatListProvider below
      }
      ref
          .read(chatListProvider.notifier)
          .updateChat(
            chat.copyWith(
              messages: [...chat.messages, errorMessage],
              updatedAt: DateTime.now(),
            ),
          );
    }
  }

  Future<void> _streamAIResponse(Chat chat, {String? delegateAgentId}) async {
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

    final modelSettingsNotifier = ref.read(modelSettingsProvider.notifier);
    final settings = await modelSettingsNotifier.getSettings(selectedModelId);

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
      } else if (settings.systemPrompt != null && messages.isNotEmpty) {
        messages.insert(0, {
          'role': 'system',
          'content': settings.systemPrompt!,
        });
      }
    }

    await _handleStreamingResponse(
      chat: chat,
      messages: messages,
      isContinuation: false,
      modelId: selectedModelId,
      modelSettings: settings,
    );
  }

  void _continueAIResponse(String lastMessageId) async {
    if (currentChat == null) return;
    ref.read(chatScreenProvider.notifier).hideSuggestions();

    final lastMessage = currentChat!.messages.lastWhere(
      (msg) => msg.role == MessageRole.assistant && msg.id == lastMessageId,
      orElse: () => currentChat!.messages.first,
    );
    if (lastMessage.content.isEmpty) return;

    final continuationMessage = _createAssistantMessage();
    await _chatStorageService.addMessageToChat(
      currentChat!.id,
      continuationMessage,
    );
    final chatFromStorage = await _chatStorageService.getChat(currentChat!.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: true);
    });
    await _streamContinuationResponse(lastMessage.content, chatFromStorage!);
  }

  Future<void> _streamContinuationResponse(
    String previousContent,
    Chat chatArg,
  ) async {
    final continuationPrompt = [
      {'role': 'user', 'content': 'Please continue your previous response.'},
      {'role': 'assistant', 'content': previousContent},
      {'role': 'user', 'content': 'Continue from where you left off.'},
    ];
    final modelSettingsNotifier = ref.read(modelSettingsProvider.notifier);
    final settings = await modelSettingsNotifier.getSettings(selectedModelId);
    if (settings.systemPrompt != null) {
      continuationPrompt.insert(0, {
        'role': 'system',
        'content': settings.systemPrompt!,
      });
    }
    await _handleStreamingResponse(
      chat: chatArg,
      messages: continuationPrompt,
      isContinuation: true,
      modelId: selectedModelId,
      modelSettings: settings,
    );
  }
}
