import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/data/providers/chat_screen_notifier.dart';
import 'package:chatorai/features/chat/data/repositories/chat_storage_service.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/question_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/reasoning_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/task_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/text_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/todo_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_call_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_result_part_widget.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/format_time_utils.dart';
import 'package:chatorai/shared/utils/message_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final String chatId;
  final String messageId;
  final ChatStorageService chatStorageService;
  final String? agentName;
  final Future<void> Function(String)? onContinuationSelected;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Function(String, String)? onMessageEdited;
  final Function(String, String)? onMessageEditedAndSend;
  final bool isLastMessage;
  final Function(String messageId, String answer)? onQuestionAnswer;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.chatId,
    required this.messageId,
    required this.chatStorageService,
    this.agentName,
    this.onContinuationSelected,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onMessageEdited,
    this.onMessageEditedAndSend,
    this.isLastMessage = false,
    this.onQuestionAnswer,
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
      AssistantMessage m =>
        m.parts.whereType<TextPart>().map((p) => p.content).join('\n'),
      SystemMessage m => m.content,
      ErrorMessage m => m.content,
      ChatMessage() => '',
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
      ChatMessage() => const SizedBox.shrink(),
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
                icon: Icon(
                  Icons.send,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
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
        _buildActionRow(
          isUser: true,
          content: m.content,
          timestamp: m.timestamp,
        ),
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

    // Render parts sequentially: Reasoning → Tools → Text → Question → Todo
    // Tools and Questions are rendered as standalone widgets, NOT inside reasoning block
    List<Widget> groupedParts = [];

    for (final part in m.parts) {
      if (part is ReasoningPart) {
        groupedParts.add(ReasoningPartWidget(part: part));
      } else if (part is ToolCallPart || part is ToolResultPart) {
        groupedParts.add(_buildPart(part, context));
      } else {
        groupedParts.add(_buildPart(part, context));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
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
              children: groupedParts,
            ),
          ),
        ),
        _buildActionRow(
          isUser: false,
          content: textContent,
          isLastMessage: widget.isLastMessage && m.isStreaming,
          cumulativeTokens: m.cumulativeTokens,
          contextLength: m.contextLength,
          agentName: widget.agentName,
          model: m.model,
          timestamp: m.timestamp,
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
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: TextPartWidget(part: p),
      ),
      ReasoningPart p => ReasoningPartWidget(part: p),
      ToolCallPart p => Padding(
        padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.sm),
        child: Opacity(opacity: 0.3, child: ToolCallPartWidget(part: p)),
      ),
      ToolResultPart p => Padding(
        padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.sm),
        child: Opacity(opacity: 0.3, child: ToolResultPartWidget(part: p)),
      ),
      TaskPart p => TaskPartWidget(part: p),
      QuestionPart p => QuestionPartWidget(
        part: p,
        onAnswer: (answer) =>
            widget.onQuestionAnswer?.call(widget.messageId, answer),
      ),
      TodoPart p => TodoPartWidget(part: p),
      MessagePart() => const SizedBox.shrink(),
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
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: ChatoraiIconSizes.lg,
          ),
          const SizedBox(width: ChatoraiSpacing.sm),
          Expanded(
            child: SelectableText(m.content, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required bool isUser,
    required String? content,
    bool isLastMessage = false,
    int? cumulativeTokens,
    int? contextLength,
    String? agentName,
    String? model,
    DateTime? timestamp,
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
      cumulativeTokens: cumulativeTokens,
      contextLength: contextLength,
      agentName: agentName,
      model: model,
      timestamp: timestamp,
    );
  }
}

String _formatTokenCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
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
  final int? cumulativeTokens;
  final int? contextLength;
  final String? agentName;
  final String? model;
  final DateTime? timestamp;

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
    this.cumulativeTokens,
    this.contextLength,
    this.agentName,
    this.model,
    this.timestamp,
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
            _ActionMenuButton(
              isUser: true,
              content: content,
              chatId: chatId,
              messageId: messageId,
              chatStorageService: chatStorageService,
              onEdit: onEdit,
              onMessageDeleted: onMessageDeleted,
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
                _ActionMenuButton(
                  isUser: false,
                  content: content,
                  chatId: chatId,
                  messageId: messageId,
                  chatStorageService: chatStorageService,
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
          // Retry indicator (last assistant message only) or token count
          Consumer(
            builder: (context, ref, _) {
              final retryState = ref.watch(chatScreenProvider);
              if (isLastMessage && retryState.isRetrying) {
                return _RetryIndicator(
                  message: retryState.retryMessage ?? 'Retrying…',
                );
              }
              if (cumulativeTokens != null) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Text(
                    _tokenDisplay(cumulativeTokens!, contextLength),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

String _tokenDisplay(int cumulativeTokens, int? contextLength) {
  final count = _formatTokenCount(cumulativeTokens);
  if (contextLength != null && contextLength > 0) {
    final pct = (cumulativeTokens / contextLength * 100).toStringAsFixed(0);
    return '$count ($pct%)';
  }
  return count;
}

class _RetryIndicator extends StatelessWidget {
  final String message;

  const _RetryIndicator({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ChatoraiColors.error;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ActionMenuButton extends StatelessWidget {
  final bool isUser;
  final String? content;
  final String chatId;
  final String messageId;
  final ChatStorageService chatStorageService;
  final VoidCallback? onEdit;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Future<void> Function(String)? onContinuationSelected;
  final bool isLastMessage;
  final ThemeData theme;
  final AppLocalizations localizations;

  const _ActionMenuButton({
    required this.isUser,
    this.content,
    required this.chatId,
    required this.messageId,
    required this.chatStorageService,
    this.onEdit,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onContinuationSelected,
    this.isLastMessage = false,
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
        if (isLastMessage &&
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
          chatStorageService: chatStorageService,
          context: context,
        );
        if (deleted) onMessageDeleted?.call();
      case 'regenerate':
        await MessageUtils.regenerateMessage(
          chatId: chatId,
          messageId: messageId,
          chatStorageService: chatStorageService,
          onRegenerate: () => onMessageRegenerate?.call(),
        );
      case 'continue':
        if (content != null) onContinuationSelected?.call(content!);
    }
  }
}

class _ContinuationSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Future<void> Function(String)? onSelected;

  const _ContinuationSuggestions({required this.suggestions, this.onSelected});

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
