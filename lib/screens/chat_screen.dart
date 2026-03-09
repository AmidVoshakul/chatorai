// ignore_for_file: avoid_print

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers.dart'
    show
        themeProvider,
        modelProvider,
        modelSettingsProvider,
        streamingContentProvider,
        chatListProvider,
        chatStorageServiceProvider,
        chatAiServiceProvider,
        currentChatIdProvider,
        currentChatProvider,
        chatScreenUIProvider,
        openRouterServiceProvider;
import 'package:chatorai/providers/chat/chat_screen_provider.dart';
import 'package:chatorai/utils/message_utils.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/models/model_settings.dart';
import 'package:chatorai/widgets/sidebar/sidebar.dart';
import 'package:chatorai/widgets/chat/chat_input.dart';
import 'package:chatorai/widgets/chat/chat_messages.dart';
import 'package:chatorai/widgets/chat/markdown_navigator_sidebar.dart';
import 'package:chatorai/widgets/chat/welcome_questions_data.dart';
import 'package:chatorai/widgets/chat/chat_app_bar.dart';
import 'package:chatorai/widgets/chat/sliding_app_bar.dart';
import 'package:chatorai/widgets/chat/speech_overlay.dart';
import 'package:chatorai/services/speech_to_text_service.dart';
import 'package:chatorai/screens/models_screen.dart';
import 'package:chatorai/utils/chat_scroll_utils.dart';
import 'package:chatorai/constants/chat_constants.dart';
import 'package:chatorai/utils/chat_error_utils.dart';
import 'package:chatorai/utils/chat_language_utils.dart';
import 'package:chatorai/utils/chat_suggestion_utils.dart';
import 'package:chatorai/utils/snackbar_utils.dart';
import 'package:chatorai/utils/markdown_parser_with_keys.dart';
import 'package:chatorai/l10n/app_localizations.dart';

// ===========================================================================
// CHAT SCREEN WIDGET
// ===========================================================================

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

