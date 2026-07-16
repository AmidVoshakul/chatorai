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

    final messagesToDelete = chat.messages
        .sublist(messageIndex)
        .map((m) => m.id)
        .toList();
    for (final msgId in messagesToDelete) {
      await _chatStorageService.deleteMessageFromChat(chat.id, msgId);
    }

    final updatedMessages = chat.messages.sublist(0, messageIndex);
    final agentName = ref.read(currentAgentProvider).name;
    final newAssistantMessage = _createAssistantMessage(agent: agentName);
    final chatWithPlaceholder = chat.copyWith(
      messages: [...updatedMessages, newAssistantMessage],
      updatedAt: DateTime.now(),
    );

    _chatStorageService.addMessageToChat(chat.id, newAssistantMessage);
    ref.read(chatListProvider.notifier).updateChat(chatWithPlaceholder);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollEnabled = true;
      _scrollToBottom(force: true);
    });

    final messages = _buildApiMessages(chatWithPlaceholder);
    await _initiateStream(
      chat: chatWithPlaceholder,
      messages: messages,
      isContinuation: false,
      delegateAgentId: null,
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

    final continuationMessage = _createAssistantMessage(
      agent: ref.read(currentAgentProvider).name,
    );
    await _chatStorageService.addMessageToChat(
      currentChat!.id,
      continuationMessage,
    );
    final chatFromStorage = await _chatStorageService.getChat(currentChat!.id);
    if (chatFromStorage == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollEnabled = true;
      _scrollToBottom(force: true);
    });

    final continuationPrompt = _buildApiMessages(chatFromStorage);
    // Replace last assistant content with continue instruction
    if (continuationPrompt.isNotEmpty) {
      continuationPrompt[continuationPrompt.length - 1] = {
        'role': 'user',
        'content': 'Please continue your previous response.',
      };
    } else {
      continuationPrompt.addAll([
        {'role': 'user', 'content': 'Please continue your previous response.'},
        {'role': 'assistant', 'content': lastMessage.content},
        {'role': 'user', 'content': 'Continue from where you left off.'},
      ]);
    }
    await _initiateStream(
      chat: chatFromStorage,
      messages: continuationPrompt,
      isContinuation: true,
      delegateAgentId: null,
    );
  }
}
