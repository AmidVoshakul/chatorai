import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gen_ui_chat_ai/widgets/chat/code_block.dart';
import 'package:gen_ui_chat_ai/widgets/chat/scrollable_action_buttons.dart';
import 'package:gen_ui_chat_ai/widgets/chat/error_message.dart';
import 'package:gen_ui_chat_ai/widgets/chat/loading_indicator.dart';
import 'package:gen_ui_chat_ai/utils/message_utils.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';

// Import min function
import 'dart:math' show min;

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
  final VoidCallback? onMessageEdited;
  final Function(String)? onMessageUpdated; // Callback for when message content is updated
  final VoidCallback? onContinueResponse; // Callback for continuing response
  final bool isLastMessage; // Whether this is the last message in chat

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
    this.onContinueResponse,
    this.isLastMessage = false,
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
    _logger.logDebug('Message reasoning content length: ${widget.message.reasoning?.length ?? 0}');
    _logger.logDebug('Message isStreaming: ${widget.isStreaming}');
    
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
    
    _logger.logDebug('[ChatMessage] Widget updated - old reasoning length: ${oldWidget.message.reasoning?.length ?? 0}, new reasoning length: ${widget.message.reasoning?.length ?? 0}');
    _logger.logDebug('[ChatMessage] Widget updated - old isStreaming: ${oldWidget.isStreaming}, new isStreaming: ${widget.isStreaming}');
    _logger.logDebug('[ChatMessage] Widget updated - old content length: ${oldWidget.message.content.length}, new content length: ${widget.message.content.length}');
    
    // Если сообщение изменилось, обновляем контроллер
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
      _logger.logDebug('[ChatMessage] Reasoning content: "${widget.message.reasoning!.substring(0, min(widget.message.reasoning!.length, 100))}${widget.message.reasoning!.length > 100 ? '...' : ''}"');
      _logger.logDebug('[ChatMessage] isStreaming: ${widget.isStreaming}');
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
                              Text(
                                widget.message.role == MessageRole.assistant && widget.message.model != null
                                  ? widget.message.model!
                                  : widget.message.role.displayName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatTime(widget.message.timestamp),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
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
                        onPressed: () {
                          // TODO: Regenerate message
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

  Widget _buildMessageContent(BuildContext context) {
    if (widget.message.content.isEmpty) {
      return Container();
    }

    // Режим inline редактирования
    if (_isEditing) {
      return _buildEditInterface(context);
    }

    // Check if content contains code blocks that need special handling
    if (widget.message.content.contains('```')) {
      return _buildCustomMarkdownContent(context);
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
    final localizations = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return localizations.justNow;
    } else if (difference.inHours < 1) {
      return localizations.minAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      if (difference.inHours == 1) {
        return localizations.onlyOneHourAgo;
      }
      return localizations.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      if (difference.inDays == 1) {
        return localizations.onlyOneDayAgo;
      }
      return localizations.daysAgo(difference.inDays);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
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
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Отмена
            TextButton(
              onPressed: _cancelEditing,
              child: Text(
                localizations.cancel,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            
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
        ),
      ],
    );
  }

  /// Обработка редактирования сообщения
  Future<void> _handleEditMessage(String newContent) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      // Создаем обновленное сообщение
      final updatedMessage = widget.message.copyWith(content: newContent);
      
      // Сохраняем изменения в базе данных
      await widget.chatStorageService.updateMessageInChat(
        widget.chatId,
        widget.message.id,
        updatedMessage,
      );
      
      // Обновляем текст в контроллере
      _textController.text = newContent;
      
      // Уведомляем родительский компонент об изменении
      if (widget.onMessageUpdated != null) {
        widget.onMessageUpdated!(newContent);
      }
      
      // Показываем уведомление об успешном редактировании
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: localizations.messageEditedSuccessfully,
        icon: Icons.edit,
      );
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.failedToEditMessage,
        icon: Icons.error,
      );
    }
  }

  /// Обработка редактирования и отправки сообщения
  Future<void> _handleEditAndSend(String newContent) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      // Создаем обновленое сообщение
      final updatedMessage = widget.message.copyWith(content: newContent);
      
      // Сохраняем изменения в базе данных
      await widget.chatStorageService.updateMessageInChat(
        widget.chatId,
        widget.message.id,
        updatedMessage,
      );
      
      // Обновляем текст в контроллере
      _textController.text = newContent;
      
      // Уведомляем родительский компонент об изменении
      if (widget.onMessageUpdated != null) {
        widget.onMessageUpdated!(newContent);
      }
      
      // TODO: Здесь должна быть логика удаления последующих сообщений и генерации нового ответа
      
      // Показываем уведомление
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: localizations.messageEditedAndResponseRegenerated,
        icon: Icons.refresh,
      );
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.failedToEditAndSendMessage,
        icon: Icons.error,
      );
    }
  }
}

// Удаляем эти классы, так как они теперь в loading_indicator.dart
