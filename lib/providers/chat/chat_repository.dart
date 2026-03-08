import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/chat_storage_service.dart';

// ===========================================================================
// CHAT REPOSITORY
// ===========================================================================

class ChatRepository {
  final ChatStorageService _storageService;

  ChatRepository({ChatStorageService? storageService})
    : _storageService = storageService ?? ChatStorageService();

  Future<List<Chat>> getChats() async {
    return await _storageService.getChats();
  }

  Future<Chat> createNewChat() async {
    final chat = _storageService.newChat();
    await _storageService.addChat(chat);
    return chat;
  }

  Future<void> deleteChat(String chatId) async {
    await _storageService.deleteChat(chatId);
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    await _storageService.renameChat(chatId, newTitle);
  }

  Future<void> updateChat(Chat chat) async {
    await _storageService.updateChat(chat);
  }

  Future<void> addMessageToChat(String chatId, Message message) async {
    final chat = await _getChatById(chatId);
    if (chat != null) {
      await _storageService.updateMessageInChat(chatId, message.id, message);
    }
  }

  Future<void> updateMessage(String chatId, Message message) async {
    await _storageService.updateMessageInChat(chatId, message.id, message);
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  Future<Chat?> _getChatById(String chatId) async {
    final chats = await getChats();
    try {
      return chats.firstWhere((c) => c.id == chatId);
    } catch (_) {
      return null;
    }
  }
}
