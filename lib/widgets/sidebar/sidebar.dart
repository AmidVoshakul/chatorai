import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/screens/settings_screen.dart';
import 'package:gen_ui_chat_ai/widgets/sidebar/chat_actions_menu.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';

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
    Key? key,
    required this.width,
    required this.isCollapsed,
    required this.onToggleSidebar,
    required this.chats,
    required this.currentChat,
    required this.onChatSelect,
    required this.onChatDelete,
    required this.onNewChat,
  }) : super(key: key);

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
                        _language == 'en' ? 'New Chat' : 'Новый чат',
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
                : Container(), // Пустой контейнер в свerнутом состоянии
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
                title: !widget.isCollapsed ? const Text('Settings') : null,
                minLeadingWidth: 0,
                contentPadding: !widget.isCollapsed 
                    ? const EdgeInsets.symmetric(horizontal: 16) 
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () {
                  print('[Sidebar] 🚀 Attempting to navigate to settings...');
                  try {
                    Navigator.pushNamed(context, '/settings');
                  } catch (e) {
                    print('[Sidebar] ❌ Navigation failed: $e');
                    print('[Sidebar] ℹ️  Manual navigation to SettingsScreen');
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
                title: !widget.isCollapsed ? const Text('App Info') : null,
                minLeadingWidth: 0,
                contentPadding: !widget.isCollapsed 
                    ? const EdgeInsets.symmetric(horizontal: 16) 
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () {
                  _showAppInfo(context, _language);
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
                            _formatDate(chat.updatedAt, _language),
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
                        onRename: (newTitle) => _handleRenameChat(chat, newTitle),
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

  void _handleRenameChat(Chat chat, String newTitle) async {
    try {
      await _chatStorageService.renameChat(chat.id, newTitle);
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: _language == 'en' 
            ? 'Chat renamed to: $newTitle' 
            : 'Чат переименован в: $newTitle',
        icon: Icons.edit,
      );
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: _language == 'en' 
            ? 'Failed to rename chat' 
            : 'Не удалось переименовать чат',
        icon: Icons.error,
      );
    }
  }

  Widget _buildEmptyState(ThemeData theme, String language) {
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
              language == 'en' 
                  ? 'No chats yet' 
                  : 'Пока нет чатов',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              language == 'en' 
                  ? 'Start a conversation by clicking "New Chat"' 
                  : 'Начните разговор, нажав "Новый чат"',
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

  String _formatDate(DateTime date, String language) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inHours < 1) {
      if (language == 'en') {
        return difference.inMinutes <= 1 ? 'Just now' : '${difference.inMinutes} min ago';
      } else {
        return difference.inMinutes <= 1 ? 'Только что' : '${difference.inMinutes} мин назад';
      }
    } else if (difference.inHours < 24) {
      if (language == 'en') {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inHours} часов назад';
      }
    } else if (difference.inDays < 7) {
      if (language == 'en') {
        return '${difference.inDays} days ago';
      } else {
        return '${difference.inDays} дней назад';
      }
    } else {
      final String pattern = language == 'en' ? 'MMM d' : 'd MMM';
      final formatter = DateFormat(pattern, language == 'en' ? 'en_US' : 'ru_RU');
      return formatter.format(date);
    }
  }

  void _showAppInfo(BuildContext context, String language) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(language == 'en' ? 'Chat AI' : 'Chat AI'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1A1A1A) 
            : Colors.white,
        content: Text(
          language == 'en' 
              ? 'Chat application with AI models through OpenRouter API.\n\nFeatures:\n• Chat with various AI models\n• Chat history storage\n• Dark and light themes\n• Adaptive interface\n\nDeveloped with ❤️ using Flutter'
              : 'Приложение для общения с AI моделями через OpenRouter API.\n\nВозможности:\n• Общение с различными AI моделями\n• Сохранение истории чатов\n• Темная и светлая темы\n• Адаптивный интерфейс\n\nРазработано с ❤️ с использованием Flutter',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(language == 'en' ? 'OK' : 'ОК'),
          ),
        ],
      ),
    );
  }
}

class ChatActionsButton extends StatefulWidget {
  final Chat chat;
  final ThemeData theme;
  final String language;
  final Function(String) onRename;
  final Function() onDelete;

  const ChatActionsButton({
    Key? key,
    required this.chat,
    required this.theme,
    required this.language,
    required this.onRename,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<ChatActionsButton> createState() => _ChatActionsButtonState();
}

class _ChatActionsButtonState extends State<ChatActionsButton> {
  late final Chat _chat;
  late final ThemeData _theme;
  late final String _language;

  @override
  void initState() {
    super.initState();
    _chat = widget.chat;
    _theme = widget.theme;
    _language = widget.language;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showChatActionsMenu,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.more_vert,
            size: 18,
            color: _theme.iconTheme.color?.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  void _showChatActionsMenu() {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    
    final position = button.localToGlobal(Offset.zero);
    final size = button.size;

    showMenu<PopupMenuItem>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          Offset(position.dx - 40, position.dy + size.height),
          Offset(position.dx - 40, position.dy + size.height),
        ),
        overlay.localToGlobal(Offset.zero) & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _theme.dividerColor, width: 1),
      ),
      color: _theme.cardColor,
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      items: [
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          enabled: true,
          child: Row(
            children: [
              Icon(Icons.share, size: 18, color: _theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(
                _language == 'en' ? 'Share Chat' : 'Поделиться чатом',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          onTap: () => _handleShareChat(),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          enabled: true,
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: _theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(
                _language == 'en' ? 'Rename Chat' : 'Переименовать чат',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          onTap: () => _handleRenameChat(),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          enabled: false,
          child: const Divider(height: 1),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          enabled: true,
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: _theme.colorScheme.error),
              const SizedBox(width: 12),
              Text(
                _language == 'en' ? 'Delete Chat' : 'Удалить чат',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _theme.colorScheme.error,
                ),
              ),
            ],
          ),
          onTap: () => widget.onDelete(),
        ),
      ],
    );
  }

  void _handleShareChat() {
    final message = _language == 'en' 
        ? 'Chat sharing is not implemented yet' 
        : 'Функция деления чата пока не реализована';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _theme.colorScheme.secondary,
      ),
    );
  }

  void _handleRenameChat() async {
    final TextEditingController controller = TextEditingController(text: _chat.title);
    
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _language == 'en' ? 'Rename Chat' : 'Переименовать чат',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _language == 'en' ? 'Enter new chat name' : 'Введите новое имя чата',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(width: 1),
            ),
            isDense: true,
          ),
          maxLength: 50,
          maxLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _language == 'en' ? 'Cancel' : 'Отмена',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _theme.colorScheme.primary,
              foregroundColor: _theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              _language == 'en' ? 'Rename' : 'Переименовать',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );

    if (result != null && result is String && result.isNotEmpty) {
      widget.onRename(result);
    }
  }
}