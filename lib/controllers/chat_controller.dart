import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/widgets/chat/welcome_questions_data.dart';
import 'package:chatorai/utils/logger.dart';

final _logger = LogTags.chat;

class ChatController extends ChangeNotifier {
  final ChatStorageService _storageService;
  final VoidCallback onStateChanged;
  final void Function(Chat chat)? onScrollToBottom;
  final void Function(Chat chat)? onShowWelcomeSuggestions;
  final void Function()? onResetSlidingAppBar;
  final void Function(String chatId)? onDeletedChat;

  List<Chat> _chats = [];
  Chat? _currentChat;
  List<String> _welcomeSuggestions = [];
  bool _showWelcomeSuggestions = false;
  List<String> _continuationSuggestions = [];
  bool _showSuggestions = false;

  ChatController({
    required ChatStorageService storageService,
    required this.onStateChanged,
    this.onScrollToBottom,
    this.onShowWelcomeSuggestions,
    this.onResetSlidingAppBar,
    this.onDeletedChat,
  }) : _storageService = storageService;

  List<Chat> get chats => _chats;
  Chat? get currentChat => _currentChat;
  List<String> get welcomeSuggestions => _welcomeSuggestions;
  bool get showWelcomeSuggestions => _showWelcomeSuggestions;
  List<String> get continuationSuggestions => _continuationSuggestions;
  bool get showSuggestions => _showSuggestions;

  Future<void> loadChats() async {
    try {
      _chats = await _storageService.getChats();
      // Note: showWelcomeSuggestionsForEmptyState needs BuildContext
      // so it's called separately with context
      onStateChanged();
    } catch (e) {
      _logger.logError('[ChatController] Error loading chats: $e');
    }
  }

  void updateCurrentChat(Chat updatedChat) {
    _currentChat = updatedChat;
    final index = _chats.indexWhere((c) => c.id == updatedChat.id);
    if (index != -1) {
      _chats[index] = updatedChat;
    }
    onStateChanged();
  }

  Future<void> createNewChat() async {
    final newChat = _storageService.newChat();
    await _storageService.addChat(newChat);

    _currentChat = newChat;
    _chats = [newChat, ..._chats];
    onResetSlidingAppBar?.call();
    onStateChanged();
  }

  void showWelcomeSuggestionsForNewChat(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final questions = WelcomeQuestionsData.getRandomQuestions(
        context,
        count: 4,
      );

      _welcomeSuggestions = questions;
      _showWelcomeSuggestions = true;
      _showSuggestions = false;
      _continuationSuggestions.clear();
      onStateChanged();
    });
  }

  void showWelcomeSuggestionsForEmptyState(BuildContext context) {
    final questions = WelcomeQuestionsData.getRandomQuestions(
      context,
      count: 4,
    );

    _welcomeSuggestions = questions;
    _showWelcomeSuggestions = true;
    _currentChat = null;
    _showSuggestions = false;
    _continuationSuggestions.clear();
    onStateChanged();
  }

  void selectChat(String chatId, BuildContext context) {
    final chat = _chats.firstWhere((c) => c.id == chatId);

    _currentChat = chat;
    _showWelcomeSuggestions = false;
    _welcomeSuggestions.clear();

    if (chat.messages.isEmpty) {
      showWelcomeSuggestionsForNewChat(context);
    }

    onScrollToBottom?.call(chat);
    onStateChanged();
  }

  Future<void> deleteChat(String chatId) async {
    await _storageService.deleteChat(chatId);
    await loadChats();

    if (_currentChat?.id == chatId) {
      _currentChat = null;
      onStateChanged();
    }

    onDeletedChat?.call(chatId);
  }

  Future<void> refreshChatMessages() async {
    if (_currentChat != null) {
      try {
        final updatedChat = await _storageService.getChat(_currentChat!.id);
        if (updatedChat != null) {
          updateCurrentChat(updatedChat);
        }
      } catch (e) {
        _logger.logError('[ChatController] Error refreshing chat messages: $e');
      }
    }
  }

  void hideSuggestions() {
    _showSuggestions = false;
    _continuationSuggestions.clear();
    onStateChanged();
  }

  void hideWelcomeSuggestions() {
    _showWelcomeSuggestions = false;
    _welcomeSuggestions.clear();
    onStateChanged();
  }

  void setContinuationSuggestions(List<String> suggestions) {
    _continuationSuggestions = suggestions;
    _showSuggestions = true;
    onStateChanged();
  }

  void setCurrentChat(Chat? chat) {
    _currentChat = chat;
    onStateChanged();
  }
}
