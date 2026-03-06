import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/chat_storage_service.dart';

class ChatState {
  final List<Chat> chats;
  final Chat? currentChat;
  final bool isLoading;
  final bool isStreaming;
  final String? error;
  final String selectedModelId;
  final List<String> continuationSuggestions;
  final bool showSuggestions;
  final bool showWelcomeSuggestions;
  final List<String> welcomeSuggestions;
  final List<String> filteredChats;
  final String searchQuery;

  const ChatState({
    this.chats = const [],
    this.currentChat,
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
    this.selectedModelId = '',
    this.continuationSuggestions = const [],
    this.showSuggestions = false,
    this.showWelcomeSuggestions = false,
    this.welcomeSuggestions = const [],
    this.filteredChats = const [],
    this.searchQuery = '',
  });

  ChatState copyWith({
    List<Chat>? chats,
    Chat? currentChat,
    bool? isLoading,
    bool? isStreaming,
    String? error,
    String? selectedModelId,
    List<String>? continuationSuggestions,
    bool? showSuggestions,
    bool? showWelcomeSuggestions,
    List<String>? welcomeSuggestions,
    List<String>? filteredChats,
    String? searchQuery,
    bool clearCurrentChat = false,
    bool clearError = false,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      currentChat: clearCurrentChat ? null : (currentChat ?? this.currentChat),
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: clearError ? null : (error ?? this.error),
      selectedModelId: selectedModelId ?? this.selectedModelId,
      continuationSuggestions:
          continuationSuggestions ?? this.continuationSuggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      showWelcomeSuggestions:
          showWelcomeSuggestions ?? this.showWelcomeSuggestions,
      welcomeSuggestions: welcomeSuggestions ?? this.welcomeSuggestions,
      filteredChats: filteredChats ?? this.filteredChats,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ChatStateNotifier extends Notifier<ChatState> {
  late ChatStorageService _storageService;

  @override
  ChatState build() {
    _storageService = ChatStorageService();
    _loadChats();
    return const ChatState(isLoading: true);
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _storageService.getChats();
      state = state.copyWith(
        chats: chats,
        isLoading: false,
        showWelcomeSuggestions: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshChats() async {
    await _loadChats();
  }

  Future<void> selectChat(String chatId) async {
    final chat = state.chats.firstWhere(
      (c) => c.id == chatId,
      orElse: () => state.chats.first,
    );

    state = state.copyWith(
      currentChat: chat,
      showWelcomeSuggestions: chat.messages.isEmpty,
      showSuggestions: false,
      continuationSuggestions: [],
    );
  }

  void clearCurrentChat() {
    state = state.copyWith(
      clearCurrentChat: true,
      showSuggestions: false,
      continuationSuggestions: [],
    );
  }

  Future<Chat> createNewChat() async {
    final newChat = _storageService.newChat();
    await _storageService.addChat(newChat);

    state = state.copyWith(
      chats: [newChat, ...state.chats],
      currentChat: newChat,
      showWelcomeSuggestions: true,
      showSuggestions: false,
      continuationSuggestions: [],
    );

    return newChat;
  }

  Future<void> deleteChat(String chatId) async {
    await _storageService.deleteChat(chatId);

    final updatedChats = state.chats.where((c) => c.id != chatId).toList();
    final shouldClearCurrent = state.currentChat?.id == chatId;

    state = state.copyWith(
      chats: updatedChats,
      clearCurrentChat: shouldClearCurrent,
    );
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    await _storageService.renameChat(chatId, newTitle);

    final updatedChats = state.chats.map((c) {
      if (c.id == chatId) {
        return c.copyWith(title: newTitle, updatedAt: DateTime.now());
      }
      return c;
    }).toList();

    final updatedCurrentChat = state.currentChat?.id == chatId
        ? state.currentChat?.copyWith(
            title: newTitle,
            updatedAt: DateTime.now(),
          )
        : state.currentChat;

    state = state.copyWith(
      chats: updatedChats,
      currentChat: updatedCurrentChat,
    );
  }

  Future<void> addMessage(Message message) async {
    if (state.currentChat == null) return;

    await _storageService.addMessageToChat(state.currentChat!.id, message);

    final updatedChat = state.currentChat!.copyWith(
      messages: [...state.currentChat!.messages, message],
      updatedAt: DateTime.now(),
    );

    _updateCurrentChat(updatedChat);
  }

  Future<void> updateLastMessage(Message message) async {
    if (state.currentChat == null) return;

    await _storageService.updateMessageInChat(
      state.currentChat!.id,
      message.id,
      message,
    );

    final messages = List<Message>.from(state.currentChat!.messages);
    if (messages.isNotEmpty) {
      messages[messages.length - 1] = message;
    }

    final updatedChat = state.currentChat!.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );

    _updateCurrentChat(updatedChat);
  }

  Future<void> deleteMessage(String messageId) async {
    if (state.currentChat == null) return;

    await _storageService.deleteMessageFromChat(
      state.currentChat!.id,
      messageId,
    );

    final updatedMessages = state.currentChat!.messages
        .where((m) => m.id != messageId)
        .toList();

    final updatedChat = state.currentChat!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    _updateCurrentChat(updatedChat);
  }

  void _updateCurrentChat(Chat chat) {
    final updatedChats = state.chats.map((c) {
      if (c.id == chat.id) return chat;
      return c;
    }).toList();

    state = state.copyWith(chats: updatedChats, currentChat: chat);
  }

  void setStreaming(bool isStreaming) {
    state = state.copyWith(isStreaming: isStreaming);
  }

  void setSelectedModel(String modelId) {
    state = state.copyWith(selectedModelId: modelId);
  }

  void setContinuationSuggestions(List<String> suggestions) {
    state = state.copyWith(
      continuationSuggestions: suggestions,
      showSuggestions: suggestions.isNotEmpty,
    );
  }

  void hideSuggestions() {
    state = state.copyWith(showSuggestions: false, continuationSuggestions: []);
  }

  void setWelcomeSuggestions(List<String> suggestions) {
    state = state.copyWith(
      welcomeSuggestions: suggestions,
      showWelcomeSuggestions: suggestions.isNotEmpty,
    );
  }

  void hideWelcomeSuggestions() {
    state = state.copyWith(
      showWelcomeSuggestions: false,
      welcomeSuggestions: [],
    );
  }

  void setSearchQuery(String query) {
    final filtered = query.isEmpty
        ? state.chats.map((c) => c.id).toList()
        : state.chats
              .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
              .map((c) => c.id)
              .toList();

    state = state.copyWith(searchQuery: query, filteredChats: filtered);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '', filteredChats: []);
  }

  Future<Chat?> getChat(String chatId) async {
    return await _storageService.getChat(chatId);
  }
}

final chatStateProvider = NotifierProvider<ChatStateNotifier, ChatState>(
  ChatStateNotifier.new,
);

final currentChatProvider = Provider<Chat?>((ref) {
  return ref.watch(chatStateProvider).currentChat;
});

final isStreamingProvider = Provider<bool>((ref) {
  return ref.watch(chatStateProvider).isStreaming;
});

final continuationSuggestionsProvider = Provider<List<String>>((ref) {
  return ref.watch(chatStateProvider).continuationSuggestions;
});

final showSuggestionsProvider = Provider<bool>((ref) {
  return ref.watch(chatStateProvider).showSuggestions;
});

final welcomeSuggestionsProvider = Provider<List<String>>((ref) {
  return ref.watch(chatStateProvider).welcomeSuggestions;
});

final showWelcomeSuggestionsProvider = Provider<bool>((ref) {
  return ref.watch(chatStateProvider).showWelcomeSuggestions;
});
