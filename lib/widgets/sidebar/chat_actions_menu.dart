import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/utils/message_utils.dart';

class ChatActionsMenu extends StatefulWidget {
  final Chat chat;
  final ThemeData theme;
  final String language;
  final Function(String) onRename;
  final Function() onDelete;

  const ChatActionsMenu({
    Key? key,
    required this.chat,
    required this.theme,
    required this.language,
    required this.onRename,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<ChatActionsMenu> createState() => _ChatActionsMenuState();
}

class _ChatActionsMenuState extends State<ChatActionsMenu> {
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
    final RenderBox button = context.findRenderObject()! as RenderBox;
    
    final position = button.localToGlobal(Offset.zero);
    final size = button.size;

    showMenu(
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
      items: <PopupMenuEntry<dynamic>>[
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
              Icon(Icons.copy_all, size: 18, color: _theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(
                _language == 'en' ? 'Copy Chat' : 'Копировать чат',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          onTap: () => _handleCopyChat(),
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
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          enabled: true,
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: _theme.colorScheme.error),
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
    // TODO: Implement chat sharing functionality
    final message = _language == 'en' 
        ? 'Chat sharing is not implemented yet' 
        : 'Функция деления чата пока не реализована';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: _theme.colorScheme.secondary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  void _handleCopyChat() async {
    try {
      // Используем функцию копирования чата из MessageUtils
      await MessageUtils.copyChat(
        messages: _chat.messages,
        chatTitle: _chat.title,
        context: context,
      );
    } catch (e) {
      final message = _language == 'en' 
          ? 'Failed to copy chat' 
          : 'Не удалось скопировать чат';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: _theme.colorScheme.error,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}