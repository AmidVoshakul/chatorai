import 'package:chatorai/core/agents/agent_provider.dart';
import 'package:chatorai/core/constants/chat_messages_constants.dart';
import 'package:chatorai/core/llm/catalog_providers.dart'
    show providerCatalogServiceProvider;
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/data/models/chat/message_converter.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input.dart'
    show MessageData;
import 'package:chatorai/features/chat/presentation/widgets/chat_messages_suggestions.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_messages_waiting_animation.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/chat_message_bubble.dart';
import 'package:chatorai/providers.dart'
    show
        chatScreenProvider,
        themeProvider,
        modelSettingsProvider,
        sessionPartsProvider;
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/markdown_parser.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = LogTags.chatService;

class ChatMessages extends ConsumerStatefulWidget {
  final Chat? chat;
  final SessionRepository sessionRepository;
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
  final void Function(String? taskSessionId)? onTaskTap;
  final String? agentName;
  final String? sessionId;

  /// Total cumulative tokens for non-active sessions (used in child session windows)
  final int? totalTokens;

  /// When `false`, this widget does NOT watch the global `chatScreenProvider`
  /// streaming state. Use this for child session windows which render their
  /// own history via stored messages and must not pick up the parent's
  /// currently-streaming parts.
  final bool isActiveSession;

  const ChatMessages({
    super.key,
    required this.sessionRepository,
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
    this.onTaskTap,
    this.agentName,
    this.sessionId,
    this.totalTokens,
    this.isActiveSession = true,
  });

  @override
  ConsumerState<ChatMessages> createState() => ChatMessagesState();
}

