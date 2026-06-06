import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/providers.dart' show streamingMessageProvider;
import 'package:chatorai/models/chat_message.dart';
import 'package:chatorai/widgets/chat/parts/chat_message_bubble.dart';
import 'package:chatorai/utils/message_utils.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/constants/chat_messages_constants.dart';
import 'package:chatorai/widgets/chat/chat_message.dart' as chat_msg;
import 'package:chatorai/widgets/chat/reasoning_message.dart' as reasoning_msg;
import 'package:chatorai/widgets/chat/loading_indicator.dart';
import 'package:chatorai/widgets/chat/continuation_suggestions.dart';
import 'package:chatorai/widgets/chat/welcome_suggestions.dart';
import 'package:chatorai/utils/markdown_parser.dart';
import 'package:chatorai/widgets/chat/chat_input.dart' show MessageData;

// ===========================================================================
// LOGGER
// ===========================================================================

// Initialize logger for this widget
final _logger = LogTags.chatService;

// ===========================================================================
// CHAT MESSAGES WIDGET
// ===========================================================================

class ChatMessages extends ConsumerStatefulWidget {
  final Chat? chat;
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
  final Function(String)? // Add callback for regenerating response (messageId)
  onRegenerateResponse;
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
  ConsumerState<ChatMessages> createState() => ChatMessagesState();
}

// ===========================================================================
// STATE
// ===========================================================================

