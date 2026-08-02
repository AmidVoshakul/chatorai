import 'dart:async';

import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// STATE
// ===========================================================================

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

// ===========================================================================
// NOTIFIER
// ===========================================================================

class SidebarNotifier extends Notifier<SidebarState> {
  Timer? _debounceTimer;

  @override
  SidebarState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const SidebarState();
  }

  void setSearchQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query, isSearching: query.isNotEmpty);
    });
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = state.copyWith(searchQuery: '', isSearching: false);
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    await ref.read(chatListProvider.notifier).renameChat(chatId, newTitle);
  }

  Future<void> deleteChat(String chatId) async {
    await ref.read(chatListProvider.notifier).deleteChat(chatId);
  }
}

// ===========================================================================
// PROVIDERS
// ===========================================================================

final sidebarProvider = NotifierProvider<SidebarNotifier, SidebarState>(
  SidebarNotifier.new,
);

final chatListLoadingProvider = Provider<bool>((ref) {
  return ref.watch(chatListProvider).isLoading;
});

final filteredChatsProvider = Provider<List<Chat>>((ref) {
  final searchQuery = ref.watch(sidebarProvider.select((s) => s.searchQuery));
  final chatsAsync = ref.watch(chatListProvider);

  return chatsAsync.when(
    data: (chats) {
      if (searchQuery.isEmpty) {
        return chats;
      }
      final lowerQuery = searchQuery.toLowerCase();
      return chats
          .where((chat) => chat.title.toLowerCase().contains(lowerQuery))
          .toList();
    },
    loading: () => const [],
    error: (e, st) => const [],
  );
});
