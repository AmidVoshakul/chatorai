import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:chatorai/widgets/chat/code_block.dart';
import 'package:chatorai/widgets/chat/scrollable_action_buttons.dart';
import 'package:chatorai/widgets/chat/error_message.dart';
import 'package:chatorai/widgets/chat/loading_indicator.dart';
import 'package:chatorai/utils/message_utils.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/utils/markdown_parser_with_keys.dart';
import 'package:chatorai/utils/format_time.dart';

// Initialize logger for this widget
final _logger = LogTags.message;

class ChatMessage extends StatefulWidget {
  final Message message;
  final bool isStreaming;
  final VoidCallback onRetry;
  final String chatId;
  final ChatStorageService chatStorageService;
  final VoidCallback onMessageDeleted; // Callback for when message is deleted
  final VoidCallback? onDelete;
  final Function(String, String)? onMessageEdited; // Callback for message edit (messageId, newContent)
  final Function(String)? onMessageUpdated; // Callback for when message content is updated (just edit) - legacy
  final Function(String, String)? onMessageEditAndSend; // Callback for edit + regenerate (messageId, newContent)
  final VoidCallback? onContinueResponse; // Callback for continuing response
  final bool isLastMessage; // Whether this is the last message in chat
  final List<MarkdownHeadingInfoWithKey>? headings; // Headings with keys for navigation

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
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> with TickerProviderStateMixin {
  // ===========================================================================
  // ANIMATION CONTROLLERS
  // ===========================================================================

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // ===========================================================================
  // STATE VARIABLES
  // ===========================================================================
  
  bool _isEditing = false; // Режим редактирования
  late TextEditingController _textController; // Контроллер для текста редактирования

  // ===========================================================================
  // LIFECYCLE METHODS
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    final previewLength = widget.message.content.length > 30 ? 30 : widget.message.content.length;
    _logger.logInfo('Initializing message widget for: ${widget.message.role} - ${widget.message.content.substring(0, previewLength)}...');
    
    // Инициализируем контроллер для редактирования
    _textController = TextEditingController(text: widget.message.content);
    
    // Слушаем изменения сообщения
    _textController.addListener(() {
      if (!_isEditing && _textController.text != widget.message.content) {
        _textController.text = widget.message.content;
      }
    });
    
    // Fade-in animation
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    // Slide-in animation
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update text controller if content changed
    if (oldWidget.message.content != widget.message.content) {
      _textController.value = TextEditingValue(
        text: widget.message.content,
        selection: TextSelection.collapsed(offset: widget.message.content.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.role == MessageRole.user;
    final localizations = AppLocalizations.of(context)!;

    // Если сообщение содержит ошибку, показываем ErrorMessage
    if (widget.message.isError) {
      return ErrorMessage(
        errorMessage: widget.message.content,
        chatId: widget.chatId,
        messageId: widget.message.id,
        chatStorageService: widget.chatStorageService,
        onMessageDeleted: widget.onMessageDeleted,
        onDelete: widget.onDelete,
        onMessageUpdated: widget.onMessageUpdated,
        isStreaming: widget.isStreaming, // Передаем флаг загрузки
        showLoadingFirst: widget.isStreaming, // Показываем загрузку перед ошибкой если идет потоковая передача
      );
    }

    // Если сообщение содержит reasoning, показываем ReasoningMessage
    // Но только если это не уже обрабатывается родительским компонентом
    if (widget.message.reasoning != null && widget.message.reasoning!.isNotEmpty) {
      _logger.logInfo('[ChatMessage] Message has reasoning content, but should be handled by parent. Showing regular message content instead.');
      // Don't return ReasoningMessage here - it should be handled by parent ChatMessages widget
      // Just continue to show the regular message content
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble (without actions)
            Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                // No avatar for any messages
                
                // User messages take responsive width, AI messages take full width
                isUser 
                  ? Flexible(
                      fit: FlexFit.loose,
                      flex: 8,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width < 800 
                            ? MediaQuery.of(context).size.width * 0.8  // Mobile: 80%
                            : MediaQuery.of(context).size.width * 0.6  // Desktop: 60%
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Preview (if message has image)
                            if (widget.message.imageData != null)
                              _buildImagePreview(),
                            
                            // Message Content
                            _buildMessageContent(context),
                            
                            // Error State
                            if (widget.message.isError)
                              _buildErrorMessage(),
                            
                            // Streaming Indicator - only show if no reasoning (reasoning handles its own indicator)
                            // This prevents duplicate indicators when reasoning is present
                            if (widget.isStreaming && 
                                widget.message.role == MessageRole.assistant &&
                                (widget.message.reasoning == null || widget.message.reasoning!.isEmpty))
                              _buildStreamingIndicator(),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                          width: 1,
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
                                  widget.message.role == MessageRole.assistant && widget.message.model != null
                                    ? widget.message.model!
                                    : widget.message.role.displayName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(widget.message.timestamp),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Image Preview (if message has image)
                          if (widget.message.imageData != null)
                            _buildImagePreview(),
                          
                          // Message Content
                          _buildMessageContent(context),
                          
                          // Error State
                          if (widget.message.isError)
                            _buildErrorMessage(),
                          
                          // Streaming Indicator - only show if no reasoning (reasoning handles its own indicator)
                          // This prevents duplicate indicators when reasoning is present
                          if (widget.isStreaming && 
                              widget.message.role == MessageRole.assistant &&
                              (widget.message.reasoning == null || widget.message.reasoning!.isEmpty))
                            _buildStreamingIndicator(),
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
                          size: 16,
                          color: theme.iconTheme.color?.withValues(alpha: 0.7),
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
                          size: 16,
                          color: theme.iconTheme.color?.withValues(alpha: 0.7),
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
                        Icons.copy_all, // Используем более современную иконку
                        size: 16, // Увеличиваем размер
                        color: theme.iconTheme.color?.withValues(alpha: 0.8), // Увеличиваем opacity
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
                      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.1), // Добавляем hover эффект
                      focusColor: theme.colorScheme.primary.withValues(alpha: 0.1), // Добавляем focus эффект
                    ),
                    
                    // Delete action for all messages
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        size: 16,
                        color: Colors.red.withValues(alpha: 0.7),
                      ),
                      onPressed: () async {
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
                          size: 16,
                          color: theme.iconTheme.color?.withValues(alpha: 0.7),
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
                          size: 16,
                          color: theme.iconTheme.color?.withValues(alpha: 0.7),
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
                      if (widget.isLastMessage && widget.message.content.isNotEmpty && 
                          (widget.message.content.endsWith('...') || 
                           widget.message.content.split(' ').length > 30 ||
                           !widget.message.isComplete))
                        IconButton(
                          icon: Icon(
                            Icons.play_arrow,
                            size: 16,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
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
                          size: 16,
                          color: theme.iconTheme.color?.withValues(alpha: 0.7),
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
                          size: 16,
                          color: theme.iconTheme.color?.withValues(alpha: 0.7),
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
    );
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  Widget _buildImagePreview() {
    if (widget.message.imageData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 200,
          ),
          child: Image.memory(
            base64Decode(widget.message.imageData!),
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (widget.message.content.isEmpty) {
      return const SizedBox.shrink();
    }

    // Режим inline редактирования
    if (_isEditing) {
      return _buildEditInterface(context);
    }

    // Check if content contains code blocks that need special handling
    if (widget.message.content.contains('```')) {
      return _buildCustomMarkdownContent(context);
    }

    // If headings are provided, use MarkdownWithHeadings
    if (widget.headings != null && widget.headings!.isNotEmpty) {
      // Filter headings that are in this message
      final messageHeadings = widget.headings!.where((h) {
        // Check if heading text is in this message content
        return widget.message.content.contains(h.text);
      }).toList();
      
      if (messageHeadings.isNotEmpty) {
        return MarkdownBody(
          data: widget.message.content,
          styleSheet: UbuntuMarkdownStyles.getMarkdownStyles(context),
          selectable: true,
          builders: {
            'h1': _HeadingBuilder(messageHeadings, level: 1),
            'h2': _HeadingBuilder(messageHeadings, level: 2),
            'h3': _HeadingBuilder(messageHeadings, level: 3),
            'h4': _HeadingBuilder(messageHeadings, level: 4),
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
      styleSheet: UbuntuMarkdownStyles.getMarkdownStyles(context),
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
    final List<Widget> contentWidgets = [];
    String currentTextBlock = '';
    bool inCodeBlock = false;
    String currentLanguage = 'text';
    String currentCodeBlock = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.startsWith('```')) {
        // Handle code block start/end
        if (inCodeBlock) {
          // End of code block
          if (currentTextBlock.isNotEmpty) {
            contentWidgets.add(
              MarkdownBody(
                data: currentTextBlock,
                styleSheet: UbuntuMarkdownStyles.getMarkdownStyles(context),
                selectable: true,
              ),
            );
            currentTextBlock = '';
          }
          if (currentCodeBlock.isNotEmpty) {
            contentWidgets.add(
              CodeBlock(
                code: currentCodeBlock,
                language: currentLanguage,
              ),
            );
            currentCodeBlock = '';
          }
          inCodeBlock = false;
        } else {
          // Start of code block
          if (currentTextBlock.isNotEmpty) {
            contentWidgets.add(
              MarkdownBody(
                data: currentTextBlock,
                styleSheet: UbuntuMarkdownStyles.getMarkdownStyles(context),
                selectable: true,
              ),
            );
            currentTextBlock = '';
          }
          inCodeBlock = true;
          currentLanguage = line.substring(3).trim();
          if (currentLanguage.isEmpty) currentLanguage = 'text';
        }
      } else if (inCodeBlock) {
        // Inside code block
        currentCodeBlock += '$line\n';
      } else {
        // Regular text
        currentTextBlock += '$line\n';
      }
    }

    // Add remaining text or code
    if (currentTextBlock.isNotEmpty) {
      contentWidgets.add(
        MarkdownBody(
          data: currentTextBlock,
          styleSheet: UbuntuMarkdownStyles.getMarkdownStyles(context),
          selectable: true,
        ),
      );
    }
    if (currentCodeBlock.isNotEmpty) {
      contentWidgets.add(
        CodeBlock(
          code: currentCodeBlock.trim(),
          language: currentLanguage,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }

  Widget _buildStreamingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ChatTypingDotsIndicator(
        dotSize: 6,
      ),
    );
  }

  Widget _buildErrorMessage() {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            localizations.failedToSendMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: widget.onRetry,
            child: Text(
              localizations.retry,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
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
    setState(() {
      _isEditing = true;
      // Обновляем текст в контроллере актуальным содержимым сообщения
      _textController.text = widget.message.content;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
    // Фокус на текстовом поле
    FocusScope.of(context).requestFocus(FocusNode());
  }

  /// Отмена редактирования
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    // Восстанавливаем оригинальный текст
    _textController.text = widget.message.content;
  }

  /// Сохранение изменений
  Future<void> _saveEditing() async {
    setState(() {
      _isEditing = false;
    });
    
    await _handleEditMessage(_textController.text);
  }

  /// Сохранение и отправка
  Future<void> _saveAndSend() async {
    setState(() {
      _isEditing = false;
    });
    
    await _handleEditAndSend(_textController.text);
  }

  /// Построение интерфейса редактирования
  Widget _buildEditInterface(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Текстовое поле для редактирования
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextField(
            controller: _textController,
            maxLines: null,
            minLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: localizations.enterYourMessage,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
        
        // Кнопки действий
        Row(
          children: [
            // Кнопка отмены/крестик - всегда слева
            if (MediaQuery.of(context).size.width < 800) ...[
              // Мобильная иконка отмены (красный крестик)
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.red,
                ),
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
            if (MediaQuery.of(context).size.width < 800) ...[
              // Мобильные иконки
              // Сохранить (зеленая галочка)
              IconButton(
                icon: Icon(
                  Icons.check,
                  size: 20,
                  color: Colors.green,
                ),
                onPressed: _saveEditing,
                tooltip: localizations.save,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              
              // Сохранить и отправить (оранжевый самолетик)
              IconButton(
                icon: Icon(
                  Icons.send,
                  size: 20,
                  color: theme.primaryColor,
                ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    setState(() {
      _isEditing = false;
    });
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
    setState(() {
      _isEditing = false;
    });
  }
}

class _HeadingBuilder extends MarkdownElementBuilder {
  final List<MarkdownHeadingInfoWithKey> headings;
  final int level;

  _HeadingBuilder(this.headings, {required this.level});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent.trim();
    
    // Find the matching heading with key
    final heading = headings.firstWhere(
      (h) => h.text == text && h.level == level,
      orElse: () {
        // This should not happen if headings are properly synced
        // Create a fallback key if no match found
        return MarkdownHeadingInfoWithKey(
          text: text,
          level: level,
          lineIndex: 0,
          rawLine: '',
          key: GlobalKey(),
        );
      },
    );

    return Container(
      key: heading.key,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: preferredStyle,
      ),
    );
  }
}
