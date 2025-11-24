import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gen_ui_chat_ai/widgets/chat/code_block.dart';
import 'package:gen_ui_chat_ai/widgets/chat/scrollable_action_buttons.dart';
import 'package:gen_ui_chat_ai/utils/message_utils.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';

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
    Key? key,
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
  }) : super(key: key);

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  bool _isEditing = false; // Режим редактирования
  late TextEditingController _textController; // Контроллер для текста редактирования

  @override
  void initState() {
    super.initState();
    final previewLength = widget.message.content.length > 30 ? 30 : widget.message.content.length;
    print('[ChatMessage] 🎨 Initializing message widget for: ${widget.message.role} - ${widget.message.content.substring(0, previewLength)}...');
    
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.role == MessageRole.user;

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
                            
                            // Streaming Indicator
                            if (widget.isStreaming && widget.message.role == MessageRole.assistant)
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
                          
                          // Streaming Indicator
                          if (widget.isStreaming && widget.message.role == MessageRole.assistant)
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
                        tooltip: 'Edit',
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
                        tooltip: 'Share',
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
                      tooltip: 'Copy message (text or markdown)', // Улучшаем tooltip
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
                      tooltip: 'Delete',
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
                        tooltip: 'Listen',
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
                        tooltip: 'Regenerate',
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
                          tooltip: 'Continue',
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
                        tooltip: 'Like',
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
                        tooltip: 'Dislike',
                        splashRadius: 20,
                      ),
                    ],
                  ],
                  buttonSpacing: 4.0,
                  height: 40.0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final theme = Theme.of(context);
    
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
      styleSheet: MarkdownStyleSheet.fromTheme(theme),
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          // TODO: Handle link tapping
        }
      },
    );
  }

  Widget _buildCustomMarkdownContent(BuildContext context) {
    final theme = Theme.of(context);
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
                styleSheet: MarkdownStyleSheet.fromTheme(theme),
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
                styleSheet: MarkdownStyleSheet.fromTheme(theme),
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
        currentCodeBlock += line + '\n';
      } else {
        // Regular text
        currentTextBlock += line + '\n';
      }
    }

    // Add remaining text or code
    if (currentTextBlock.isNotEmpty) {
      contentWidgets.add(
        MarkdownBody(
          data: currentTextBlock,
          styleSheet: MarkdownStyleSheet.fromTheme(theme),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AI is typing',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          _TypingDotsAnimation(),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
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
            'Failed to send message',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: widget.onRetry,
            child: Text(
              'Retry',
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
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

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
              hintText: 'Enter your message...',
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
                'Cancel',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            
            // Сохранить
            TextButton(
              onPressed: _saveEditing,
              child: Text(
                'Save',
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
              child: Text('Save & Send'),
            ),
          ],
        ),
      ],
    );
  }

  /// Обработка редактирования сообщения
  Future<void> _handleEditMessage(String newContent) async {
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
        message: 'Message edited successfully',
        icon: Icons.edit,
      );
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Failed to edit message',
        icon: Icons.error,
      );
    }
  }

  /// Обработка редактирования и отправки сообщения
  Future<void> _handleEditAndSend(String newContent) async {
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
      
      // TODO: Здесь должна быть логика удаления последующих сообщений и генерации нового ответа
      
      // Показываем уведомление
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: 'Message edited and response regenerated',
        icon: Icons.refresh,
      );
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Failed to edit and send message',
        icon: Icons.error,
      );
    }
  }
}

class _TypingDotsAnimation extends StatefulWidget {
  @override
  __TypingDotsAnimationState createState() => __TypingDotsAnimationState();
}

class __TypingDotsAnimationState extends State<_TypingDotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final opacity = _controller.value >= 0.33 && _controller.value < 0.66
                ? 1.0
                : 0.3;
            return Opacity(
              opacity: opacity,
              child: child,
            );
          },
          child: const Text('•'),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final opacity = _controller.value >= 0.66
                ? 1.0
                : 0.3;
            return Opacity(
              opacity: opacity,
              child: child,
            );
          },
          child: const Text('•'),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final opacity = _controller.value < 0.33 ? 1.0 : 0.3;
            return Opacity(
              opacity: opacity,
              child: child,
            );
          },
          child: const Text('•'),
        ),
      ],
    );
  }
}