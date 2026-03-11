import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:chatorai/widgets/chat/code_block.dart';
import 'package:chatorai/widgets/chat/scrollable_action_buttons.dart';
import 'package:chatorai/widgets/chat/error_message.dart';
import 'package:chatorai/widgets/chat/loading_indicator.dart';
import 'package:chatorai/utils/message_utils.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/constants/chat_constants.dart';
import 'package:chatorai/utils/markdown_parser.dart';
import 'package:chatorai/utils/format_time.dart';
import 'package:chatorai/providers/chat/chat_message_provider.dart';

// ===========================================================================
// CHAT MESSAGE WIDGET
// ===========================================================================

class ChatMessage extends ConsumerStatefulWidget {
  final Message message;
  final bool isStreaming;
  final VoidCallback onRetry;
  final String chatId;
  final ChatStorageService chatStorageService;
  final VoidCallback onMessageDeleted; // Callback for when message is deleted
  final VoidCallback? onDelete;
  final Function(String, String)?
  onMessageEdited; // Callback for message edit (messageId, newContent)
  final Function(String)?
  onMessageUpdated; // Callback for when message content is updated (just edit) - legacy
  final Function(String, String)?
  onMessageEditAndSend; // Callback for edit + regenerate (messageId, newContent)
  final VoidCallback? onContinueResponse; // Callback for continuing response
  final bool isLastMessage; // Whether this is the last message in chat
  final List<MarkdownHeadingInfoWithKey>?
  headings; // Headings with keys for navigation

  const ChatMessage({
    super.key,
    required this.message,
    required this.isStreaming,
    required this.onRetry,
    required this.chatId,
    required this.chatStorageService,
    required this.onMessageDeleted,
    this.onDelete,
    this.onMessageEdited,
    this.onMessageUpdated,
    this.onMessageEditAndSend,
    this.onContinueResponse,
    this.isLastMessage = false,
    this.headings,
  });

  @override
  ConsumerState<ChatMessage> createState() => _ChatMessageState();
}

// ===========================================================================
// CHAT MESSAGE STATE
// ===========================================================================

