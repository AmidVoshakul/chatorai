import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/screens/settings_screen.dart';
import 'package:gen_ui_chat_ai/widgets/sidebar/sidebar_chat_actions_menu.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';

// Initialize logger for this widget
final _logger = LogTags.sidebar;

// Cache for formatted dates to avoid repeated formatting
class Sidebar extends StatefulWidget {
  final double width;
  final bool isCollapsed;
  final VoidCallback onToggleSidebar;
  final List<Chat> chats;
  final Chat? currentChat;
  final Function(String) onChatSelect;
  final Function(String) onChatDelete;
  final Function() onNewChat;

  const Sidebar({
    super.key,
    required this.width,
    required this.isCollapsed,
    required this.onToggleSidebar,
    required this.chats,
    required this.currentChat,
    required this.onChatSelect,
    required this.onChatDelete,
    required this.onNewChat,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late ThemeData _theme;
  late String _language;
  late ChatStorageService _chatStorageService;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _chatStorageService = ChatStorageService();
  }

  List<Chat> get _filteredChats {
    if (_searchQuery.isEmpty) return widget.chats;
    return widget.chats.where((chat) => 
      chat.title.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _theme = themeProvider.getTheme();
    _language = themeProvider.selectedLanguage;
    final localizations = AppLocalizations.of(context)!;

    return AnimatedContainer(
      width: widget.width,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          right: BorderSide(
            color: _theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              left: widget.isCollapsed ? 2 : 16, 
              right: widget.isCollapsed ? 2 : 16,
              top: widget.isCollapsed ? 0 : 12,
              bottom: widget.isCollapsed ? 0 : 8,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Title and close button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!widget.isCollapsed)
                      Expanded(
                        child: Text(
                          localizations.appShortName,
                          style: _theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _theme.textTheme.headlineSmall?.color,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    if (widget.isCollapsed)
                      const Spacer(),
                    IconButton(
                      icon: Icon(
                        widget.isCollapsed ? Icons.menu : Icons.close,
                        color: _theme.iconTheme.color,
                        size: 18,
                      ),
                      onPressed: widget.onToggleSidebar,
                      padding: widget.isCollapsed ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      splashRadius: widget.isCollapsed ? 16 : 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Search field and New Chat button in one row
          if (!widget.isCollapsed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Search field
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: localizations.searchChats,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: _theme.dividerColor, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: _theme.dividerColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: _theme.colorScheme.primary, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  // New Chat icon button
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      onPressed: widget.onNewChat,
                      icon: const Icon(Icons.edit_square),
                      style: IconButton.styleFrom(
                        side: BorderSide(color: _theme.dividerColor, width: 1),
                        padding: const EdgeInsets.all(8),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Chat List
          Expanded(
            child: !widget.isCollapsed 
                ? (_filteredChats.isEmpty
                    ? _buildEmptyState(_theme, _language)
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = _filteredChats[index];
                          return _buildChatItem(chat);
                        },
                      ))
                : Container(), // Пустой контейнер в свёрнутом состоянии
          ),
          
          // Footer
          if (!widget.isCollapsed)
            Container(
              decoration: BoxDecoration(
                color: _theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _theme.dividerColor,
                  ),
                  // Settings
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(localizations.settings),
                    minLeadingWidth: 0,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () {
                      _logger.logInfo('[Sidebar] Attempting to navigate to settings...');
                      try {
                        Navigator.pushNamed(context, '/settings');
                      } catch (e) {
                        _logger.logError('[Sidebar] Navigation failed: $e');
                        _logger.logInfo('[Sidebar] Manual navigation to SettingsScreen');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Chat chat) {
    final isSelected = widget.currentChat?.id == chat.id;
    final localizations = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onChatSelect(chat.id),
        borderRadius: BorderRadius.zero,
        hoverColor: _theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          height: 60,
          child: Stack(
            children: [
              // Main content (only show in expanded state)
              if (!widget.isCollapsed)
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: isSelected 
                          ? _theme.colorScheme.primary
                          : _theme.iconTheme.color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            chat.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: isSelected 
                                  ? _theme.colorScheme.primary
                                  : _theme.textTheme.bodyMedium?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            _formatDate(chat.updatedAt, _language, localizations),
                            style: TextStyle(
                              fontSize: 11,
                              color: _theme.textTheme.bodySmall?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    // Always reserve space for icons on the right
                    const SizedBox(width: 36), // Space for both icons
                  ],
                ),
              
              // Always position icons at the same right position (only show in expanded state)
              if (!widget.isCollapsed)
                Stack(
                  children: [
                    // Chat actions menu (show for all chats)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: ChatActionsMenu(
                        chat: chat,
                        theme: _theme,
                        language: _language,
                        onRename: (newTitle) => _handleRenameChat(chat, newTitle, localizations),
                        onDelete: () => widget.onChatDelete(chat.id),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRenameChat(Chat chat, String newTitle, AppLocalizations localizations) async {
    try {
      await _chatStorageService.renameChat(chat.id, newTitle);
      setState(() {
        widget.chats.firstWhere((c) => c.id == chat.id).title = newTitle;
      });
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: localizations.chatRenamedTo(newTitle),
        icon: Icons.edit,
      );
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.failedToRenameChat,
        icon: Icons.error,
      );
    }
  }

  Widget _buildEmptyState(ThemeData theme, String language) {
    final localizations = AppLocalizations.of(context)!;
    final hasSearch = _searchQuery.isNotEmpty;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.chat_bubble_outline,
              size: 60,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch 
                  ? localizations.noChatsFound(_searchQuery)
                  : localizations.noChatsYet,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch 
                  ? localizations.tryDifferentSearchTerm
                  : localizations.startConversation,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, String language, AppLocalizations localizations) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return difference.inMinutes <= 1 
          ? localizations.justNow 
          : localizations.minAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return difference.inHours == 1 
          ? localizations.onlyOneHourAgo 
          : localizations.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return difference.inDays == 1 
          ? localizations.onlyOneDayAgo 
          : localizations.daysAgo(difference.inDays);
    } else {
      final String pattern = language == 'en' ? 'MMM d' : 'd MMM';
      final formatter = DateFormat(pattern, language == 'en' ? 'en_US' : 'ru_RU');
      return formatter.format(date);
    }
  }

}
