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
        currentChatIdProvider,
        isStreamingProvider,
        continuationSuggestionsProvider,
        showSuggestionsProvider,
        welcomeSuggestionsProvider,
        showWelcomeSuggestionsProvider,
        speechUiStateProvider,
        speechStatusMessageProvider;
import 'package:chatorai/providers/chat/streaming_content_controller.dart';
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
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/utils/markdown_parser_with_keys.dart';
import 'package:chatorai/l10n/app_localizations.dart';

// Initialize logger for this screen
final _logger = LogTags.chatScreen;

class ChatScreen extends ConsumerStatefulWidget {
  final OpenRouterClient? openRouterService;

  const ChatScreen({super.key, this.openRouterService});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  late ChatStorageService _chatStorageService;
  late OpenRouterClient _openRouterService;

  bool _isSidebarCollapsed = false;

  List<Chat> _chats = [];
  Chat? _currentChat;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _chatInputFocusNode = FocusNode();
  late ScrollController _messageScrollController;
  ChatScrollUtils? _chatScrollUtils;
  String _selectedModel = ChatScreenConstants.defaultModelId;
  OpenRouterModel? _selectedModelObject;
  bool _isSuggestionsLoading = false;
  bool _showSuggestions = false;
  List<String> _continuationSuggestions = [];

  // Welcome suggestions for empty chats
  bool _showWelcomeSuggestions = false;
  List<String> _welcomeSuggestions = [];

  // Streaming state
  bool _isStreaming = false;

  // Navigator state
  final GlobalKey<ChatMessagesState> _chatMessagesKey =
      GlobalKey<ChatMessagesState>();
  bool _isNavigatorVisible = false;
  List<MarkdownHeadingInfoWithKey> _navigatorHeadings = [];
  int _activeHeadingIndex = -1;

  // Sliding AppBar state
  final GlobalKey<SlidingAppBarState> _slidingAppBarKey =
      GlobalKey<SlidingAppBarState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Speech overlay state
  SpeechUiState _speechUiState = SpeechUiState.idle;
  String _speechStatusMessage = '';

  // Streaming content controller for selective UI updates
  late StreamingContentNotifier _streamingController;

  // Provider-based getters (these delegate to providers)
  List<Chat> get chats =>
      ref.watch(chatListProvider).whenOrNull(data: (d) => d) ?? _chats;
  bool get isStreamingFromProvider => ref.watch(isStreamingProvider);
  List<String> get continuationSuggestionsFromProvider =>
      ref.watch(continuationSuggestionsProvider);
  bool get showSuggestionsFromProvider => ref.watch(showSuggestionsProvider);
  List<String> get welcomeSuggestionsFromProvider =>
      ref.watch(welcomeSuggestionsProvider);
  bool get showWelcomeSuggestionsFromProvider =>
      ref.watch(showWelcomeSuggestionsProvider);
  SpeechUiState get speechUiStateFromProvider =>
      ref.watch(speechUiStateProvider);
  String get speechStatusMessageFromProvider =>
      ref.watch(speechStatusMessageProvider);

