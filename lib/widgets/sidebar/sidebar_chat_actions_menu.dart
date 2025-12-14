import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/utils/message_utils.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';

// Initialize logger for this widget
final _logger = LogTags.sidebar;

class ChatActionsMenu extends StatefulWidget {
  final Chat chat;
  final ThemeData theme;
  final String language;
  final Function(String) onRename;
  final Function() onDelete;

  const ChatActionsMenu({
    super.key,
    required this.chat,
    required this.theme,
    required this.language,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<ChatActionsMenu> createState() => _ChatActionsMenuState();
}

class _ChatActionsMenuState extends State<ChatActionsMenu> {
  late final Chat _chat;
  late final ThemeData _theme;

  // Helper methods for theme access
  Color _getPrimaryColor() => _theme.colorScheme.primary;
  Color _getOnPrimaryColor() => _theme.colorScheme.onPrimary;
  Color _getDividerColor() => _theme.dividerColor;
  Color _getCardColor() => _theme.cardColor;
  Color _getIconColor() => _theme.iconTheme.color ?? Colors.black;
  Color _getErrorColor() => _theme.colorScheme.error;

  @override
  void initState() {
    super.initState();
    _chat = widget.chat;
    _theme = widget.theme;
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
            color: _getIconColor().withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  void _showChatActionsMenu() {
    final localizations = AppLocalizations.of(context)!;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject()! as RenderBox;

    final position = button.localToGlobal(Offset.zero);
    final size = button.size;

    try {
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
          side: BorderSide(color: _getDividerColor(), width: 1),
        ),
        color: _getCardColor(),
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        items: <PopupMenuEntry<dynamic>>[
          PopupMenuItem(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            enabled: true,
            child: Row(
              children: [
                Icon(Icons.share, size: 18, color: _getIconColor()),
                const SizedBox(width: 12),
                Text(
                  localizations.shareChat,
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
                Icon(Icons.copy_all, size: 18, color: _getIconColor()),
                const SizedBox(width: 12),
                Text(
                  localizations.copyChat,
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
                Icon(Icons.edit, size: 18, color: _getIconColor()),
                const SizedBox(width: 12),
                Text(
                  localizations.renameChat,
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
                Icon(Icons.delete, size: 20, color: _getErrorColor()),
                const SizedBox(width: 12),
                Text(
                  localizations.deleteChat,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _getErrorColor(),
                  ),
                ),
              ],
            ),
            onTap: () => widget.onDelete(),
          ),
        ],
      );
    } catch (e, stackTrace) {
      _logger.logError('[ChatActionsMenu] Failed to show menu: $e\nStack trace: $stackTrace');
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.failedToShowMenu,
        icon: Icons.error,
      );
    }
  }

  void _handleShareChat() {
    // TODO: Implement chat sharing functionality
    final localizations = AppLocalizations.of(context)!;
    final message = localizations.chatSharingNotImplemented;
    SnackbarUtils.showSecondarySnackBar(
      context: context,
      message: message,
      icon: Icons.share,
    );
  }

  void _handleRenameChat() async {
    final TextEditingController controller = TextEditingController(
      text: _chat.title,
    );

    final localizations = AppLocalizations.of(context)!;

    try {
      final result = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            localizations.renameChatTitle,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: localizations.enterNewChatName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _getDividerColor(), width: 1),
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
                localizations.cancel,
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
                backgroundColor: _getPrimaryColor(),
                foregroundColor: _getOnPrimaryColor(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                localizations.rename,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

      if (result != null && result is String && result.isNotEmpty) {
        widget.onRename(result);
      }
    } catch (e, stackTrace) {
      _logger.logError('[ChatActionsMenu] Failed to rename chat: $e\nStack trace: $stackTrace');
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.failedToRenameChat,
        icon: Icons.error,
      );
    }
  }

  void _handleCopyChat() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      // Используем функцию копирования чата из MessageUtils
      await MessageUtils.copyChat(
        messages: _chat.messages,
        chatTitle: _chat.title,
        context: context,
      );
    } catch (e, stackTrace) {
      _logger.logError('[ChatActionsMenu] Failed to copy chat: $e\nStack trace: $stackTrace');
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.failedToCopyChat,
        icon: Icons.error,
      );
    }
  }
}
