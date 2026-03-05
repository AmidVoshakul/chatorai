import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/utils/message_utils.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/widgets/chat/chat_message.dart' as chat_msg;
import 'package:chatorai/widgets/chat/reasoning_message.dart' as reasoning_msg;
import 'package:chatorai/widgets/chat/loading_indicator.dart';
import 'package:chatorai/widgets/chat/continuation_suggestions.dart';
import 'package:chatorai/widgets/chat/welcome_suggestions.dart';
import 'package:chatorai/utils/markdown_parser_with_keys.dart';
import 'package:chatorai/widgets/chat/chat_input.dart' show MessageData;

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
  final OpenRouterClient openRouterService;
  final ChatStorageService chatStorageService;
  final String? selectedModel;
  final Function(MessageData)
  onSendMessage; // Add callback for sending messages
  final Function() onMessageDeleted; // Add callback for message deletion
  final Function(String, String)?
  onMessageEdited; // Callback for message edit (messageId, newContent)
  final Function(String, String)?
  onMessageEditAndSend; // Callback for edit + regenerate (messageId, newContent)
  final Function(String)?
  onContinueResponse; // Add callback for continuing response
  final VoidCallback?
  onRegenerateResponse; // Add callback for regenerating response
  final ScrollController? scrollController; // External scroll controller
  final List<String> continuationSuggestions; // Suggestions to display
  final bool showSuggestions; // Whether to show suggestions
  final bool isSuggestionsLoading; // Whether suggestions are loading
  final VoidCallback?
  onSuggestionsClose; // Callback when suggestions are closed
  final VoidCallback? onSuggestionsRefresh; // Callback to refresh suggestions

  // Welcome suggestions for empty chats
  final List<String> welcomeSuggestions; // Welcome questions to display
  final bool showWelcomeSuggestions; // Whether to show welcome suggestions
  final VoidCallback?
  onWelcomeSuggestionsClose; // Callback when welcome suggestions are closed

  // Navigator callbacks
  final Function(List<MarkdownHeadingInfoWithKey> headings)? onHeadingsUpdated;
  final Function()? onToggleNavigator;

  const ChatMessages({
    super.key,
    required this.openRouterService,
    required this.chatStorageService,
    this.chat,
    this.selectedModel,
    required this.onSendMessage,
    required this.onMessageDeleted,
    this.onMessageEdited,
    this.onMessageEditAndSend,
    this.onContinueResponse,
    this.onRegenerateResponse,
    this.scrollController,
    this.continuationSuggestions = const [],
    this.showSuggestions = false,
    this.isSuggestionsLoading = false,
    this.onSuggestionsClose,
    this.onSuggestionsRefresh,
    this.welcomeSuggestions = const [],
    this.showWelcomeSuggestions = false,
    this.onWelcomeSuggestionsClose,
    this.onHeadingsUpdated,
    this.onToggleNavigator,
  });

  @override
  State<ChatMessages> createState() => ChatMessagesState();
}

