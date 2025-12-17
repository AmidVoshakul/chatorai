import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/utils/message_utils.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_message.dart' as chat_msg;
import 'package:gen_ui_chat_ai/widgets/chat/reasoning_message.dart'
    as reasoning_msg;
import 'package:gen_ui_chat_ai/widgets/chat/loading_indicator.dart';

// Initialize logger for this widget
final _logger = LogTags.chatService;

/// Centralized constants for ChatMessages widget
class ChatMessagesConstants {
  // UI Constants
  static const double horizontalPadding = 20.0;
  static const double verticalPadding = 16.0;
  static const double messageSpacing = 8.0;
  static const double loadingIndicatorSize = 12.0;

  // Animation & Update Constants
  static const Duration updateInterval = Duration(milliseconds: 16); // 60 FPS
  static const int minChunkLengthForUpdate = 1;

  // Display Constants
  static const int maxPreviewLength = 50;
  static const int maxReasoningPreviewLength = 100;

  // Error Messages
  static const String noAssistantMessageError =
      'No assistant message to update';
  static const String noReasoningError =
      'Cannot update reasoning, no assistant message found';
}

class ChatMessages extends StatefulWidget {
  final Chat? chat;
  final OpenRouterService openRouterService;
  final ChatStorageService chatStorageService;
  final String? selectedModel;
  final Function(String) onSendMessage; // Add callback for sending messages
  final Function() onMessageDeleted; // Add callback for message deletion
  final Function(String)?
  onContinueResponse; // Add callback for continuing response
  final ScrollController? scrollController; // External scroll controller

  const ChatMessages({
    super.key,
    required this.openRouterService,
    required this.chatStorageService,
    this.chat,
    this.selectedModel,
    required this.onSendMessage,
    required this.onMessageDeleted,
    this.onContinueResponse,
    this.scrollController,
  });

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _logger.logInfo(
      '[ChatMessages] Initializing ChatMessages with chat: ${widget.chat?.id}, messages: ${widget.chat?.messages.length ?? 0}',
    );

    // Use external scroll controller if provided, otherwise create new one
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(covariant ChatMessages oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if this is a new chat or messages changed
    final messagesChanged =
        widget.chat?.id != oldWidget.chat?.id ||
        (widget.chat?.messages.length ?? 0) !=
            (oldWidget.chat?.messages.length ?? 0);

    // Also check if last message content changed (for streaming updates)
    final lastMessageChanged = _hasLastMessageChanged(oldWidget);

    if (messagesChanged || lastMessageChanged) {
      setState(() {});
    }
  }

