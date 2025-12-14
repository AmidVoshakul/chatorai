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

  @override
  void initState() {
    super.initState();
    _chatStorageService = ChatStorageService();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _theme = themeProvider.getTheme();
    _language = themeProvider.selectedLanguage;
    final localizations = AppLocalizations.of(context)!;

    return AnimatedContainer(
      width: widget.isCollapsed ? 58 : widget.width,
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
            height: 64,
            padding: EdgeInsets.only(left: widget.isCollapsed ? 4 : 16, right: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!widget.isCollapsed)
                  Expanded(
                    child: Text(
                      'GenUI',
                      style: _theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _theme.textTheme.headlineSmall?.color,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (widget.isCollapsed) const SizedBox(),
                Container(
                  margin: EdgeInsets.zero,
                  child: IconButton(
                    icon: Icon(
                      widget.isCollapsed ? Icons.menu_open : Icons.menu,
                      color: _theme.iconTheme.color,
                      size: 20,
                    ),
                    onPressed: widget.onToggleSidebar,
                    padding: EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          
          // New Chat Button
          if (!widget.isCollapsed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onNewChat,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _theme.colorScheme.primary, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        localizations.newChat,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Chat List
          Expanded(
            child: !widget.isCollapsed 
                ? (widget.chats.isEmpty
                    ? _buildEmptyState(_theme, _language)
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: widget.chats.length,
                        itemBuilder: (context, index) {
                          final chat = widget.chats[index];
                          return _buildChatItem(chat);
                        },
                      ))
                : Container(), // Пустой кон��ейнер в свeнутом состоянии
          ),
          
          // Footer
          Column(
            children: [
              Divider(
                height: 1,
                thickness: 1,
                color: _theme.dividerColor,
              ),
              // Settings
              ListTile(
                leading: const Icon(Icons.settings),
                title: !widget.isCollapsed ? Text(localizations.settings) : null,
                minLeadingWidth: 0,
                contentPadding: !widget.isCollapsed 
                    ? const EdgeInsets.symmetric(horizontal: 16) 
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              // App Info
              ListTile(
                leading: const Icon(Icons.info),
                title: !widget.isCollapsed ? Text(localizations.appInfo) : null,
                minLeadingWidth: 0,
                contentPadding: !widget.isCollapsed 
                    ? const EdgeInsets.symmetric(horizontal: 16) 
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () {
                  _showAppInfo(context, _language, localizations);
                },
              ),
            ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noChatsYet,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.startConversation,
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
      if (language == 'en') {
        return difference.inMinutes <= 1 ? localizations.justNow : localizations.minAgo(difference.inMinutes);
      } else {
        return difference.inMinutes <= 1 ? localizations.justNow : '${difference.inMinutes} мин назад';
      }
    } else if (difference.inHours < 24) {
      if (language == 'en') {
        return difference.inHours == 1 ? localizations.onlyOneHourAgo : localizations.hoursAgo(difference.inHours);
      } else {
        return difference.inHours == 1 ? localizations.onlyOneHourAgo : '${difference.inHours} часов назад';
      }
    } else if (difference.inDays < 7) {
      if (language == 'en') {
        return difference.inDays == 1 ? localizations.onlyOneDayAgo : localizations.daysAgo(difference.inDays);
      } else {
        return difference.inDays == 1 ? localizations.onlyOneDayAgo : '${difference.inDays} дней назад';
      }
    } else {
      final String pattern = language == 'en' ? 'MMM d' : 'd MMM';
      final formatter = DateFormat(pattern, language == 'en' ? 'en_US' : 'ru_RU');
      return formatter.format(date);
    }
  }

  void _showAppInfo(BuildContext context, String language, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.appTitle),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        content: Text(
          localizations.appDescription,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.ok),
          ),
        ],
      ),
    );
  }
}
