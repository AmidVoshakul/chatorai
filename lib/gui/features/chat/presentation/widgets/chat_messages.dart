import 'package:chatorai/core/agents/agent_provider.dart';
import 'package:chatorai/core/constants/chat_messages_constants.dart';
import 'package:chatorai/core/llm/catalog_providers.dart'
    show providerCatalogServiceProvider;
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/chat/chat/assistant_content.dart';
import 'package:chatorai/core/chat/chat/chat_message.dart';
import 'package:chatorai/core/chat/chat/message_converter.dart';
import 'package:chatorai/core/chat/chat_models.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input.dart'
    show MessageData;
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_messages_suggestions.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_messages_waiting_animation.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_scroll_follow_controller.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/parts/chat_message_bubble.dart';
import 'package:chatorai/gui/shared/utils/markdown_parser.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart'
    show
        chatScreenProvider,
        themeProvider,
        modelSettingsProvider,
        sessionPartsProvider;
import 'package:chatorai/shared/utils/logger.dart';
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

  /// External follow owner (main chat via [ChatMessagesArea], owned by
  /// ChatScreen). Null → internal fallback (child window, tests): same class,
  /// same rules (DRY) without touching forbidden callers.
  final ChatScrollFollowController? followController;

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
    this.followController,
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
  final HeadingAnchorRegistry _headingRegistry = HeadingAnchorRegistry();

  /// Cache of non-synthetic messages, keyed on the source messages list
  /// reference and a content hash. The list reference changes exactly when
  /// messages are added or removed, so this avoids re-allocating +
  /// re-filtering the full list on every build (e.g. while streaming parts
  /// update via chatScreenProvider).
  List<Message>? _cachedVisibleMessages;
  List<Message>? _cachedSourceList;
  int _cachedSourceSignature = 0;

  /// Follow owner: external for main chat, internal fallback otherwise.
  late final ChatScrollFollowController _follow;
  bool _ownsFollow = false;
  List<AssistantContent>? _lastPartsRef;

  /// Cheap structural signature: a new list reference plus a change to the
  /// trailing message (streaming updates the last message's content/parts)
  /// invalidates the cache. Avoids allocating a per-message string on every
  /// build (the previous hash joined every message into one large String).
  static int _signature(List<Message>? source) {
    if (source == null) return 0;
    if (source.isEmpty) return 1;
    int hash = source.length;
    for (final m in source) {
      hash = Object.hash(
        hash,
        m.id.hashCode,
        m.content.hashCode,
        m.isComplete.hashCode,
        m.role.hashCode,
      );
    }
    return hash;
  }

  List<Message> get _visibleMessages {
    final source = widget.chat?.messages;
    if (_cachedSourceList == source &&
        _cachedVisibleMessages != null &&
        _cachedSourceSignature == _signature(source)) {
      return _cachedVisibleMessages!;
    }
    _cachedSourceList = source;
    _cachedSourceSignature = _signature(source);
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
    if (widget.followController != null) {
      _follow = widget.followController!;
    } else {
      _follow = ChatScrollFollowController();
      _ownsFollow = true;
    }
    _follow.attach(_scrollController);
    _logger.logInfo(
      '[ChatMessages] ScrollController initialized: ${_scrollController.hashCode}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateHeadings();
    });
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    if (_ownsFollow) _follow.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatMessages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _scrollController = widget.scrollController ?? _scrollController;
      _follow.attach(_scrollController);
    }
    if (oldWidget.followController != widget.followController &&
        widget.followController != null) {
      _follow.dispose();
      _follow = widget.followController!;
      _ownsFollow = false;
      _follow.attach(_scrollController);
    }
    if (_shouldRefreshHeadings(oldWidget)) _refreshHeadingsCache();
  }

  bool _shouldRefreshHeadings(ChatMessages oldWidget) {
    final newMessages = widget.chat?.messages ?? [];
    if (newMessages.isNotEmpty &&
        !newMessages.last.isComplete &&
        newMessages.last.role == MessageRole.assistant) {
      return false;
    }
    final oldMessages = oldWidget.chat?.messages ?? [];
    if (widget.chat?.id != oldWidget.chat?.id) return true;
    if (oldMessages.length != newMessages.length) return true;
    for (int i = 0; i < oldMessages.length; i++) {
      if (oldMessages[i].content != newMessages[i].content) return true;
    }
    return false;
  }

  void _refreshHeadingsCache() {
    _cachedSourceList = null;
    _cachedVisibleMessages = null;
    _cachedSourceSignature = 0;
    _updateHeadings();
  }

  void _notePartsGrowth(List<AssistantContent> parts) {
    if (identical(_lastPartsRef, parts)) return;
    _lastPartsRef = parts;
    final autoScroll = ref.read(themeProvider).autoScrollDuringStreaming;
    _follow.noteGrowth(autoScroll: autoScroll);
  }

  void _updateHeadings() {
    final messages = widget.chat?.messages ?? [];

    final parseStopwatch = Stopwatch()..start();
    _headings = MarkdownParserWithKeys.parseAllMessagesHeadings(
      messages,
      existingHeadings: _headings.isNotEmpty ? _headings : null,
      registry: _headingRegistry,
    );
    // Drop anchors for headings that no longer exist (deleted/edited messages).
    _headingRegistry.prune(_headings.map((h) => h.anchor.id).toSet());
    parseStopwatch.stop();

    _logger.logInfo(
      '[ChatMessages] Updated headings: ${_headings.length} total, messages=${messages.length}, parse=${parseStopwatch.elapsedMilliseconds}ms',
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

  void sendMessage(MessageData messageData) {
    widget.onSendMessage(messageData);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final streamingParts = widget.sessionId != null
        ? (ref.watch(sessionPartsProvider(widget.sessionId!)).value?.parts ??
              const <AssistantContent>[])
        : const <AssistantContent>[];
    final streamingIsActive = widget.isActiveSession
        ? ref.watch(chatScreenProvider.select((s) => s.isStreaming))
        : false;

    _notePartsGrowth(streamingParts);

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

    // Total number of list items. This is the value the [SelectionArea] below
    // is keyed on: whenever the list length changes (a message is added/removed
    // or a streaming/welcome/suggestion row toggles) the [SelectionArea] is
    // rebuilt from scratch, discarding any active text selection. This prevents
    // the Flutter framework assertion in `selectable_region.dart`
    // (`currentSelectionStartIndex < selectables.length`) that fires when an
    // in-progress selection references selectable indices that no longer exist
    // after the list mutates during streaming.
    final itemCount =
        messages.length +
        (shouldShowWaitingAnimation ? 1 : 0) +
        (showStreamingBubble ? 1 : 0) +
        (widget.showSuggestions && widget.continuationSuggestions.isNotEmpty
            ? 1
            : 0) +
        (shouldShowWelcome ? 1 : 0);

    final children = <Widget>[];

    if (shouldShowWelcome) {
      children.add(
        ChatMessagesWelcomeSuggestions(
          suggestions: widget.welcomeSuggestions,
          parentContext: context,
          onSuggestionTap: (suggestion) {
            widget.onSendMessage(MessageData(text: suggestion));
          },
          onClose: widget.onWelcomeSuggestionsClose,
        ),
      );
    }

    // While the streaming bubble is visible it fully represents the message
    // being streamed (card, reasoning, text). Rendering the static bubble for
    // that same id as well would duplicate every part — most visibly a task
    // card — so the static entry is skipped until the stream finalizes and
    // the bubble swaps back to the completed message.
    final streamingBubbleMessageId =
        showStreamingBubble &&
            messages.isNotEmpty &&
            messages.last.role == MessageRole.assistant
        ? messages.last.id
        : null;

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.id == streamingBubbleMessageId) continue;
      final isLastMessage = i == messages.length - 1;

      final chatMsg = messageToChatMessage(message);
      final agentNameForMessage = (chatMsg is AssistantMessage)
          ? (chatMsg.isCompactionSummary
                ? AppLocalizations.of(context)!.compactionAgentName
                : (chatMsg.agent ?? currentAgent.name))
          : currentAgent.name;
      final originalModelId = (chatMsg is AssistantMessage)
          ? chatMsg.model
          : null;
      final resolvedMsg = (chatMsg is AssistantMessage)
          ? chatMsg.copyWith(model: _resolveModelDisplayName(chatMsg.model))
          : chatMsg;
      final reasoningEnabled = originalModelId != null
          ? (modelSettings.settingsCache[originalModelId]?.reasoningEnabled ??
                true)
          : true;

      children.add(
        ChatMessageBubble(
          key: ValueKey(message.id),
          message: resolvedMsg,
          chatId: widget.chat!.id,
          messageId: message.id,
          headings: _headings,
          sessionRepository: widget.sessionRepository,
          agentName: widget.agentName ?? agentNameForMessage,
          onContinuationSelected: message.role == MessageRole.assistant
              ? (_) => widget.onContinueResponse?.call(message.id)
              : null,
          onMessageDeleted: widget.onMessageDeleted,
          onMessageRegenerate: widget.onRegenerateResponse != null
              ? () => widget.onRegenerateResponse!(message.id)
              : null,
          onMessageEdited: widget.onMessageEdited,
          onMessageEditedAndSend: widget.onMessageEditAndSend,
          isLastMessage: isLastMessage,
          onTaskTap: widget.onTaskTap,
          expandReasoningByDefault: expandReasoningByDefault,
          reasoningEnabled: reasoningEnabled,
        ),
      );
    }

    if (showStreamingBubble) {
      final lastMessage = messages.isNotEmpty ? messages.last : null;
      final message = _buildStreamingAssistantMessage(
        messages: messages,
        streamingMessageParts: streamingMessageParts,
        streamingIsActive: streamingIsActive,
      );
      final agentNameForStream =
          lastMessage?.agent ?? widget.agentName ?? currentAgent.name;
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ChatMessageBubble(
            key: const ValueKey('streaming-bubble'),
            message: message,
            chatId: widget.chat?.id ?? '',
            messageId: lastMessage?.id ?? 'streaming',
            headings: _headings,
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
        ),
      );
    } else if (shouldShowWaitingAnimation) {
      children.add(
        ChatMessagesWaitingAnimation(loadingIndicatorKey: _loadingIndicatorKey),
      );
    }

    if (widget.showSuggestions && widget.continuationSuggestions.isNotEmpty) {
      children.add(
        ChatMessagesContinuationSuggestions(
          suggestions: widget.continuationSuggestions,
          isLoading: widget.isSuggestionsLoading,
          parentContext: context,
          onSuggestionTap: (suggestion) {
            widget.onSendMessage(MessageData(text: suggestion));
          },
          onClose: widget.onSuggestionsClose,
          onRefresh: widget.onSuggestionsRefresh,
        ),
      );
    }

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            // LayoutBuilder sits OUTSIDE the scrollable so [constraints] carry
            // the real viewport height (inside a scrollable the main axis is
            // unbounded).
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minContentHeight =
                    (constraints.maxHeight -
                            ChatMessagesConstants.verticalPadding * 2)
                        .clamp(0.0, double.infinity)
                        .toDouble();
                return RepaintBoundary(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: false,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _follow.handleNotification,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: _scrollPhysics(context),
                        padding: EdgeInsets.only(
                          left: ChatMessagesConstants.horizontalPadding,
                          right: ChatMessagesConstants.horizontalPadding,
                          top: ChatMessagesConstants.verticalPadding,
                          bottom: ChatMessagesConstants.verticalPadding,
                        ),
                        child: SelectionArea(
                          // Rebuilt only when the item count changes (message
                          // added/removed, streaming/welcome/suggestion row
                          // toggles). Keeping the Scrollable ABOVE SelectionArea
                          // means this rebuild never recreates the
                          // ScrollPosition, so the scroll offset is preserved
                          // across list mutations (including the streaming-bubble
                          // -> final-message swap at the end of a response, which
                          // previously caused a jump-to-top).
                          key: ValueKey(itemCount),
                          // The scrollable is top-down: offset 0 shows the
                          // oldest content, growing offsets move towards the
                          // newest. minHeight keeps short content (welcome
                          // screen) anchored to the TOP of the viewport
                          // instead of hugging the input.
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minContentHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
