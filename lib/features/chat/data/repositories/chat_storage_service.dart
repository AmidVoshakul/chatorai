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
  static const Duration _cacheDuration = Duration(seconds: 30);

  // Cache for SharedPreferences
  SharedPreferences? _prefsCache;

  // In-memory cache
  List<Chat>? _chatsCache;
  DateTime? _chatsCacheTimestamp;

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  Future<SharedPreferences> _getPrefs() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  bool _isCacheValid() {
    if (_chatsCache == null || _chatsCacheTimestamp == null) return false;
    return DateTime.now().difference(_chatsCacheTimestamp!) < _cacheDuration;
  }

  void _invalidateCache() {
    _chatsCache = null;
    _chatsCacheTimestamp = null;
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
    _invalidateCache();
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
      _invalidateCache();
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
      _invalidateCache();
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
        _invalidateCache();

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
      _invalidateCache();
    }
  }

  /// Get chat by ID (optimized to use caching)
  Future<Chat?> getChat(String chatId) async {
    // Try to find in cached chats first (more efficient)
    if (_isCacheValid() && _chatsCache != null) {
      try {
        return _chatsCache!.firstWhere((c) => c.id == chatId);
      } catch (e) {
        // Not in cache, continue to fetch from storage
      }
    }

    // Fetch from storage
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
      _invalidateCache();
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
      _invalidateCache();
    }
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Private method to get chats from storage (with caching)
  Future<List<Chat>> _getChatsFromStorage(SharedPreferences prefs) async {
    // Return cached data if valid
    if (_isCacheValid() && _chatsCache != null) {
      return _chatsCache!;
    }

    final chatsJson = prefs.getString(_chatsKey);
    if (chatsJson == null) {
      _logger.logDebug('[ChatStorageService] No chats found in storage');
      _chatsCache = [];
      _chatsCacheTimestamp = DateTime.now();
      return [];
    }

    try {
      final List<dynamic> chatsData = json.decode(chatsJson);

      final chats = chatsData.map((data) => Chat.fromJson(data)).toList();

      // Update cache
      _chatsCache = chats;
      _chatsCacheTimestamp = DateTime.now();

      return chats;
    } catch (e) {
      _logger.logError('Error parsing chats from storage: $e');
      _chatsCache = [];
      _chatsCacheTimestamp = DateTime.now();
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
