part of 'chat_screen.dart';

extension _ChatScreenManagementExt on _ChatScreenState {
  Future<void> _createNewChat() async {
    final newChat = await ref.read(chatListProvider.notifier).createNewChat();
    ref.read(currentChatIdProvider.notifier).setChatId(newChat.id);
    _showWelcomeSuggestions();
  }

  void _selectChat(String chatId) {
    final chatListAsync = ref.read(chatListProvider);
    final chat = chatListAsync.whenOrNull(
      data: (chats) {
        try {
          return chats.firstWhere((c) => c.id == chatId);
        } catch (_) {
          return null;
        }
      },
    );
    if (chat == null) return;
    ref.read(currentChatIdProvider.notifier).setChatId(chatId);
    if (chat.messages.isEmpty) {
      _showWelcomeSuggestions();
    } else {
      ref.read(chatScreenProvider.notifier).hideAllSuggestions();
    }
    _chatScrollUtils?.scrollToBottom();
  }

  Future<void> _deleteChat(String chatId) async {
    final chatListAsync = ref.read(chatListProvider);
    final chat = chatListAsync.whenOrNull(
      data: (chats) => chats.firstWhere((c) => c.id == chatId),
    );
    if (chat == null) return;

    final localizations = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => KeyboardHandlerDialog(
        onEnter: () => Navigator.pop(dialogContext, true),
        onEscape: () => Navigator.pop(dialogContext, false),
        child: AlertDialog(
          title: Text(localizations.deleteChat),
          content: Text(localizations.confirmDeleteMessage(chat.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                localizations.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete == true) {
      final wasCurrentChat = currentChat != null && currentChat!.id == chatId;
      await ref.read(chatListProvider.notifier).deleteChat(chatId);
      if (wasCurrentChat && mounted) {
        ref.read(currentChatIdProvider.notifier).setChatId(null);
        _showWelcomeSuggestions();
      }
    }
  }
}
