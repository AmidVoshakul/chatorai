import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/providers/chat/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final chatListProvider =
    NotifierProvider<ChatListNotifier, AsyncValue<List<Chat>>>(
      ChatListNotifier.new,
    );

class ChatListNotifier extends Notifier<AsyncValue<List<Chat>>> {
  @override
  AsyncValue<List<Chat>> build() {
    final repository = ref.watch(chatRepositoryProvider);
    loadChats(repository);
    return const AsyncValue.loading();
  }

  Future<void> loadChats(ChatRepository repository) async {
    state = const AsyncValue.loading();
    try {
      final chats = await repository.getChats();
      state = AsyncValue.data(chats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Chat> createNewChat() async {
    final repository = ref.read(chatRepositoryProvider);
    final newChat = await repository.createNewChat();
    state.whenData((chats) {
      state = AsyncValue.data([newChat, ...chats]);
    });
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
    state.whenData((chats) {
      final index = chats.indexWhere((c) => c.id == updatedChat.id);
      if (index != -1) {
        final newChats = List<Chat>.from(chats);
        newChats[index] = updatedChat;
        state = AsyncValue.data(newChats);
      }
    });
  }
}

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