class ChatMessagesState extends State<ChatMessages>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final GlobalKey _loadingIndicatorKey = GlobalKey();

  // Navigator state
  List<MarkdownHeadingInfoWithKey> _headings =
      []; // Store heading info with keys

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _logger.logInfo(
      '[ChatMessages] Initializing ChatMessages with chat: ${widget.chat?.id}, messages: ${widget.chat?.messages.length ?? 0}',
    );

    // Use external scroll controller if provided, otherwise create new one
    _scrollController = widget.scrollController ?? ScrollController();
    _logger.logInfo(
      '[ChatMessages] ScrollController initialized: ${_scrollController.hashCode}',
    );

    // Initialize headings
    _updateHeadings();
  }

  @override
  void didUpdateWidget(ChatMessages oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update headings when chat content changes
    // Check for: chat ID change, message count change, or content changes
    final oldMessages = oldWidget.chat?.messages ?? [];
    final newMessages = widget.chat?.messages ?? [];

    bool shouldUpdate =
        widget.chat?.id != oldWidget.chat?.id ||
        oldMessages.length != newMessages.length;

    // Also check for content changes (for streaming updates)
    if (!shouldUpdate && oldMessages.length == newMessages.length) {
      for (int i = 0; i < oldMessages.length; i++) {
        if (oldMessages[i].content != newMessages[i].content) {
          shouldUpdate = true;
          break;
        }
      }
    }

    if (shouldUpdate) {
      _updateHeadings();
    }
  }

  void _updateHeadings() {
    final messages = widget.chat?.messages ?? [];

    _headings = MarkdownParserWithKeys.parseAllMessagesHeadings(
      messages,
      existingHeadings: _headings.isNotEmpty ? _headings : null,
    );

    _logger.logInfo(
      '[ChatMessages] Updated headings: ${_headings.length} total',
    );

    // Notify parent about headings update
    if (widget.onHeadingsUpdated != null) {
      widget.onHeadingsUpdated!(_headings);
    }
  }

  void refreshHeadings() {
    _updateHeadings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleNavigator() {
    // Notify parent about toggle
    if (widget.onToggleNavigator != null) {
      widget.onToggleNavigator!();
    }
  }

  // Public method to toggle navigator from parent widgets
  void toggleNavigator() {
    _toggleNavigator();
  }

  // Public method to send messages from outside (e.g., from chat input)
  void sendMessage(MessageData messageData) {
    // Notify parent to handle AI response
    widget.onSendMessage(messageData);
  }

  void selectModel(String modelId) {
    // Model selection is handled by parent, just trigger rebuild
    setState(() {});
  }

  void _handleDeleteMessage(Message message) async {
    final bool deleted = await MessageUtils.deleteMessage(
      chatId: widget.chat?.id ?? '',
      messageId: message.id,
      chatStorageService: widget.chatStorageService,
      context: context,
    );

    if (deleted) {
      widget.onMessageDeleted();
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
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
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
    // 3. AND it has no content yet AND no reasoning yet (waiting for first chunk)
    final shouldShowWaitingAnimation =
        hasMessages &&
        hasAssistantMessage &&
        messages.last.content.isEmpty &&
        (messages.last.reasoning == null || messages.last.reasoning!.isEmpty) &&
        !messages.last.isComplete;

    // Show welcome suggestions when chat is empty and welcome suggestions are enabled
    final shouldShowWelcome =
        !hasMessages &&
        widget.showWelcomeSuggestions &&
        widget.welcomeSuggestions.isNotEmpty;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Messages List
          Expanded(
            child: RepaintBoundary(
              child: ListView.builder(
                controller: _scrollController,
                // Cache visible items and some offscreen items for better performance
                cacheExtent: 200,
                // Add physics for better scroll performance
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: ChatMessagesConstants.horizontalPadding,
                  right: ChatMessagesConstants.horizontalPadding,
                  top: ChatMessagesConstants.verticalPadding,
                  bottom: ChatMessagesConstants.verticalPadding,
                ),
                itemCount:
                    messages.length +
                    (shouldShowWaitingAnimation ? 1 : 0) +
                    (widget.showSuggestions &&
                            widget.continuationSuggestions.isNotEmpty
                        ? 1
                        : 0) +
                    (shouldShowWelcome ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show waiting animation at the end
                  if (shouldShowWaitingAnimation && index == messages.length) {
                    return _buildWaitingAnimation();
                  }

                  // Show continuation suggestions after messages
                  final suggestionsIndex =
                      messages.length + (shouldShowWaitingAnimation ? 1 : 0);
                  if (widget.showSuggestions &&
                      widget.continuationSuggestions.isNotEmpty &&
                      index == suggestionsIndex) {
                    return _buildContinuationSuggestions();
                  }

                  // Show welcome suggestions at the beginning
                  if (shouldShowWelcome && index == 0) {
                    return _buildWelcomeSuggestions();
                  }

                  if (index >= messages.length) {
                    return const SizedBox.shrink();
                  }

                  final message = messages[index];
                  final isLastMessage = index == messages.length - 1;
                  final isAssistantMessage =
                      message.role == MessageRole.assistant;
                  final isEmptyAssistantMessage =
                      isAssistantMessage && message.content.isEmpty;

                  // During streaming: handle assistant message with reasoning
                  if (isEmptyAssistantMessage &&
                      !message.isComplete &&
                      isLastMessage) {
                    final hasReasoning =
                        message.reasoning != null &&
                        message.reasoning!.isNotEmpty;
                    final hasContent = message.content.isNotEmpty;

                    // If no reasoning and no content yet, hide the empty message
                    if (!hasReasoning && !hasContent) {
                      return const SizedBox.shrink();
                    }

                    if (hasReasoning && !hasContent) {
                      // Show only reasoning (streaming) - content not started yet
                      return reasoning_msg.ReasoningMessage(
                        key: ValueKey(message.id),
                        reasoning: message.reasoning!,
                        isStreaming: true,
                      );
                    } else if (hasReasoning && hasContent) {
                      // Show both reasoning and content (streaming)
                      return Column(
                        key: ValueKey(message.id),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          reasoning_msg.ReasoningMessage(
                            key: ValueKey('${message.id}_reasoning'),
                            reasoning: message.reasoning!,
                            isStreaming: true,
                          ),
                          const SizedBox(
                            height: ChatMessagesConstants.messageSpacing,
                          ),
                          chat_msg.ChatMessage(
                            key: ValueKey('${message.id}_content'),
                            message: message,
                            isStreaming: true,
                            isLastMessage: isLastMessage,
                            onRetry: () {},
                            chatId: widget.chat?.id ?? '',
                            chatStorageService: widget.chatStorageService,
                            onMessageDeleted: widget.onMessageDeleted,
                            onMessageEdited:
                                (String messageId, String newContent) {
                                  widget.onMessageEdited?.call(
                                    messageId,
                                    newContent,
                                  );
                                },
                            onMessageEditAndSend:
                                (String messageId, String newContent) {
                                  widget.onMessageEditAndSend?.call(
                                    messageId,
                                    newContent,
                                  );
                                },
                            onMessageUpdated: (newContent) {
                              if (newContent == 'REGENERATE') {
                                widget.onRegenerateResponse?.call();
                              }
                            },
                            onDelete: () {},
                            onContinueResponse: null,
                            headings: _headings,
                          ),
                        ],
                      );
                    }
                    // No reasoning yet, skip this message (waiting animation shown separately)
                    return const SizedBox.shrink();
                  }

                  // Show reasoning first if present
                  if (message.reasoning != null &&
                      message.reasoning!.isNotEmpty) {
                    return Column(
                      key: ValueKey(message.id),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reasoning message
                        reasoning_msg.ReasoningMessage(
                          key: ValueKey('${message.id}_reasoning'),
                          reasoning: message.reasoning!,
                          isStreaming: isStreaming && isLastMessage,
                        ),
                        const SizedBox(
                          height: ChatMessagesConstants.messageSpacing,
                        ),
                        // Main message
                        chat_msg.ChatMessage(
                          key: ValueKey('${message.id}_content'),
                          message: message,
                          isStreaming: isStreaming && isLastMessage,
                          isLastMessage: isLastMessage,
                          onRetry: () {
                            if (message.role == MessageRole.user) {
                              widget.onSendMessage(
                                MessageData(
                                  text: message.content,
                                  imagePath: null,
                                  imageType: message.imageType,
                                  base64Data: message.imageData,
                                ),
                              );
                            }
                          },
                          chatId: widget.chat?.id ?? '',
                          chatStorageService: widget.chatStorageService,
                          onMessageDeleted: widget.onMessageDeleted,
                          onMessageEdited:
                              (String messageId, String newContent) {
                                widget.onMessageEdited?.call(
                                  messageId,
                                  newContent,
                                );
                              },
                          onMessageEditAndSend:
                              (String messageId, String newContent) {
                                widget.onMessageEditAndSend?.call(
                                  messageId,
                                  newContent,
                                );
                              },
                          onMessageUpdated: (newContent) {
                            if (newContent == 'REGENERATE') {
                              widget.onRegenerateResponse?.call();
                            }
                          },
                          onDelete: () {
                            _handleDeleteMessage(message);
                          },
                          onContinueResponse:
                              message.role == MessageRole.assistant
                              ? () =>
                                    widget.onContinueResponse?.call(message.id)
                              : null,
                          headings: _headings,
                        ),
                      ],
                    );
                  }

                  // Hide empty assistant messages (shouldn't happen, but safety check)
                  if (isAssistantMessage && message.content.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return chat_msg.ChatMessage(
                    key: ValueKey(message.id), // CRITICAL: Only use message.id
                    message: message,
                    isStreaming: isStreaming && isLastMessage,
                    isLastMessage: isLastMessage,
                    onRetry: () {
                      if (message.role == MessageRole.user) {
                        widget.onSendMessage(
                          MessageData(
                            text: message.content,
                            imagePath: null,
                            imageType: message.imageType,
                            base64Data: message.imageData,
                          ),
                        );
                      }
                    },
                    chatId: widget.chat?.id ?? '',
                    chatStorageService: widget.chatStorageService,
                    onMessageDeleted: widget.onMessageDeleted,
                    onMessageEdited: (String messageId, String newContent) {
                      widget.onMessageEdited?.call(messageId, newContent);
                    },
                    onMessageEditAndSend:
                        (String messageId, String newContent) {
                          widget.onMessageEditAndSend?.call(
                            messageId,
                            newContent,
                          );
                        },
                    onMessageUpdated: (newContent) {
                      if (newContent == 'REGENERATE') {
                        widget.onRegenerateResponse?.call();
                      }
                    },
                    onDelete: () {
                      _handleDeleteMessage(message);
                    },
                    onContinueResponse: message.role == MessageRole.assistant
                        ? () => widget.onContinueResponse?.call(message.id)
                        : null,
                    headings: _headings,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSuggestions() {
    return WelcomeSuggestions(
      suggestions: widget.welcomeSuggestions,
      context: context,
      onSuggestionTap: (suggestion) {
        // Send the suggestion through the parent callback
        widget.onSendMessage(MessageData(text: suggestion));
      },
      onClose: widget.onWelcomeSuggestionsClose,
    );
  }

  Widget _buildContinuationSuggestions() {
    return ContinuationSuggestions(
      suggestions: widget.continuationSuggestions,
      isLoading: widget.isSuggestionsLoading,
      context: context,
      onSuggestionTap: (suggestion) {
        // Send the suggestion through the parent callback
        widget.onSendMessage(MessageData(text: suggestion));
      },
      onClose: widget.onSuggestionsClose,
      onRefresh: widget.onSuggestionsRefresh,
    );
  }
}