class _ChatMessageState extends ConsumerState<ChatMessage>
    with TickerProviderStateMixin {
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  AnimationController? _slideController;
  Animation<Offset>? _slideAnimation;

  late TextEditingController _textController;
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.message.content);
    _textController.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animationsInitialized) {
      _initAnimations();
    }
  }

  void _onTextChanged() {
    final isEditing = ref.watch(chatMessageProvider.select((s) => s.isEditing));
    if (!isEditing && _textController.text != widget.message.content) {
      _textController.text = widget.message.content;
    }
  }

  void _initAnimations() {
    if (_animationsInitialized) return;
    _animationsInitialized = true;

    _fadeController = AnimationController(
      duration: ChatoraiDurations.slow,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );
    _fadeController!.forward();

    _slideController = AnimationController(
      duration: ChatoraiDurations.normal,
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController!, curve: Curves.easeOut),
        );
    _slideController!.forward();
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _slideController?.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update text controller if content changed
    if (oldWidget.message.content != widget.message.content) {
      _textController.value = TextEditingValue(
        text: widget.message.content,
        selection: TextSelection.collapsed(
          offset: widget.message.content.length,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth < ChatScreenConstants.mobileBreakpoint;
    final isUser = widget.message.role == MessageRole.user;
    final isAssistant = widget.message.role == MessageRole.assistant;
    final hasImage = widget.message.imageData != null;
    final showStreaming =
        widget.isStreaming &&
        isAssistant &&
        (widget.message.reasoning == null || widget.message.reasoning!.isEmpty);

    if (widget.message.isError) {
      return ErrorMessage(
        errorMessage: widget.message.content,
        chatId: widget.chatId,
        messageId: widget.message.id,
        chatStorageService: widget.chatStorageService,
        onMessageDeleted: widget.onMessageDeleted,
        onDelete: widget.onDelete,
        onMessageUpdated: widget.onMessageUpdated,
        isStreaming: widget.isStreaming,
        showLoadingFirst: widget.isStreaming,
      );
    }

    // Убрали вызов _initAnimations() отсюда - теперь в didChangeDependencies()

    return RepaintBoundary(
      child: SlideTransition(
        position: _slideAnimation!,
        child: FadeTransition(
          opacity: _fadeAnimation!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Message bubble (without actions)
              Row(
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  // No avatar for any messages

                  // User messages take responsive width, AI messages take full width
                  isUser
                      ? Flexible(
                          fit: FlexFit.loose,
                          flex: 8,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: isMobile
                                  ? screenWidth * 0.8
                                  : screenWidth * 0.6,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: ChatoraiSpacing.md,
                              vertical: ChatoraiSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                ChatoraiBorderRadius.md,
                              ),
                              boxShadow: ChatoraiShadows.cardShadow,
                              border: Border.all(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: ChatoraiBorderWidth.thinBold,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image Preview (if message has image)
                                if (hasImage) _buildImagePreview(),

                                // Message Content
                                _buildMessageContent(context),

                                // Error State
                                if (widget.message.isError)
                                  _buildErrorMessage(),

                                // Streaming Indicator
                                if (showStreaming) _buildStreamingIndicator(),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ChatoraiSpacing.md,
                              vertical: ChatoraiSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(
                                ChatoraiBorderRadius.md,
                              ),
                              boxShadow: ChatoraiShadows.cardShadow,
                              border: Border.all(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: ChatoraiBorderWidth.thinBold,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Message Header
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isAssistant &&
                                                widget.message.model != null
                                            ? widget.message.model!
                                            : widget.message.role.displayName,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withValues(alpha: 0.7),
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: ChatoraiSpacing.sm),
                                    Text(
                                      _formatTime(widget.message.timestamp),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: ChatoraiSpacing.sm),

                                // Image Preview (if message has image)
                                if (hasImage) _buildImagePreview(),

                                // Message Content
                                _buildMessageContent(context),

                                // Error State
                                if (widget.message.isError)
                                  _buildErrorMessage(),

                                // Streaming Indicator
                                if (showStreaming) _buildStreamingIndicator(),
                              ],
                            ),
                          ),
                        ),
                ],
              ),

              // Message Actions (outside the message bubble, on main chat background)
              if (!widget.isStreaming)
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  alignment: Alignment.centerRight,
                  child: ScrollableActionButtons(
                    buttonSpacing: 4.0,
                    height: 40.0,
                    children: [
                      // User message actions (only edit and copy)
                      if (isUser) ...[
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: ChatoraiIconSizes.actionIcon,
                            color: theme.iconTheme.color?.withValues(
                              alpha: ChatoraiIconOpacity.medium,
                            ),
                          ),
                          onPressed: _startEditing,
                          tooltip: localizations.edit,
                          splashRadius: 20,
                        ),
                      ],

                      // Share action for assistant messages
                      if (!isUser) ...[
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            size: ChatoraiIconSizes.actionIcon,
                            color: theme.iconTheme.color?.withValues(
                              alpha: ChatoraiIconOpacity.medium,
                            ),
                          ),
                          onPressed: () {
                            MessageUtils.shareMessage(
                              content: widget.message.content,
                              context: context,
                            );
                          },
                          tooltip: localizations.share,
                          splashRadius: 20,
                        ),
                      ],

                      // Universal copy action
                      IconButton(
                        icon: Icon(
                          Icons.copy_all,
                          size: ChatoraiIconSizes.actionIcon,
                          color: theme.iconTheme.color?.withValues(alpha: 0.8),
                        ),
                        onPressed: () {
                          // Копируем сообщение без добавления имени отправителя
                          // (для одиночных сообщений это не нужно)
                          MessageUtils.copyMessage(
                            content: widget.message.content,
                            context: context,
                            senderName: null, // Не добавляем имя отправителя
                          );
                        },
                        tooltip: localizations.copyMessage, // Улучшаем tooltip
                        splashRadius: 24, // Увеличиваем радиус клика
                        hoverColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ), // Добавляем hover эффект
                        focusColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ), // Добавляем focus эффект
                      ),

                      // Delete action for all messages
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: ChatoraiIconSizes.actionIcon,
                          color: Colors.red.withValues(alpha: 0.7),
                        ),
                        onPressed: () async {
                          // Close keyboard before deleting
                          FocusScope.of(context).unfocus();

                          final bool deleted = await MessageUtils.deleteMessage(
                            chatId: widget.chatId,
                            messageId: widget.message.id,
                            chatStorageService: widget.chatStorageService,
                            context: context,
                          );

                          if (deleted) {
                            widget.onMessageDeleted();
                          }
                        },
                        tooltip: localizations.delete,
                        splashRadius: 20,
                      ),

                      // AI-specific actions (only for assistant messages)
                      if (!isUser) ...[
                        // Listen button
                        IconButton(
                          icon: Icon(
                            Icons.volume_up,
                            size: ChatoraiIconSizes.actionIcon,
                            color: theme.iconTheme.color?.withValues(
                              alpha: ChatoraiIconOpacity.medium,
                            ),
                          ),
                          onPressed: () {
                            // TODO: Voice message
                          },
                          tooltip: localizations.listen,
                          splashRadius: 20,
                        ),

                        // Regenerate button
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            size: ChatoraiIconSizes.actionIcon,
                            color: theme.iconTheme.color?.withValues(
                              alpha: ChatoraiIconOpacity.medium,
                            ),
                          ),
                          onPressed: () async {
                            await MessageUtils.regenerateMessage(
                              chatId: widget.chatId,
                              messageId: widget.message.id,
                              chatStorageService: widget.chatStorageService,
                              onRegenerate: () {
                                // Вызываем callback родителя для перегенерации
                                if (widget.onMessageUpdated != null) {
                                  widget.onMessageUpdated!('REGENERATE');
                                }
                              },
                            );
                          },
                          tooltip: localizations.regenerate,
                          splashRadius: 20,
                        ),

                        // Continue response button (only show for recent assistant messages that might be incomplete)
                        if (widget.isLastMessage &&
                            widget.message.content.isNotEmpty &&
                            (widget.message.content.endsWith('...') ||
                                widget.message.content.split(' ').length > 30 ||
                                !widget.message.isComplete))
                          IconButton(
                            icon: Icon(
                              Icons.play_arrow,
                              size: ChatoraiIconSizes.actionIcon,
                              color: theme.colorScheme.primary.withValues(
                                alpha: ChatoraiIconOpacity.medium,
                              ),
                            ),
                            onPressed: () {
                              if (widget.onContinueResponse != null) {
                                widget.onContinueResponse!();
                              }
                            },
                            tooltip: localizations.continueResponse,
                            splashRadius: 20,
                          ),

                        // Like button
                        IconButton(
                          icon: Icon(
                            Icons.thumb_up,
                            size: ChatoraiIconSizes.actionIcon,
                            color: theme.iconTheme.color?.withValues(
                              alpha: ChatoraiIconOpacity.medium,
                            ),
                          ),
                          onPressed: () {
                            // TODO: Like message
                          },
                          tooltip: localizations.like,
                          splashRadius: 20,
                        ),

                        // Dislike button
                        IconButton(
                          icon: Icon(
                            Icons.thumb_down,
                            size: ChatoraiIconSizes.actionIcon,
                            color: theme.iconTheme.color?.withValues(
                              alpha: ChatoraiIconOpacity.medium,
                            ),
                          ),
                          onPressed: () {
                            // TODO: Dislike message
                          },
                          tooltip: localizations.dislike,
                          splashRadius: 20,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  Widget _buildImagePreview() {
    if (widget.message.imageData == null) {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, child) {
        // Кэшированное декодирование через provider
        final decodedImage = ref.watch(
          imageCacheProvider(widget.message.imageData!),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
            border: Border.all(
              color: ChatoraiColors.neonBlue.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200.0),
              child: Image.memory(
                decodedImage,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (widget.message.content.isEmpty) {
      return const SizedBox.shrink();
    }

    // Режим inline редактирования
    final isEditing = ref.watch(chatMessageProvider.select((s) => s.isEditing));
    if (isEditing) {
      return _buildEditInterface(context);
    }

    // Check if content contains code blocks that need special handling
    if (widget.message.content.contains('```')) {
      return _buildCustomMarkdownContent(context);
    }

    // If headings are provided, use MarkdownWithHeadings
    if (widget.headings != null && widget.headings!.isNotEmpty) {
      // Filter headings for this specific message by messageId
      final messageHeadings = widget.headings!
          .where((h) => h.messageId == widget.message.id)
          .toList();

      if (messageHeadings.isNotEmpty) {
        return MarkdownBody(
          data: widget.message.content,
          styleSheet: ChatoraiMarkdownStyles.getMarkdownStyles(context),
          selectable: true,
          builders: {
            'h1': _HeadingBuilder(
              messageHeadings,
              level: 1,
              messageId: widget.message.id,
            ),
            'h2': _HeadingBuilder(
              messageHeadings,
              level: 2,
              messageId: widget.message.id,
            ),
            'h3': _HeadingBuilder(
              messageHeadings,
              level: 3,
              messageId: widget.message.id,
            ),
          },
          onTapLink: (text, href, title) {
            if (href != null) {
              // TODO: Handle link tapping
            }
          },
        );
      }
    }

    return MarkdownBody(
      data: widget.message.content,
      styleSheet: ChatoraiMarkdownStyles.getMarkdownStyles(context),
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          // TODO: Handle link tapping
        }
      },
    );
  }

  Widget _buildCustomMarkdownContent(BuildContext context) {
    final lines = widget.message.content.split('\n');
    final styleSheet = ChatoraiMarkdownStyles.getMarkdownStyles(context);

    final messageHeadings =
        widget.headings
            ?.where((h) => h.messageId == widget.message.id)
            .toList() ??
        [];

    final List<Widget> contentWidgets = [];
    String currentTextBlock = '';
    bool inCodeBlock = false;
    String currentLanguage = 'text';
    String currentCodeBlock = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('```')) {
        if (inCodeBlock) {
          if (currentTextBlock.isNotEmpty) {
            contentWidgets.add(
              _buildMarkdownBlock(
                currentTextBlock,
                styleSheet,
                messageHeadings,
              ),
            );
            currentTextBlock = '';
          }
          if (currentCodeBlock.isNotEmpty) {
            contentWidgets.add(
              CodeBlock(code: currentCodeBlock, language: currentLanguage),
            );
            currentCodeBlock = '';
          }
          inCodeBlock = false;
        } else {
          if (currentTextBlock.isNotEmpty) {
            contentWidgets.add(
              _buildMarkdownBlock(
                currentTextBlock,
                styleSheet,
                messageHeadings,
              ),
            );
            currentTextBlock = '';
          }
          inCodeBlock = true;
          currentLanguage = line.substring(3).trim();
          if (currentLanguage.isEmpty) currentLanguage = 'text';
        }
      } else if (inCodeBlock) {
        currentCodeBlock += '$line\n';
      } else {
        currentTextBlock += '$line\n';
      }
    }

    if (currentTextBlock.isNotEmpty) {
      contentWidgets.add(
        _buildMarkdownBlock(currentTextBlock, styleSheet, messageHeadings),
      );
    }
    if (currentCodeBlock.isNotEmpty) {
      contentWidgets.add(
        CodeBlock(code: currentCodeBlock.trim(), language: currentLanguage),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }

  Widget _buildMarkdownBlock(
    String data,
    MarkdownStyleSheet styleSheet,
    List<MarkdownHeadingInfoWithKey> messageHeadings,
  ) {
    return MarkdownBody(
      data: data,
      styleSheet: styleSheet,
      selectable: true,
      builders: {
        'h1': _HeadingBuilder(
          messageHeadings,
          level: 1,
          messageId: widget.message.id,
        ),
        'h2': _HeadingBuilder(
          messageHeadings,
          level: 2,
          messageId: widget.message.id,
        ),
        'h3': _HeadingBuilder(
          messageHeadings,
          level: 3,
          messageId: widget.message.id,
        ),
      },
    );
  }

  Widget _buildStreamingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: ChatoraiSpacing.sm),
      child: ChatTypingDotsIndicator(dotSize: 6),
    );
  }

  Widget _buildErrorMessage() {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final bodySmallStyle = theme.textTheme.bodySmall;

    return Container(
      margin: const EdgeInsets.only(top: ChatoraiSpacing.sm),
      padding: const EdgeInsets.all(ChatoraiSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error,
            color: Colors.red,
            size: ChatoraiIconSizes.actionIcon,
          ),
          const SizedBox(width: 4),
          Text(
            localizations.failedToSendMessage,
            style: bodySmallStyle?.copyWith(color: Colors.red),
          ),
          const Spacer(),
          TextButton(
            onPressed: widget.onRetry,
            child: Text(
              localizations.retry,
              style: bodySmallStyle?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return formatMessageTime(dateTime, context: context);
  }

  // ===========================================================================
  // EDITING METHODS
  // ===========================================================================

  /// Переключение в режим редактирования
  void _startEditing() {
    ref.read(chatMessageProvider.notifier).startEditing(widget.message.content);
    _textController.text = widget.message.content;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  /// Отмена редактирования
  void _cancelEditing() {
    ref.read(chatMessageProvider.notifier).cancelEditing();
    // Восстанавливаем оригинальный текст
    _textController.text = widget.message.content;
  }

  /// Сохранение изменений
  Future<void> _saveEditing() async {
    ref.read(chatMessageProvider.notifier).saveEditing();
    await _handleEditMessage(_textController.text);
  }

  /// Сохранение и отправка
  Future<void> _saveAndSend() async {
    ref.read(chatMessageProvider.notifier).saveEditing();
    await _handleEditAndSend(_textController.text);
  }

  /// Построение интерфейса редактирования
  Widget _buildEditInterface(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isMobile =
        MediaQuery.of(context).size.width <
        ChatScreenConstants.mobileBreakpoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Текстовое поле для редактирования
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

        // Кнопки действий
        Row(
          children: [
            // Кнопка отмены/крестик - всегда слева
            if (isMobile) ...[
              // Мобильная иконка отмены (красный крестик)
              IconButton(
                icon: Icon(Icons.close, size: 20, color: Colors.red),
                onPressed: _cancelEditing,
                tooltip: localizations.cancel,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ] else ...[
              // Десктоп текстовая отмена
              TextButton(
                onPressed: _cancelEditing,
                child: Text(
                  localizations.cancel,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
              ),
            ],

            // Spacer чтобы отодвинуть остальные кнопки вправо
            const Spacer(),

            // Остальные кнопки (сохранить, сохранить и отправить) - справа
            if (isMobile) ...[
              // Мобильные иконки
              // Сохранить (зеленая галочка)
              IconButton(
                icon: Icon(Icons.check, size: 20, color: Colors.green),
                onPressed: _saveEditing,
                tooltip: localizations.save,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),

              // Сохранить и отправить (оранжевый самолетик)
              IconButton(
                icon: Icon(Icons.send, size: 20, color: theme.primaryColor),
                onPressed: _saveAndSend,
                tooltip: localizations.saveAndSend,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ] else ...[
              // Десктоп текстовые кнопки
              // Сохранить
              TextButton(
                onPressed: _saveEditing,
                child: Text(
                  localizations.save,
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),

              // Сохранить и отправить
              ElevatedButton(
                onPressed: _saveAndSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ChatoraiBorderRadius.xs,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChatoraiSpacing.lg,
                    vertical: ChatoraiSpacing.sm,
                  ),
                ),
                child: Text(localizations.saveAndSend),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Обработка редактирования сообщения (только уведомление родителя)
  Future<void> _handleEditMessage(String newContent) async {
    // Просто уведомляем родительский компонент об изменении
    // Сохранение и обновление UI будет в ChatScreen
    if (widget.onMessageEdited != null) {
      widget.onMessageEdited!(widget.message.id, newContent);
    } else if (widget.onMessageUpdated != null) {
      widget.onMessageUpdated!(newContent);
    }

    // Обновляем текст в контроллере
    _textController.text = newContent;

    // Выходим из режима редактирования
    ref.read(chatMessageProvider.notifier).saveEditing();
  }

  /// Обработка редактирования и отправки сообщения
  Future<void> _handleEditAndSend(String newContent) async {
    // Уведомляем родительский компонент об изменении и необходимости regeneration
    // Вся логика (сохранение, удаление ответов, генерация) будет в ChatScreen
    if (widget.onMessageEditAndSend != null) {
      await widget.onMessageEditAndSend!(widget.message.id, newContent);
    } else if (widget.onMessageUpdated != null) {
      // Fallback для совместимости
      widget.onMessageUpdated!(newContent);
    }

    // Обновляем текст в контроллере
    _textController.text = newContent;

    // Выходим из режима редактирования
    ref.read(chatMessageProvider.notifier).saveEditing();
  }
}

class _HeadingBuilder extends MarkdownElementBuilder {
  final List<MarkdownHeadingInfoWithKey> headings;
  final int level;
  final String messageId;

  _HeadingBuilder(
    this.headings, {
    required this.level,
    required this.messageId,
  });

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final rawText = element.textContent.trim();
    final normalizedText = stripMarkdownFormatting(rawText);

    final anchorId = '${messageId}_${level}_$normalizedText';
    var anchor = HeadingAnchorRegistry().getAnchor(anchorId);

    if (anchor == null) {
      anchor = HeadingAnchor(
        id: anchorId,
        text: normalizedText,
        level: level,
        lineIndex: 0,
        rawLine: rawText,
        messageId: messageId,
      );
      HeadingAnchorRegistry().registerAnchor(anchor);
    }

    return _HeadingAnchorWidget(
      key: ValueKey('heading_$anchorId'),
      anchor: anchor,
      child: Container(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(rawText, style: preferredStyle),
      ),
    );
  }
}

class _HeadingAnchorWidget extends StatefulWidget {
  final HeadingAnchor? anchor;
  final Widget child;

  const _HeadingAnchorWidget({super.key, this.anchor, required this.child});

  @override
  State<_HeadingAnchorWidget> createState() => _HeadingAnchorWidgetState();
}

class _HeadingAnchorWidgetState extends State<_HeadingAnchorWidget> {
  static final _registry = HeadingAnchorRegistry();

  @override
  void initState() {
    super.initState();
    if (widget.anchor != null) {
      _registry.registerAnchor(widget.anchor!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.anchor != null) {
      widget.anchor!.context = context;
      _registry.registerAnchor(widget.anchor!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
