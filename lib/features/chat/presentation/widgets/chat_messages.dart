import 'package:chatorai/core/agents/agent_provider.dart';
import 'package:chatorai/core/constants/chat_messages_constants.dart';
import 'package:chatorai/core/llm/catalog_providers.dart'
    show providerCatalogServiceProvider;
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/data/models/chat/message_converter.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/repositories/chat_storage_service.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input.dart'
    show MessageData;
import 'package:chatorai/features/chat/presentation/widgets/chat_messages_suggestions.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_messages_waiting_animation.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/chat_message_bubble.dart';
import 'package:chatorai/providers.dart' show streamingMessageProvider;
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = LogTags.chatService;

class ChatMessages extends ConsumerStatefulWidget {
  final Chat? chat;
  final ChatStorageService chatStorageService;
  final String? selectedModel;
  final Function(MessageData) onSendMessage;
  final Function() onMessageDeleted;
  final Function(String, String)? onMessageEdited;
  final Function(String, String)? onMessageEditAndSend;
  final Function(String)? onContinueResponse;
  final Function(String)? onRegenerateResponse;
  final ScrollController? scrollController;
  final List<String> continuationSuggestions;
  final bool showSuggestions;
  final bool isSuggestionsLoading;
  final VoidCallback? onSuggestionsClose;
  final VoidCallback? onSuggestionsRefresh;
  final List<String> welcomeSuggestions;
  final bool showWelcomeSuggestions;
  final VoidCallback? onWelcomeSuggestionsClose;
  final Function(List<MarkdownHeadingInfoWithKey> headings)? onHeadingsUpdated;
  final Function()? onToggleNavigator;
  final Function(String messageId, String answer)? onQuestionAnswer;

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
    this.onQuestionAnswer,
  });

  @override
  ConsumerState<ChatMessages> createState() => ChatMessagesState();
}

