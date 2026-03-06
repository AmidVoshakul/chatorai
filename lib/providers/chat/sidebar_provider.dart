import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/providers/chat/chat_providers.dart';
import 'package:chatorai/services/chat_storage_service.dart';

class SidebarState {
  final String searchQuery;
  final bool isSearching;

  const SidebarState({this.searchQuery = '', this.isSearching = false});

  SidebarState copyWith({String? searchQuery, bool? isSearching}) {
    return SidebarState(
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class SidebarNotifier extends Notifier<SidebarState> {
  late final ChatStorageService _storageService;

  @override
  SidebarState build() {
    _storageService = ChatStorageService();
    return const SidebarState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, isSearching: query.isNotEmpty);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '', isSearching: false);
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    await _storageService.renameChat(chatId, newTitle);
    ref.read(chatListProvider.notifier).renameChat(chatId, newTitle);
  }

  Future<void> deleteChat(String chatId) async {
    await ref.read(chatListProvider.notifier).deleteChat(chatId);
  }
}

final sidebarProvider = NotifierProvider<SidebarNotifier, SidebarState>(
  SidebarNotifier.new,
);

final filteredChatsProvider = Provider<List<Chat>>((ref) {
  final sidebarState = ref.watch(sidebarProvider);
  final chatsAsync = ref.watch(chatListProvider);

  return chatsAsync.when(
    data: (chats) {
      if (sidebarState.searchQuery.isEmpty) {
        return chats;
      }
      return chats
          .where(
            (chat) => chat.title.toLowerCase().contains(
              sidebarState.searchQuery.toLowerCase(),
            ),
          )
          .toList();
    },
    loading: () => [],
    error: (e, st) => [],
  );
});