  @override
  void initState() {
    super.initState();
    _chatStorageService = ChatStorageService();
    _openRouterService = widget.openRouterService ?? OpenRouterService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _streamingController = ref.read(streamingContentProvider.notifier);
      }
    });

    _messageScrollController = ScrollController();

    // Add scroll listener for sliding app bar
    _messageScrollController.addListener(_handleScrollForSlidingAppBar);

    // Add scroll listener for heading sync
    _messageScrollController.addListener(_handleScrollForHeadingSync);

    // Ensure sliding app bar is visible on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _slidingAppBarKey.currentState != null) {
        _slidingAppBarKey.currentState?.show();
      }
    });

    // Initialize scroll utilities immediately (no need to wait for frame)
    _chatScrollUtils = ChatScrollUtils(
      scrollController: _messageScrollController,
      animationDuration: ChatScreenConstants.scrollAnimationDuration,
      animationCurve: Curves.easeOut,
    );
    _chatScrollUtils!.initialize();

    // Initialize model selection from model provider in post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final modelState = ref.read(modelProvider);
        _selectedModel = modelState.selectedModelId;
        _selectedModelObject = modelState.selectedModelObject;
      }
    });

    // Load chats after a short delay to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChats();
    });
  }

  // Handle scroll events for sliding app bar
  void _handleScrollForSlidingAppBar() {
    if (!_messageScrollController.hasClients) return;

    final offset = _messageScrollController.offset;

    // Only apply sliding behavior on mobile
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= ChatScreenConstants.mobileBreakpoint) return;

    // Pass ALL scroll events to sliding app bar
    // The SlidingAppBar's handleScroll() method has its own logic to determine
    // when to hide/show based on scroll direction and position
    _slidingAppBarKey.currentState?.handleScroll(offset);
  }

  void _handleScrollForHeadingSync() {
    if (!_messageScrollController.hasClients || _navigatorHeadings.isEmpty) {
      return;
    }

    final currentOffset = _messageScrollController.offset;
    final viewportHeight = _messageScrollController.position.viewportDimension;

    int newActiveIndex = -1;

    for (int i = 0; i < _navigatorHeadings.length; i++) {
      final heading = _navigatorHeadings[i];
      final context = heading.key.currentContext;

      if (context != null) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final position = box.localToGlobal(Offset.zero);
          final headingTop = position.dy;

          if (headingTop < viewportHeight / 2 && headingTop > -50) {
            newActiveIndex = i;
            break;
          }
        }
      }
    }

    if (newActiveIndex == -1) {
      final scrollMax = _messageScrollController.position.maxScrollExtent;
      if (currentOffset >= scrollMax - 100) {
        newActiveIndex = _navigatorHeadings.length - 1;
      }
    }

    if (newActiveIndex != _activeHeadingIndex) {
      setState(() {
        _activeHeadingIndex = newActiveIndex;
      });
    }
  }

  @override
  void dispose() {
    // No need to remove listener - using Riverpod
    _messageScrollController.removeListener(_handleScrollForSlidingAppBar);
    _messageScrollController.removeListener(_handleScrollForHeadingSync);
    _messageScrollController.dispose();
    _titleController.dispose();
    _chatScrollUtils?.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatStorageService.getChats();
      setState(() {
        _chats = chats;
        // Always show welcome suggestions on app load
        // User can either send a message (creates new chat) or open sidebar to select existing chat
        _showWelcomeSuggestionsForEmptyState();
      });
    } catch (e) {
      _logger.logError('[ChatScreen] Error loading chats: $e');
    }
  }

  // Helper method to update both current chat and chats list
  void _updateCurrentChat(Chat updatedChat) {
    _currentChat = updatedChat;
    // Update the chat in the _chats list
    final index = _chats.indexWhere((c) => c.id == updatedChat.id);
    if (index != -1) {
      _chats[index] = updatedChat;
    }

    // Update the chat in Riverpod provider
    ref.read(chatListProvider.notifier).updateChat(updatedChat);

    // Просто вызываем setState без throttling
    setState(() {});
  }

  Future<void> _createNewChat() async {
    // Use Riverpod provider for proper state management
    final newChat = await ref.read(chatListProvider.notifier).createNewChat();

    // Update current chat in Riverpod provider for sidebar sync
    ref.read(currentChatIdProvider.notifier).state = newChat.id;

    setState(() {
      _currentChat = newChat;
    });

    _slidingAppBarKey.currentState?.reset();

    // Show welcome suggestions for new chat
    _showWelcomeSuggestionsForNewChat();
  }

  void _showWelcomeSuggestionsForNewChat() {
    // Use post-frame callback to ensure context is fully updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Generate random welcome questions
      final questions = WelcomeQuestionsData.getRandomQuestions(
        context,
        count: 4,
      );

      setState(() {
        _welcomeSuggestions = questions;
        _showWelcomeSuggestions = true;
        // Hide continuation suggestions if they're showing
        _showSuggestions = false;
        _continuationSuggestions.clear();
      });
    });
  }

  void _showWelcomeSuggestionsForEmptyState() {
    // Generate random welcome questions
    final questions = WelcomeQuestionsData.getRandomQuestions(
      context,
      count: 4,
    );

    setState(() {
      _welcomeSuggestions = questions;
      _showWelcomeSuggestions = true;
      _currentChat = null; // Always reset to no chat selected
      // Hide continuation suggestions
      _showSuggestions = false;
      _continuationSuggestions.clear();
    });
  }

  void _selectChat(String chatId) {
    // Get chat from Riverpod provider
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

    // Update current chat in Riverpod provider for sidebar sync
    ref.read(currentChatIdProvider.notifier).state = chatId;

    _chatScrollUtils?.reset();
    _slidingAppBarKey.currentState?.reset();

    // Check if this chat has messages
    final hasMessages = chat.messages.isNotEmpty;

    setState(() {
      _currentChat = chat;
      // Reset suggestions state - always hide first
      _showWelcomeSuggestions = false;
      _welcomeSuggestions.clear();
      _showSuggestions = false;
      _continuationSuggestions.clear();
    });

    // Show welcome suggestions only for empty chats (new chats)
    if (!hasMessages) {
      _showWelcomeSuggestionsForNewChat();
    }

    Future.microtask(() {
      _chatScrollUtils?.scrollToBottom();
    });
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
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteChat),
        content: Text(localizations.confirmDeleteMessage(chat.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localizations.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // Use Riverpod provider for proper state management
      await ref.read(chatListProvider.notifier).deleteChat(chatId);

      // Clear current chat if it was deleted and update provider
      if (_currentChat?.id == chatId) {
        ref.read(currentChatIdProvider.notifier).state = null;
        setState(() {
          _currentChat = null;
        });
      }
    }
  }

  void _handleSendMessage(MessageData messageData) async {
    // Reset scroll lock before sending new message
    _chatScrollUtils?.resetAutoScrollLock();

    // Hide continuation and welcome suggestions when user sends a new message
    if (_showSuggestions || _showWelcomeSuggestions) {
      setState(() {
        _showSuggestions = false;
        _continuationSuggestions.clear();
        _showWelcomeSuggestions = false;
        _welcomeSuggestions.clear();
      });
    }

    // Handle sidebar based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < ChatScreenConstants.mobileBreakpoint) {
      if (!_isSidebarCollapsed) {
        setState(() {
          _isSidebarCollapsed = true;
        });
      }
    } else {
      // On wide screens, ensure sidebar stays open
      if (_isSidebarCollapsed) {
        setState(() {
          _isSidebarCollapsed = false;
        });
      }
    }

    if (_currentChat == null) {
      await _createNewChat();
      if (_currentChat == null) {
        _logger.logError('[ChatScreen] Failed to create chat');
        return;
      }
    }

    final userMessage = _createUserMessage(
      messageData.text,
      base64Data: messageData.imagePath != null ? messageData.base64Data : null,
      imageType: messageData.imageType,
    );

    // Add user message to chat storage
    await _chatStorageService.addMessageToChat(_currentChat!.id, userMessage);

    // Get updated chat from storage (includes title update if it was a new chat)
    final chatFromStorage = await _chatStorageService.getChat(_currentChat!.id);
    if (chatFromStorage != null) {
      _currentChat = chatFromStorage;
    }

    // Update local state immediately with the message
    final updatedChat = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, userMessage],
      updatedAt: DateTime.now(),
    );
    _updateCurrentChat(updatedChat);

    // Add assistant placeholder (indicators will show)
    final assistantMessage = _createAssistantMessage();

    await _chatStorageService.addMessageToChat(
      _currentChat!.id,
      assistantMessage,
    );

    // Get updated chat from storage to ensure we have latest data
    final chatFromStorage2 = await _chatStorageService.getChat(
      _currentChat!.id,
    );
    if (chatFromStorage2 != null) {
      _currentChat = chatFromStorage2;
    }

    final chatWithAssistant = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, assistantMessage],
      updatedAt: DateTime.now(),
    );
    _updateCurrentChat(chatWithAssistant);

    // CRITICAL: Scroll to indicator AFTER it appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollUtils?.scrollToIndicator();
    });

    // Start streaming
    _sendToAI(messageData.text);
  }

  /// Перегенерировать ответ AI
  ///
  /// Удаляет последнее AI сообщение и генерирует новый ответ на основе последнего user сообщения
  Future<void> _regenerateResponse() async {
    if (_currentChat == null || _currentChat!.messages.isEmpty) {
      _logger.logError('[ChatScreen] Cannot regenerate - no chat or messages');
      return;
    }

    setState(() {
      _showSuggestions = false;
      _continuationSuggestions.clear();
    });

    final lastAIMessageIndex = _currentChat!.messages.lastIndexWhere(
      (m) => m.role == MessageRole.assistant,
    );

    if (lastAIMessageIndex == -1) {
      _logger.logError('[ChatScreen] Cannot regenerate - no AI message found');
      return;
    }

    final lastUserMessageIndex = _currentChat!.messages.lastIndexWhere(
      (m) => m.role == MessageRole.user,
    );

    if (lastUserMessageIndex == -1) {
      _logger.logError(
        '[ChatScreen] Cannot regenerate - no user message found',
      );
      return;
    }

    final lastUserMessage = _currentChat!.messages[lastUserMessageIndex];
    final lastAIMessage = _currentChat!.messages[lastAIMessageIndex];

    // Удаляем AI сообщение из базы данных
    await _chatStorageService.deleteMessageFromChat(
      _currentChat!.id,
      lastAIMessage.id,
    );

    // Обновляем локальный чат без AI сообщения
    final updatedMessages = List<Message>.from(_currentChat!.messages);
    updatedMessages.removeAt(lastAIMessageIndex);

    final updatedChat = _currentChat!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
    _updateCurrentChat(updatedChat);

    // Сбрасываем scroll lock
    _chatScrollUtils?.resetAutoScrollLock();

    // Добавляем новый placeholder для AI
    final newAssistantMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isComplete: false,
      model: _selectedModel,
    );

    await _chatStorageService.addMessageToChat(
      _currentChat!.id,
      newAssistantMessage,
    );

    // Обновляем локальный чат с новым placeholder
    final chatWithNewPlaceholder = _currentChat!.copyWith(
      messages: [...updatedMessages, newAssistantMessage],
      updatedAt: DateTime.now(),
    );
    _updateCurrentChat(chatWithNewPlaceholder);

    // Прокручиваем к индикатору
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollUtils?.scrollToIndicator();
    });

    // Начинаем потоковую передачу с content последнего user сообщения
    _sendToAI(lastUserMessage.content);
  }

  Future<void> _sendToAI(String userMessage) async {
    if (_currentChat == null) {
      _logger.logError('[ChatScreen] No current chat available in _sendToAI');
      return;
    }

    try {
      // Stream response from AI with retry logic
      _sendToAIWithRetry(userMessage);
    } catch (e) {
      _logger.logError('[ChatScreen] Error sending message to AI: $e');

      // Add error message
      final errorMessage = Message(
        role: MessageRole.assistant,
        content: ChatScreenConstants.defaultErrorMessage,
        timestamp: DateTime.now(),
        isComplete: true,
      );

      await _chatStorageService.addMessageToChat(
        _currentChat!.id,
        errorMessage,
      );

      // Get updated chat from storage to ensure we have latest data
      final chatFromStorage = await _chatStorageService.getChat(
        _currentChat!.id,
      );
      if (chatFromStorage != null) {
        _currentChat = chatFromStorage;
      }

      final updatedChat = _currentChat!.copyWith(
        messages: [..._currentChat!.messages, errorMessage],
        updatedAt: DateTime.now(),
      );
      _updateCurrentChat(updatedChat);
    }
  }

  Future<void> _sendToAIWithRetry(
    String userMessage, {
    int retryCount = 0,
  }) async {
    try {
      // Stream response from AI
      _logger.logInfo(
        '[ChatScreen] Starting AI response streaming after message saved',
      );
      await _streamAIResponse();
      _logger.logInfo('[ChatScreen] AI response streaming completed');
    } catch (e) {
      // Check if it's a rate limit error (DioException with 429 status)
      if (e.toString().contains('429') ||
          e.toString().contains('Rate limit') ||
          e.toString().contains('bad response')) {
        if (retryCount < ChatScreenConstants.maxRetryAttempts) {
          final delay = Duration(
            seconds:
                ChatScreenConstants.baseRetryDelaySeconds *
                pow(2, retryCount).toInt(),
          );
          _logger.logWarning(
            '[ChatScreen] Rate limit hit, retrying in ${delay.inSeconds} seconds... (attempt ${retryCount + 1}/${ChatScreenConstants.maxRetryAttempts})',
          );

          // Show retry message to user
          final localizations = AppLocalizations.of(context);
          final retryMessageContent = localizations != null
              ? localizations.rateLimitRetryMessage(delay.inSeconds)
              : 'Rate limit exceeded. Retrying in ${delay.inSeconds} seconds...';
          final retryMessage = Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: MessageRole.assistant,
            content: retryMessageContent,
            timestamp: DateTime.now(),
            isComplete: true,
          );

          await _chatStorageService.addMessageToChat(
            _currentChat!.id,
            retryMessage,
          );

          // Get updated chat from storage to ensure we have latest data
          final chatFromStorage = await _chatStorageService.getChat(
            _currentChat!.id,
          );
          if (chatFromStorage != null) {
            _currentChat = chatFromStorage;
          }

          _updateCurrentChat(
            _currentChat!.copyWith(
              messages: [..._currentChat!.messages, retryMessage],
              updatedAt: DateTime.now(),
            ),
          );

          await Future.delayed(delay);

          // Remove retry message and retry
          final messagesWithoutRetry = _currentChat!.messages
              .where((msg) => msg.content != retryMessage.content)
              .toList();

          _updateCurrentChat(
            _currentChat!.copyWith(
              messages: messagesWithoutRetry,
              updatedAt: DateTime.now(),
            ),
          );

          await _sendToAIWithRetry(userMessage, retryCount: retryCount + 1);
        } else {
          _logger.logError('[ChatScreen] Max retries exceeded for rate limit');

          // Add final error message
          final errorMessage = Message(
            role: MessageRole.assistant,
            content: ChatScreenConstants.rateLimitMessage,
            timestamp: DateTime.now(),
            isComplete: true,
          );

          await _chatStorageService.addMessageToChat(
            _currentChat!.id,
            errorMessage,
          );

          // Get updated chat from storage to ensure we have latest data
          final chatFromStorage = await _chatStorageService.getChat(
            _currentChat!.id,
          );
          if (chatFromStorage != null) {
            _currentChat = chatFromStorage;
          }

          final updatedChat = _currentChat!.copyWith(
            messages: [..._currentChat!.messages, errorMessage],
            updatedAt: DateTime.now(),
          );

          if (mounted) {
            _updateCurrentChat(updatedChat);
          }
        }
      } else {
        // Re-throw non-rate-limit errors
        rethrow;
      }
    }
  }

  /// Convert Message to OpenRouter format with support for images
  Map<String, dynamic> _convertMessageToOpenRouterFormat(Message msg) {
    // If message has an image, use multimodal format
    if (msg.imageData != null && msg.imageType != null) {
      return {
        'role': msg.role.name,
        'content': [
          {'type': 'text', 'text': msg.content},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:${msg.imageType};base64,${msg.imageData}',
            },
          },
        ],
      };
    }

    // Standard text message
    return {'role': msg.role.name, 'content': msg.content};
  }

  /// Sanitizes messages before sending to API:
  /// - Removes assistant messages containing errors
  /// - Truncates overly long messages
  /// - Preserves multimodal structure
  List<Map<String, dynamic>> _sanitizeMessages(
    List<Map<String, dynamic>> messages,
  ) {
    return ChatErrorUtils.sanitizeMessages(messages);
  }

  Future<void> _streamAIResponse() async {
    if (_currentChat == null) {
      _logger.logError('[ChatScreen] No current chat available');
      return;
    }

    final messages = _currentChat!.messages
        .where((m) => !m.isError)
        .map((msg) => _convertMessageToOpenRouterFormat(msg))
        .toList();

    final modelSettingsNotifier = ref.read(modelSettingsProvider.notifier);
    final settings = await modelSettingsNotifier.getSettings(_selectedModel);

    if (settings.systemPrompt != null && messages.isNotEmpty) {
      messages.insert(0, {'role': 'system', 'content': settings.systemPrompt!});
    }

    await _handleStreamingResponse(
      messages: messages,
      isContinuation: false,
      modelId: _selectedModel,
      modelSettings: settings,
    );
  }

  /// Try getChatCompletion with adaptive rollback on 400-like errors
  /// Uses 5% token reduction per attempt before removing messages
  Future<ChatCompletionResponse> _getChatCompletionWithAdaptiveRollback({
    required String model,
    required List<Map<String, dynamic>> messages,
    required ModelSettings modelSettings,
  }) async {
    // Sanitize messages
    var attemptMsgs = _sanitizeMessages(messages);

    // Get model context length
    final modelObj = ref.read(modelProvider.notifier).getModelById(model);
    final modelContextLength =
        modelObj?.contextLength ?? ChatScreenConstants.defaultMaxTokens;

    // Calculate safe initial maxTokens: min(user setting, contextLength)
    int currentMaxTokens = min(modelSettings.maxTokens, modelContextLength);

    // Effective minimum tokens (dynamic based on model size)
    final effectiveMinTokens = min(8000, modelContextLength ~/ 2);

    final reductionFactor = ChatScreenConstants.reductionFactor;
    int tokenReductionAttempts = 0;

    while (true) {
      try {
        final response = await _openRouterService.getChatCompletion(
          model: model,
          messages: attemptMsgs,
          maxTokens: currentMaxTokens,
          temperature: modelSettings.temperature,
          topP: modelSettings.topP,
          frequencyPenalty: modelSettings.frequencyPenalty,
          presencePenalty: modelSettings.presencePenalty,
          includeReasoning: true,
        );

        return response;
      } catch (e) {
        final err = e.toString();
        final isBadRequest =
            err.contains('400') ||
            err.toLowerCase().contains('bad response') ||
            err.toLowerCase().contains('client error') ||
            err.toLowerCase().contains('bad request');

        if (!isBadRequest) rethrow;

        // 1. Try token reduction first
        if (tokenReductionAttempts <
                ChatScreenConstants.maxTokenReductionAttempts &&
            currentMaxTokens > effectiveMinTokens) {
          int newTokens = (currentMaxTokens * reductionFactor).floor();
          if (newTokens < effectiveMinTokens) newTokens = effectiveMinTokens;

          if (newTokens < currentMaxTokens) {
            tokenReductionAttempts++;
            currentMaxTokens = newTokens;
            _logger.logInfo(
              '[AdaptiveRollback] Reduced maxTokens to $currentMaxTokens (attempt $tokenReductionAttempts)',
            );
            continue;
          }
        }

        // 2. Remove oldest non-system message(s)
        if (attemptMsgs.length <= 1) {
          _logger.logError(
            '[AdaptiveRollback] Cannot remove more messages, rethrowing',
          );
          rethrow;
        }

        // Remove one non-system message (prefer removing oldest)
        int removedCount = 0;
        for (int i = 0; i < attemptMsgs.length && removedCount < 2; i++) {
          if (attemptMsgs[i]['role'] != 'system') {
            attemptMsgs.removeAt(i);
            removedCount++;
            i--; // adjust index after removal
          }
        }

        _logger.logInfo(
          '[AdaptiveRollback] Removed $removedCount messages, remaining: ${attemptMsgs.length}',
        );

        // Reset token reduction attempts, but KEEP currentMaxTokens reduced (don't reset to contextLength)
        tokenReductionAttempts = 0;
      }
    }
  }

  // Method to add assistant message from ChatMessages
  Future<void> addAssistantMessage() async {
    if (_currentChat == null) return;

    final assistantMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isComplete: false,
    );

    // Update chat storage and local state immediately
    await _chatStorageService.addMessageToChat(
      _currentChat!.id,
      assistantMessage,
    );

    // Get updated chat from storage to ensure we have latest data
    final chatFromStorage = await _chatStorageService.getChat(_currentChat!.id);
    if (chatFromStorage != null) {
      _currentChat = chatFromStorage;
    }

    final updatedChat = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, assistantMessage],
      updatedAt: DateTime.now(),
    );
    if (mounted) {
      _updateCurrentChat(updatedChat);
    }
  }

  // Method to update assistant message content
  void updateAssistantMessage(String content) {
    if (_currentChat == null) return;

    final messages = _currentChat!.messages;
    if (messages.isNotEmpty && messages.last.role == MessageRole.assistant) {
      final updatedMessage = messages.last.copyWith(content: content);

      _chatStorageService
          .updateMessageInChat(
            _currentChat!.id,
            updatedMessage.id,
            updatedMessage,
          )
          .then((_) {
            final updatedChat = _currentChat!.copyWith(
              messages: [
                ..._currentChat!.messages.take(
                  _currentChat!.messages.length - 1,
                ),
                updatedMessage,
              ],
              updatedAt: DateTime.now(),
            );

            if (mounted) {
              _updateCurrentChat(updatedChat);
            }
          });
    }
  }

  void _handleToggleStreaming(bool isStreaming) {
    // Streaming state managed in _handleStreamingResponse
  }

  Future<void> _stopStreaming() async {
    setState(() {
      _isStreaming = false;
    });

    // Reset streaming controller
    _streamingController.reset();

    if (_currentChat != null && _currentChat!.messages.isNotEmpty) {
      final lastMessage = _currentChat!.messages.last;

      if (!lastMessage.isComplete) {
        final stoppedMessage = lastMessage.copyWith(isComplete: true);

        await _chatStorageService.updateMessageInChat(
          _currentChat!.id,
          stoppedMessage.id,
          stoppedMessage,
        );

        final chatFromStorage = await _chatStorageService.getChat(
          _currentChat!.id,
        );
        if (chatFromStorage != null) {
          _currentChat = chatFromStorage;
        }

        _updateCurrentChat(
          _currentChat!.copyWith(
            messages: [
              ..._currentChat!.messages.take(_currentChat!.messages.length - 1),
              stoppedMessage,
            ],
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  void _refreshChatMessages() async {
    if (_currentChat != null) {
      try {
        final updatedChat = await _chatStorageService.getChat(_currentChat!.id);
        if (updatedChat != null) {
          _updateCurrentChat(updatedChat);

          // Show welcome suggestions if chat is now empty
          if (updatedChat.messages.isEmpty) {
            _showWelcomeSuggestionsForNewChat();
          }
        }
      } catch (e) {
        _logger.logError('[ChatScreen] Error refreshing chat messages: $e');
      }
    }
  }

  /// Обработка редактирования сообщения (просто сохранение)
  Future<void> _handleMessageEdited(String messageId, String newContent) async {
    if (_currentChat == null) {
      _logger.logError('[ChatScreen] Cannot edit message - no current chat');
      return;
    }

    try {
      final messages = _currentChat!.messages;
      final messageIndex = messages.indexWhere((m) => m.id == messageId);

      if (messageIndex != -1) {
        final editedMessage = messages[messageIndex].copyWith(
          content: newContent,
        );
        await _chatStorageService.updateMessageInChat(
          _currentChat!.id,
          messageId,
          editedMessage,
        );

        final updatedMessages = List<Message>.from(messages);
        updatedMessages[messageIndex] = editedMessage;

        final updatedChat = _currentChat!.copyWith(
          messages: updatedMessages,
          updatedAt: DateTime.now(),
        );

        _updateCurrentChat(updatedChat);

        if (mounted) {
          final localizations = AppLocalizations.of(context);
          final successMessage = localizations != null
              ? localizations.messageEditedSuccessfully
              : 'Message edited successfully';
          SnackbarUtils.showSuccessSnackBar(
            context: context,
            message: successMessage,
            icon: Icons.edit,
          );
        }
      } else {
        _logger.logError(
          '[ChatScreen] Message $messageId not found in current chat',
        );
        if (mounted) {
          final localizations = AppLocalizations.of(context);
          final errorMessage = localizations != null
              ? localizations.messageNotFound
              : 'Message not found';
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: errorMessage,
            icon: Icons.error,
          );
        }
      }
    } catch (e) {
      _logger.logError('[ChatScreen] Error handling message edit: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        final errorMessage = localizations != null
            ? localizations.errorEditingMessage
            : 'Error editing message';
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: errorMessage,
          icon: Icons.error,
        );
      }
    }
  }

  /// Обработка редактирования сообщения и отправки (regenerate)
  Future<void> _handleMessageEditAndSend(
    String messageId,
    String newContent,
  ) async {
    if (_currentChat == null) {
      _logger.logError('[ChatScreen] Cannot edit and send - no current chat');
      return;
    }

    try {
      // 1. Обновляем сообщение пользователя
      final messages = _currentChat!.messages;
      final messageIndex = messages.indexWhere((m) => m.id == messageId);

      if (messageIndex == -1) {
        _logger.logError('[ChatScreen] Message $messageId not found');
        return;
      }

      // Обновляем сообщение пользователя
      final editedUserMessage = messages[messageIndex].copyWith(
        content: newContent,
      );
      await _chatStorageService.updateMessageInChat(
        _currentChat!.id,
        messageId,
        editedUserMessage,
      );

      // 2. Удаляем все последующие сообщения (ответы AI и т.д.)
      final messagesAfterEdit = messages.sublist(0, messageIndex + 1);

      // Удаляем сообщения из storage, начиная с последнего
      for (int i = messages.length - 1; i > messageIndex; i--) {
        await _chatStorageService.deleteMessageFromChat(
          _currentChat!.id,
          messages[i].id,
        );
      }

      // 3. Создаём новый chat с обновлённым сообщением пользователя и без последующих сообщений
      final updatedChat = _currentChat!.copyWith(
        messages: messagesAfterEdit,
        updatedAt: DateTime.now(),
      );

      _updateCurrentChat(updatedChat);

      // 4. Добавляем placeholder для AI ответа
      final assistantMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isComplete: false,
        model: _selectedModel,
      );

      await _chatStorageService.addMessageToChat(
        _currentChat!.id,
        assistantMessage,
      );

      // Обновляем локальный чат с новым placeholder
      final chatWithAssistant = updatedChat.copyWith(
        messages: [...messagesAfterEdit, assistantMessage],
        updatedAt: DateTime.now(),
      );
      _updateCurrentChat(chatWithAssistant);

      // 5. Прокручиваем к индикатору
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatScrollUtils?.scrollToIndicator();
      });

      // 6. Отправляем запрос к AI с обновлённым контентом
      _sendToAI(newContent);

      // Показываем уведомление об успешном редактировании и отправке
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        final successMessage =
            localizations?.messageEditedAndResponseRegenerated ??
            'Message edited and response regenerated';
        SnackbarUtils.showSuccessSnackBar(
          context: context,
          message: successMessage,
          icon: Icons.refresh,
        );
      }
    } catch (e) {
      _logger.logError('[ChatScreen] Error in edit and send: $e');
      // Показываем ошибку пользователю
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        final errorMessage =
            localizations?.errorEditAndSendMessage ??
            'Error editing and sending message';
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: errorMessage,
          icon: Icons.error,
        );
      }
    }
  }

  // Navigator methods
  void _onHeadingsUpdated(List<MarkdownHeadingInfoWithKey> headings) {
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _navigatorHeadings = headings;
        });
      }
    });
  }

  void _toggleNavigator() {
    setState(() {
      _isNavigatorVisible = !_isNavigatorVisible;
    });
  }

  void _onHeadingTap(String headingText, String messageId, int level) {
    // Find the heading
    final heading = _navigatorHeadings.firstWhere(
      (h) =>
          h.text == headingText && h.messageId == messageId && h.level == level,
      orElse: () {
        return _navigatorHeadings.firstWhere(
          (h) => h.text == headingText,
          orElse: () {
            _logger.logError('[HeadingTap] Heading not found: $headingText');
            throw Exception('Heading not found: $headingText');
          },
        );
      },
    );

    // Update active heading index
    final headingIndex = _navigatorHeadings.indexOf(heading);
    if (headingIndex >= 0) {
      setState(() {
        _activeHeadingIndex = headingIndex;
      });
    }

    // Close the navigator
    setState(() {
      _isNavigatorVisible = false;
    });

    // Use approximate scroll since ListView doesn't build all items
    Future.delayed(const Duration(milliseconds: 200), () async {
      if (!mounted) return;
      await _scrollToHeadingByMessage(messageId, level, heading.text);
    });
  }

  Future<void> _scrollToHeadingByMessage(
    String messageId,
    int level,
    String headingText,
  ) async {
    if (_currentChat == null || !_messageScrollController.hasClients) return;

    // Find message and calculate heading line index from content
    int messageIndex = -1;
    int headingLineIndex = 0;

    for (int i = 0; i < _currentChat!.messages.length; i++) {
      if (_currentChat!.messages[i].id == messageId) {
        messageIndex = i;
        // Find which line the heading is on within the message content
        final content = _currentChat!.messages[i].content;
        final lines = content.split('\n');
        final headingPrefix = '${'#' * level} ';

        for (int j = 0; j < lines.length; j++) {
          if (lines[j].startsWith(headingPrefix) &&
              lines[j].contains(headingText)) {
            headingLineIndex = j;
            _logger.logInfo(
              '[HeadingTap] Found heading at line $j: ${lines[j]}',
            );
            break;
          }
        }
        break;
      }
    }

    if (messageIndex == -1) return;

    // Calculate position - position at TOP of viewport
    const double appBarHeight = 80.0; // More space for appbar
    const double baseMessageHeight = 180.0;
    const double lineHeight = 24.0;
    final headingExtraSpace = (level - 1) * 18.0;
    final lineOffset = headingLineIndex * lineHeight;

    // Position heading at top of viewport (subtract more)
    final targetOffset =
        (messageIndex * baseMessageHeight +
                lineOffset +
                headingExtraSpace -
                appBarHeight)
            .clamp(0.0, _messageScrollController.position.maxScrollExtent);

    _logger.logInfo(
      '[HeadingTap] Scroll to msgIdx=$messageIndex, lineIdx=$headingLineIndex, offset=$targetOffset',
    );

    await _messageScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // Method to continue AI response
  void _continueAIResponse(String lastMessageId) async {
    if (_currentChat == null) {
      _logger.logError('[ChatScreen] No current chat available');
      return;
    }

    final lastMessage = _currentChat!.messages.lastWhere(
      (msg) => msg.role == MessageRole.assistant && msg.id == lastMessageId,
      orElse: () => _currentChat!.messages.first,
    );

    if (lastMessage.content.isEmpty) {
      _logger.logError('[ChatScreen] Last message has no content to continue');
      return;
    }

    // Add a placeholder for the continued response
    final continuationMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isComplete: false,
      model: _selectedModel,
    );

    // Update chat storage and local state immediately
    await _chatStorageService.addMessageToChat(
      _currentChat!.id,
      continuationMessage,
    );

    // Get updated chat from storage to ensure we have latest data
    final chatFromStorage = await _chatStorageService.getChat(_currentChat!.id);
    if (chatFromStorage != null) {
      _currentChat = chatFromStorage;
    }

    final updatedChat = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, continuationMessage],
      updatedAt: DateTime.now(),
    );

    _updateCurrentChat(updatedChat);

    // CRITICAL: Scroll to indicator AFTER it appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollUtils?.scrollToIndicator();
    });

    // Send continuation request to AI
    await _streamContinuationResponse(lastMessage.content);
  }

  Future<void> _streamContinuationResponse(String previousContent) async {
    final continuationPrompt = [
      {
        'role': 'user',
        'content':
            'Please continue your previous response. Do not repeat what you already said.',
      },
      {'role': 'assistant', 'content': previousContent},
      {'role': 'user', 'content': 'Continue from where you left off.'},
    ];

    final modelSettingsNotifier = ref.read(modelSettingsProvider.notifier);
    final settings = await modelSettingsNotifier.getSettings(_selectedModel);

    if (settings.systemPrompt != null) {
      continuationPrompt.insert(0, {
        'role': 'system',
        'content': settings.systemPrompt!,
      });
    }

    await _handleStreamingResponse(
      messages: continuationPrompt,
      isContinuation: true,
      modelId: _selectedModel,
      modelSettings: settings,
    );
  }

  /// Shared method to handle streaming responses (both regular and continuation)
  ///
  /// CRITICAL: This method implements proper Flutter streaming architecture:
  /// 1. Each chunk creates NEW Message object
  /// 2. Each chunk creates NEW List
  /// 3. setState() is called on every chunk
  /// 4. No mutation of existing objects
  Future<void> _handleStreamingResponse({
    required List<Map<String, dynamic>> messages,
    required bool isContinuation,
    required String modelId,
    required ModelSettings modelSettings,
  }) async {
    // Calculate safe initial maxTokens: min(user setting, contextLength)
    final modelObj = ref.read(modelProvider.notifier).getModelById(modelId);
    final modelContextLength =
        modelObj?.contextLength ?? ChatScreenConstants.defaultMaxTokens;

    int currentMaxTokens = min(modelSettings.maxTokens, modelContextLength);

    // Effective minimum tokens (dynamic based on model size)
    final effectiveMinTokens = min(8000, modelContextLength ~/ 2);

    final reductionFactor = ChatScreenConstants.reductionFactor;
    int tokenReductionAttempts = 0;

    // Set streaming state
    setState(() {
      _isStreaming = true;
    });

    // Start streaming controller for selective UI updates
    _streamingController.startStreaming(_currentChat?.id ?? '');

    // Local accumulators for this stream (not state variables)
    String accumulatedContent = '';
    String accumulatedReasoning = '';

    // Create a local flag that can be captured by closures
    bool isStreamingLocal = true;

    // THROTTLING: Timer to batch UI updates (every 50ms instead of every chunk)
    DateTime lastUpdateTime = DateTime.now();
    const updateIntervalMs =
        50; // 20 FPS for UI updates - sufficient for smooth feel

    // Pending update flags
    bool pendingContentUpdate = false;
    bool pendingReasoningUpdate = false;

    // Helper to throttle UI updates - now uses streaming controller for selective rebuilds
    void throttleUpdate() {
      final now = DateTime.now();
      final elapsed = now.difference(lastUpdateTime).inMilliseconds;

      if (elapsed >= updateIntervalMs) {
        // Time to update UI via streaming controller (selective rebuild)
        if (mounted &&
            _currentChat != null &&
            _currentChat!.messages.isNotEmpty) {
          // Update streaming controller instead of full setState
          _streamingController.updateContent(
            accumulatedContent,
            reasoning: accumulatedReasoning.isNotEmpty
                ? accumulatedReasoning
                : null,
          );

          // Also update local state less frequently for other UI elements
          // but skip the full _updateCurrentChat to avoid rebuilding entire screen
          lastUpdateTime = now;
        }
        pendingContentUpdate = false;
        pendingReasoningUpdate = false;
      } else {
        // Schedule an update for later
        pendingContentUpdate = true;
        pendingReasoningUpdate = true;
      }
    }

    // Timer to ensure pending updates get applied
    Future<void> flushPendingUpdates() async {
      while (pendingContentUpdate || pendingReasoningUpdate) {
        await Future.delayed(const Duration(milliseconds: 10));
        if (pendingContentUpdate || pendingReasoningUpdate) {
          if (mounted &&
              _currentChat != null &&
              _currentChat!.messages.isNotEmpty) {
            // Update streaming controller instead of full setState
            _streamingController.updateContent(
              accumulatedContent,
              reasoning: accumulatedReasoning.isNotEmpty
                  ? accumulatedReasoning
                  : null,
            );
          }
          pendingContentUpdate = false;
          pendingReasoningUpdate = false;
        }
      }
    }

    // Sanitize messages
    var attemptMsgs = _sanitizeMessages(messages);

    while (true) {
      try {
        await _openRouterService.streamChatCompletion(
          messages: attemptMsgs,
          model: modelId,
          maxTokens: currentMaxTokens,
          temperature: modelSettings.temperature,
          topP: modelSettings.topP,
          frequencyPenalty: modelSettings.frequencyPenalty,
          presencePenalty: modelSettings.presencePenalty,
          includeReasoning: true,
          onChunk: (content) {
            if (!isStreamingLocal || !_isStreaming || content.isEmpty) {
              return;
            }

            accumulatedContent += content;
            throttleUpdate();
          },
          onReasoning: (reasoning) {
            if (!isStreamingLocal || !_isStreaming || reasoning.isEmpty) {
              return;
            }

            accumulatedReasoning += reasoning;
            throttleUpdate();
          },
          onCompletion: (fullContent) async {
            if (!isStreamingLocal || !_isStreaming) {
              return;
            }

            // First, flush any pending updates
            await flushPendingUpdates();

            if (mounted &&
                _currentChat != null &&
                _currentChat!.messages.isNotEmpty) {
              final lastMessage = _currentChat!.messages.last;
              final completedMessage = lastMessage.copyWith(
                content: accumulatedContent,
                reasoning: accumulatedReasoning,
                isComplete: true,
              );
              final newMessages = List<Message>.from(_currentChat!.messages);
              newMessages[newMessages.length - 1] = completedMessage;
              final newChat = _currentChat!.copyWith(
                messages: newMessages,
                updatedAt: DateTime.now(),
              );
              _updateCurrentChat(newChat);

              setState(() {
                _isStreaming = false;
              });

              // Reset streaming controller after completion
              _streamingController.stopStreaming();

              _chatStorageService.updateMessageInChat(
                newChat.id,
                completedMessage.id,
                completedMessage,
              );

              if (!isContinuation) {
                _showContinuationSuggestions(completedMessage);
              }
            }
          },
        );

        break; // success
      } catch (e) {
        final err = e.toString();
        final isBadRequest =
            err.contains('400') ||
            err.toLowerCase().contains('bad response') ||
            err.toLowerCase().contains('client error') ||
            err.toLowerCase().contains('bad request');

        if (!isBadRequest) {
          setState(() {
            _isStreaming = false;
          });
          _streamingController.reset();
          await _handleStreamingError(e, isContinuation);
          break;
        }

        // 1. Token reduction
        if (tokenReductionAttempts <
                ChatScreenConstants.maxTokenReductionAttempts &&
            currentMaxTokens > effectiveMinTokens) {
          int newTokens = (currentMaxTokens * reductionFactor).floor();
          if (newTokens < effectiveMinTokens) newTokens = effectiveMinTokens;

          if (newTokens < currentMaxTokens) {
            tokenReductionAttempts++;
            currentMaxTokens = newTokens;
            _logger.logInfo(
              '[AdaptiveRollback] Reduced maxTokens to $currentMaxTokens (attempt $tokenReductionAttempts)',
            );
            continue;
          }
        }

        // 2. Remove oldest non-system messages
        if (attemptMsgs.length <= 1) {
          setState(() {
            _isStreaming = false;
          });
          _streamingController.reset();
          await _handleStreamingError(e, isContinuation);
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

        _logger.logInfo(
          '[AdaptiveRollback] Removed $removedCount messages, remaining: ${attemptMsgs.length}',
        );

        // Reset token reduction attempts, but KEEP currentMaxTokens reduced
        tokenReductionAttempts = 0;
      }
    }
  }

  /// Handle streaming errors with proper error message display
  Future<void> _handleStreamingError(Object error, bool isContinuation) async {
    final errorMessage = _formatErrorMessage(error);

    // Update the existing assistant message with error content
    if (_currentChat != null && _currentChat!.messages.isNotEmpty) {
      final lastMessage = _currentChat!.messages.last;
      if (lastMessage.role == MessageRole.assistant) {
        // Update existing message with error content
        final errorResponseMessage = lastMessage.copyWith(
          content: errorMessage,
          isComplete: true,
          isError: true,
        );

        await _chatStorageService.updateMessageInChat(
          _currentChat!.id,
          errorResponseMessage.id,
          errorResponseMessage,
        );

        // Get updated chat from storage to ensure we have latest data
        final chatFromStorage = await _chatStorageService.getChat(
          _currentChat!.id,
        );
        if (chatFromStorage != null) {
          _currentChat = chatFromStorage;
        }

        final updatedChat = _currentChat!.copyWith(
          messages: [
            ..._currentChat!.messages.take(_currentChat!.messages.length - 1),
            errorResponseMessage,
          ],
          updatedAt: DateTime.now(),
        );

        if (mounted) {
          _updateCurrentChat(updatedChat);
        }
      } else {
        // If last message is not assistant, add new error message
        final errorResponseMessage = Message(
          role: MessageRole.assistant,
          content: errorMessage,
          timestamp: DateTime.now(),
          isComplete: true,
          isError: true,
        );

        await _chatStorageService.addMessageToChat(
          _currentChat!.id,
          errorResponseMessage,
        );

        // Get updated chat from storage to ensure we have latest data
        final chatFromStorage = await _chatStorageService.getChat(
          _currentChat!.id,
        );
        if (chatFromStorage != null) {
          _currentChat = chatFromStorage;
        }

        final updatedChat = _currentChat!.copyWith(
          messages: [..._currentChat!.messages, errorResponseMessage],
          updatedAt: DateTime.now(),
        );

        if (mounted) {
          _updateCurrentChat(updatedChat);
        }
      }
    }
  }

  void _updateSelectedModel(String modelId, OpenRouterModel? modelObject) {
    if (!mounted) return;

    OpenRouterModel? finalModelObject = modelObject;
    if (finalModelObject == null) {
      final modelState = ref.read(modelProvider);
      if (modelState.modelsLoaded) {
        finalModelObject = ref
            .read(modelProvider.notifier)
            .getModelById(modelId);
      }
    }

    // Update both local state AND Riverpod provider for proper synchronization
    ref.read(modelProvider.notifier).setSelectedModel(modelId);

    setState(() {
      _selectedModel = modelId;
      _selectedModelObject = finalModelObject;
    });
  }

  // Show model selection screen
  void _showModelSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModelsScreen(
          onModelSelected: (String modelId, OpenRouterModel? modelObject) {
            _updateSelectedModel(modelId, modelObject);
          },
          currentModel: _selectedModel,
        ),
      ),
    );
  }

  bool _hasHeadings() {
    return _navigatorHeadings.isNotEmpty;
  }

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
      model: model ?? _selectedModel,
    );
  }

  Widget _buildSidebarDrawer({
    required double width,
    bool isCollapsed = false,
  }) {
    return Drawer(
      width: width,
      child: Sidebar(
        width: width,
        isCollapsed: isCollapsed,
        onToggleSidebar: () {
          Navigator.pop(context);
        },
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

  Widget _buildChatMessages({bool wrapWithGesture = false}) {
    final chatMessages = ChatMessages(
      key: _chatMessagesKey,
      openRouterService: _openRouterService,
      chatStorageService: _chatStorageService,
      chat: _currentChat,
      selectedModel: _selectedModel,
      onSendMessage: _handleSendMessage,
      onMessageDeleted: _refreshChatMessages,
      onMessageEdited: _handleMessageEdited,
      onMessageEditAndSend: _handleMessageEditAndSend,
      onContinueResponse: (messageId) => _continueAIResponse(messageId),
      onRegenerateResponse: _regenerateResponse,
      scrollController: _messageScrollController,
      continuationSuggestions: _continuationSuggestions,
      showSuggestions: _showSuggestions,
      isSuggestionsLoading: _isSuggestionsLoading,
      onSuggestionsClose: () {
        setState(() {
          _showSuggestions = false;
          _continuationSuggestions.clear();
        });
      },
      onSuggestionsRefresh: () {
        if (_currentChat != null && _currentChat!.messages.isNotEmpty) {
          _showContinuationSuggestions(_currentChat!.messages.last);
        }
      },
      welcomeSuggestions: _welcomeSuggestions,
      showWelcomeSuggestions: _showWelcomeSuggestions,
      onWelcomeSuggestionsClose: () {
        setState(() {
          _showWelcomeSuggestions = false;
          _welcomeSuggestions.clear();
        });
      },
      onHeadingsUpdated: _onHeadingsUpdated,
      onToggleNavigator: _toggleNavigator,
    );

    if (wrapWithGesture) {
      return GestureDetector(
        onDoubleTap: () {
          if (_hasHeadings()) {
            _toggleNavigator();
          }
        },
        child: chatMessages,
      );
    }

    return chatMessages;
  }

  @override
  Widget build(BuildContext context) {
    // Watch model changes for app bar - with null safety
    String? watchedModelId;
    OpenRouterModel? watchedModelObject;

    try {
      watchedModelId = ref.watch(
        modelProvider.select((s) => s.selectedModelId),
      );
      watchedModelObject = ref.watch(
        modelProvider.select((s) => s.selectedModelObject),
      );

      // Update local state if changed
      if (watchedModelId != null && watchedModelId != _selectedModel) {
        _selectedModel = watchedModelId;
      }
      if (watchedModelObject != null &&
          watchedModelObject != _selectedModelObject) {
        _selectedModelObject = watchedModelObject;
      }
    } catch (_) {
      // Provider not initialized yet, use defaults
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // Simple mobile/desktop detection
    final isMobile = screenWidth < 800;

    // Create ChatInput once to preserve state across layout changes
    final chatInput = ChatInput(
      key: const ValueKey('chat_input_widget'),
      onSendMessage: _handleSendMessage,
      onToggleStreaming: _handleToggleStreaming,
      onStopStreaming: _stopStreaming,
      isStreaming: _isStreaming,
      focusNode: _chatInputFocusNode,
      onSpeechStateChanged: (state, message) {
        if (mounted) {
          setState(() {
            _speechUiState = state;
            _speechStatusMessage = message;
          });
        }
      },
      checkModelSupportsImages: (modelId) {
        // Use ModelProvider's synchronous check for currently selected model
        return ref.read(modelProvider.notifier).modelSupportsImagesSelected();
      },
    );

    // Build the base layout
    Widget baseLayout;
    if (isMobile) {
      baseLayout = _buildMobileLayout(context, chatInput);
    } else {
      baseLayout = _buildDesktopLayout(context, chatInput);
    }

    // Wrap with navigator overlay if needed
    if (_navigatorHeadings.isNotEmpty) {
      return Stack(
        children: [
          baseLayout,
          // Navigator overlay with swipe to close
          MarkdownNavigatorSidebar(
            headings: _navigatorHeadings,
            activeHeadingIndex: _activeHeadingIndex,
            isOpen: _isNavigatorVisible,
            onClose: _toggleNavigator,
            onHeadingTap: _onHeadingTap,
          ),
        ],
      );
    }

    return baseLayout;
  }

  Widget _buildMobileLayout(BuildContext context, Widget chatInput) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSidebarDrawer(width: ChatScreenConstants.sidebarWidth),
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          // Swipe from left edge to open drawer
          if (details.globalPosition.dx < 50) {
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        child: Column(
          children: [
            // Sliding App Bar (only on mobile)
            SlidingAppBar(
              key: _slidingAppBarKey,
              selectedModel: _selectedModel,
              selectedModelObject: _selectedModelObject,
              onMenuPressed: () {
                // Open drawer using scaffold key
                _scaffoldKey.currentState?.openDrawer();
              },
              onModelSelected: () {
                // Navigate to models screen
                _showModelSelection();
              },
              hasHeadings: _hasHeadings,
              onNavigatorPressed: () {
                // Toggle navigator
                _toggleNavigator();
              },
              isMobile: true,
            ),

            // Chat content area with width control
            Expanded(
              child: _buildChatContentWrapper(
                context,
                child: Column(
                  children: [
                    // Chat Messages
                    Expanded(child: _buildChatMessages(wrapWithGesture: true)),

                    // Input Area
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

  Widget _buildDesktopLayout(BuildContext context, Widget chatInput) {
    return Scaffold(
      appBar: ChatAppBar(
        selectedModel: _selectedModel,
        selectedModelObject: _selectedModelObject,
        hasHeadings: _hasHeadings,
        onToggleNavigator: _toggleNavigator,
        onModelSelected: _updateSelectedModel,
      ),
      drawer: _buildSidebarDrawer(width: ChatScreenConstants.sidebarWidth),
      body: Column(
        children: [
          // Chat content area with width control
          Expanded(
            child: _buildChatContentWrapper(
              context,
              child: Column(
                children: [
                  // Chat Messages
                  Expanded(child: _buildChatMessages()),

                  // Input Area
                  chatInput,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget to wrap chat content with responsive width
  Widget _buildChatContentWrapper(
    BuildContext context, {
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Wrap with swipe gesture to open navigator (only if headings exist and navigator is closed)
    Widget content = GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_hasHeadings() && !_isNavigatorVisible) {
          // Swipe left from right edge to open
          if (details.primaryDelta! < -10 &&
              details.globalPosition.dx > screenWidth - 30) {
            _toggleNavigator();
          }
        }
      },
      child: Stack(
        children: [
          child,
          // Speech overlay
          if (_speechUiState != SpeechUiState.idle)
            SpeechOverlayWidget(
              state: _speechUiState,
              message: _speechStatusMessage,
            ),
        ],
      ),
    );

    // Only apply width constraints on desktop (wide screens)
    if (screenWidth >= ChatScreenConstants.mobileBreakpoint) {
      // If wide screen mode is enabled, use full width
      if (ref.watch(themeProvider).wideScreenMode) {
        return content;
      } else {
        // Use 75% width by default on desktop
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            width: screenWidth * 0.65,
            child: content,
          ),
        );
      }
    } else {
      // On mobile, always use full width
      return content;
    }
  }

  // Method to show continuation suggestions for a message
  Future<void> _showContinuationSuggestions(Message message) async {
    if (_isSuggestionsLoading) return;

    setState(() {
      _isSuggestionsLoading = true;
    });

    try {
      final language = _detectLanguage(message.content);
      final suggestions = await _getContinuationSuggestions(
        message.content,
        language,
      );

      if (suggestions.isNotEmpty) {
        setState(() {
          _continuationSuggestions = suggestions;
          _showSuggestions = true;
        });
      }
    } catch (e) {
      // Extract and format the actual server response
      String errorMessage = _formatErrorMessage(e);

      // Create an error message to show in the chat
      final errorMessageObject = Message(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.assistant,
        content: errorMessage,
        timestamp: DateTime.now(),
        isComplete: true,
        isError: true,
      );

      // Add the error message to the chat storage
      if (_currentChat != null) {
        await _chatStorageService.addMessageToChat(
          _currentChat!.id,
          errorMessageObject,
        );

        // Update the current chat state
        final updatedChat = _currentChat!.copyWith(
          messages: [..._currentChat!.messages, errorMessageObject],
          updatedAt: DateTime.now(),
        );

        _updateCurrentChat(updatedChat);
      }

      // Show a snackbar to notify the user
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        String displayMessage;
        if (localizations != null) {
          final errorShort = errorMessage.length > 100
              ? '${errorMessage.substring(0, 100)}...'
              : errorMessage;
          displayMessage = localizations.generatingSuggestionsFailed(
            errorShort,
          );
        } else {
          displayMessage =
              'Failed to generate suggestions: ${errorMessage.length > 100 ? '${errorMessage.substring(0, 100)}...' : errorMessage}';
        }

        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: displayMessage,
          icon: Icons.error,
        );
      }
    } finally {
      setState(() {
        _isSuggestionsLoading = false;
      });
    }
  }

  // Method to detect language from text
  String _detectLanguage(String text) {
    return ChatLanguageUtils.detectLanguage(text);
  }

  String _getLocalizedPrompt(
    AppLocalizations localizations,
    String language,
    bool isSystemPrompt,
  ) {
    const supportedLanguages = {'ru', 'zh', 'ja', 'ar', 'uk'};
    if (!supportedLanguages.contains(language)) {
      language = 'en';
    }
    return isSystemPrompt
        ? localizations.systemPromptSuggestion
        : localizations.userPromptSuggestion;
  }

  Future<List<String>> _getContinuationSuggestions(
    String lastMessageContent,
    String language,
  ) async {
    try {
      final localizations = AppLocalizations.of(context);
      final systemPrompt = localizations != null
          ? _getLocalizedPrompt(localizations, language, true)
          : 'You are a helpful assistant. Continue the conversation by providing 3 specific and logical continuations of the last message. Respond in the same language as the user.';
      final userPrompt = localizations != null
          ? _getLocalizedPrompt(localizations, language, false)
          : 'Provide 3 specific and logical continuations for this message. Answer only with the list, no additional text.';

      final suggestionPrompt = [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'assistant', 'content': lastMessageContent},
        {'role': 'user', 'content': userPrompt},
      ];

      final modelSettingsNotifier = ref.read(modelSettingsProvider.notifier);
      final settings = await modelSettingsNotifier.getSettings(_selectedModel);

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

      final response = await _getChatCompletionWithAdaptiveRollback(
        model: _selectedModel,
        messages: suggestionPrompt,
        modelSettings: suggestionSettings,
      );

      final suggestionsText = response.content;
      final suggestions = parseSuggestions(suggestionsText);

      return suggestions;
    } catch (e) {
      // Return default suggestions from localization
      final localizations = AppLocalizations.of(context);
      return [
        localizations?.defaultSuggestion1 ?? 'Tell me more about this topic',
        localizations?.defaultSuggestion2 ?? 'Can you provide examples?',
        localizations?.defaultSuggestion3 ?? 'What are the alternatives?',
        localizations?.defaultSuggestion4 ?? 'How does this apply in practice?',
      ];
    }
  }

  // Method to extract and format error message from DioException or other errors
  String _formatErrorMessage(Object error) {
    return ChatErrorUtils.formatError(error);
  }
}
