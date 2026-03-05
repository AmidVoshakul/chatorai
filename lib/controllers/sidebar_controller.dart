import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/utils/logger.dart';

final _logger = LogTags.sidebar;

class SidebarController extends ChangeNotifier {
  final ChatStorageService _chatStorageService;
  final List<Chat> _allChats;
  String _searchQuery = '';

  SidebarController({
    required List<Chat> chats,
    ChatStorageService? chatStorageService,
  }) : _allChats = chats,
       _chatStorageService = chatStorageService ?? ChatStorageService();

  String get searchQuery => _searchQuery;

  List<Chat> get filteredChats {
    if (_searchQuery.isEmpty) return _allChats;
    return _allChats
        .where(
          (chat) =>
              chat.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> renameChat(
    BuildContext context,
    Chat chat,
    String newTitle,
  ) async {
    try {
      await _chatStorageService.renameChat(chat.id, newTitle);
      final index = _allChats.indexWhere((c) => c.id == chat.id);
      if (index != -1) {
        _allChats[index].title = newTitle;
        notifyListeners();
      }
    } catch (e) {
      _logger.logError('[SidebarController] Failed to rename chat: $e');
      rethrow;
    }
  }
}