// ===========================================================================
// STATE VARIABLES
// ===========================================================================

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  late ChatStorageService _chatStorageService;
  late ScrollController _messageScrollController;
  ChatScrollUtils? _chatScrollUtils;

  final GlobalKey<ChatMessagesState> _chatMessagesKey =
      GlobalKey<ChatMessagesState>();
  final GlobalKey<SlidingAppBarState> _slidingAppBarKey =
      GlobalKey<SlidingAppBarState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DateTime? _lastScrollUpdate;
  static const _scrollThrottleDuration = Duration(milliseconds: 16);
  late final FocusNode _chatInputFocusNode;

  // Cached values for performance
  double _cachedScreenWidth = 0;
  bool _isMobile = false;

  // Speech state
  SpeechUiState _speechUiState = SpeechUiState.idle;
  String _speechStatusMessage = '';
  double _speechSoundLevel = 0.0;

  // ===========================================================================
  // LIFECYCLE METHODS
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _chatStorageService = ref.read(chatStorageServiceProvider);

    _messageScrollController = ScrollController();
    _messageScrollController.addListener(_handleScroll);
    _messageScrollController.addListener(_handleHeadingSync);

    _chatInputFocusNode = FocusNode();

    _chatScrollUtils = ChatScrollUtils(
      scrollController: _messageScrollController,
      animationDuration: ChatScreenConstants.scrollAnimationDuration,
      animationCurve: Curves.easeOut,
    );
    _chatScrollUtils!.initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _slidingAppBarKey.currentState != null) {
        _slidingAppBarKey.currentState?.show();
      }
      _showWelcomeSuggestions();
    });
  }

  @override
  void dispose() {
    _messageScrollController.removeListener(_handleScroll);
    _messageScrollController.removeListener(_handleHeadingSync);
    _messageScrollController.dispose();
    _chatScrollUtils?.dispose();
    _chatInputFocusNode.dispose();
    super.dispose();
  }

  // ===========================================================================
  // SCROLL HANDLERS
  // ===========================================================================

  void _handleScroll() {
    final now = DateTime.now();
    if (_lastScrollUpdate != null &&
        now.difference(_lastScrollUpdate!) < _scrollThrottleDuration) {
      return;
    }
    _lastScrollUpdate = now;

    if (!_messageScrollController.hasClients) return;

    final offset = _messageScrollController.offset;
    if (_cachedScreenWidth >= ChatScreenConstants.mobileBreakpoint) return;

    _slidingAppBarKey.currentState?.handleScroll(offset);
  }

  void _handleHeadingSync() {
    final now = DateTime.now();
    if (_lastScrollUpdate != null &&
        now.difference(_lastScrollUpdate!) < _scrollThrottleDuration) {
      return;
    }
    _lastScrollUpdate = now;

    final uiState = ref.watch(chatScreenUIProvider);
    if (!_messageScrollController.hasClients ||
        uiState.navigatorHeadings.isEmpty) {
      return;
    }

    final currentOffset = _messageScrollController.offset;
    final viewportHeight = _messageScrollController.position.viewportDimension;

    final registry = HeadingAnchorRegistry();
    int newActiveIndex = -1;

    for (int i = 0; i < uiState.navigatorHeadings.length; i++) {
      final heading = uiState.navigatorHeadings[i];
      final anchorId = '${heading.messageId}_${heading.level}_${heading.text}';
      final anchor = registry.getAnchor(anchorId);
      final context = anchor?.context ?? heading.context;

      if (context == null || !context.mounted) {
        continue;
      }

      try {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final position = box.localToGlobal(Offset.zero);
          if (position.dy < viewportHeight / 2 && position.dy > -50) {
            newActiveIndex = i;
            break;
          }
        }
      } catch (e) {
        // Ignore render errors
      }
    }

    if (newActiveIndex == -1) {
      final scrollMax = _messageScrollController.position.maxScrollExtent;
      if (currentOffset >= scrollMax - 100) {
        newActiveIndex = uiState.navigatorHeadings.length - 1;
      } else if (currentOffset < 100) {
        newActiveIndex = 0;
      }
    }

    if (newActiveIndex != -1 && newActiveIndex != uiState.activeHeadingIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && newActiveIndex != -1) {
          ref
              .read(chatScreenUIProvider.notifier)
              .setActiveHeadingIndex(newActiveIndex);
        }
      });
    }
  }

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  Chat? get currentChat => ref.watch(currentChatProvider);

  String get selectedModelId => ref.watch(modelProvider).selectedModelId;

  OpenRouterModel? get selectedModelObject =>
      ref.watch(modelProvider).selectedModelObject;

  // ===========================================================================
  // WELCOME SUGGESTIONS
  // ===========================================================================

  void _showWelcomeSuggestions() {
    final questions = WelcomeQuestionsData.getRandomQuestions(
      context,
      count: 4,
    );
    ref.read(chatScreenProvider.notifier).showWelcomeSuggestions(questions);
  }

  // ===========================================================================
  // CHAT MANAGEMENT
  // ===========================================================================

  Future<void> _createNewChat() async {
    final newChat = await ref.read(chatListProvider.notifier).createNewChat();
    ref.read(currentChatIdProvider.notifier).state = newChat.id;
    ref.read(chatScreenProvider.notifier).setCurrentChat(newChat);
    _slidingAppBarKey.currentState?.reset();
    _showWelcomeSuggestions();
  }

  void _selectChat(String chatId) {
    final chatListAsync = ref.read(chatListProvider);
    final chat = chatListAsync.whenOrNull(
      data: (chats) {
        try {
          return chats.firstWhere((c) => c.id == chatId);
        } catch (_) {
          return null;
        }
      },
    );
    if (chat == null) return;

    ref.read(currentChatIdProvider.notifier).state = chatId;
    ref.read(chatScreenProvider.notifier).setCurrentChat(chat);
    _chatScrollUtils?.reset();
    _slidingAppBarKey.currentState?.reset();

    if (chat.messages.isEmpty) {
      _showWelcomeSuggestions();
    } else {
      ref.read(chatScreenProvider.notifier).hideAllSuggestions();
    }
    _chatScrollUtils?.scrollToBottom();
  }

  Future<void> _deleteChat(String chatId) async {
    final chatListAsync = ref.read(chatListProvider);
    final chat = chatListAsync.whenOrNull(
      data: (chats) => chats.firstWhere((c) => c.id == chatId),
    );
    if (chat == null) return;

    final localizations = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => KeyboardHandlerDialog(
        onEnter: () => Navigator.pop(dialogContext, true),
        onEscape: () => Navigator.pop(dialogContext, false),
        child: AlertDialog(
          title: Text(localizations.deleteChat),
          content: Text(localizations.confirmDeleteMessage(chat.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                localizations.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete == true) {
      final wasCurrentChat = currentChat != null && currentChat!.id == chatId;
      await ref.read(chatListProvider.notifier).deleteChat(chatId);
      if (wasCurrentChat && mounted) {
        ref.read(currentChatIdProvider.notifier).state = null;
        ref.read(chatScreenProvider.notifier).setCurrentChat(null);
        _showWelcomeSuggestions();
      }
    }
  }

  // ===========================================================================
  // MESSAGE HANDLING
  // ===========================================================================

  void _handleSendMessage(MessageData messageData) async {
    _chatScrollUtils?.resetAutoScrollLock();
    ref.read(chatScreenProvider.notifier).hideAllSuggestions();

    final screenWidth = _cachedScreenWidth;
    final uiState = ref.read(chatScreenUIProvider);
    if (screenWidth < ChatScreenConstants.mobileBreakpoint) {
      if (!uiState.isSidebarCollapsed) {
        ref.read(chatScreenUIProvider.notifier).setSidebarCollapsed(true);
      }
    } else {
      if (uiState.isSidebarCollapsed) {
        ref.read(chatScreenUIProvider.notifier).setSidebarCollapsed(false);
      }
    }

    if (currentChat == null) {
      await _createNewChat();
      // After creating new chat, get it directly from chatListProvider since currentChat getter may not be updated yet
      final chatsAsync = ref.read(chatListProvider);
      final chats = chatsAsync.whenOrNull(data: (d) => d) ?? [];
      if (chats.isEmpty) return;
      final newChat = chats.first;
      ref.read(currentChatIdProvider.notifier).state = newChat.id;
      ref.read(chatScreenProvider.notifier).setCurrentChat(newChat);
      // Use newChat directly
      await _handleAddMessagesAndStream(newChat, messageData.text);
      return;
    }

    await _handleAddMessagesAndStream(currentChat!, messageData.text);
  }

  Future<void> _handleAddMessagesAndStream(Chat chat, String text) async {
    final userMessage = _createUserMessage(
      text,
      base64Data: null,
      imageType: null,
    );

    await _chatStorageService.addMessageToChat(chat.id, userMessage);

    final chatFromStorage = await _chatStorageService.getChat(chat.id);
    if (chatFromStorage == null) {
      return;
    }

    final assistantMessage = _createAssistantMessage();
    final allMessages = [...chatFromStorage.messages, assistantMessage];
    final chatWithBoth = chatFromStorage.copyWith(
      messages: allMessages,
      updatedAt: DateTime.now(),
    );

    _chatStorageService.addMessageToChat(chatFromStorage.id, assistantMessage);

    // Update both providers with the chat that includes assistant message
    ref.read(chatScreenProvider.notifier).setCurrentChat(chatWithBoth);
    ref.read(chatListProvider.notifier).updateChat(chatWithBoth);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollUtils?.scrollToIndicator();
    });

    _sendToAI(text, chatWithBoth);
  }

  // ===========================================================================
  // MESSAGE CREATION HELPERS
  // ===========================================================================

  Message _createUserMessage(
    String content, {
    String? base64Data,
    String? imageType,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      isComplete: true,
      imageData: base64Data,
      imageType: imageType,
    );
  }

  Message _createAssistantMessage({
    String content = '',
    bool isComplete = false,
    String? model,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      isComplete: isComplete,
      model: model ?? selectedModelId,
    );
  }

  // ===========================================================================
  // REGENERATE RESPONSE
  // ===========================================================================

  Future<void> _regenerateResponse(String messageId) async {
    final chat = currentChat;
    if (chat == null || chat.messages.isEmpty) return;

    ref.read(chatScreenProvider.notifier).hideSuggestions();

    // Find the message to regenerate
    final messageIndex = chat.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final targetMessage = chat.messages[messageIndex];
    if (targetMessage.role != MessageRole.assistant) return;

    // Find the user message that precedes this AI message
    int userMessageIndex = -1;
    for (int i = messageIndex - 1; i >= 0; i--) {
      if (chat.messages[i].role == MessageRole.user) {
        userMessageIndex = i;
        break;
      }
    }

    if (userMessageIndex == -1) return;

    final userMessage = chat.messages[userMessageIndex];

    final messagesToDelete = chat.messages
        .sublist(messageIndex)
        .map((m) => m.id)
        .toList();
    for (final msgId in messagesToDelete) {
      await _chatStorageService.deleteMessageFromChat(chat.id, msgId);
    }

    final updatedMessages = chat.messages.sublist(0, messageIndex);
    final updatedChat = chat.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    _chatScrollUtils?.resetAutoScrollLock();

    final newAssistantMessage = _createAssistantMessage();
    final chatWithNewPlaceholder = updatedChat.copyWith(
      messages: [...updatedMessages, newAssistantMessage],
      updatedAt: DateTime.now(),
    );

    _chatStorageService.addMessageToChat(chat.id, newAssistantMessage);
    ref.read(chatListProvider.notifier).updateChat(chatWithNewPlaceholder);
    ref
        .read(chatScreenProvider.notifier)
        .setCurrentChat(chatWithNewPlaceholder);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollUtils?.scrollToIndicator();
    });

    _sendToAI(userMessage.content, chatWithNewPlaceholder);
  }

  // ===========================================================================
  // AI STREAMING METHODS
  // ===========================================================================

  Future<void> _sendToAI(String userMessage, [Chat? providedChat]) async {
    final chat = providedChat ?? currentChat;
    if (chat == null) return;

    try {
      _sendToAIWithRetry(userMessage, chat);
    } catch (e) {
      final errorMessage = Message(
        role: MessageRole.assistant,
        content: ChatScreenConstants.defaultErrorMessage,
        timestamp: DateTime.now(),
        isComplete: true,
      );
      await _chatStorageService.addMessageToChat(chat.id, errorMessage);
      final chatFromStorage = await _chatStorageService.getChat(chat.id);
      if (chatFromStorage != null) {
        ref.read(chatScreenProvider.notifier).setCurrentChat(chatFromStorage);
      }
      ref
          .read(chatListProvider.notifier)
          .updateChat(
            chat.copyWith(
              messages: [...chat.messages, errorMessage],
              updatedAt: DateTime.now(),
            ),
          );
    }
  }

  Future<void> _sendToAIWithRetry(
    String userMessage,
    Chat chat, {
    int retryCount = 0,
  }) async {
    try {
      await _streamAIResponse(chat);
    } catch (e) {
      if (e.toString().contains('429') ||
          e.toString().contains('Rate limit') ||
          e.toString().contains('bad response')) {
        if (retryCount < ChatScreenConstants.maxRetryAttempts) {
          final delay = Duration(
            seconds:
                ChatScreenConstants.baseRetryDelaySeconds *
                pow(2, retryCount).toInt(),
          );
          final localizations = AppLocalizations.of(context);
          final retryMessageContent =
              localizations?.rateLimitRetryMessage(delay.inSeconds) ??
              'Retrying...';
          final retryMessage = Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: MessageRole.assistant,
            content: retryMessageContent,
            timestamp: DateTime.now(),
            isComplete: true,
          );

          await _chatStorageService.addMessageToChat(chat.id, retryMessage);
          ref
              .read(chatListProvider.notifier)
              .updateChat(
                chat.copyWith(
                  messages: [...chat.messages, retryMessage],
                  updatedAt: DateTime.now(),
                ),
              );

          await Future.delayed(delay);

          final messagesWithoutRetry = chat.messages
              .where((msg) => msg.content != retryMessage.content)
              .toList();
          ref
              .read(chatListProvider.notifier)
              .updateChat(
                chat.copyWith(
                  messages: messagesWithoutRetry,
                  updatedAt: DateTime.now(),
                ),
              );

          await _sendToAIWithRetry(
            userMessage,
            chat,
            retryCount: retryCount + 1,
          );
        } else {
          final errorMessage = Message(
            role: MessageRole.assistant,
            content: ChatScreenConstants.rateLimitMessage,
            timestamp: DateTime.now(),
            isComplete: true,
          );
          await _chatStorageService.addMessageToChat(chat.id, errorMessage);
          ref
              .read(chatListProvider.notifier)
              .updateChat(
                chat.copyWith(
                  messages: [...chat.messages, errorMessage],
                  updatedAt: DateTime.now(),
                ),
              );
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> _streamAIResponse(Chat chat) async {
    // Limit message history to last N messages for performance
    // LLM doesn't need the entire conversation history
    const int maxHistoryMessages = 20;
    final recentMessages = chat.messages.length > maxHistoryMessages
        ? chat.messages.sublist(chat.messages.length - maxHistoryMessages)
        : chat.messages;

    final messages = recentMessages
        .where((m) => !m.isError)
        .map(
          (msg) => ref
              .read(chatAiServiceProvider)
              .convertMessageToOpenRouterFormat(msg),
        )
        .toList();

    final modelSettingsNotifier = ref.read(modelSettingsProvider.notifier);
    final settings = await modelSettingsNotifier.getSettings(selectedModelId);

    if (settings.systemPrompt != null && messages.isNotEmpty) {
      messages.insert(0, {'role': 'system', 'content': settings.systemPrompt!});
    }

    await _handleStreamingResponse(
      chat: chat,
      messages: messages,
      isContinuation: false,
      modelId: selectedModelId,
      modelSettings: settings,
    );
  }

  // ===========================================================================
  // STREAMING RESPONSE HANDLER
  // ===========================================================================

  Future<void> _handleStreamingResponse({
    required Chat chat,
    required List<Map<String, dynamic>> messages,
    required bool isContinuation,
    required String modelId,
    required ModelSettings modelSettings,
  }) async {
    final modelContextLength = ChatScreenConstants.defaultMaxTokens;
    int currentMaxTokens = min(modelSettings.maxTokens, modelContextLength);
    final effectiveMinTokens = min(8000, modelContextLength ~/ 2);
    const reductionFactor = ChatScreenConstants.reductionFactor;
    int tokenReductionAttempts = 0;

    ref.read(chatScreenProvider.notifier).setStreaming(true);
    ref.read(streamingContentProvider.notifier).startStreaming(chat.id);

    final StringBuffer pendingContent = StringBuffer();
    final StringBuffer fullContent = StringBuffer();
    final StringBuffer pendingReasoning = StringBuffer();
    final StringBuffer fullReasoning = StringBuffer();

    DateTime lastUpdateTime = DateTime.now();
    const updateIntervalMs = 250;

    bool _isWordBoundary(String text) {
      if (text.isEmpty) return false;
      final lastChar = text[text.length - 1];
      return lastChar == ' ' ||
          lastChar == '\n' ||
          lastChar == '.' ||
          lastChar == ',' ||
          lastChar == '!' ||
          lastChar == '?' ||
          lastChar == ';' ||
          lastChar == ':' ||
          lastChar == ')' ||
          lastChar == ']' ||
          lastChar == '}' ||
          lastChar == '"' ||
          lastChar == "'";
    }

    void throttleUpdate({bool forceUpdate = false}) {
      final now = DateTime.now();
      final elapsed = now.difference(lastUpdateTime).inMilliseconds;

      final pendingContentStr = pendingContent.toString();
      final pendingReasoningStr = pendingReasoning.toString();

      final shouldUpdate =
          forceUpdate ||
          elapsed >= updateIntervalMs ||
          _isWordBoundary(pendingContentStr) ||
          _isWordBoundary(pendingReasoningStr);

      if (shouldUpdate) {
        if (mounted && chat.messages.isNotEmpty) {
          fullContent.write(pendingContentStr);
          fullReasoning.write(pendingReasoningStr);
          ref
              .read(streamingContentProvider.notifier)
              .updateContent(
                fullContent.toString(),
                reasoning: fullReasoning.isNotEmpty
                    ? fullReasoning.toString()
                    : null,
              );
          pendingContent.clear();
          pendingReasoning.clear();
          lastUpdateTime = now;
        }
      }
    }

    void flushPendingUpdates() {
      final pendingContentStr = pendingContent.toString();
      final pendingReasoningStr = pendingReasoning.toString();
      fullContent.write(pendingContentStr);
      fullReasoning.write(pendingReasoningStr);
      pendingContent.clear();
      pendingReasoning.clear();
      throttleUpdate(forceUpdate: true);
    }

    final aiService = ref.read(chatAiServiceProvider);
    final attemptMsgs = aiService.sanitizeMessages(messages);
    final client = aiService.client;

    while (true) {
      try {
        await client.streamChatCompletion(
          messages: attemptMsgs,
          model: modelId,
          maxTokens: currentMaxTokens,
          temperature: modelSettings.temperature,
          topP: modelSettings.topP,
          frequencyPenalty: modelSettings.frequencyPenalty,
          presencePenalty: modelSettings.presencePenalty,
          includeReasoning: true,
          onChunk: (content) {
            if (content.isEmpty) return;
            pendingContent.write(content);
            throttleUpdate();
          },
          onReasoning: (reasoning) {
            if (reasoning.isEmpty) return;
            pendingReasoning.write(reasoning);
            throttleUpdate();
          },
          onCompletion: (fullContent) async {
            flushPendingUpdates();

            if (mounted && chat.messages.isNotEmpty) {
              final lastMessage = chat.messages.last;
              final completedMessage = lastMessage.copyWith(
                content: fullContent.toString(),
                reasoning: fullReasoning.isNotEmpty
                    ? fullReasoning.toString()
                    : null,
                isComplete: true,
              );
              final newMessages = List<Message>.from(chat.messages);
              newMessages[newMessages.length - 1] = completedMessage;
              final newChat = chat.copyWith(
                messages: newMessages,
                updatedAt: DateTime.now(),
              );

              ref.read(chatListProvider.notifier).updateChat(newChat);
              ref.read(chatScreenProvider.notifier).setCurrentChat(newChat);
              ref.read(chatScreenProvider.notifier).setStreaming(false);
              ref.read(streamingContentProvider.notifier).stopStreaming();

              await _chatStorageService.updateMessageInChat(
                newChat.id,
                completedMessage.id,
                completedMessage,
              );

              _showContinuationSuggestions(completedMessage);
            }
          },
        );
        break;
      } catch (e) {
        final err = e.toString();
        final isBadRequest =
            err.contains('400') || err.toLowerCase().contains('bad response');
        if (!isBadRequest) {
          ref.read(chatScreenProvider.notifier).setStreaming(false);
          ref.read(streamingContentProvider.notifier).reset();
          await _handleStreamingError(e);
          break;
        }

        if (tokenReductionAttempts <
                ChatScreenConstants.maxTokenReductionAttempts &&
            currentMaxTokens > effectiveMinTokens) {
          int newTokens = (currentMaxTokens * reductionFactor).floor();
          if (newTokens < effectiveMinTokens) newTokens = effectiveMinTokens;
          if (newTokens < currentMaxTokens) {
            tokenReductionAttempts++;
            currentMaxTokens = newTokens;
            continue;
          }
        }

        if (attemptMsgs.length <= 1) {
          ref.read(chatScreenProvider.notifier).setStreaming(false);
          ref.read(streamingContentProvider.notifier).reset();
          await _handleStreamingError(e);
          break;
        }

        int removedCount = 0;
        for (int i = 0; i < attemptMsgs.length && removedCount < 2; i++) {
          if (attemptMsgs[i]['role'] != 'system') {
            attemptMsgs.removeAt(i);
            removedCount++;
            i--;
          }
        }
        tokenReductionAttempts = 0;
      }
    }
  }

  // ===========================================================================
  // ERROR HANDLING
  // ===========================================================================

  Future<void> _handleStreamingError(Object error) async {
    final errorMessage = ChatErrorUtils.formatError(error);
    if (currentChat != null && currentChat!.messages.isNotEmpty) {
      final lastMessage = currentChat!.messages.last;
      if (lastMessage.role == MessageRole.assistant) {
        final errorResponseMessage = lastMessage.copyWith(
          content: errorMessage,
          isComplete: true,
          isError: true,
        );
        await _chatStorageService.updateMessageInChat(
          currentChat!.id,
          errorResponseMessage.id,
          errorResponseMessage,
        );
        final newMessages = [
          ...currentChat!.messages.take(currentChat!.messages.length - 1),
          errorResponseMessage,
        ];
        ref
            .read(chatListProvider.notifier)
            .updateChat(
              currentChat!.copyWith(
                messages: newMessages,
                updatedAt: DateTime.now(),
              ),
            );
      }
    }
  }

  // ===========================================================================
  // STREAMING CONTROL
  // ===========================================================================

  void _stopStreaming() {
    // Stop the AI service streaming
    final aiService = ref.read(chatAiServiceProvider);
    aiService.stopGeneration();

    // Update UI state
    ref.read(chatScreenProvider.notifier).setStreaming(false);
    ref.read(streamingContentProvider.notifier).reset();
  }

  // ===========================================================================
  // REFRESH CHAT MESSAGES
  // ===========================================================================

  void _refreshChatMessages() async {
    FocusScope.of(context).unfocus();
    if (currentChat != null) {
      final updatedChat = await _chatStorageService.getChat(currentChat!.id);
      if (updatedChat != null) {
        ref.read(chatListProvider.notifier).updateChat(updatedChat);
        ref.read(chatScreenProvider.notifier).setCurrentChat(updatedChat);
        ref.read(chatScreenProvider.notifier).hideSuggestions();
        if (updatedChat.messages.isEmpty) {
          ref.read(chatScreenProvider.notifier).hideAllSuggestions();
          _showWelcomeSuggestions();
        }
      }
    }
  }

  // ===========================================================================
  // MESSAGE EDIT HANDLERS
  // ===========================================================================

  Future<void> _handleMessageEdited(String messageId, String newContent) async {
    if (currentChat == null) return;
    final messages = currentChat!.messages;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final editedMessage = messages[messageIndex].copyWith(content: newContent);
    await _chatStorageService.updateMessageInChat(
      currentChat!.id,
      messageId,
      editedMessage,
    );
    final updatedMessages = List<Message>.from(messages)
      ..[messageIndex] = editedMessage;
    final updatedChat = currentChat!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
    ref.read(chatListProvider.notifier).updateChat(updatedChat);
    ref.read(chatScreenProvider.notifier).setCurrentChat(updatedChat);

    final localizations = AppLocalizations.of(context);
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message: localizations?.messageEditedSuccessfully ?? 'Message edited',
      icon: Icons.edit,
    );
  }

  Future<void> _handleMessageEditAndSend(
    String messageId,
    String newContent,
  ) async {
    if (currentChat == null) return;

    ref.read(chatScreenProvider.notifier).hideSuggestions();

    final messages = currentChat!.messages;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final editedUserMessage = messages[messageIndex].copyWith(
      content: newContent,
    );
    await _chatStorageService.updateMessageInChat(
      currentChat!.id,
      messageId,
      editedUserMessage,
    );

    // Delete all messages AFTER the edited one (but keep messages BEFORE it)
    for (int i = messages.length - 1; i > messageIndex; i--) {
      await _chatStorageService.deleteMessageFromChat(
        currentChat!.id,
        messages[i].id,
      );
    }

    // Keep all messages BEFORE the edited one, replacing it with edited version
    final messagesBeforeEdit = messages.sublist(0, messageIndex + 1);
    messagesBeforeEdit[messagesBeforeEdit.length - 1] = editedUserMessage;

    final updatedChat = currentChat!.copyWith(
      messages: messagesBeforeEdit,
      updatedAt: DateTime.now(),
    );

    final assistantMessage = _createAssistantMessage();
    final chatWithAssistant = updatedChat.copyWith(
      messages: [...messagesBeforeEdit, assistantMessage],
      updatedAt: DateTime.now(),
    );

    await _chatStorageService.addMessageToChat(
      currentChat!.id,
      assistantMessage,
    );

    ref.read(chatListProvider.notifier).updateChat(chatWithAssistant);
    ref.read(chatScreenProvider.notifier).setCurrentChat(chatWithAssistant);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollUtils?.scrollToIndicator();
    });

    _sendToAI(newContent, chatWithAssistant);

    final localizations = AppLocalizations.of(context);
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message:
          localizations?.messageEditedAndResponseRegenerated ??
          'Message regenerated',
      icon: Icons.refresh,
    );
  }

  // ===========================================================================
  // NAVIGATOR HANDLERS
  // ===========================================================================

  void _onHeadingsUpdated(List<MarkdownHeadingInfoWithKey> headings) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatScreenUIProvider.notifier).setNavigatorHeadings(headings);
      }
    });
  }

  void _toggleNavigator() {
    ref.read(chatScreenUIProvider.notifier).toggleNavigator();
  }

  void _onHeadingTap(String headingText, String messageId, int level) {
    final uiState = ref.watch(chatScreenUIProvider);

    final normalizedTapText = stripMarkdownFormatting(headingText);
    final headingIndex = uiState.navigatorHeadings.indexWhere(
      (h) =>
          h.messageId == messageId &&
          h.level == level &&
          stripMarkdownFormatting(h.text) == normalizedTapText,
    );

    if (headingIndex >= 0) {
      ref
          .read(chatScreenUIProvider.notifier)
          .setActiveHeadingIndex(headingIndex);

      final heading = uiState.navigatorHeadings[headingIndex];

      final registry = HeadingAnchorRegistry();
      final normalizedText = stripMarkdownFormatting(headingText);
      final anchorId = '${messageId}_${level}_$normalizedText';
      final anchor = registry.getAnchor(anchorId);
      final context = anchor?.context ?? heading.context;

      void performScroll() {
        var ctx = anchor?.context ?? heading.context;

        if (ctx == null || !ctx.mounted) {
          final registry = HeadingAnchorRegistry();
          for (final a in registry.allAnchors) {
            if (a.messageId == messageId &&
                a.context != null &&
                a.context!.mounted) {
              ctx = a.context;
              break;
            }
          }
        }

        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return;
        }

        if (_messageScrollController.hasClients) {
          final chat = currentChat;
          if (chat != null) {
            final messageIndex = chat.messages.indexWhere(
              (m) => m.id == messageId,
            );
            if (messageIndex >= 0) {
              final viewportHeight =
                  _messageScrollController.position.viewportDimension;
              final maxScroll =
                  _messageScrollController.position.maxScrollExtent;

              final avgItemHeight =
                  viewportHeight > 0 && chat.messages.isNotEmpty
                  ? viewportHeight / min(chat.messages.length, 5)
                  : 150.0;

              final estimatedOffset = messageIndex * avgItemHeight;
              final targetOffset = estimatedOffset.clamp(0.0, maxScroll);

              _messageScrollController.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        }
      }

      if (context != null && context.mounted) {
        performScroll();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          performScroll();
        });
      }
    }
    ref.read(chatScreenUIProvider.notifier).setNavigatorVisible(false);
  }

  // ===========================================================================
  // CONTINUATION RESPONSE HANDLERS
  // ===========================================================================

  void _continueAIResponse(String lastMessageId) async {
    if (currentChat == null) return;

    ref.read(chatScreenProvider.notifier).hideSuggestions();

    final lastMessage = currentChat!.messages.lastWhere(
      (msg) => msg.role == MessageRole.assistant && msg.id == lastMessageId,
      orElse: () => currentChat!.messages.first,
    );
    if (lastMessage.content.isEmpty) return;

    final continuationMessage = _createAssistantMessage();
    await _chatStorageService.addMessageToChat(
      currentChat!.id,
      continuationMessage,
    );
    final chatFromStorage = await _chatStorageService.getChat(currentChat!.id);
    if (chatFromStorage != null) {
      ref.read(chatListProvider.notifier).updateChat(chatFromStorage);
      ref.read(chatScreenProvider.notifier).setCurrentChat(chatFromStorage);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollUtils?.scrollToIndicator();
    });

    await _streamContinuationResponse(lastMessage.content, chatFromStorage!);
  }

  Future<void> _streamContinuationResponse(
    String previousContent,
    Chat chatArg,
  ) async {
    final continuationPrompt = [
      {'role': 'user', 'content': 'Please continue your previous response.'},
      {'role': 'assistant', 'content': previousContent},
      {'role': 'user', 'content': 'Continue from where you left off.'},
    ];

    final modelSettingsNotifier = ref.read(modelSettingsProvider.notifier);
    final settings = await modelSettingsNotifier.getSettings(selectedModelId);

    if (settings.systemPrompt != null) {
      continuationPrompt.insert(0, {
        'role': 'system',
        'content': settings.systemPrompt!,
      });
    }

    await _handleStreamingResponse(
      chat: chatArg,
      messages: continuationPrompt,
      isContinuation: true,
      modelId: selectedModelId,
      modelSettings: settings,
    );
  }

  // ===========================================================================
  // MODEL SELECTION
  // ===========================================================================

  void _updateSelectedModel(String modelId, OpenRouterModel? modelObject) {
    ref.read(modelProvider.notifier).setSelectedModel(modelId);
  }

  void _showModelSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModelsScreen(
          onModelSelected: _updateSelectedModel,
          currentModel: selectedModelId,
        ),
      ),
    );
  }

  bool _hasHeadings() {
    return ref.read(chatScreenUIProvider).navigatorHeadings.isNotEmpty;
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  Widget _buildSidebarDrawer({required double width}) {
    final isCollapsed = ref.watch(
      chatScreenUIProvider.select((s) => s.isSidebarCollapsed),
    );
    return Drawer(
      key: ValueKey('sidebar_drawer_$isCollapsed'),
      width: width,
      child: Sidebar(
        width: width,
        isCollapsed: isCollapsed,
        onToggleSidebar: () => Navigator.pop(context),
        onChatSelect: (chatId) {
          _selectChat(chatId);
          Navigator.of(context).pop();
        },
        onChatDelete: _deleteChat,
        onNewChat: () {
          _createNewChat();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ===========================================================================
  // BUILD CHAT MESSAGES
  // ===========================================================================

  Widget _buildChatMessages({bool wrapWithGesture = false}) {
    final chatState = ref.watch(chatScreenProvider);
    final chatMessages = ChatMessages(
      key: _chatMessagesKey,
      openRouterService: ref.read(openRouterServiceProvider),
      chatStorageService: _chatStorageService,
      chat: chatState.currentChat,
      selectedModel: chatState.selectedModelId,
      onSendMessage: _handleSendMessage,
      onMessageDeleted: _refreshChatMessages,
      onMessageEdited: _handleMessageEdited,
      onMessageEditAndSend: _handleMessageEditAndSend,
      onContinueResponse: _continueAIResponse,
      onRegenerateResponse: _regenerateResponse,
      scrollController: _messageScrollController,
      continuationSuggestions: chatState.continuationSuggestions,
      showSuggestions: chatState.showSuggestions,
      isSuggestionsLoading: chatState.isSuggestionsLoading,
      onSuggestionsClose: () =>
          ref.read(chatScreenProvider.notifier).hideSuggestions(),
      onSuggestionsRefresh: () {
        if (chatState.currentChat != null &&
            chatState.currentChat!.messages.isNotEmpty) {
          _showContinuationSuggestions(chatState.currentChat!.messages.last);
        }
      },
      welcomeSuggestions: chatState.welcomeSuggestions,
      showWelcomeSuggestions: chatState.showWelcomeSuggestions,
      onWelcomeSuggestionsClose: () =>
          ref.read(chatScreenProvider.notifier).hideWelcomeSuggestions(),
      onHeadingsUpdated: _onHeadingsUpdated,
      onToggleNavigator: _toggleNavigator,
    );

    if (wrapWithGesture) {
      return GestureDetector(
        onDoubleTap: () {
          if (_hasHeadings()) _toggleNavigator();
        },
        child: chatMessages,
      );
    }
    return chatMessages;
  }

  // ===========================================================================
  // MAIN BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isStreaming = ref.watch(
      chatScreenProvider.select((s) => s.isStreaming),
    );
    _cachedScreenWidth = MediaQuery.of(context).size.width;
    _isMobile = _cachedScreenWidth < ChatScreenConstants.mobileBreakpoint;

    final chatInput = ChatInput(
      key: const ValueKey('chat_input_widget'),
      onSendMessage: _handleSendMessage,
      onToggleStreaming: (_) {},
      onStopStreaming: _stopStreaming,
      isStreaming: isStreaming,
      focusNode: _chatInputFocusNode,
      onSpeechStateChanged: (state, message) {
        setState(() {
          _speechUiState = state;
          _speechStatusMessage = message;
        });
      },
      onSoundLevelChanged: (level) {
        setState(() {
          _speechSoundLevel = (level / 30).clamp(0.0, 1.0);
        });
      },
      checkModelSupportsImages: (_) =>
          ref.read(modelProvider.notifier).modelSupportsImagesSelected(),
    );

    Widget baseLayout = _isMobile
        ? _buildMobileLayout(chatInput)
        : _buildDesktopLayout(chatInput);

    // Wrap with speech overlay if speech is active
    if (_speechUiState != SpeechUiState.idle) {
      baseLayout = Stack(
        children: [
          baseLayout,
          SpeechOverlayWidget(
            state: _speechUiState,
            message: _speechStatusMessage,
            soundLevel: _speechSoundLevel,
          ),
        ],
      );
    }

    final uiState = ref.watch(chatScreenUIProvider);
    if (uiState.navigatorHeadings.isNotEmpty) {
      return Stack(
        children: [
          baseLayout,
          MarkdownNavigatorSidebar(
            headings: uiState.navigatorHeadings,
            activeHeadingIndex: uiState.activeHeadingIndex,
            isOpen: uiState.isNavigatorVisible,
            onClose: _toggleNavigator,
            onHeadingTap: _onHeadingTap,
          ),
        ],
      );
    }

    return baseLayout;
  }

  // ===========================================================================
  // LAYOUT BUILDERS
  // ===========================================================================

  Widget _buildMobileLayout(Widget chatInput) {
    final hasHeadings = _hasHeadings();
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSidebarDrawer(width: ChatScreenConstants.sidebarWidth),
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          if (details.globalPosition.dx < 50) {
            FocusScope.of(context).unfocus();
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        child: Column(
          children: [
            SlidingAppBar(
              key: _slidingAppBarKey,
              selectedModel: selectedModelId,
              selectedModelObject: selectedModelObject,
              onMenuPressed: () {
                FocusScope.of(context).unfocus();
                _scaffoldKey.currentState?.openDrawer();
              },
              onModelSelected: _showModelSelection,
              hasHeadings: () => hasHeadings,
              onNavigatorPressed: _toggleNavigator,
              isMobile: true,
            ),
            Expanded(
              child: _buildChatContentWrapper(
                child: Column(
                  children: [
                    Expanded(child: _buildChatMessages(wrapWithGesture: true)),
                    chatInput,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Widget chatInput) {
    final hasHeadings = _hasHeadings();
    return Scaffold(
      key: _scaffoldKey,
      appBar: ChatAppBar(
        selectedModel: selectedModelId,
        selectedModelObject: selectedModelObject,
        hasHeadings: () => hasHeadings,
        onToggleNavigator: _toggleNavigator,
        onModelSelected: _updateSelectedModel,
        onMenuPressed: () {
          FocusScope.of(context).unfocus();
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      drawer: _buildSidebarDrawer(width: ChatScreenConstants.sidebarWidth),
      body: Column(
        children: [
          Expanded(
            child: _buildChatContentWrapper(
              child: Column(
                children: [
                  Expanded(child: _buildChatMessages()),
                  chatInput,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CONTENT WRAPPER
  // ===========================================================================

  Widget _buildChatContentWrapper({required Widget child}) {
    final screenWidth = _cachedScreenWidth;
    final isNavigatorVisible = ref.watch(
      chatScreenUIProvider.select((s) => s.isNavigatorVisible),
    );
    final wideScreenMode = ref.watch(
      themeProvider.select((s) => s.wideScreenMode),
    );

    Widget content = GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_hasHeadings() && !isNavigatorVisible) {
          if (details.primaryDelta! < -10 &&
              details.globalPosition.dx > screenWidth - 30) {
            _toggleNavigator();
          }
        }
      },
      child: child,
    );

    if (screenWidth >= ChatScreenConstants.mobileBreakpoint) {
      if (wideScreenMode) {
        return content;
      }
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          width: screenWidth * 0.65,
          child: content,
        ),
      );
    }
    return content;
  }

  // ===========================================================================
  // CONTINUATION SUGGESTIONS
  // ===========================================================================

  Future<void> _showContinuationSuggestions(Message message) async {
    final chatState = ref.read(chatScreenProvider);
    if (chatState.isSuggestionsLoading) return;

    ref.read(chatScreenProvider.notifier).setSuggestionsLoading(true);

    try {
      final language = ChatLanguageUtils.detectLanguage(message.content);
      final suggestions = await _getContinuationSuggestions(
        message.content,
        language,
      );

      if (suggestions.isNotEmpty) {
        ref
            .read(chatScreenProvider.notifier)
            .showContinuationSuggestions(suggestions);
      }
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message:
            localizations?.generatingSuggestionsFailed('Error') ?? 'Failed',
        icon: Icons.error,
      );
    } finally {
      ref.read(chatScreenProvider.notifier).setSuggestionsLoading(false);
    }
  }

  Future<List<String>> _getContinuationSuggestions(
    String content,
    String language,
  ) async {
    final localizations = AppLocalizations.of(context);
    final systemPrompt =
        localizations?.systemPromptSuggestion ?? 'You are a helpful assistant.';
    final userPrompt =
        localizations?.userPromptSuggestion ?? 'Provide 3 continuations.';

    final suggestionPrompt = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'assistant', 'content': content},
      {'role': 'user', 'content': userPrompt},
    ];

    final settings = await ref
        .read(modelSettingsProvider.notifier)
        .getSettings(selectedModelId);
    final suggestionSettings = settings.copyWith(
      maxTokens: 500,
      temperature: 0.7,
    );

    if (suggestionSettings.systemPrompt != null) {
      suggestionPrompt.insert(0, {
        'role': 'system',
        'content': suggestionSettings.systemPrompt!,
      });
    }

    try {
      final response = await ref
          .read(chatAiServiceProvider)
          .getChatCompletionWithAdaptiveRollback(
            model: selectedModelId,
            messages: suggestionPrompt,
            modelSettings: suggestionSettings,
          );
      return parseSuggestions(response.content);
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      return [
        localizations?.defaultSuggestion1 ?? 'Tell me more',
        localizations?.defaultSuggestion2 ?? 'Examples?',
        localizations?.defaultSuggestion3 ?? 'Alternatives?',
      ];
    }
  }
}
