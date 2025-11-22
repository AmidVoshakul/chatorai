import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gen_ui_chat_ai/widgets/chat/code_block.dart';
import 'package:gen_ui_chat_ai/utils/ui_helper.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';

class ChatMessage extends StatefulWidget {
  final Message message;
  final bool isStreaming;
  final VoidCallback onRetry;

  const ChatMessage({
    Key? key,
    required this.message,
    required this.isStreaming,
    required this.onRetry,
  }) : super(key: key);

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
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
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.3),
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
                          
                          // Message Actions
                          if (!widget.isStreaming)
                            _buildMessageActions(),
                        ],
                      ),
                    ),
                  )
                : Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.3),
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
                              widget.message.role.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTime(widget.message.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
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
                        
                        // Message Actions
                        if (!widget.isStreaming)
                          _buildMessageActions(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.message.content.isEmpty) {
      return Container();
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
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
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
        color: Colors.red.withOpacity(0.1),
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

  Widget _buildMessageActions() {
    final theme = Theme.of(context);
    final isUser = widget.message.role == MessageRole.user;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // User message actions (only edit and copy)
          if (isUser) ...[
            IconButton(
              icon: Icon(
                Icons.edit,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.7),
              ),
              onPressed: () {
                // TODO: Edit user message
              },
              tooltip: 'Edit',
              splashRadius: 20,
            ),
            const SizedBox(width: 4),
          ],
          
          // Share action for assistant messages
          if (!isUser) ...[
            IconButton(
              icon: Icon(
                Icons.share,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.7),
              ),
              onPressed: () {
                // TODO: Share message
              },
              tooltip: 'Share',
              splashRadius: 20,
            ),
            const SizedBox(width: 4),
          ],
          
          // Universal copy action
          IconButton(
            icon: Icon(
              Icons.copy,
              size: 16,
              color: theme.iconTheme.color?.withOpacity(0.7),
            ),
            onPressed: () {
              // TODO: Copy message
              UIHelper.showSuccessSnackBar(context, "Message copied to clipboard");
            },
            tooltip: 'Copy',
            splashRadius: 20,
          ),
          
          // AI-specific actions (only for assistant messages)
          if (!isUser) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.volume_up,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.7),
              ),
              onPressed: () {
                // TODO: Voice message
              },
              tooltip: 'Listen',
              splashRadius: 20,
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.7),
              ),
              onPressed: () {
                // TODO: Regenerate message
              },
              tooltip: 'Regenerate',
              splashRadius: 20,
            ),
            IconButton(
              icon: Icon(
                Icons.thumb_up,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.7),
              ),
              onPressed: () {
                // TODO: Like message
              },
              tooltip: 'Like',
              splashRadius: 20,
            ),
            IconButton(
              icon: Icon(
                Icons.thumb_down,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.7),
              ),
              onPressed: () {
                // TODO: Dislike message
              },
              tooltip: 'Dislike',
              splashRadius: 20,
            ),
          ],
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