class ChatMessagesState extends ConsumerState<ChatMessages>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final GlobalKey _loadingIndicatorKey = GlobalKey();

  List<MarkdownHeadingInfoWithKey> _headings = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _logger.logInfo(
      '[ChatMessages] Initializing ChatMessages with chat: ${widget.chat?.id}, messages: ${widget.chat?.messages.length ?? 0}',
    );
    _scrollController = widget.scrollController ?? ScrollController();
    _logger.logInfo(
      '[ChatMessages] ScrollController initialized: ${_scrollController.hashCode}',
    );
    _updateHeadings();
  }

  @override
  void dispose() {
    // Only dispose if we created the controller (widget.scrollController was null)
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatMessages oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newMessages = widget.chat?.messages ?? [];
    final isStreaming =
        newMessages.isNotEmpty &&
        !newMessages.last.isComplete &&
        newMessages.last.role == MessageRole.assistant;

    if (isStreaming) {
      return;
    }

    final oldMessages = oldWidget.chat?.messages ?? [];

    bool shouldUpdate =
        widget.chat?.id != oldWidget.chat?.id ||
        oldMessages.length != newMessages.length;

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

    HeadingAnchorRegistry().clear();

    _headings = MarkdownParserWithKeys.parseAllMessagesHeadings(
      messages,
      existingHeadings: _headings.isNotEmpty ? _headings : null,
    );

    _logger.logInfo(
      '[ChatMessages] Updated headings: ${_headings.length} total',
    );

    if (widget.onHeadingsUpdated != null) {
      widget.onHeadingsUpdated!(_headings);
    }
  }

  void refreshHeadings() {
    _updateHeadings();
  }

  String? _resolveModelDisplayName(String? modelId) {
    if (modelId == null || modelId.isEmpty) return null;
    final catalog = ref.read(providerCatalogServiceProvider);
    final config = catalog.getModel(modelId);
    return config?.displayName ?? modelId;
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

  void _toggleNavigator() {
    if (widget.onToggleNavigator != null) {
      widget.onToggleNavigator!();
    }
  }

  void toggleNavigator() {
    _toggleNavigator();
  }

  void sendMessage(MessageData messageData) {
    widget.onSendMessage(messageData);
  }

  void selectModel(String modelId) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final streamingState = ref.watch(streamingMessageProvider);
    final streamingParts = streamingState.accumulatedParts;
    final streamingIsActive = streamingState.isStreaming;
    final currentAgent = ref.watch(currentAgentProvider);

    final isWaitingForStream = streamingIsActive && streamingParts.isEmpty;
    final hasReasoningOnly =
        streamingIsActive &&
        streamingParts.isNotEmpty &&
        streamingParts.every((p) => p is ReasoningPart);

    final theme = Theme.of(context);

    final messages = widget.chat?.messages ?? [];
    final hasMessages = messages.isNotEmpty;
    final hasAssistantMessage =
        hasMessages && messages.last.role == MessageRole.assistant;

    final lastMessageIsComplete =
        hasAssistantMessage && messages.last.isComplete;
    final showStreamingBubble =
        streamingParts.isNotEmpty &&
        streamingIsActive &&
        !lastMessageIsComplete;

    final shouldShowWaitingAnimation =
        (isWaitingForStream || hasReasoningOnly) &&
        hasMessages &&
        hasAssistantMessage &&
        messages.last.content.isEmpty &&
        !messages.last.isComplete;

    final shouldShowWelcome =
        !hasMessages &&
        widget.showWelcomeSuggestions &&
        widget.welcomeSuggestions.isNotEmpty;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
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
                controller: _scrollController,
                itemBuilder: (context, index) {
                  int welcomeOffset = 0;

                  if (shouldShowWelcome) {
                    if (index == 0) {
                      return ChatMessagesWelcomeSuggestions(
                        suggestions: widget.welcomeSuggestions,
                        parentContext: context,
                        onSuggestionTap: (suggestion) {
                          widget.onSendMessage(MessageData(text: suggestion));
                        },
                        onClose: widget.onWelcomeSuggestionsClose,
                      );
                    }
                    welcomeOffset = 1;
                  }

                  final msgIndex = index - welcomeOffset;
                  if (msgIndex >= 0 && msgIndex < messages.length) {
                    final message = messages[msgIndex];
                    final isLastMessage = msgIndex == messages.length - 1;

                    final isEmptyAssistantMessage =
                        message.role == MessageRole.assistant &&
                        message.content.isEmpty;

                    if (isEmptyAssistantMessage && isLastMessage) {
                      return const SizedBox.shrink();
                    }

                    final chatMsg = messageToChatMessage(message);
                    final resolvedMsg = (chatMsg is AssistantMessage)
                        ? chatMsg.copyWith(
                            model: _resolveModelDisplayName(chatMsg.model),
                          )
                        : chatMsg;
                    return ChatMessageBubble(
                      key: ValueKey(message.id),
                      message: resolvedMsg,
                      chatId: widget.chat!.id,
                      messageId: message.id,
                      chatStorageService: widget.chatStorageService,
                      agentName: currentAgent.name,
                      onContinuationSelected:
                          message.role == MessageRole.assistant
                          ? (suggestion) =>
                                widget.onContinueResponse?.call(suggestion)
                          : null,
                      onMessageDeleted: widget.onMessageDeleted,
                      onMessageRegenerate: widget.onRegenerateResponse != null
                          ? () => widget.onRegenerateResponse!(message.id)
                          : null,
                      onMessageEdited: widget.onMessageEdited,
                      onMessageEditedAndSend: widget.onMessageEditAndSend,
                      isLastMessage: isLastMessage,
                    );
                  }

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
                            model: _resolveModelDisplayName(lastMessage?.model),
                            isStreaming: streamingIsActive,
                            timestamp: lastMessage?.timestamp ?? DateTime.now(),
                            cumulativeTokens: lastMessage?.cumulativeTokens,
                            contextLength: lastMessage?.contextLength,
                          ),
                          chatId: widget.chat?.id ?? '',
                          messageId: lastMessage?.id ?? 'streaming',
                          chatStorageService: widget.chatStorageService,
                          agentName: currentAgent.name,
                        ),
                      );
                    }
                    extraPos++;
                  } else if (shouldShowWaitingAnimation) {
                    if (index == extraPos) {
                      return ChatMessagesWaitingAnimation(
                        loadingIndicatorKey: _loadingIndicatorKey,
                      );
                    }
                    extraPos++;
                  }

                  if (widget.showSuggestions &&
                      widget.continuationSuggestions.isNotEmpty &&
                      index == extraPos) {
                    return ChatMessagesContinuationSuggestions(
                      suggestions: widget.continuationSuggestions,
                      isLoading: widget.isSuggestionsLoading,
                      parentContext: context,
                      onSuggestionTap: (suggestion) {
                        widget.onSendMessage(MessageData(text: suggestion));
                      },
                      onClose: widget.onSuggestionsClose,
                      onRefresh: widget.onSuggestionsRefresh,
                    );
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
}
