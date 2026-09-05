import 'dart:convert';
import 'dart:typed_data';

import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/chat/chat/chat_message.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/parts/action_row.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

class UserMessageBubble extends StatefulWidget {
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
  State<UserMessageBubble> createState() => _UserMessageBubbleState();
}

class _UserMessageBubbleState extends State<UserMessageBubble> {
  Uint8List? _cachedBytes;
  String? _cachedMessageId;

  @override
  void didUpdateWidget(covariant UserMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.imageData != widget.message.imageData) {
      _cachedBytes = null;
      _cachedMessageId = null;
    }
  }

  Uint8List _decodeImage(String base64) {
    try {
      return base64Decode(base64);
    } catch (_) {
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageData = widget.message.imageData;
    final imageType = widget.message.imageType;

    if (imageData != null && imageType != null) {
      final messageId = widget.message.id;
      if (_cachedMessageId != messageId) {
        _cachedBytes = _decodeImage(imageData);
        _cachedMessageId = messageId;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxWidth = widget.maxWidth > 1.0
            ? widget.maxWidth
            : constraints.maxWidth * widget.maxWidth;
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
                      if (imageData != null && imageType != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ChatoraiBorderRadius.sm,
                            ),
                            child: Image.memory(
                              _cachedBytes ?? Uint8List(0),
                              fit: BoxFit.contain,
                              width: effectiveMaxWidth,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                      if (widget.message.imageName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.message.imageName!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.message.attachedDocName != null)
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
                                  widget.message.attachedDocName!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.message.files.isNotEmpty &&
                          widget.message.imageData == null)
                        ...widget.message.files.map(
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
                      Text(
                        widget.message.content,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ActionRow(
              isUser: true,
              isLastMessage: false,
              content: widget.message.content,
              chatId: widget.chatId,
              messageId: widget.messageId,
              sessionRepository: widget.sessionRepository,
              onEdit: widget.onEdit,
              onMessageDeleted: widget.onMessageDeleted,
              onMessageRegenerate: widget.onMessageRegenerate,
              onContinuationSelected: widget.onContinuationSelected,
              agentName: null,
              model: null,
              timestamp: widget.timestamp,
            ),
          ],
        );
      },
    );
  }
}
