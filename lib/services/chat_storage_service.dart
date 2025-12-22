import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';
import '../utils/logger.dart';

// Initialize logger for this service
final _logger = LogTags.storage;

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
    
    chats.insert(0, chat);
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
    _logger.logInfo('[ChatStorageService] Updating message $messageId in chat $chatId');
    _logger.logDebug('[ChatStorageService] Message reasoning before save: "${updatedMessage.reasoning}"');
    
    final prefs = await SharedPreferences.getInstance();
    final chats = await _getChatsFromStorage(prefs);
    
    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = chats[chatIndex];
      final messageIndex = chat.messages.indexWhere((msg) => msg.id == messageId);
      
      if (messageIndex != -1) {
        final existingMessage = chat.messages[messageIndex];
        // Preserve existing reasoning if the updated message doesn't have reasoning
        final finalMessage = updatedMessage.reasoning != null 
            ? updatedMessage 
            : updatedMessage.copyWith(reasoning: existingMessage.reasoning);
        
        final updatedMessages = List<Message>.from(chat.messages);
        updatedMessages[messageIndex] = finalMessage;
        
        final updatedChat = chat.copyWith(
          messages: updatedMessages,
          updatedAt: DateTime.now(),
        );
        
        chats[chatIndex] = updatedChat;
        await _saveChatsToStorage(prefs, chats);
        
        _logger.logInfo('[ChatStorageService] Message updated successfully');
        _logger.logDebug('[ChatStorageService] Message reasoning after save: "${finalMessage.reasoning}"');
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
      _logger.logDebug('[ChatStorageService] No chats found in storage');
      return [];
    }
    
    try {
      _logger.logDebug('[ChatStorageService] Raw JSON from storage: $chatsJson');
      final List<dynamic> chatsData = json.decode(chatsJson);
      _logger.logDebug('[ChatStorageService] Loading ${chatsData.length} chats from storage');
      
      // Log reasoning content in JSON before deserialization
      for (int i = 0; i < chatsData.length; i++) {
        final chatData = chatsData[i] as Map<String, dynamic>;
        final messages = chatData['messages'] as List;
        _logger.logDebug('[ChatStorageService] Loading chat $i with ${messages.length} messages');
        for (int j = 0; j < messages.length; j++) {
          final message = messages[j] as Map<String, dynamic>;
          final reasoning = message['reasoning'];
          _logger.logDebug('[ChatStorageService]   Message $j: reasoning="$reasoning"');
        }
      }
      
      final chats = chatsData.map((data) => Chat.fromJson(data)).toList();
      
      // Log reasoning content for debugging
      for (int i = 0; i < chats.length; i++) {
        final chat = chats[i];
        _logger.logDebug('[ChatStorageService] Chat $i (${chat.id}): ${chat.messages.length} messages');
        for (int j = 0; j < chat.messages.length; j++) {
          final message = chat.messages[j];
          _logger.logDebug('[ChatStorageService]   Message $j: role=${message.role}, reasoning="${message.reasoning}"');
        }
      }
      
      return chats;
    } catch (e) {
      _logger.logError('Error parsing chats from storage: $e');
      return [];
    }
  }

  /// Private method to save chats to storage
  Future<void> _saveChatsToStorage(SharedPreferences prefs, List<Chat> chats) async {
    final chatsData = chats.map((chat) => chat.toJson()).toList();
    
    // Log reasoning content in JSON before saving
    for (int i = 0; i < chatsData.length; i++) {
      final chatData = chatsData[i];
      final messages = chatData['messages'] as List;
      _logger.logDebug('[ChatStorageService] Saving chat $i with ${messages.length} messages');
      for (int j = 0; j < messages.length; j++) {
        final message = messages[j] as Map<String, dynamic>;
        final reasoning = message['reasoning'];
        _logger.logDebug('[ChatStorageService]   Message $j: reasoning="$reasoning"');
      }
    }
    
    final chatsJson = json.encode(chatsData);
    await prefs.setString(_chatsKey, chatsJson);
  }
}