  bool _hasLastMessageChanged(ChatMessages oldWidget) {
    if (widget.chat == null || oldWidget.chat == null) {
      return false;
    }
    if (widget.chat!.messages.isEmpty || oldWidget.chat!.messages.isEmpty) {
      return false;
    }
    
    final oldLast = oldWidget.chat!.messages.last;
    final newLast = widget.chat!.messages.last;
    
    // Check if it's the same message but content/reasoning changed
    if (oldLast.id == newLast.id) {
      final changed = oldLast.content != newLast.content ||
          oldLast.reasoning != newLast.reasoning ||
          oldLast.isComplete != newLast.isComplete;
      return changed;
    }
    
    return false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Public method to send messages from outside (e.g., from chat input)
  void sendMessage(String content) {
    _logger.logInfo('[ChatMessages] sendMessage called: $content');
    // Notify parent to handle AI response
    widget.onSendMessage(content);
  }

  void selectModel(String modelId) {
    // Model selection is handled by parent, just trigger rebuild
    setState(() {});
  }

  void _handleDeleteMessage(Message message) async {
    _logger.logInfo('[ChatMessages] Deleting message: ${message.id}');

    final bool deleted = await MessageUtils.deleteMessage(
      chatId: widget.chat?.id ?? '',
      messageId: message.id,
      chatStorageService: widget.chatStorageService,
      context: context,
    );

    if (deleted) {
      _logger.logInfo('[ChatMessages] Message deleted from database');
      widget.onMessageDeleted();
    } else {
      _logger.logError('[ChatMessages] Failed to delete message from database');
    }
  }

  // Анимация ожидания ответа
  Widget _buildWaitingAnimation() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ChatMessagesConstants.horizontalPadding,
        vertical: ChatMessagesConstants.messageSpacing,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ChatLoadingIndicator(
            size: ChatMessagesConstants.loadingIndicatorSize,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // CRITICAL: Always read from widget.chat, never from local state
    final messages = widget.chat?.messages ?? [];
    final hasMessages = messages.isNotEmpty;
    final hasAssistantMessage =
        hasMessages && messages.last.role == MessageRole.assistant;
    final isStreaming = hasAssistantMessage && !messages.last.isComplete;
    
    // FIX: Only show waiting animation when:
    // 1. There are no messages at all (first message being sent)
    // 2. OR there's an assistant message but it has NO content yet (waiting for first chunk)
    final isWaiting = !hasMessages || 
        (hasAssistantMessage && messages.last.content.isEmpty && !messages.last.isComplete);

    // CRITICAL: Force continuous rebuilds during streaming
    // This is the KEY to real-time visual updates!
    if (isStreaming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Re-check current state after frame
          final currentMessages = widget.chat?.messages ?? [];
          final currentHasAssistant =
              currentMessages.isNotEmpty &&
              currentMessages.last.role == MessageRole.assistant;
          final currentIsStreaming =
              currentHasAssistant && !currentMessages.last.isComplete;

          if (currentIsStreaming) {
            // Force rebuild to show new content
            setState(() {});
          }
        }
      });
    }

    // CRITICAL FIX: Prevent animations on empty chat
    // Only show waiting animation AFTER user has sent first message
    final shouldShowWaiting = (isWaiting && hasMessages) || 
        (hasAssistantMessage && messages.last.content.isEmpty && !messages.last.isComplete);

    // Check if we should show reasoning during streaming
    final lastMessage = hasMessages ? messages.last : null;
    final showReasoningDuringStreaming = 
        isStreaming && 
        lastMessage != null && 
        lastMessage.reasoning != null && 
        lastMessage.reasoning!.isNotEmpty &&
        lastMessage.content.isEmpty;

    // Don't show waiting animation if reasoning is already being displayed
    final shouldShowWaitingAnimation = shouldShowWaiting && !showReasoningDuringStreaming;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: ChatMessagesConstants.horizontalPadding,
                vertical: ChatMessagesConstants.verticalPadding,
              ),
              itemCount: messages.length + (shouldShowWaitingAnimation ? 1 : 0),
              itemBuilder: (context, index) {
                // Show waiting animation at the end (only if reasoning not shown)
                if (shouldShowWaitingAnimation && index == messages.length) {
                  return _buildWaitingAnimation();
                }

                if (index >= messages.length) {
                  return Container();
                }

                final message = messages[index];
                final isLastMessage = index == messages.length - 1;
                final isAssistantMessage =
                    message.role == MessageRole.assistant;
                final isEmptyAssistantMessage =
                    isAssistantMessage && message.content.isEmpty;

                // During streaming with reasoning: show reasoning, skip waiting animation
                if (isEmptyAssistantMessage && !message.isComplete && isLastMessage) {
                  if (message.reasoning != null && message.reasoning!.isNotEmpty) {
                    return reasoning_msg.ReasoningMessage(
                      key: ValueKey('${message.id}_${message.reasoning?.length ?? 0}'),
                      reasoning: message.reasoning!,
                      isStreaming: true,
                    );
                  }
                  // No reasoning yet, skip this message (waiting animation shown separately)
                  return Container();
                }

                // Show reasoning first if present
                if (message.reasoning != null &&
                    message.reasoning!.isNotEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reasoning message
                      reasoning_msg.ReasoningMessage(
                        key: ValueKey(
                          '${message.id}_${message.reasoning?.length ?? 0}',
                        ),
                        reasoning: message.reasoning!,
                        isStreaming: isStreaming && isLastMessage,
                      ),
                      const SizedBox(
                        height: ChatMessagesConstants.messageSpacing,
                      ),
                      // Main message
                      chat_msg.ChatMessage(
                        key: ValueKey(
                          '${message.id}_${message.content.length}',
                        ),
                        message: message,
                        isStreaming: isStreaming && isLastMessage,
                        isLastMessage: isLastMessage,
                        onRetry: () {
                          if (message.role == MessageRole.user) {
                            // Call parent's send method through widget
                            widget.onSendMessage(message.content);
                          }
                        },
                        chatId: widget.chat?.id ?? '',
                        chatStorageService: widget.chatStorageService,
                        onMessageDeleted: widget.onMessageDeleted,
                        onMessageUpdated: (newContent) {
                          // Parent handles updates
                        },
                        onDelete: () {
                          _handleDeleteMessage(message);
                        },
                        onContinueResponse:
                            message.role == MessageRole.assistant
                            ? () => widget.onContinueResponse?.call(message.id)
                            : null,
                      ),
                    ],
                  );
                }

                return chat_msg.ChatMessage(
                  message: message,
                  isStreaming: isStreaming && isLastMessage,
                  isLastMessage: isLastMessage,
                  onRetry: () {
                    if (message.role == MessageRole.user) {
                      widget.onSendMessage(message.content);
                    }
                  },
                  chatId: widget.chat?.id ?? '',
                  chatStorageService: widget.chatStorageService,
                  onMessageDeleted: widget.onMessageDeleted,
                  onMessageUpdated: (newContent) {
                    // Parent handles updates
                  },
                  onDelete: () {
                    _handleDeleteMessage(message);
                  },
                  onContinueResponse: message.role == MessageRole.assistant
                      ? () => widget.onContinueResponse?.call(message.id)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