class ChatMessagesState extends ConsumerState<ChatMessages>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final GlobalKey _loadingIndicatorKey = GlobalKey();

  List<MarkdownHeadingInfoWithKey> _headings = [];

  /// Cache of non-synthetic messages, keyed on the source messages list
  /// reference. The list reference changes exactly when messages are added or
  /// removed, so this avoids re-allocating + re-filtering the full list on
  /// every build (e.g. while streaming parts update via chatScreenProvider).
  List<Message>? _cachedVisibleMessages;
  List<Message>? _cachedSourceList;

  List<Message> get _visibleMessages {
    final source = widget.chat?.messages;
    if (_cachedSourceList == source && _cachedVisibleMessages != null) {
      return _cachedVisibleMessages!;
    }
    _cachedSourceList = source;
    _cachedVisibleMessages =
        source?.where((m) => !m.synthetic).toList() ?? const [];
    return _cachedVisibleMessages!;
  }

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

  static ScrollPhysics _scrollPhysics(BuildContext context) {
    final isMobile = switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
    return isMobile
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
  }

  List<MessagePart> _streamingMessageParts(
    List<AssistantContent> streamingParts, {
    required List<Message> messages,
  }) {
    if (streamingParts.isEmpty) return const [];
    // Only parts of the CURRENT streaming message may appear in the
    // streaming bubble: the last assistant message that is still
    // incomplete. Keying off `streamingParts.last` alone leaks the parts
    // of the previously completed response into the bubble right after a
    // new send — the old answer briefly shows up and then "switches" to
    // the new one when its first deltas arrive.
    final currentAssistant =
        messages.isNotEmpty &&
            messages.last.role == MessageRole.assistant &&
            !messages.last.isComplete
        ? messages.last
        : null;
    if (currentAssistant == null) return const [];
    final filteredParts = streamingParts
        .where((p) => p.messageId == currentAssistant.id)
        .toList();
    return filteredParts
        .map(assistantContentToMessagePart)
        .where((p) => !(p is TextPart && p.content.isEmpty && p.isStreaming))
        .toList();
  }

  bool _showStreamingBubble({
    required List<MessagePart> streamingMessageParts,
    required bool streamingIsActive,
    required List<Message> messages,
  }) {
    return streamingMessageParts.isNotEmpty &&
        streamingIsActive &&
        !(messages.isNotEmpty &&
            messages.last.role == MessageRole.assistant &&
            messages.last.isComplete);
  }

  AssistantMessage _buildStreamingAssistantMessage({
    required List<Message> messages,
    required List<MessagePart> streamingMessageParts,
    required bool streamingIsActive,
  }) {
    final lastMessage = messages.isNotEmpty ? messages.last : null;
    return AssistantMessage(
      id: lastMessage?.id ?? 'streaming',
      parts: streamingMessageParts,
      model: _resolveModelDisplayName(lastMessage?.model),
      isStreaming: streamingIsActive,
      timestamp: lastMessage?.timestamp ?? DateTime.now(),
      contextLength: lastMessage?.contextLength,
    );
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

  void sendMessage(MessageData messageData) {
    widget.onSendMessage(messageData);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final streamingSessionId = ref.watch(
      chatScreenProvider.select((s) => s.streamingSessionId),
    );
    final streamingParts = streamingSessionId != null
        ? (ref.watch(sessionPartsProvider(streamingSessionId)).value?.parts ??
              const <AssistantContent>[])
        : const <AssistantContent>[];
    final streamingIsActive = widget.isActiveSession
        ? ref.watch(chatScreenProvider.select((s) => s.isStreaming))
        : false;

    final messages = _visibleMessages;
    final List<MessagePart> streamingMessageParts = _streamingMessageParts(
      streamingParts,
      messages: messages,
    );

    final currentAgent = ref.watch(currentAgentProvider);

    final isWaitingForStream =
        streamingIsActive && streamingMessageParts.isEmpty;

    final hasReasoningOnly =
        streamingIsActive &&
        streamingMessageParts.isNotEmpty &&
        streamingMessageParts.every((p) => p is ReasoningPart);

    final theme = Theme.of(context);

    final hasMessages = messages.isNotEmpty;
    final hasAssistantMessage =
        hasMessages && messages.last.role == MessageRole.assistant;

    int cumulativeForIndex(int msgIndex) {
      var total = 0;
      for (var i = 0; i <= msgIndex && i < messages.length; i++) {
        final m = messages[i];
        if (m.role == MessageRole.assistant) {
          total += m.tokensInput ?? 0;
          total += m.tokensOutput ?? 0;
          total += m.tokensReasoning ?? 0;
        }
      }
      return total;
    }

    final showStreamingBubble = _showStreamingBubble(
      streamingMessageParts: streamingMessageParts,
      streamingIsActive: streamingIsActive,
      messages: messages,
    );

    final modelSettings = ref.watch(modelSettingsProvider);
    final expandReasoningByDefault = ref
        .watch(themeProvider)
        .expandReasoningByDefault;

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
              child: SelectionArea(
                child: ListView.builder(
                  physics: _scrollPhysics(context),
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

                      final chatMsg = messageToChatMessage(message);
                      final agentNameForMessage = (chatMsg is AssistantMessage)
                          ? (chatMsg.agent ?? currentAgent.name)
                          : currentAgent.name;
                      final originalModelId = (chatMsg is AssistantMessage)
                          ? chatMsg.model
                          : null;
                      final resolvedMsg = (chatMsg is AssistantMessage)
                          ? chatMsg.copyWith(
                              model: _resolveModelDisplayName(chatMsg.model),
                            )
                          : chatMsg;
                      final reasoningEnabled = originalModelId != null
                          ? (modelSettings
                                    .settingsCache[originalModelId]
                                    ?.reasoningEnabled ??
                                true)
                          : true;
                      return ChatMessageBubble(
                        key: ValueKey(message.id),
                        message: resolvedMsg,
                        chatId: widget.chat!.id,
                        messageId: message.id,
                        sessionRepository: widget.sessionRepository,
                        agentName: widget.agentName ?? agentNameForMessage,
                        onContinuationSelected:
                            message.role == MessageRole.assistant
                            ? (_) => widget.onContinueResponse?.call(message.id)
                            : null,
                        onMessageDeleted: widget.onMessageDeleted,
                        onMessageRegenerate: widget.onRegenerateResponse != null
                            ? () => widget.onRegenerateResponse!(message.id)
                            : null,
                        onMessageEdited: widget.onMessageEdited,
                        onMessageEditedAndSend: widget.onMessageEditAndSend,
                        isLastMessage: isLastMessage,
                        cumulativeTokens: message.role == MessageRole.assistant
                            ? (widget.totalTokens ??
                                  cumulativeForIndex(msgIndex))
                            : null,
                        contextLength: message.contextLength,
                        onTaskTap: widget.onTaskTap,
                        expandReasoningByDefault: expandReasoningByDefault,
                        reasoningEnabled: reasoningEnabled,
                      );
                    }

                    final afterMessages = welcomeOffset + messages.length;
                    var extraPos = afterMessages;

                    if (showStreamingBubble) {
                      if (index == extraPos) {
                        final lastMessage = messages.isNotEmpty
                            ? messages.last
                            : null;
                        final message = _buildStreamingAssistantMessage(
                          messages: messages,
                          streamingMessageParts: streamingMessageParts,
                          streamingIsActive: streamingIsActive,
                        );
                        final agentNameForStream =
                            lastMessage?.agent ??
                            widget.agentName ??
                            currentAgent.name;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ChatMessageBubble(
                            key: const ValueKey('streaming-bubble'),
                            message: message,
                            chatId: widget.chat?.id ?? '',
                            messageId: lastMessage?.id ?? 'streaming',
                            sessionRepository: widget.sessionRepository,
                            agentName: agentNameForStream,
                            onTaskTap: widget.onTaskTap,
                            expandReasoningByDefault: expandReasoningByDefault,
                            reasoningEnabled: message.model != null
                                ? (modelSettings
                                          .settingsCache[message.model]
                                          ?.reasoningEnabled ??
                                      true)
                                : true,
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
          ),
        ],
      ),
    );
  }
}
