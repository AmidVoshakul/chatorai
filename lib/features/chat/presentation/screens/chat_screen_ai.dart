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
    final sessionRepository = await ref.read(sessionRepositoryProvider.future);
    final sessionId = chat.toSessionId();
    for (final msgId in messagesToDelete) {
      await sessionRepository.appendEvent(
        MessageDeleted(
          sessionId: sessionId,
          messageId: msgId,
          timestamp: DateTime.now(),
        ),
      );
    }

    final chatAfterDelete = chat.copyWith(
      messages: chat.messages.sublist(0, messageIndex),
      updatedAt: DateTime.now(),
    );

    // Auto-generate session title from the first user message when the chat
    // still carries the localized default title.
    if (mounted) {
      if (chatAfterDelete.isDefaultTitle) {
        await _autoGenerateTitleIfNeeded(chatAfterDelete);
      }
    }

    // Appends the assistant placeholder and streams the regenerated response
    // into the same session as the deleted messages (no duplicate session).
    await _startAssistantTurn(
      chat: chatAfterDelete,
      sessionId: sessionId.value,
      agentName: ref.read(currentAgentProvider).name,
      buildMessages: (withPlaceholder) => _buildApiMessages(withPlaceholder),
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

    final sessionId = currentChat!.toSessionId();

    // Auto-generate session title from the first user message when the chat
    // still carries the localized default title.
    if (mounted) {
      final chatToCheck = currentChat;
      if (chatToCheck != null && chatToCheck.isDefaultTitle) {
        await _autoGenerateTitleIfNeeded(chatToCheck);
      }
    }

    final chatFromStorage = currentChat;
    if (chatFromStorage == null) return;

    // Appends the continuation placeholder and streams into it, reusing the
    // placeholder id so no second assistant message is created on reload.
    await _startAssistantTurn(
      chat: chatFromStorage,
      sessionId: sessionId.value,
      agentName: ref.read(currentAgentProvider).name,
      isContinuation: true,
      buildMessages: (withPlaceholder) {
        final continuationPrompt = _buildApiMessages(withPlaceholder);
        // Replace last assistant content with continue instruction
        if (continuationPrompt.isNotEmpty) {
          continuationPrompt[continuationPrompt.length - 1] = {
            'role': 'user',
            'content': 'Please continue your previous response.',
          };
        } else {
          continuationPrompt.addAll([
            {
              'role': 'user',
              'content': 'Please continue your previous response.',
            },
            {'role': 'assistant', 'content': lastMessage.content},
            {'role': 'user', 'content': 'Continue from where you left off.'},
          ]);
        }
        return continuationPrompt;
      },
    );
  }
}
