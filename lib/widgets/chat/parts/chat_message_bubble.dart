import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_message.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/utils/format_time.dart';
import 'package:chatorai/utils/message_utils.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/widgets/chat/parts/text_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/reasoning_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/tool_call_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/tool_result_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/task_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/question_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/todo_part_widget.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final String chatId;
  final String messageId;
  final ChatStorageService chatStorageService;
  final Future<void> Function(String)? onContinuationSelected;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Function(String, String)? onMessageEdited;
  final Function(String, String)? onMessageEditedAndSend;
  final bool isLastMessage;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.chatId,
    required this.messageId,
    required this.chatStorageService,
    this.onContinuationSelected,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onMessageEdited,
    this.onMessageEditedAndSend,
    this.isLastMessage = false,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isEditing = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _textController.text = _getMessageContent();
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _textController.text = _getMessageContent();
    });
  }

  Future<void> _saveEditing() async {
    final newContent = _textController.text.trim();
    if (newContent.isNotEmpty && newContent != _getMessageContent()) {
      widget.onMessageEdited?.call(widget.messageId, newContent);
    }
    setState(() => _isEditing = false);
  }

  Future<void> _saveAndSend() async {
    final newContent = _textController.text.trim();
    if (newContent.isNotEmpty) {
      widget.onMessageEditedAndSend?.call(widget.messageId, newContent);
    }
    setState(() => _isEditing = false);
  }

  String _getMessageContent() {
    return switch (widget.message) {
      UserMessage m => m.content,
      AssistantMessage m => m.parts
          .whereType<TextPart>()
          .map((p) => p.content)
          .join('\n'),
      SystemMessage m => m.content,
      ErrorMessage m => m.content,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && widget.message is UserMessage) {
      return _buildEditInterface();
    }
    return switch (widget.message) {
      UserMessage m => _userBubble(m, context),
      AssistantMessage m => _assistantBubble(m, context),
      SystemMessage m => _systemBubble(m, context),
      ErrorMessage m => _errorBubble(m, context),
    };
  }

  Widget _buildEditInterface() {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextField(
            controller: _textController,
            maxLines: null,
            minLines: 3,
            decoration: InputDecoration(
              hintText: localizations.enterYourMessage,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
            style: TextStyle(
              fontSize: ChatoraiFontSizes.base,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.red),
                onPressed: _cancelEditing,
                tooltip: localizations.cancel,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              )
            else
              TextButton(
                onPressed: _cancelEditing,
                child: Text(localizations.cancel),
              ),
            const Spacer(),
            if (isMobile) ...[
              IconButton(
                icon: const Icon(Icons.check, size: 20, color: Colors.green),
                onPressed: _saveEditing,
                tooltip: localizations.save,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, size: 20, color: theme.colorScheme.primary),
                onPressed: _saveAndSend,
                tooltip: localizations.saveAndSend,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ] else ...[
              TextButton(
                onPressed: _saveEditing,
                child: Text(localizations.save),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saveAndSend,
                child: Text(localizations.saveAndSend),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _buildActionRow(isUser: true, content: _textController.text),
      ],
    );
  }

  Widget _userBubble(UserMessage m, BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatoraiSpacing.md,
                vertical: ChatoraiSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.files.isNotEmpty)
                    ...m.files.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SelectableText(
                          f,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  SelectableText(m.content, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
        _buildActionRow(isUser: true, content: m.content),
      ],
    );
  }

  Widget _assistantBubble(AssistantMessage m, BuildContext context) {
    if (m.parts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textContent = m.parts
        .whereType<TextPart>()
        .map((p) => p.content)
        .join('\n');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.md,
            vertical: ChatoraiSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
            boxShadow: ChatoraiShadows.cardShadow,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: ChatoraiBorderWidth.thinBold,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...m.parts.map((part) => _buildPart(part, context)),
              if (m.model != null) ...[
                const SizedBox(height: ChatoraiSpacing.sm),
                _AssistantHeader(model: m.model!, timestamp: m.timestamp),
              ],
            ],
          ),
        ),
        _buildActionRow(
          isUser: false,
          content: textContent,
          isLastMessage: widget.isLastMessage && m.isStreaming,
        ),
        if (!m.isStreaming && m.continuationSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ContinuationSuggestions(
              suggestions: m.continuationSuggestions,
              onSelected: widget.onContinuationSelected,
            ),
          ),
      ],
    );
  }

  Widget _buildPart(MessagePart part, BuildContext context) {
    return switch (part) {
      TextPart p => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextPartWidget(part: p),
        ),
      ReasoningPart p => ReasoningPartWidget(part: p),
      ToolCallPart p => ToolCallPartWidget(part: p),
      ToolResultPart p => ToolResultPartWidget(part: p),
      TaskPart p => TaskPartWidget(part: p),
      QuestionPart p => QuestionPartWidget(part: p),
      TodoPart p => TodoPartWidget(part: p),
    };
  }

  Widget _systemBubble(SystemMessage m, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        m.content,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _errorBubble(ErrorMessage m, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(ChatoraiSpacing.md),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: ChatoraiIconSizes.lg),
          const SizedBox(width: ChatoraiSpacing.sm),
          Expanded(child: SelectableText(m.content, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required bool isUser,
    required String? content,
    bool isLastMessage = false,
  }) {
    return _ActionRow(
      isUser: isUser,
      content: content,
      isLastMessage: isLastMessage,
      chatId: widget.chatId,
      messageId: widget.messageId,
      chatStorageService: widget.chatStorageService,
      onEdit: isUser ? _startEditing : null,
      onMessageDeleted: widget.onMessageDeleted,
      onMessageRegenerate: widget.onMessageRegenerate,
      onContinuationSelected: widget.onContinuationSelected,
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  final String model;
  final DateTime timestamp;

  const _AssistantHeader({required this.model, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedTime = formatMessageTime(timestamp, context: context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '$model · $formattedTime',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool isUser;
  final bool isLastMessage;
  final String? content;
  final String chatId;
  final String messageId;
  final ChatStorageService chatStorageService;
  final VoidCallback? onEdit;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Future<void> Function(String)? onContinuationSelected;

  const _ActionRow({
    required this.isUser,
    required this.isLastMessage,
    this.content,
    required this.chatId,
    required this.messageId,
    required this.chatStorageService,
    this.onEdit,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onContinuationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color?.withValues(
      alpha: ChatoraiIconOpacity.medium,
    );
    final localizations = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // User message: Edit
        if (isUser && onEdit != null)
          IconButton(
            icon: Icon(Icons.edit, size: ChatoraiIconSizes.actionIcon, color: iconColor),
            onPressed: onEdit,
            splashRadius: 20,
            tooltip: localizations.edit,
          ),

        // Assistant message: Share
        if (!isUser)
          IconButton(
            icon: Icon(Icons.share, size: ChatoraiIconSizes.actionIcon, color: iconColor),
            onPressed: content != null
                ? () => MessageUtils.shareMessage(content: content!, context: context)
                : null,
            splashRadius: 20,
            tooltip: localizations.share,
          ),

        // All messages: Copy
        IconButton(
          icon: Icon(Icons.copy_all, size: ChatoraiIconSizes.actionIcon, color: theme.iconTheme.color?.withValues(alpha: 0.8)),
          onPressed: content != null
              ? () => MessageUtils.copyMessage(content: content!, context: context)
              : null,
          splashRadius: 24,
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          focusColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          tooltip: localizations.copyMessage,
        ),

        // All messages: Delete
        IconButton(
          icon: Icon(Icons.delete, size: ChatoraiIconSizes.actionIcon, color: Colors.red.withValues(alpha: 0.7)),
          onPressed: () async {
            FocusScope.of(context).unfocus();
            final deleted = await MessageUtils.deleteMessage(
              chatId: chatId,
              messageId: messageId,
              chatStorageService: chatStorageService,
              context: context,
            );
            if (deleted) {
              onMessageDeleted?.call();
            }
          },
          splashRadius: 20,
          tooltip: localizations.delete,
        ),

        // // Assistant only: Listen
        // if (!isUser)
        //   IconButton(
        //     icon: Icon(Icons.volume_up, size: ChatoraiIconSizes.actionIcon, color: iconColor),
        //     onPressed: null,
        //     splashRadius: 20,
        //     tooltip: localizations.listen,
        //   ),

        // Assistant only: Regenerate
        if (!isUser)
          IconButton(
            icon: Icon(Icons.refresh, size: ChatoraiIconSizes.actionIcon, color: iconColor),
            onPressed: () async {
              await MessageUtils.regenerateMessage(
                chatId: chatId,
                messageId: messageId,
                chatStorageService: chatStorageService,
                onRegenerate: () => onMessageRegenerate?.call(),
              );
            },
            splashRadius: 20,
            tooltip: localizations.regenerate,
          ),

        // Assistant only: Continue (conditional)
        if (!isUser &&
            isLastMessage &&
            content != null &&
            content!.isNotEmpty &&
            (content!.endsWith('...') || content!.split(' ').length > 30))
          IconButton(
            icon: Icon(Icons.play_arrow, size: ChatoraiIconSizes.actionIcon, color: theme.colorScheme.primary.withValues(alpha: ChatoraiIconOpacity.medium)),
            onPressed: onContinuationSelected != null
                ? () => onContinuationSelected!(content!)
                : null,
            splashRadius: 20,
            tooltip: localizations.continueResponse,
          ),
      ],
    );
  }
}

class _ContinuationSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Future<void> Function(String)? onSelected;

  const _ContinuationSuggestions({
    required this.suggestions,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          onPressed: () => onSelected?.call(suggestion),
        );
      }).toList(),
    );
  }
}