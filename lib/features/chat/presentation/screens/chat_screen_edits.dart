part of 'chat_screen.dart';

extension _ChatScreenEditsExt on _ChatScreenState {
  Future<void> _handleMessageEdited(String messageId, String newContent) async {
    if (currentChat == null) return;
    final messages = currentChat!.messages;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final editedMessage = messages[messageIndex].copyWith(content: newContent);
    await _chatStorageService.updateMessageInChat(
      currentChat!.id,
      messageId,
      editedMessage,
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
    await _chatStorageService.updateMessageInChat(
      currentChat!.id,
      messageId,
      editedUserMessage,
    );

    for (int i = messages.length - 1; i > messageIndex; i--) {
      await _chatStorageService.deleteMessageFromChat(
        currentChat!.id,
        messages[i].id,
      );
    }

    final messagesBeforeEdit = messages.sublist(0, messageIndex + 1);
    messagesBeforeEdit[messageIndex] = editedUserMessage;
    final updatedChat = currentChat!.copyWith(
      messages: messagesBeforeEdit,
      updatedAt: DateTime.now(),
    );

    final assistantMessage = _createAssistantMessage(
      agent: ref.read(currentAgentProvider).name,
    );
    final chatWithAssistant = updatedChat.copyWith(
      messages: [...messagesBeforeEdit, assistantMessage],
      updatedAt: DateTime.now(),
    );

    await _chatStorageService.addMessageToChat(
      currentChat!.id,
      assistantMessage,
    );
    ref.read(chatListProvider.notifier).updateChat(chatWithAssistant);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollEnabled = true;
      _scrollToBottom(force: true);
    });

    final apiMessages = _buildApiMessages(chatWithAssistant);
    await _initiateStream(
      chat: chatWithAssistant,
      messages: apiMessages,
      isContinuation: false,
      delegateAgentId: null,
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
