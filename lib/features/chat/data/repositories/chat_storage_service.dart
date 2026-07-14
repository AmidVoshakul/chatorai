import 'dart:convert';

import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Initialize logger for this service
final _logger = LogTags.storage;

// ===========================================================================
// CHAT STORAGE SERVICE
// ===========================================================================

/// Legacy chat storage backed by SharedPreferences.
///
/// Prefer [SessionRepository] for new code. This service is retained for
/// backward compatibility during the migration to event-sourced sessions.
@Deprecated('Use SessionRepository instead')
class ChatStorageService {
  static const String _chatsKey = 'chats_storage';
  static const int _defaultPageSize = 50;

  // Cache for SharedPreferences
  SharedPreferences? _prefsCache;

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  Future<SharedPreferences> _getPrefs() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

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

  /// Get chats with pagination
  Future<List<Chat>> getChats({
    int page = 0,
    int pageSize = _defaultPageSize,
  }) async {
    final prefs = await _getPrefs();
    final allChats = await _getChatsFromStorage(prefs);

    // Sort by updatedAt descending
    allChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Apply pagination
    final startIndex = page * pageSize;
    if (startIndex >= allChats.length) {
      return [];
    }

    final endIndex = (startIndex + pageSize).clamp(0, allChats.length);
    return allChats.sublist(startIndex, endIndex);
  }

  /// Get all chats (legacy method, used internally)
  Future<List<Chat>> getAllChats() async {
    final prefs = await _getPrefs();
    return await _getChatsFromStorage(prefs);
  }

  /// Add a new chat to storage
  Future<void> addChat(Chat chat) async {
    final prefs = await _getPrefs();
    final chats = await _getChatsFromStorage(prefs);

    chats.insert(0, chat);
    await _saveChatsToStorage(prefs, chats);
  }

  /// Rename chat title
  Future<void> renameChat(String chatId, String newTitle) async {
    final prefs = await _getPrefs();
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
    final prefs = await _getPrefs();
    final chats = await _getChatsFromStorage(prefs);

    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      chats.removeAt(chatIndex);
      await _saveChatsToStorage(prefs, chats);
    }
  }

  /// Update message in chat
  Future<void> updateMessageInChat(
    String chatId,
    String messageId,
    Message updatedMessage,
  ) async {
    _logger.logInfo(
      '[ChatStorageService] Updating message $messageId in chat $chatId',
    );

    final prefs = await _getPrefs();
    final chats = await _getChatsFromStorage(prefs);

    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = chats[chatIndex];
      final messageIndex = chat.messages.indexWhere(
        (msg) => msg.id == messageId,
      );

      if (messageIndex != -1) {
        final existingMessage = chat.messages[messageIndex];
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
      }
    }
  }

  /// Add message to chat
  Future<void> addMessageToChat(String chatId, Message message) async {
    final prefs = await _getPrefs();
    final chats = await _getChatsFromStorage(prefs);

    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = chats[chatIndex];
      final updatedChat = chat.copyWith(
        messages: [...chat.messages, message],
        updatedAt: DateTime.now(),
      );

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
    final chats = await getAllChats();
    try {
      return chats.firstWhere((c) => c.id == chatId);
    } catch (e) {
      return null;
    }
  }

  /// Delete message from chat
  Future<void> deleteMessageFromChat(String chatId, String messageId) async {
    final prefs = await _getPrefs();
    final chats = await _getChatsFromStorage(prefs);

    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = chats[chatIndex];
      final filteredMessages = chat.messages
          .where((message) => message.id != messageId)
          .toList();

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
    final prefs = await _getPrefs();
    final chats = await _getChatsFromStorage(prefs);

    final chatIndex = chats.indexWhere((c) => c.id == chat.id);
    if (chatIndex != -1) {
      chats[chatIndex] = chat.copyWith(updatedAt: DateTime.now());
      await _saveChatsToStorage(prefs, chats);
    }
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Private method to get chats from storage
  Future<List<Chat>> _getChatsFromStorage(SharedPreferences prefs) async {
    final chatsJson = prefs.getString(_chatsKey);
    if (chatsJson == null) {
      _logger.logDebug('[ChatStorageService] No chats found in storage');
      return [];
    }

    try {
      final List<dynamic> chatsData = json.decode(chatsJson);

      return chatsData.map((data) => Chat.fromJson(data)).toList();
    } catch (e) {
      _logger.logError('Error parsing chats from storage: $e');
      return [];
    }
  }

  /// Private method to save chats to storage
  Future<void> _saveChatsToStorage(
    SharedPreferences prefs,
    List<Chat> chats,
  ) async {
    final chatsData = chats.map((chat) => chat.toJson()).toList();

    final chatsJson = json.encode(chatsData);
    await prefs.setString(_chatsKey, chatsJson);
  }
}
