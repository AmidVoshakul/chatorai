import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/providers/chat/chat_repository.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/services/chat_ai_service.dart';
import 'package:chatorai/providers/model_provider.dart';

// ===========================================================================
// SERVICE PROVIDERS
// ===========================================================================

final chatStorageServiceProvider = Provider<ChatStorageService>((ref) {
  return ChatStorageService();
});

final chatAiServiceProvider = Provider<ChatAiService>((ref) {
  final client = ref.watch(openRouterServiceProvider);
  return ChatAiService(client: client);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final storageService = ref.watch(chatStorageServiceProvider);
  return ChatRepository(storageService: storageService);
});

// ===========================================================================
// CHAT LIST PROVIDER
// ===========================================================================

final chatListProvider =
    NotifierProvider<ChatListNotifier, AsyncValue<List<Chat>>>(
      ChatListNotifier.new,
    );

// ===========================================================================
// CHAT LIST NOTIFIER
// ===========================================================================

class ChatListNotifier extends Notifier<AsyncValue<List<Chat>>> {
  bool _isLoadingChats = false;
  bool _hasLoadedOnce = false;
  Future<void>? _loadFuture;

  @override
  AsyncValue<List<Chat>> build() {
    final repository = ref.watch(chatRepositoryProvider);
    // Only start loading if we haven't loaded yet
    if (!_hasLoadedOnce) {
      _loadFuture = _loadChats(repository);
      return const AsyncValue.loading();
    }
    // Return current state if already loaded
    return state;
  }

  Future<void> _loadChats(ChatRepository repository) async {
    // If already loading, wait for the existing load to complete
    if (_isLoadingChats && _loadFuture != null) {
      await _loadFuture;
      return;
    }

    if (_hasLoadedOnce) {
      return;
    }

    _isLoadingChats = true;
    try {
      final chats = await repository.getChats();
      state = AsyncValue.data(chats);
      _hasLoadedOnce = true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingChats = false;
      _loadFuture = null;
    }
  }

  Future<void> loadChats({bool forceReload = false}) async {
    if (forceReload) {
      _hasLoadedOnce = false;
    }
    final repository = ref.read(chatRepositoryProvider);
    await _loadChats(repository);
  }

  Future<Chat> createNewChat() async {
    // Wait for initial load to complete if not already loaded
    // This prevents race condition where new chat gets overwritten
    if (!_hasLoadedOnce) {
      final repository = ref.read(chatRepositoryProvider);
      await _loadChats(repository);
    }

    final repository = ref.read(chatRepositoryProvider);
    final newChat = await repository.createNewChat();

    // Get current state AFTER load completes
    final currentState = state;
    if (currentState.hasValue) {
      final chats = currentState.value!;
      state = AsyncValue.data([newChat, ...chats]);
    } else if (currentState.isLoading) {
      // This should not happen after waiting for load
      state = AsyncValue.data([newChat]);
    } else if (currentState.hasError) {
      // If there was an error, start with the new chat
      state = AsyncValue.data([newChat]);
    }

    return newChat;
  }

  Future<void> deleteChat(String chatId) async {
    final repository = ref.read(chatRepositoryProvider);
    await repository.deleteChat(chatId);
    state.whenData((chats) {
      state = AsyncValue.data(chats.where((c) => c.id != chatId).toList());
    });
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    final repository = ref.read(chatRepositoryProvider);
    await repository.renameChat(chatId, newTitle);
    state.whenData((chats) {
      state = AsyncValue.data(
        chats.map((c) {
          if (c.id == chatId) {
            return c.copyWith(title: newTitle, updatedAt: DateTime.now());
          }
          return c;
        }).toList(),
      );
    });
  }

  void updateChat(Chat updatedChat) {
    final currentState = state;

    // Handle case where state has value
    if (currentState.hasValue) {
      final chats = currentState.value!;
      final index = chats.indexWhere((c) => c.id == updatedChat.id);
      if (index != -1) {
        final newChats = List<Chat>.from(chats);
        newChats[index] = updatedChat;
        state = AsyncValue.data(newChats);
        // Persist to storage
        ref.read(chatRepositoryProvider).updateChat(updatedChat);
      }
    }
    // Handle case where state is loading - store update for later
    else if (currentState.isLoading) {
      // Queue the update by creating a new state with the updated chat
      // This ensures the update is not lost
      state = AsyncValue.data([updatedChat]);
    }
    // Handle case where state has error - start fresh with updated chat
    else if (currentState.hasError) {
      state = AsyncValue.data([updatedChat]);
    }
  }
}

// ===========================================================================
// CURRENT CHAT PROVIDERS
// ===========================================================================

final currentChatIdProvider = StateProvider<String?>((ref) => null);

final currentChatProvider = Provider<Chat?>((ref) {
  final chatId = ref.watch(currentChatIdProvider);
  final chatsAsync = ref.watch(chatListProvider);

  if (chatId == null) return null;

  // Handle all states properly
  return chatsAsync.when(
    data: (chats) {
      try {
        return chats.firstWhere((c) => c.id == chatId);
      } catch (_) {
        return null;
      }
    },
    loading: () {
      // While loading, try to find chat in current state if available
      // This prevents UI from losing current chat during reloads
      try {
        final currentChats = chatsAsync.value;
        if (currentChats != null) {
          return currentChats.firstWhere((c) => c.id == chatId);
        }
      } catch (_) {}
      return null;
    },
    error: (e, st) {
      // On error, try to keep the current chat if possible
      try {
        final currentChats = chatsAsync.value;
        if (currentChats != null) {
          return currentChats.firstWhere((c) => c.id == chatId);
        }
      } catch (_) {}
      return null;
    },
  );
});
