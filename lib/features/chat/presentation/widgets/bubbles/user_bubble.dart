import 'dart:convert';
import 'dart:typed_data';

import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/action_row.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

class UserMessageBubble extends StatelessWidget {
  final UserMessage message;
  final String chatId;
  final String messageId;
  final SessionRepository sessionRepository;
  final VoidCallback? onEdit;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Future<void> Function(String)? onContinuationSelected;
  final DateTime? timestamp;
  final double maxWidth;

  static Uint8List _imageBytes(String base64) {
    try {
      return base64Decode(base64);
    } catch (_) {
      return Uint8List(0);
    }
  }

  const UserMessageBubble({
    super.key,
    required this.message,
    required this.chatId,
    required this.messageId,
    required this.sessionRepository,
    this.onEdit,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onContinuationSelected,
    this.timestamp,
    this.maxWidth = 0.65,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxWidth = maxWidth > 1.0
            ? maxWidth
            : constraints.maxWidth * maxWidth;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChatoraiSpacing.md,
                    vertical: ChatoraiSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      ChatoraiBorderRadius.md,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.imageData != null &&
                          message.imageType != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ChatoraiBorderRadius.sm,
                            ),
                            child: Image.memory(
                              _imageBytes(message.imageData!),
                              fit: BoxFit.contain,
                              width: effectiveMaxWidth,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                      if (message.attachedDocName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  message.attachedDocName!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (message.files.isNotEmpty && message.imageData == null)
                        ...message.files.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              f,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      Text(message.content, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
            ActionRow(
              isUser: true,
              isLastMessage: false,
              content: message.content,
              chatId: chatId,
              messageId: messageId,
              sessionRepository: sessionRepository,
              onEdit: onEdit,
              onMessageDeleted: onMessageDeleted,
              onMessageRegenerate: onMessageRegenerate,
              onContinuationSelected: onContinuationSelected,
              agentName: null,
              model: null,
              timestamp: timestamp,
            ),
          ],
        );
      },
    );
  }
}
