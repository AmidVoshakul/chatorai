import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/message_utils.dart';
import 'package:flutter/material.dart';

class ActionMenuButton extends StatelessWidget {
  final bool isUser;
  final String? content;
  final String chatId;
  final String messageId;
  final SessionRepository sessionRepository;
  final VoidCallback? onEdit;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Future<void> Function(String)? onContinuationSelected;
  final bool isLastMessage;
  final bool isCompactionSummary;
  final ThemeData theme;
  final AppLocalizations localizations;

  const ActionMenuButton({
    super.key,
    required this.isUser,
    this.content,
    required this.chatId,
    required this.messageId,
    required this.sessionRepository,
    this.onEdit,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onContinuationSelected,
    this.isLastMessage = false,
    this.isCompactionSummary = false,
    required this.theme,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.more_vert,
          size: 18,
          color: theme.iconTheme.color?.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(
          renderBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final items = <PopupMenuEntry<String>>[
      if (isUser && onEdit != null) ...[
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              const SizedBox(width: 8),
              Text(localizations.edit),
            ],
          ),
        ),
      ],
      PopupMenuItem(
        value: 'copy',
        child: Row(
          children: [
            Icon(Icons.copy_all, size: 18),
            const SizedBox(width: 8),
            Text(localizations.copyMessage),
          ],
        ),
      ),
      if (!isUser) ...[
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 18),
              const SizedBox(width: 8),
              Text(localizations.share),
            ],
          ),
        ),
        if (!isCompactionSummary)
          PopupMenuItem(
            value: 'regenerate',
            child: Row(
              children: [
                Icon(Icons.refresh, size: 18),
                const SizedBox(width: 8),
                Text(localizations.regenerate),
              ],
            ),
          ),
        if (!isCompactionSummary &&
            isLastMessage &&
            content != null &&
            content!.isNotEmpty &&
            (content!.endsWith('...') || content!.split(' ').length > 30))
          PopupMenuItem(
            value: 'continue',
            child: Row(
              children: [
                Icon(Icons.play_arrow, size: 18),
                const SizedBox(width: 8),
                Text(localizations.continueResponse),
              ],
            ),
          ),
      ],
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Text(localizations.delete, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];

    final result = await showMenu<String>(
      context: context,
      position: position,
      items: items,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    if (result == null || context.mounted == false) return;

    switch (result) {
      case 'edit':
        onEdit?.call();
        break;
      case 'copy':
        if (content != null) {
          MessageUtils.copyMessage(content: content!, context: context);
        }
        break;
      case 'share':
        if (content != null) {
          MessageUtils.shareMessage(content: content!, context: context);
        }
        break;
      case 'delete':
        FocusScope.of(context).unfocus();
        final deleted = await MessageUtils.deleteMessage(
          chatId: chatId,
          messageId: messageId,
          sessionRepository: sessionRepository,
          context: context,
        );
        if (deleted) onMessageDeleted?.call();
        break;
      case 'regenerate':
        await MessageUtils.regenerateMessage(
          chatId: chatId,
          messageId: messageId,
          sessionRepository: sessionRepository,
          onRegenerate: () => onMessageRegenerate?.call(),
        );
        break;
      case 'continue':
        onContinuationSelected?.call(messageId);
        break;
    }
  }
}
