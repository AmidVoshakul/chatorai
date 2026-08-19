import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/format_time_utils.dart';
import 'package:flutter/material.dart';

import 'action_menu_button.dart';

class ActionRow extends StatelessWidget {
  final bool isUser;
  final bool isLastMessage;
  final String? content;
  final String chatId;
  final String messageId;
  final SessionRepository sessionRepository;
  final VoidCallback? onEdit;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Future<void> Function(String)? onContinuationSelected;
  final String? agentName;
  final String? model;
  final DateTime? timestamp;
  final bool isCompactionSummary;

  const ActionRow({
    super.key,
    required this.isUser,
    required this.isLastMessage,
    this.content,
    required this.chatId,
    required this.messageId,
    required this.sessionRepository,
    this.onEdit,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onContinuationSelected,
    this.agentName,
    this.model,
    this.timestamp,
    this.isCompactionSummary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    final formattedTimestamp = timestamp != null
        ? formatMessageTime(timestamp!, context: context)
        : null;

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Spacer(),
            if (formattedTimestamp != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  formattedTimestamp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
            ActionMenuButton(
              isUser: true,
              content: content,
              chatId: chatId,
              messageId: messageId,
              sessionRepository: sessionRepository,
              onEdit: onEdit,
              onMessageDeleted: onMessageDeleted,
              onMessageRegenerate: onMessageRegenerate,
              theme: theme,
              localizations: localizations,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(width: 4),
                if (agentName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      agentName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                if (model != null)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, left: 4),
                      child: Text(
                        '•  $model',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ActionMenuButton(
                  isUser: false,
                  content: content,
                  chatId: chatId,
                  messageId: messageId,
                  sessionRepository: sessionRepository,
                  onMessageDeleted: onMessageDeleted,
                  onMessageRegenerate: onMessageRegenerate,
                  onContinuationSelected: onContinuationSelected,
                  isLastMessage: isLastMessage,
                  localizations: localizations,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