class ChatMessagesState extends ConsumerState<ChatMessages>
        // ===========================================================================
        // STATE VARIABLES
        // ===========================================================================
        with
        AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final GlobalKey _loadingIndicatorKey = GlobalKey();

  // Streaming state - managed via ref.watch in build

  // Navigator state
  List<MarkdownHeadingInfoWithKey> _headings =
      []; // Store heading info with keys

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  bool get wantKeepAlive => true;

  // ===========================================================================
  // INIT STATE
  // ===========================================================================

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // DID UPDATE WIDGET
  // ===========================================================================

  @override
  void didUpdateWidget(ChatMessages oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Skip heading updates during streaming to prevent UI lag
    final newMessages = widget.chat?.messages ?? [];
    final isStreaming =
        newMessages.isNotEmpty &&
        !newMessages.last.isComplete &&
        newMessages.last.role == MessageRole.assistant;

    if (isStreaming) {
      return;
    }

    // Update headings when chat content changes
    // Check for: chat ID change, message count change, or content changes
    final oldMessages = oldWidget.chat?.messages ?? [];

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

  // ===========================================================================
  // HEADING METHODS
  // ===========================================================================

  void _updateHeadings() {
    final messages = widget.chat?.messages ?? [];

    HeadingAnchorRegistry().clear();

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

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  void refreshHeadings() {
    _updateHeadings();
  }

  void scrollToHeading(String messageId) {
    final messageIndex =
        widget.chat?.messages.indexWhere((m) => m.id == messageId) ?? -1;
    if (messageIndex >= 0) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ===========================================================================
  // NAVIGATOR
  // ===========================================================================

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
  // ===========================================================================
  // MESSAGE HANDLERS
  // ===========================================================================

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

  // ===========================================================================
  // WAITING ANIMATION
  // ===========================================================================

  // Animation of waiting for a response
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

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin

    // Watch streaming message provider
    final streamingState = ref.watch(streamingMessageProvider);
    final streamingParts = streamingState.accumulatedParts;
    final streamingIsActive = streamingState.isStreaming;

    final theme = Theme.of(context);

    final messages = widget.chat?.messages ?? [];
    final hasMessages = messages.isNotEmpty;
    final hasAssistantMessage =
        hasMessages && messages.last.role == MessageRole.assistant;
    final isStreaming = hasAssistantMessage && !messages.last.isComplete;

    final lastMessageIsComplete =
        hasAssistantMessage && messages.last.isComplete;
    final showStreamingBubble =
        streamingParts.isNotEmpty &&
        (streamingIsActive || streamingState.justEnded) &&
        !lastMessageIsComplete;

    final shouldShowWaitingAnimation =
        hasMessages &&
        hasAssistantMessage &&
        messages.last.content.isEmpty &&
        (messages.last.reasoning == null || messages.last.reasoning!.isEmpty) &&
        !messages.last.isComplete &&
        !showStreamingBubble;

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
                // Add physics for better scroll performance
                physics: const BouncingScrollPhysics(),
                // Performance optimizations
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                padding: EdgeInsets.only(
                  left: ChatMessagesConstants.horizontalPadding,
                  right: ChatMessagesConstants.horizontalPadding,
                  top: ChatMessagesConstants.verticalPadding,
                  bottom: ChatMessagesConstants.verticalPadding,
                ),
                itemCount:
                    messages.length +
                    (shouldShowWaitingAnimation ? 1 : 0) +
                    (showStreamingBubble ? 1 : 0) +
                    (widget.showSuggestions &&
                            widget.continuationSuggestions.isNotEmpty
                        ? 1
                        : 0) +
                    (shouldShowWelcome ? 1 : 0),
                itemBuilder: (context, index) {
                  int welcomeOffset = 0;

                  if (shouldShowWelcome) {
                    if (index == 0) {
                      return _buildWelcomeSuggestions();
                    }
                    welcomeOffset = 1;
                  }

                  // Regular messages
                  final msgIndex = index - welcomeOffset;
                  if (msgIndex >= 0 && msgIndex < messages.length) {
                    final message = messages[msgIndex];
                    final isLastMessage = msgIndex == messages.length - 1;
                    final isAssistantMessage =
                        message.role == MessageRole.assistant;
                    final isEmptyAssistantMessage =
                        isAssistantMessage && message.content.isEmpty;

                    if (isEmptyAssistantMessage && isLastMessage) {
                      return const SizedBox.shrink();
                    }

                    if (message.reasoning != null &&
                        message.reasoning!.isNotEmpty) {
                      return Column(
                        key: ValueKey(message.id),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          reasoning_msg.ReasoningMessage(
                            key: ValueKey('${message.id}_reasoning'),
                            reasoning: message.reasoning!,
                            isStreaming: isStreaming && isLastMessage,
                          ),
                          const SizedBox(
                            height: ChatMessagesConstants.messageSpacing,
                          ),
                          chat_msg.ChatMessage(
                            key: ValueKey(message.id),
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
                                widget.onRegenerateResponse?.call(message.id);
                              }
                            },
                            onDelete: () {
                              _handleDeleteMessage(message);
                            },
                            onContinueResponse:
                                message.role == MessageRole.assistant
                                ? () => widget.onContinueResponse?.call(
                                    message.id,
                                  )
                                : null,
                            headings: _headings,
                          ),
                        ],
                      );
                    }

                    if (isAssistantMessage && message.content.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return chat_msg.ChatMessage(
                      key: ValueKey(message.id),
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
                          widget.onRegenerateResponse?.call(message.id);
                        }
                      },
                      onDelete: () {
                        _handleDeleteMessage(message);
                      },
                      onContinueResponse: message.role == MessageRole.assistant
                          ? () => widget.onContinueResponse?.call(message.id)
                          : null,
                      headings: _headings.isEmpty ? null : _headings,
                    );
                  }

                  // After all regular messages: streaming bubble or waiting animation
                  final afterMessages = welcomeOffset + messages.length;
                  var extraPos = afterMessages;

                  if (showStreamingBubble && streamingParts.isNotEmpty) {
                    if (index == extraPos) {
                      final lastMessage = messages.isNotEmpty
                          ? messages.last
                          : null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ChatMessageBubble(
                          message: AssistantMessage(
                            id: lastMessage?.id ?? 'streaming',
                            parts: streamingParts,
                            model: lastMessage?.model,
                            isStreaming: streamingIsActive,
                            timestamp: lastMessage?.timestamp ?? DateTime.now(),
                          ),
                        ),
                      );
                    }
                    extraPos++;
                  } else if (shouldShowWaitingAnimation) {
                    if (index == extraPos) {
                      return _buildWaitingAnimation();
                    }
                    extraPos++;
                  }

                  // Continuation suggestions at the very end
                  if (widget.showSuggestions &&
                      widget.continuationSuggestions.isNotEmpty &&
                      index == extraPos) {
                    return _buildContinuationSuggestions();
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUGGESTION BUILDERS
  // ===========================================================================

  // ===========================================================================
  // SUGGESTION BUILDERS
  // ===========================================================================

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

  // ===========================================================================
  // CONTINUATION SUGGESTIONS
  // ===========================================================================

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
