part of 'chat_screen.dart';

extension _ChatScreenManagementExt on _ChatScreenState {
  Future<void> _createNewChat() async {
    final newChat = await ref.read(chatListProvider.notifier).createNewChat();
    ref.read(currentChatIdProvider.notifier).setChatId(newChat.id);
    ref.read(permissionServiceProvider).clearSession();
    _showWelcomeSuggestions();
  }

  Future<void> _selectChat(String chatId) async {
    _pendingSelectChatId = chatId;
    final chat = await ref
        .read(chatListProvider.notifier)
        .ensureChatLoaded(chatId);
    if (chat == null || !mounted || _pendingSelectChatId != chatId) {
      _pendingSelectChatId = null;
      return;
    }
    _pendingSelectChatId = null;
    ref.read(currentChatIdProvider.notifier).setChatId(chatId);
    if (chat.isDefaultTitle && chat.messages.isEmpty) {
      _showWelcomeSuggestions();
    } else {
      ref.read(chatScreenProvider.notifier).hideAllSuggestions();
    }
    _scrollToBottom(force: true);
  }

  Future<void> _deleteChat(String chatId) async {
    final chatListAsync = ref.read(chatListProvider);
    final chat = chatListAsync.whenOrNull(
      data: (chats) => chats.firstWhere((c) => c.id == chatId),
    );
    if (chat == null) return;

    final localizations = AppLocalizations.of(context)!;
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
