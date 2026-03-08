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

  @override
  AsyncValue<List<Chat>> build() {
    final repository = ref.watch(chatRepositoryProvider);
    _loadChats(repository);
    return const AsyncValue.loading();
  }

  Future<void> _loadChats(ChatRepository repository) async {
    if (_isLoadingChats) {
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
    // Ensure chats are loaded first if not already loaded
    if (!_hasLoadedOnce) {
      final repository = ref.read(chatRepositoryProvider);
      await _loadChats(repository);
    }

    final repository = ref.read(chatRepositoryProvider);
    final newChat = await repository.createNewChat();

    // Handle all states - loading, data, or error
    final currentState = state;
    if (currentState.hasValue) {
      final chats = currentState.value!;
      state = AsyncValue.data([newChat, ...chats]);
    } else if (currentState.isLoading) {
      // If still loading, rebuild after load completes
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

  return chatsAsync.whenOrNull(
    data: (chats) {
      try {
        return chats.firstWhere((c) => c.id == chatId);
      } catch (_) {
        return null;
      }
    },
  );
});
