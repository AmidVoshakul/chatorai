import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/constants/chat_constants.dart';

class ChatScreenState {
  final Chat? currentChat;
  final String selectedModelId;
  final List<Chat> chats;
  final bool isStreaming;
  final bool isSuggestionsLoading;
  final bool showSuggestions;
  final bool showWelcomeSuggestions;
  final List<String> continuationSuggestions;
  final List<String> welcomeSuggestions;
  final bool isSidebarCollapsed;
  final bool isNavigatorVisible;
  final List<String> navigatorHeadings;
  final int activeHeadingIndex;

  const ChatScreenState({
    this.currentChat,
    this.selectedModelId = ChatScreenConstants.defaultModelId,
    this.chats = const [],
    this.isStreaming = false,
    this.isSuggestionsLoading = false,
    this.showSuggestions = false,
    this.showWelcomeSuggestions = false,
    this.continuationSuggestions = const [],
    this.welcomeSuggestions = const [],
    this.isSidebarCollapsed = true,
    this.isNavigatorVisible = false,
    this.navigatorHeadings = const [],
    this.activeHeadingIndex = -1,
  });

  ChatScreenState copyWith({
    Chat? currentChat,
    bool clearCurrentChat = false,
    String? selectedModelId,
    List<Chat>? chats,
    bool? isStreaming,
    bool? isSuggestionsLoading,
    bool? showSuggestions,
    bool? showWelcomeSuggestions,
    List<String>? continuationSuggestions,
    List<String>? welcomeSuggestions,
    bool? isSidebarCollapsed,
    bool? isNavigatorVisible,
    List<String>? navigatorHeadings,
    int? activeHeadingIndex,
  }) {
    return ChatScreenState(
      currentChat: clearCurrentChat ? null : (currentChat ?? this.currentChat),
      selectedModelId: selectedModelId ?? this.selectedModelId,
      chats: chats ?? this.chats,
      isStreaming: isStreaming ?? this.isStreaming,
      isSuggestionsLoading: isSuggestionsLoading ?? this.isSuggestionsLoading,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      showWelcomeSuggestions:
          showWelcomeSuggestions ?? this.showWelcomeSuggestions,
      continuationSuggestions:
          continuationSuggestions ?? this.continuationSuggestions,
      welcomeSuggestions: welcomeSuggestions ?? this.welcomeSuggestions,
      isSidebarCollapsed: isSidebarCollapsed ?? this.isSidebarCollapsed,
      isNavigatorVisible: isNavigatorVisible ?? this.isNavigatorVisible,
      navigatorHeadings: navigatorHeadings ?? this.navigatorHeadings,
      activeHeadingIndex: activeHeadingIndex ?? this.activeHeadingIndex,
    );
  }
}

class ChatScreenNotifier extends StateNotifier<ChatScreenState> {
  final ChatStorageService _storageService;

  ChatScreenNotifier(this._storageService) : super(const ChatScreenState());

  Future<void> loadChats() async {
    final chats = await _storageService.getChats();
    state = state.copyWith(chats: chats);
  }

  void setCurrentChat(Chat? chat) {
    state = state.copyWith(currentChat: chat, clearCurrentChat: chat == null);
  }

  void updateCurrentChat(Chat chat) {
    state = state.copyWith(currentChat: chat);
    final index = state.chats.indexWhere((c) => c.id == chat.id);
    if (index != -1) {
      final newChats = List<Chat>.from(state.chats);
      newChats[index] = chat;
      state = state.copyWith(chats: newChats);
    }
  }

  void addChat(Chat chat) {
    state = state.copyWith(chats: [chat, ...state.chats]);
  }

  void removeChat(String chatId) {
    final newChats = state.chats.where((c) => c.id != chatId).toList();
    final clearCurrent = state.currentChat?.id == chatId;
    state = state.copyWith(chats: newChats, clearCurrentChat: clearCurrent);
  }

  void setSelectedModel(String modelId) {
    state = state.copyWith(selectedModelId: modelId);
  }

  void setStreaming(bool isStreaming) {
    state = state.copyWith(isStreaming: isStreaming);
  }

  void setSuggestionsLoading(bool loading) {
    state = state.copyWith(isSuggestionsLoading: loading);
  }

  void showContinuationSuggestions(List<String> suggestions) {
    state = state.copyWith(
      showSuggestions: suggestions.isNotEmpty,
      continuationSuggestions: suggestions,
    );
  }

  void hideSuggestions() {
    state = state.copyWith(showSuggestions: false, continuationSuggestions: []);
  }

  void showWelcomeSuggestions(List<String> suggestions) {
    state = state.copyWith(
      showWelcomeSuggestions: suggestions.isNotEmpty,
      welcomeSuggestions: suggestions,
    );
  }

  void hideWelcomeSuggestions() {
    state = state.copyWith(
      showWelcomeSuggestions: false,
      welcomeSuggestions: [],
    );
  }

  void hideAllSuggestions() {
    state = state.copyWith(
      showSuggestions: false,
      showWelcomeSuggestions: false,
      continuationSuggestions: [],
      welcomeSuggestions: [],
    );
  }

  void setSidebarCollapsed(bool collapsed) {
    state = state.copyWith(isSidebarCollapsed: collapsed);
  }

  void toggleNavigator() {
    state = state.copyWith(isNavigatorVisible: !state.isNavigatorVisible);
  }

  void setNavigatorVisible(bool visible) {
    state = state.copyWith(isNavigatorVisible: visible);
  }

  void setNavigatorHeadings(List<String> headings) {
    state = state.copyWith(navigatorHeadings: headings);
  }

  void setActiveHeadingIndex(int index) {
    state = state.copyWith(activeHeadingIndex: index);
  }
}
