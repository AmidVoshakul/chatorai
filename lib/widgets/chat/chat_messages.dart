import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/openrouter/openrouter_service.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/providers.dart' show streamingContentProvider;
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

    // Watch streaming state with select to avoid full rebuild on every content update
    final streamingContent = ref.watch(
      streamingContentProvider.select((s) => s.content),
    );
    final streamingReasoning = ref.watch(
      streamingContentProvider.select((s) => s.reasoning),
    );

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
    // 4. AND there's no streaming content/reasoning (first chunk not received yet)
    final shouldShowWaitingAnimation =
        hasMessages &&
        hasAssistantMessage &&
        messages.last.content.isEmpty &&
        (messages.last.reasoning == null || messages.last.reasoning!.isEmpty) &&
        !messages.last.isComplete &&
        streamingContent.isEmpty &&
        streamingReasoning.isEmpty;

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
                  // Use streaming content from controller if available
                  final effectiveContent =
                      (streamingContent.isNotEmpty && isLastMessage)
                      ? streamingContent
                      : message.content;
                  final effectiveReasoning =
                      (streamingReasoning.isNotEmpty && isLastMessage)
                      ? streamingReasoning
                      : message.reasoning;

                  if (isEmptyAssistantMessage &&
                      !message.isComplete &&
                      isLastMessage) {
                    final hasReasoning =
                        effectiveReasoning != null &&
                        effectiveReasoning.isNotEmpty;
                    final hasContent = effectiveContent.isNotEmpty;

                    // If no reasoning and no content yet, hide the empty message
                    if (!hasReasoning && !hasContent) {
                      return const SizedBox.shrink();
                    }

                    // Always show Column structure to prevent flicker when content starts streaming
                    // This prevents widget recreation when transitioning from reasoning-only to reasoning+content
                    final streamingMessage = message.copyWith(
                      content: effectiveContent,
                      reasoning: effectiveReasoning,
                    );
                    return RepaintBoundary(
                      child: Column(
                        key: ValueKey('${message.id}_streaming'),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasReasoning)
                            reasoning_msg.ReasoningMessage(
                              key: ValueKey('${message.id}_reasoning'),
                              reasoning: effectiveReasoning,
                              isStreaming: !hasContent,
                            ),
                          if (hasReasoning && hasContent)
                            const SizedBox(
                              height: ChatMessagesConstants.messageSpacing,
                            ),
                          if (hasContent)
                            chat_msg.ChatMessage(
                              key: ValueKey('${message.id}_content'),
                              message: streamingMessage,
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
                                  widget.onRegenerateResponse?.call(
                                    streamingMessage.id,
                                  );
                                }
                              },
                              onDelete: () {},
                              onContinueResponse: null,
                              headings: _headings.isEmpty ? null : _headings,
                            ),
                        ],
                      ),
                    );
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
                              widget.onRegenerateResponse?.call(message.id);
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
