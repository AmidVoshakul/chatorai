import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';

class ChatStorageService {
  static const String _chatsKey = 'chats_storage';

  /// Create a new chat with default values
  Chat newChat() {
    return Chat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Новый чат',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Add a new chat to storage
  Future<void> addChat(Chat chat) async {
    final prefs = await SharedPreferences.getInstance();
    final chats = await _getChatsFromStorage(prefs);
    
    chats.add(chat);
    await _saveChatsToStorage(prefs, chats);
  }

  /// Rename chat title
  Future<void> renameChat(String chatId, String newTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final chats = await _getChatsFromStorage(prefs);
    
    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      chats[chatIndex] = chats[chatIndex].copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      await _saveChatsToStorage(prefs, chats);
    }
  }

  /// Delete a chat by ID
  Future<void> deleteChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final chats = await _getChatsFromStorage(prefs);
    
    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      chats.removeAt(chatIndex);
      await _saveChatsToStorage(prefs, chats);
    }
  }

  /// Get all chats from storage
  Future<List<Chat>> getChats() async {
    final prefs = await SharedPreferences.getInstance();
    return await _getChatsFromStorage(prefs);
  }

  /// Update chat title
  Future<void> updateChatTitle(String chatId, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final chats = await _getChatsFromStorage(prefs);
    
    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      chats[chatIndex] = chats[chatIndex].copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      await _saveChatsToStorage(prefs, chats);
    }
  }

  /// Update message in chat
  Future<void> updateMessageInChat(String chatId, String messageId, Message updatedMessage) async {
    final prefs = await SharedPreferences.getInstance();
    final chats = await _getChatsFromStorage(prefs);
    
    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = chats[chatIndex];
      final messageIndex = chat.messages.indexWhere((msg) => msg.id == messageId);
      
      if (messageIndex != -1) {
        final updatedMessages = List<Message>.from(chat.messages);
        updatedMessages[messageIndex] = updatedMessage;
        
        final updatedChat = chat.copyWith(
          messages: updatedMessages,
          updatedAt: DateTime.now(),
        );
        
        chats[chatIndex] = updatedChat;
        await _saveChatsToStorage(prefs, chats);
      }
    }
  }

  /// Add message to chat
  Future<void> addMessageToChat(String chatId, Message message) async {
    final prefs = await SharedPreferences.getInstance();
    final chats = await _getChatsFromStorage(prefs);
    
    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = chats[chatIndex];
      final updatedChat = chat.copyWith(
        messages: [...chat.messages, message],
        updatedAt: DateTime.now(),
      );
      
      // Auto-update chat title if it's still default
      String chatTitle = chat.title;
      if (chat.title == 'Новый чат' && message.role == MessageRole.user) {
        chatTitle = message.content.length > 30 
            ? '${message.content.substring(0, 30)}...' 
            : message.content;
      }
      
      chats[chatIndex] = updatedChat.copyWith(title: chatTitle);
      await _saveChatsToStorage(prefs, chats);
    }
  }

  /// Get chat by ID
  Future<Chat?> getChat(String chatId) async {
    final chats = await getChats();
    try {
      return chats.firstWhere((c) => c.id == chatId);
    } catch (e) {
      return null;
    }
  }

  /// Delete message from chat
  Future<void> deleteMessageFromChat(String chatId, String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final chats = await _getChatsFromStorage(prefs);
    
    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = chats[chatIndex];
      final filteredMessages = chat.messages.where((message) => message.id != messageId).toList();
      
      final updatedChat = chat.copyWith(
        messages: filteredMessages,
        updatedAt: DateTime.now(),
      );
      
      chats[chatIndex] = updatedChat;
      await _saveChatsToStorage(prefs, chats);
    }
  }

  /// Update existing chat
  Future<void> updateChat(Chat chat) async {
    final prefs = await SharedPreferences.getInstance();
    final chats = await _getChatsFromStorage(prefs);
    
    final chatIndex = chats.indexWhere((c) => c.id == chat.id);
    if (chatIndex != -1) {
      chats[chatIndex] = chat.copyWith(updatedAt: DateTime.now());
      await _saveChatsToStorage(prefs, chats);
    }
  }

  /// Private method to get chats from storage
  Future<List<Chat>> _getChatsFromStorage(SharedPreferences prefs) async {
    final chatsJson = prefs.getString(_chatsKey);
    if (chatsJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> chatsData = json.decode(chatsJson);
      return chatsData.map((data) => Chat.fromJson(data)).toList();
    } catch (e) {
      print('Error parsing chats from storage: $e');
      return [];
    }
  }

  /// Private method to save chats to storage
  Future<void> _saveChatsToStorage(SharedPreferences prefs, List<Chat> chats) async {
    final chatsJson = json.encode(chats.map((chat) => chat.toJson()).toList());
    await prefs.setString(_chatsKey, chatsJson);
  }
}