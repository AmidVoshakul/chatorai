part of 'chat_screen.dart';

extension _ChatScreenEditsExt on _ChatScreenState {
  Future<void> _handleMessageEdited(String messageId, String newContent) async {
    if (currentChat == null) return;
    final messages = currentChat!.messages;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final editedMessage = messages[messageIndex].copyWith(content: newContent);
    final sessionRepository = await ref.read(sessionRepositoryProvider.future);
    final sessionId = currentChat!.toSessionId();
    await sessionRepository.appendEvent(
      MessageUpdated(
        sessionId: sessionId,
        messageId: messageId,
        content: editedMessage.content,
        reasoning: editedMessage.reasoning,
        model: editedMessage.model,
        error: editedMessage.isError ? editedMessage.content : null,
        timestamp: editedMessage.timestamp,
      ),
    );
    final updatedMessages = List<Message>.from(messages)
      ..[messageIndex] = editedMessage;
    final updatedChat = currentChat!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
    ref.read(chatListProvider.notifier).updateChat(updatedChat);

    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message: localizations.messageEditedSuccessfully,
      icon: Icons.edit,
    );
  }

  Future<void> _handleMessageEditAndSend(
    String messageId,
    String newContent,
  ) async {
    if (currentChat == null) return;
    ref.read(chatScreenProvider.notifier).hideSuggestions();

    final messages = currentChat!.messages;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final editedUserMessage = messages[messageIndex].copyWith(
      content: newContent,
    );
    final sessionRepository = await ref.read(sessionRepositoryProvider.future);
    final sessionId = currentChat!.toSessionId();
    await sessionRepository.appendEvent(
      MessageUpdated(
        sessionId: sessionId,
        messageId: messageId,
        content: editedUserMessage.content,
        reasoning: editedUserMessage.reasoning,
        model: editedUserMessage.model,
        error: editedUserMessage.isError ? editedUserMessage.content : null,
        timestamp: editedUserMessage.timestamp,
      ),
    );

    for (int i = messages.length - 1; i > messageIndex; i--) {
      await sessionRepository.appendEvent(
        MessageDeleted(
          sessionId: sessionId,
          messageId: messages[i].id,
          timestamp: DateTime.now(),
        ),
      );
    }

    final messagesBeforeEdit = messages.sublist(0, messageIndex + 1);
    messagesBeforeEdit[messageIndex] = editedUserMessage;
    final updatedChat = currentChat!.copyWith(
      messages: messagesBeforeEdit,
      updatedAt: DateTime.now(),
    );

    // Appends the assistant placeholder, updates the chat list and streams
    // into that exact message id (no duplicate bubbles on reload).
    await _startAssistantTurn(
      chat: updatedChat,
      sessionId: sessionId.value,
      agentName: ref.read(currentAgentProvider).name,
      buildMessages: (withPlaceholder) => _buildApiMessages(withPlaceholder),
    );

    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message: localizations.messageEditedAndResponseRegenerated,
      icon: Icons.refresh,
    );
  }
}
