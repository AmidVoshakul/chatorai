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
  final GlobalKey _loadingIndicatorKey = GlobalKey();

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
            key: _loadingIndicatorKey,
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
    // This is the ONLY place we read messages - no local state, no caching
    final messages = widget.chat?.messages ?? [];
    final hasMessages = messages.isNotEmpty;
    final hasAssistantMessage =
        hasMessages && messages.last.role == MessageRole.assistant;
    final isStreaming = hasAssistantMessage && !messages.last.isComplete;
    
    // Show waiting animation ONLY when:
    // 1. There ARE messages (user has sent something)
    // 2. AND last message is assistant
    // 3. AND it has no content yet (waiting for first chunk)
    final shouldShowWaitingAnimation = hasMessages && 
        hasAssistantMessage && 
        messages.last.content.isEmpty && 
        !messages.last.isComplete;

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
                // Show waiting animation at the end
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

                // During streaming: handle assistant message with reasoning
                if (isEmptyAssistantMessage && !message.isComplete && isLastMessage) {
                  final hasReasoning = message.reasoning != null && message.reasoning!.isNotEmpty;
                  
                  if (hasReasoning) {
                    // Show reasoning (streaming) - this replaces waiting animation
                    return reasoning_msg.ReasoningMessage(
                      key: ValueKey(message.id), // CRITICAL: Only use message.id
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
                    key: ValueKey(message.id), // Key on the Column
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reasoning message
                      reasoning_msg.ReasoningMessage(
                        key: ValueKey('${message.id}_reasoning'), // Unique key
                        reasoning: message.reasoning!,
                        isStreaming: isStreaming && isLastMessage,
                      ),
                      const SizedBox(
                        height: ChatMessagesConstants.messageSpacing,
                      ),
                      // Main message
                      chat_msg.ChatMessage(
                        key: ValueKey('${message.id}_content'), // Unique key
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
                        onContinueResponse:
                            message.role == MessageRole.assistant
                            ? () => widget.onContinueResponse?.call(message.id)
                            : null,
                      ),
                    ],
                  );
                }

                return chat_msg.ChatMessage(
                  key: ValueKey(message.id), // CRITICAL: Only use message.id
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
