import 'package:chatorai/core/chat/chat_models.dart';
import 'package:chatorai/gui/shared/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/gui/shared/utils/message_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

// ===========================================================================
// CHAT ACTIONS MENU WIDGET
// ===========================================================================

class ChatActionsMenu extends StatelessWidget {
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

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showChatActionsMenu(context),
        child: Tooltip(
          message: localizations.chatActionsMenuTooltip,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.more_vert,
              size: 18,
              color: theme.iconTheme.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  void _showChatActionsMenu(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
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
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      color: theme.cardColor,
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: () => _handleShareChat(context),
          child: Row(
            children: [
              Icon(Icons.share, size: 18, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(
                localizations.shareChat,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: () => _handleCopyChat(context),
          child: Row(
            children: [
              Icon(Icons.copy_all, size: 18, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(
                localizations.copyChat,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: () => _handleRenameChat(context),
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text(
                localizations.renameChat,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.all(0),
          height: 4,
          child: Container(height: 1, color: theme.dividerColor),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: onDelete,
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Text(
                localizations.deleteChat,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleShareChat(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    if (chat.messages.isEmpty) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'No messages to share',
      );
      return;
    }

    final chatText = _formatChatForSharing(chat);
    bool shared = false;

    try {
      final result = await Share.share(chatText, subject: chat.title);
      if (result.status == ShareResultStatus.success) {
        shared = true;
      }
    } catch (e) {
      try {
        await Clipboard.setData(ClipboardData(text: chatText));
        if (!context.mounted) return;
        SnackbarUtils.showSuccessSnackBar(
          context: context,
          message: localizations.copyChat,
          icon: Icons.copy,
        );
        return;
      } catch (_) {}
    }

    if (!shared) return;

    if (!context.mounted) return;
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message: localizations.shareChat,
      icon: Icons.share,
    );
  }

  String _formatChatForSharing(Chat chat) {
    final buffer = StringBuffer();
    buffer.writeln('# ${chat.title}');
    buffer.writeln('');
    for (final message in chat.messages) {
      final role = message.role == MessageRole.user ? 'You' : 'AI';
      buffer.writeln('**$role:**');
      buffer.writeln(message.content);
      buffer.writeln('');
    }
    return buffer.toString();
  }

  void _handleRenameChat(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(
      text: chat.title,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => KeyboardHandlerDialog(
        onEnter: () {
          if (controller.text.trim().isNotEmpty) {
            Navigator.of(dialogContext).pop(controller.text.trim());
          }
        },
        onEscape: () => Navigator.of(dialogContext).pop(null),
        child: AlertDialog(
          title: Text(
            localizations.renameChatTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
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
                borderSide: BorderSide(color: theme.dividerColor, width: 1),
              ),
              isDense: true,
            ),
            maxLength: 50,
            maxLines: 1,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(
                localizations.cancel,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                localizations.rename,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      onRename(result);
    }
  }

  void _handleCopyChat(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      await MessageUtils.copyChat(
        messages: chat.messages,
        chatTitle: chat.title,
        context: context,
      );
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: localizations.failedToCopyChat,
          icon: Icons.error,
        );
      }
    }
  }
}
