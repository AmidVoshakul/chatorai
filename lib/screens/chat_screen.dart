// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatorai/providers/theme_provider.dart';
import 'package:chatorai/providers/model_settings_provider.dart';
import 'package:chatorai/services/chat_storage_service.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/models/model_settings.dart';
import 'package:chatorai/widgets/sidebar/sidebar.dart';
import 'package:chatorai/widgets/chat/chat_input.dart';
import 'package:chatorai/widgets/chat/chat_messages.dart';
import 'package:chatorai/widgets/chat/markdown_navigator_sidebar.dart';
import 'package:chatorai/widgets/chat/welcome_questions_data.dart';
import 'package:chatorai/widgets/chat/sliding_app_bar.dart';
import 'package:chatorai/widgets/chat/speech_overlay.dart';
import 'package:chatorai/services/speech_to_text_service.dart';
import 'package:chatorai/screens/models_screen.dart';
import 'package:chatorai/utils/chat_scroll_utils.dart';
import 'package:chatorai/utils/snackbar_utils.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/utils/markdown_parser_with_keys.dart';

// Initialize logger for this screen
final _logger = LogTags.chatScreen;

/// Centralized constants for ChatScreen configuration
class ChatScreenConstants {
  // UI Constants
  static const double sidebarWidth = 280.0;
  static const double sidebarCollapsedWidth = 40.0;
  static const int mobileBreakpoint = 800;
  
  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const int baseRetryDelaySeconds = 2;
  
  // Token Management
  static const int defaultMaxTokens = 32000;
  
  // Error Handling
  static const int maxErrorLength = 500;
  static const String defaultErrorMessage = 'Sorry, I encountered an error while processing your request. Please try again.';
  static const String rateLimitMessage = 'Sorry, the service is currently at capacity. Please try again in a few minutes.';
  
  // Scroll & Animation
  static const Duration scrollAnimationDuration = Duration(milliseconds: 300);
  static const Duration sidebarUpdateDelay = Duration(milliseconds: 10);
  static const Duration modelLoadWaitTime = Duration(milliseconds: 500);
  
  // Model Defaults
  static const String defaultModelId = 'nvidia/nemotron-3-nano-30b-a3b:free';
  
  // Continuation Suggestions (moved to ContinuationSuggestions widget constants)
}

class ChatScreen extends StatefulWidget {
  final String? initialModel;
  // Optional overrides for testing
  final OpenRouterClient? openRouterService;
  final ThemeProvider? themeProvider;

  const ChatScreen({
    super.key,
    this.initialModel,
    this.openRouterService,
    this.themeProvider,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late ChatStorageService _chatStorageService;
  late OpenRouterClient _openRouterService;
  late ThemeProvider _themeProvider;
  
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
  final GlobalKey<ChatMessagesState> _chatMessagesKey = GlobalKey<ChatMessagesState>();
  bool _isNavigatorVisible = false;
  List<MarkdownHeadingInfoWithKey> _navigatorHeadings = [];
  
  // Sliding AppBar state
  final GlobalKey<SlidingAppBarState> _slidingAppBarKey = GlobalKey<SlidingAppBarState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Speech overlay state
  SpeechUiState _speechUiState = SpeechUiState.idle;
  String _speechStatusMessage = '';
  
  // Streaming optimization - throttle updates
  DateTime _lastUpdateTime = DateTime.now();
  static const Duration _updateThrottle = Duration(milliseconds: 50); // 20 FPS max
  
  @override
  void initState() {
    super.initState();
    _logger.logInfo('[ChatScreen] Initializing ChatScreen services...');
    _chatStorageService = ChatStorageService();
    _logger.logInfo('[ChatScreen] ChatStorageService initialized');
    _openRouterService = widget.openRouterService ?? OpenRouterService();
    _logger.logInfo('[ChatScreen] OpenRouterService initialized (injected: ${widget.openRouterService != null})');
    _themeProvider = widget.themeProvider ?? Provider.of<ThemeProvider>(context, listen: false);
    _logger.logInfo('[ChatScreen] ThemeProvider accessed (injected: ${widget.themeProvider != null})');
    
    // Initialize scroll controller
    _messageScrollController = ScrollController();
    _logger.logInfo('[ChatScreen] ScrollController initialized');
    
    // Add scroll listener for sliding app bar
    _messageScrollController.addListener(_handleScrollForSlidingAppBar);
    _logger.logInfo('[ChatScreen] SlidingAppBar scroll listener added');
    
    // Ensure sliding app bar is visible on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _slidingAppBarKey.currentState != null) {
        _slidingAppBarKey.currentState?.show();
        _logger.logInfo('[ChatScreen] SlidingAppBar shown on startup');
      }
    });
    
    // Initialize scroll utilities immediately (no need to wait for frame)
    _chatScrollUtils = ChatScrollUtils(
      scrollController: _messageScrollController,
      animationDuration: ChatScreenConstants.scrollAnimationDuration,
      animationCurve: Curves.easeOut,
    );
    _chatScrollUtils!.initialize();
    _logger.logInfo('[ChatScreen] ChatScrollUtils initialized');

    // Initialize model selection from ThemeProvider
    // Get the saved model ID immediately from ThemeProvider
    _selectedModel = _themeProvider.selectedModelId;
    _selectedModelObject = _themeProvider.selectedModelObject;
    
    _logger.logInfo('[ChatScreen] Initial model from ThemeProvider: $_selectedModel, hasObject: ${_selectedModelObject != null}, modelsLoaded: ${_themeProvider.modelsLoaded}, settingsLoaded: ${_themeProvider.settingsLoaded}');

    // Listen to ThemeProvider changes to update loading state
    _themeProvider.addListener(_onThemeProviderChange);

    // If models are already loaded and we have the object, we're done
    // If not, _onThemeProviderChange will update us when models finish loading
    if (!_themeProvider.modelsLoaded) {
      _logger.logInfo('[ChatScreen] Models still loading, will update when ready');
    }

    // Load chats after a short delay to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChats();
    });
  }

  // Listen for ThemeProvider changes to update loading state
  void _onThemeProviderChange() {
    // Update the loading state when models finish loading
    if (mounted) {
      final themeModelId = _themeProvider.selectedModelId;
      final themeModelObject = _themeProvider.selectedModelObject;
      
      // Always update from ThemeProvider to ensure we have the latest
      // This handles both settings loading and model loading
      if (_selectedModel != themeModelId || _selectedModelObject != themeModelObject) {
        _logger.logInfo('[ChatScreen] _onThemeProviderChange: Updating model to $themeModelId');
        
        _selectedModel = themeModelId;
        _selectedModelObject = themeModelObject;
        
        if (_selectedModelObject != null && _selectedModel.isNotEmpty) {
          _logger.logInfo('[ChatScreen] Updated to: ${_selectedModelObject!.name} with context: ${_selectedModelObject!.contextLength}');
        }
      }
      
      setState(() {
        // This will trigger a rebuild and update the loading indicator
      });
    }
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

  @override
  void dispose() {
    // Remove listener to prevent memory leaks
    _themeProvider.removeListener(_onThemeProviderChange);
    _messageScrollController.removeListener(_handleScrollForSlidingAppBar);
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
  // OPTIMIZED: Throttled updates during streaming to prevent lag
  void _updateCurrentChat(Chat updatedChat) {
    _currentChat = updatedChat;
    // Update the chat in the _chats list
    final index = _chats.indexWhere((c) => c.id == updatedChat.id);
    if (index != -1) {
      _chats[index] = updatedChat;
    }
    
    // Throttle updates during streaming (max 20 FPS)
    final now = DateTime.now();
    if (!_isStreaming || now.difference(_lastUpdateTime) >= _updateThrottle) {
      _lastUpdateTime = now;
      setState(() {});
    }
  }

  Future<void> _createNewChat() async {
    _logger.logInfo('[ChatScreen] Creating new chat...');
    final newChat = _chatStorageService.newChat();
    await _chatStorageService.addChat(newChat);
    
    // Update local state - new chat should be at the top
    setState(() {
      _currentChat = newChat;
      // Update chats list for sidebar - new chat at the beginning
      _chats = [newChat, ..._chats];
    });
    
    // Reset sliding app bar
    _slidingAppBarKey.currentState?.reset();
    
    // Show welcome suggestions for the new empty chat
    _showWelcomeSuggestionsForNewChat();
  }

  void _showWelcomeSuggestionsForNewChat() {
    // Use post-frame callback to ensure context is fully updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Generate random welcome questions
      final questions = WelcomeQuestionsData.getRandomQuestions(context, count: 4);
      
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
    final questions = WelcomeQuestionsData.getRandomQuestions(context, count: 4);
    
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
    _logger.logInfo('[ChatScreen] Selecting chat: $chatId');
    final chat = _chats.firstWhere((c) => c.id == chatId);
    
    // Reset scroll state before switching
    _chatScrollUtils?.reset();
    
    // Reset sliding app bar
    _slidingAppBarKey.currentState?.reset();
    
    setState(() {
      _currentChat = chat;
      // Always hide welcome suggestions when selecting a chat
      _showWelcomeSuggestions = false;
      _welcomeSuggestions.clear();
    });
    
    // Show welcome suggestions if chat is empty (for continuation)
    if (chat.messages.isEmpty) {
      _showWelcomeSuggestionsForNewChat();
    }
    
    // Auto-scroll to bottom when chat is loaded
    // Используем Future.microtask для гарантированного вызова после setState
    Future.microtask(() {
      _logger.logInfo('[ChatScreen] Microtask: scrolling to bottom');
      _chatScrollUtils?.scrollToBottom();
    });
    
    _logger.logInfo('[ChatScreen] Chat selected: ${chat.title}');
  }

  Future<void> _deleteChat(String chatId) async {
    final chat = _chats.firstWhere((c) => c.id == chatId);
    final String currentLanguage = _themeProvider.selectedLanguage;
    
    String getLocalizedText(String key) {
      if (currentLanguage == 'en') {
        return {
          'deleteChat': 'Delete Chat',
          'confirmDelete': 'Are you sure you want to delete the chat "${chat.title}"?',
          'cancel': 'Cancel',
          'delete': 'Delete',
        }[key] ?? key;
      } else {
        return {
          'deleteChat': 'Удалить чат',
          'confirmDelete': 'Вы действительно хотите удалить чат "${chat.title}"?',
          'cancel': 'Отмена',
          'delete': 'Удалить',
        }[key] ?? key;
      }
    }
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getLocalizedText('deleteChat')),
        content: Text(getLocalizedText('confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(getLocalizedText('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(getLocalizedText('delete')),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _chatStorageService.deleteChat(chatId);
      await _loadChats();
      
      // Show success snackbar
      if (!mounted) return;
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: currentLanguage == 'en' 
            ? 'Chat deleted successfully' 
            : 'Чат успешно удален',
        icon: Icons.delete,
      );
      
      // Clear current chat if it was deleted
      if (_currentChat?.id == chatId) {
        setState(() {
          _currentChat = null;
        });
      }
    }
  }

  void _handleSendMessage(MessageData messageData) async {
    _logger.logInfo('[ChatScreen] Received message to send: ${messageData.text}');
    
    // NOTE: Model support check is now done in ChatInput before calling this method
    // This prevents data loss if model doesn't support media
    
    // Reset scroll lock before sending new message
    // Это единственное место, где сбрасываем флаг для нового user intent
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
      _logger.logInfo('[ChatScreen] FORCE closing sidebar on narrow screen (${screenWidth.toInt()}px) when sending message');
      if (!_isSidebarCollapsed) {
        setState(() {
          _isSidebarCollapsed = true;
        });
      }
    } else {
      _logger.logInfo('[ChatScreen] Keeping sidebar open on wide screen (${screenWidth.toInt()}px)');
      // On wide screens, ensure sidebar stays open
      if (_isSidebarCollapsed) {
        setState(() {
          _isSidebarCollapsed = false;
        });
      }
    }
    
    if (_currentChat == null) {
      _logger.logInfo('[ChatScreen] Creating new chat...');
      await _createNewChat();
      if (_currentChat == null) {
        _logger.logError('[ChatScreen] Failed to create chat');
        return;
      }
      _logger.logInfo('[ChatScreen] New chat created: ${_currentChat!.id}');
    } else {
      _logger.logInfo('[ChatScreen] Using existing chat: ${_currentChat!.id}');
    }

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: messageData.text,
      timestamp: DateTime.now(),
      isComplete: true,
      imageData: messageData.imagePath != null ? messageData.base64Data : null,
      imageType: messageData.imageType,
    );

    _logger.logInfo('[ChatScreen] Created user message: ${userMessage.id}');
    
    // Add user message to chat storage
    await _chatStorageService.addMessageToChat(_currentChat!.id, userMessage);
    _logger.logInfo('[ChatScreen] Message saved to storage');
    
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
    final assistantMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isComplete: false,
      model: _selectedModel,
    );
    
    await _chatStorageService.addMessageToChat(_currentChat!.id, assistantMessage);
    
    // Get updated chat from storage to ensure we have latest data
    final chatFromStorage2 = await _chatStorageService.getChat(_currentChat!.id);
    if (chatFromStorage2 != null) {
      _currentChat = chatFromStorage2;
    }
    
    final chatWithAssistant = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, assistantMessage],
      updatedAt: DateTime.now(),
    );
    _updateCurrentChat(chatWithAssistant);

    // CRITICAL: Scroll to indicator AFTER it appears
    // Используем post-frame callback для гарантированного вызова после обновления UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.logInfo('[ChatScreen] PostFrame: scrolling to indicator');
      _chatScrollUtils?.scrollToIndicator();
    });

    // Start streaming
    _sendToAI(messageData.text);
  }

  /// Перегенерировать ответ AI
  /// 
  /// Удаляет последнее AI сообщение и генерирует новый ответ на основе последнего user сообщения
  Future<void> _regenerateResponse() async {
    _logger.logInfo('[ChatScreen] Starting regeneration...');
    
    if (_currentChat == null || _currentChat!.messages.isEmpty) {
      _logger.logError('[ChatScreen] Cannot regenerate - no chat or messages');
      return;
    }

    // Скрываем вопросы для продолжения
    setState(() {
      _showSuggestions = false;
      _continuationSuggestions.clear();
    });

    // Находим последнее AI сообщение
    final lastAIMessageIndex = _currentChat!.messages.lastIndexWhere(
      (m) => m.role == MessageRole.assistant
    );
    
    if (lastAIMessageIndex == -1) {
      _logger.logError('[ChatScreen] Cannot regenerate - no AI message found');
      return;
    }

    // Находим последнее user сообщение (перед AI)
    final lastUserMessageIndex = _currentChat!.messages.lastIndexWhere(
      (m) => m.role == MessageRole.user
    );
    
    if (lastUserMessageIndex == -1) {
      _logger.logError('[ChatScreen] Cannot regenerate - no user message found');
      return;
    }

    final lastUserMessage = _currentChat!.messages[lastUserMessageIndex];
    final lastAIMessage = _currentChat!.messages[lastAIMessageIndex];

    _logger.logInfo('[ChatScreen] Regenerating response for user message: ${lastUserMessage.id}');
    _logger.logInfo('[ChatScreen] Deleting AI message: ${lastAIMessage.id}');

    // Удаляем AI сообщение из базы данных
    await _chatStorageService.deleteMessageFromChat(
      _currentChat!.id,
      lastAIMessage.id
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
    
    await _chatStorageService.addMessageToChat(_currentChat!.id, newAssistantMessage);
    
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
    _logger.logInfo('[ChatScreen] Starting _sendToAI with message: $userMessage');
    if (_currentChat == null) {
      _logger.logError('[ChatScreen] No current chat available in _sendToAI');
      return;
    }
    _logger.logInfo('[ChatScreen] Current chat available, proceeding with AI processing');
    
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

      await _chatStorageService.addMessageToChat(_currentChat!.id, errorMessage);

      // Get updated chat from storage to ensure we have latest data
      final chatFromStorage = await _chatStorageService.getChat(_currentChat!.id);
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

  Future<void> _sendToAIWithRetry(String userMessage, {int retryCount = 0}) async {
    try {
      // Stream response from AI
      _logger.logInfo('[ChatScreen] Starting AI response streaming after message saved');
      await _streamAIResponse();
      _logger.logInfo('[ChatScreen] AI response streaming completed');
    } catch (e) {
      // Check if it's a rate limit error (DioException with 429 status)
      if (e.toString().contains('429') ||
          e.toString().contains('Rate limit') ||
          e.toString().contains('bad response')) {
        if (retryCount < ChatScreenConstants.maxRetryAttempts) {
          final delay = Duration(seconds: ChatScreenConstants.baseRetryDelaySeconds * pow(2, retryCount).toInt());
          _logger.logWarning('[ChatScreen] Rate limit hit, retrying in ${delay.inSeconds} seconds... (attempt ${retryCount + 1}/${ChatScreenConstants.maxRetryAttempts})');

          // Show retry message to user
          final retryMessage = Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: MessageRole.assistant,
            content: 'Rate limit exceeded. Retrying in ${delay.inSeconds} seconds...',
            timestamp: DateTime.now(),
            isComplete: true,
          );

          await _chatStorageService.addMessageToChat(_currentChat!.id, retryMessage);
          
          // Get updated chat from storage to ensure we have latest data
          final chatFromStorage = await _chatStorageService.getChat(_currentChat!.id);
          if (chatFromStorage != null) {
            _currentChat = chatFromStorage;
          }
          
          _updateCurrentChat(_currentChat!.copyWith(
            messages: [..._currentChat!.messages, retryMessage],
            updatedAt: DateTime.now(),
          ));

          await Future.delayed(delay);

          // Remove retry message and retry
          final messagesWithoutRetry = _currentChat!.messages
              .where((msg) => msg.content != retryMessage.content)
              .toList();

          _updateCurrentChat(_currentChat!.copyWith(
            messages: messagesWithoutRetry,
            updatedAt: DateTime.now(),
          ));

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

          await _chatStorageService.addMessageToChat(_currentChat!.id, errorMessage);

          // Get updated chat from storage to ensure we have latest data
          final chatFromStorage = await _chatStorageService.getChat(_currentChat!.id);
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
              'url': 'data:${msg.imageType};base64,${msg.imageData}'
            }
          }
        ]
      };
    }
    
    // Standard text message
    return {
      'role': msg.role.name,
      'content': msg.content
    };
  }

  Future<void> _streamAIResponse() async {
    _logger.logInfo('[ChatScreen] Starting AI response streaming...');
    if (_currentChat == null) {
      _logger.logError('[ChatScreen] No current chat available');
      return;
    }
    _logger.logInfo('[ChatScreen] Current chat available, proceeding...');

    // Filter out messages marked as error so we don't resend API error payloads
    final filteredList = _currentChat!.messages.where((m) => !m.isError).toList();
    final messages = filteredList
        .map((msg) => _convertMessageToOpenRouterFormat(msg))
        .toList();

    _logger.logInfo('[ChatScreen] Sending ${messages.length} messages to AI service');
    
    final selectedModel = _selectedModel;
    
    // Get model settings
    final modelSettingsProvider = context.read<ModelSettingsProvider>();
    final modelSettings = await modelSettingsProvider.getSettings(selectedModel, context);
    
    // Add system prompt if it exists and this is the first message
    if (modelSettings.systemPrompt != null && messages.isNotEmpty) {
      // Insert system prompt at the beginning
      messages.insert(0, {
        'role': 'system',
        'content': modelSettings.systemPrompt!
      });
      _logger.logInfo('[ChatScreen] Added system prompt to messages');
    }
    
    _logger.logInfo('[ChatScreen] Using model: $selectedModel with settings: $modelSettings');
    
    await _handleStreamingResponse(
      messages: messages,
      isContinuation: false,
      modelId: selectedModel,
      modelSettings: modelSettings,
    );
  }



  /// Try getChatCompletion with adaptive rollback on 400-like errors
  /// Uses 5% token reduction per attempt before removing messages
  Future<ChatCompletionResponse> _getChatCompletionWithAdaptiveRollback({
    required String model,
    required List<Map<String, String>> messages,
    required ModelSettings modelSettings,
  }) async {
    // Reuse the same sanitization logic as for streaming
    List<Map<String, dynamic>> sanitize(List<Map<String, dynamic>> src) {
      final patterns = [
        'Exception',
        'DioException',
        'This exception was thrown',
        'Traceback',
        'stack trace',
        'status code',
        'RequestOptions',
        'Bad Request',
        'Client error',
        'SocketException',
        'HttpException',
      ];

      const int maxMessageLen = 20000;
      final out = <Map<String, dynamic>>[];

      for (final m in src) {
        var content = m['content'] ?? '';
        final role = m['role'] ?? 'user';

        final hasErrPattern = patterns.any((p) => content.contains(p));
        if (role == 'assistant' && hasErrPattern) {
          continue;
        }

        if (content.length > maxMessageLen) {
          content = '${content.substring(0, maxMessageLen)}...[truncated]';
        }

        // Preserve the full message structure (including images if present)
        if (m.containsKey('content') && m['content'] is List) {
          // Multimodal message
          out.add(m);
        } else {
          // Text message
          out.add({'role': role, 'content': content});
        }
      }

      return out;
    }

    var attemptMsgs = sanitize(messages);

    // Get model context length for precise calculation
    final modelObj = _themeProvider.getModelById(model);
    final modelContextLength = modelObj?.contextLength ?? ChatScreenConstants.defaultMaxTokens;
    
    // Mutable max tokens - start with provided or model's full context
    int currentMaxTokens = modelSettings.maxTokens;
    
    // Token reduction state
    int tokenReductionAttempts = 0;
    const int maxTokenReductionAttempts = 10; // Allow up to 10 reductions (5% each)
    const double reductionFactor = 0.97; // 3% reduction per attempt
    const int minTokens = 8000; // Absolute minimum to prevent too small values

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
          includeReasoning: modelSettings.reasoningEnabled,
        );

        return response;
      } catch (e) {
        final err = e.toString();
        final isBadRequest = err.contains('400') || 
            err.toLowerCase().contains('bad response') || 
            err.toLowerCase().contains('client error') || 
            err.toLowerCase().contains('bad request');
        
        if (!isBadRequest) rethrow;

        // Token reduction first (5% per attempt)
        if (tokenReductionAttempts < maxTokenReductionAttempts &&
            currentMaxTokens > minTokens) {
          int newTokens = (currentMaxTokens * reductionFactor).floor();
          
          if (newTokens < minTokens) {
            newTokens = minTokens;
          }
          
          if (newTokens < currentMaxTokens) {
            tokenReductionAttempts++;
            currentMaxTokens = newTokens;
            continue; // retry with reduced tokens
          }
        }

        // Try to remove oldest non-system message(s)
        if (attemptMsgs.length <= 1) rethrow;

        final removableIndex = attemptMsgs.indexWhere((m) => m['role'] != 'system');
        if (removableIndex == -1) rethrow;

        attemptMsgs.removeAt(removableIndex);
        if (removableIndex < attemptMsgs.length && attemptMsgs[removableIndex]['role'] == 'assistant') {
          attemptMsgs.removeAt(removableIndex);
        }

        // Reset token reduction attempts after message removal
        tokenReductionAttempts = 0;
        currentMaxTokens = modelContextLength;
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
    await _chatStorageService.addMessageToChat(_currentChat!.id, assistantMessage);
    
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
      
      _chatStorageService.updateMessageInChat(
        _currentChat!.id, 
        updatedMessage.id, 
        updatedMessage
      ).then((_) {
        final updatedChat = _currentChat!.copyWith(
          messages: [
            ..._currentChat!.messages.take(_currentChat!.messages.length - 1),
            updatedMessage
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
    _logger.logInfo('[ChatScreen] Streaming toggled: $isStreaming');
    // This is called when a message is sent to start streaming
    // The actual streaming state is managed in _handleStreamingResponse
  }

  Future<void> _stopStreaming() async {
    _logger.logInfo('[ChatScreen] Stopping streaming...');
    
    // Set streaming state to false - this will cause streaming callbacks to stop
    setState(() {
      _isStreaming = false;
    });
    
    // Mark the last message as complete (stopped)
    if (_currentChat != null && _currentChat!.messages.isNotEmpty) {
      final lastMessage = _currentChat!.messages.last;
      
      if (!lastMessage.isComplete) {
        final stoppedMessage = lastMessage.copyWith(isComplete: true);
        
        // Update storage
        await _chatStorageService.updateMessageInChat(
          _currentChat!.id,
          stoppedMessage.id,
          stoppedMessage,
        );
        
        // Get updated chat from storage to ensure we have latest data
        final chatFromStorage = await _chatStorageService.getChat(_currentChat!.id);
        if (chatFromStorage != null) {
          _currentChat = chatFromStorage;
        }
        
        // Update state
        _updateCurrentChat(_currentChat!.copyWith(
          messages: [..._currentChat!.messages.take(_currentChat!.messages.length - 1), stoppedMessage],
          updatedAt: DateTime.now(),
        ));
      }
    }
    
    _logger.logInfo('[ChatScreen] Streaming stopped successfully');
  }

  void _refreshChatMessages() async {
    _logger.logInfo('[ChatScreen] Refreshing chat messages after deletion');
    
    if (_currentChat != null) {
      try {
        // Reload the chat from storage to get updated messages
        final updatedChat = await _chatStorageService.getChat(_currentChat!.id);
        if (updatedChat != null) {
          _updateCurrentChat(updatedChat);
          _logger.logInfo('[ChatScreen] Chat messages refreshed, now ${updatedChat.messages.length} messages');
        } else {
          _logger.logError('[ChatScreen] Failed to reload chat after deletion');
        }
      } catch (e) {
        _logger.logError('[ChatScreen] Error refreshing chat messages: $e');
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

  void _onHeadingTap(String headingText) {
    _logger.logInfo('[HeadingTap] Tapped heading: $headingText');
    
    // Find the heading with its key
    final heading = _navigatorHeadings.firstWhere(
      (h) => h.text == headingText,
      orElse: () {
        _logger.logError('[HeadingTap] Heading not found: $headingText');
        throw Exception('Heading not found: $headingText');
      },
    );
    
    // Close the navigator FIRST
    setState(() {
      _isNavigatorVisible = false;
    });
    
    // Wait for the navigator to close and UI to update
    Future.delayed(const Duration(milliseconds: 150), () async {
      if (!mounted) return;
      
      // Get the context of the heading widget
      final headingContext = heading.key.currentContext;
      if (headingContext == null || !headingContext.mounted) {
        _logger.logError('[HeadingTap] Heading context is null or not mounted!');
        return;
      }
      
      // Use Scrollable.ensureVisible to scroll to the widget
      await Scrollable.ensureVisible(
        headingContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.15, // 15% from top (below AppBar)
      ).catchError((error) {
        _logger.logError('[HeadingTap] Scroll error: $error');
      });
    });
  }

  // Method to continue AI response
  void _continueAIResponse(String lastMessageId) async {
    _logger.logInfo('[ChatScreen] Continuing AI response for message: $lastMessageId');
    
    if (_currentChat == null) {
      _logger.logError('[ChatScreen] No current chat available');
      return;
    }
    
    // Find the last assistant message
    final lastMessage = _currentChat!.messages.lastWhere(
      (msg) => msg.role == MessageRole.assistant && msg.id == lastMessageId,
      orElse: () => _currentChat!.messages.first, // Fallback
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
    await _chatStorageService.addMessageToChat(_currentChat!.id, continuationMessage);
    
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
    // Используем post-frame callback для гарантированного вызова после обновления UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.logInfo('[ChatScreen] PostFrame: scrolling to indicator (continuation)');
      _chatScrollUtils?.scrollToIndicator();
    });

    // Send continuation request to AI
    await _streamContinuationResponse(lastMessage.content);
  }

  Future<void> _streamContinuationResponse(String previousContent) async {
    _logger.logInfo('[ChatScreen] Starting AI continuation streaming...');
    
    // Create a continuation prompt
    final continuationPrompt = [
      {'role': 'user', 'content': 'Please continue your previous response. Do not repeat what you already said.'},
      {'role': 'assistant', 'content': previousContent},
      {'role': 'user', 'content': 'Continue from where you left off.'},
    ];
    
    // Get model settings for continuation
    final modelSettingsProvider = context.read<ModelSettingsProvider>();
    final modelSettings = await modelSettingsProvider.getSettings(_selectedModel, context);
    
    // Add system prompt if it exists
    if (modelSettings.systemPrompt != null) {
      continuationPrompt.insert(0, {
        'role': 'system',
        'content': modelSettings.systemPrompt!
      });
    }
    
    _logger.logInfo('[ChatScreen] Using model: $_selectedModel with settings: $modelSettings for continuation');
    
    await _handleStreamingResponse(
      messages: continuationPrompt,
      isContinuation: true,
      modelId: _selectedModel,
      modelSettings: modelSettings,
    );
  }

  // Method to get optimal max tokens for different models based on their context length
  // Returns the full context length of the model
  int _getOptimalMaxTokensForModel(OpenRouterModel model) {
    // Use model provided context length when available to allow full usage
    if (model.contextLength == null) {
      return ChatScreenConstants.defaultMaxTokens;
    }

    final contextLength = model.contextLength!;

    // Only ensure minimum for very small models
    if (contextLength < 1000) {
      return 1000;
    }

    return contextLength;
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
    // Use a mutable local max tokens so we can reduce it on 400 before removing messages
    int currentMaxTokens = modelSettings.maxTokens;
    final streamType = isContinuation ? 'Continuation' : 'AI';
    _logger.logInfo('[ChatScreen] Starting $streamType streaming...');
    
    // Set streaming state
    setState(() {
      _isStreaming = true;
    });
    
    // Local accumulators for this stream (not state variables)
    String accumulatedContent = '';
    String accumulatedReasoning = '';
    
    // Create a local flag that can be captured by closures
    bool isStreamingLocal = true;
    
    // Prepare messages by sanitizing out error-filled assistant messages and truncating huge individual messages
    List<Map<String, dynamic>> sanitize(List<Map<String, dynamic>> src) {
      final patterns = [
        'Exception',
        'DioException',
        'This exception was thrown',
        'Traceback',
        'stack trace',
        'status code',
        'RequestOptions',
        'Bad Request',
        'Client error',
        'SocketException',
        'HttpException',
      ];

      const int maxMessageLen = 20000; // per-message soft limit

      final out = <Map<String, dynamic>>[];

      for (final m in src) {
        var content = m['content'] ?? '';
        final role = m['role'] ?? 'user';

        final hasErrPattern = patterns.any((p) => content.contains(p));
        if (role == 'assistant' && hasErrPattern) {
          continue; // drop this assistant message
        }

        if (content.length > maxMessageLen) {
          content = '${content.substring(0, maxMessageLen)}...[truncated]';
        }

        // Preserve the full message structure (including images if present)
        if (m.containsKey('content') && m['content'] is List) {
          // Multimodal message
          out.add(m);
        } else {
          // Text message
          out.add({'role': role, 'content': content});
        }
      }

      return out;
    }

    // Adaptive retry: on 400-like errors, use 5% token reduction first,
    // then progressively remove oldest non-system messages and retry
    final originalSanitized = sanitize(messages);
    var attemptMsgs = List<Map<String, dynamic>>.from(originalSanitized);

    // Get model context length for precise calculation
    final modelObj = _themeProvider.getModelById(modelId);
    final modelContextLength = modelObj?.contextLength ?? ChatScreenConstants.defaultMaxTokens;
    
    // Token reduction state
    int tokenReductionAttempts = 0;
    const int maxTokenReductionAttempts = 10; // Allow up to 10 reductions (5% each)
    const double reductionFactor = 0.95; // 5% reduction per attempt
    const int minTokens = 8000; // Absolute minimum

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
          includeReasoning: modelSettings.reasoningEnabled,
          onChunk: (content) {
            // Check local flag first (fast), then state flag
            if (!isStreamingLocal || !_isStreaming || content.isEmpty) {
              if (isStreamingLocal) {
                _logger.logInfo('[ChatScreen] Chunk skipped: streaming stopped (content: "${content.substring(0, min(20, content.length))}")');
              }
              return;
            }

            // Accumulate locally
            accumulatedContent += content;

            // Update UI on EVERY chunk with IMMUTABLE update
            if (mounted && _currentChat != null && _currentChat!.messages.isNotEmpty) {
              final lastMessage = _currentChat!.messages.last;

              // CRITICAL: Create NEW message object with new content
              final updatedMessage = lastMessage.copyWith(
                content: accumulatedContent,
              );

              // CRITICAL: Create NEW list with updated message
              final newMessages = List<Message>.from(_currentChat!.messages);
              newMessages[newMessages.length - 1] = updatedMessage;

              // CRITICAL: Create NEW chat object
              final newChat = _currentChat!.copyWith(
                messages: newMessages,
                updatedAt: DateTime.now(),
              );

              // CRITICAL: setState with NEW objects
              _updateCurrentChat(newChat);
            }
          },
          onReasoning: (reasoning) {
            // Check local flag first (fast), then state flag
            if (!isStreamingLocal || !_isStreaming || reasoning.isEmpty) {
              if (isStreamingLocal) {
                _logger.logInfo('[ChatScreen] Reasoning skipped: streaming stopped (reasoning: "${reasoning.substring(0, min(20, reasoning.length))}")');
              }
              return;
            }

            // Accumulate locally
            accumulatedReasoning += reasoning;

            // Update UI on EVERY reasoning chunk
            if (mounted && _currentChat != null && _currentChat!.messages.isNotEmpty) {
              final lastMessage = _currentChat!.messages.last;

              // CRITICAL: Create NEW message with new reasoning
              final updatedMessage = lastMessage.copyWith(
                reasoning: accumulatedReasoning,
              );

              // CRITICAL: Create NEW list
              final newMessages = List<Message>.from(_currentChat!.messages);
              newMessages[newMessages.length - 1] = updatedMessage;

              // CRITICAL: Create NEW chat
              final newChat = _currentChat!.copyWith(
                messages: newMessages,
                updatedAt: DateTime.now(),
              );

              // CRITICAL: setState with NEW objects
              _updateCurrentChat(newChat);
            }
          },
          onCompletion: (fullContent) {
            // Check if streaming was stopped
            if (!isStreamingLocal || !_isStreaming) {
              _logger.logInfo('[ChatScreen] Completion skipped: streaming was stopped');
              return;
            }

            _logger.logInfo('[ChatScreen] Streaming completed normally');

            // Final immutable update to mark as complete
            if (mounted && _currentChat != null && _currentChat!.messages.isNotEmpty) {
              final lastMessage = _currentChat!.messages.last;

              // CRITICAL: Create NEW completed message
              final completedMessage = lastMessage.copyWith(
                content: accumulatedContent,
                reasoning: accumulatedReasoning,
                isComplete: true,
              );

              // CRITICAL: Create NEW list
              final newMessages = List<Message>.from(_currentChat!.messages);
              newMessages[newMessages.length - 1] = completedMessage;

              // CRITICAL: Create NEW chat
              final newChat = _currentChat!.copyWith(
                messages: newMessages,
                updatedAt: DateTime.now(),
              );

              // CRITICAL: setState with NEW objects
              _updateCurrentChat(newChat);

              // Reset streaming state and force final rebuild
              setState(() {
                _isStreaming = false;
              });

              // Save to storage (this is OK, it's the final state)
              _chatStorageService.updateMessageInChat(
                newChat.id, 
                completedMessage.id, 
                completedMessage
              );

              // Show continuation suggestions
              if (!isContinuation) {
                _showContinuationSuggestions(completedMessage);
              }
            }
          },
        );

        // If we reached here, the streaming started & completed successfully
        break; // exit retry loop
      } catch (e) {
        final err = e.toString();
        _logger.logError('[ChatScreen] Error in $streamType streaming: $err');

        // Detect 400/bad request cases - adaptive rollback
        final isBadRequest = err.contains('400') || err.toLowerCase().contains('bad response') || err.toLowerCase().contains('client error') || err.toLowerCase().contains('bad request');
        if (!isBadRequest) {
          setState(() {
            _isStreaming = false;
          });
          await _handleStreamingError(e, isContinuation);
          break;
        }

        // Token reduction first (5% per attempt)
        if (tokenReductionAttempts < maxTokenReductionAttempts &&
            currentMaxTokens > minTokens) {
          int newTokens = (currentMaxTokens * reductionFactor).floor();
          
          if (newTokens < minTokens) {
            newTokens = minTokens;
          }
          
          if (newTokens < currentMaxTokens) {
            tokenReductionAttempts++;
            currentMaxTokens = newTokens;
            continue; // retry with reduced tokens
          }
        }

        // If token reductions exhausted or not helpful, fall back to removing oldest non-system message(s) and retry
        if (attemptMsgs.length <= 1) {
          setState(() {
            _isStreaming = false;
          });
          await _handleStreamingError(e, isContinuation);
          break;
        }

        // Find first removable index (skip system messages)
        final removableIndex = attemptMsgs.indexWhere((m) => m['role'] != 'system');
        if (removableIndex == -1) {
          setState(() {
            _isStreaming = false;
          });
          await _handleStreamingError(e, isContinuation);
          break;
        }

        // Remove the oldest user/assistant pair if possible
        attemptMsgs.removeAt(removableIndex);
        if (removableIndex < attemptMsgs.length && attemptMsgs[removableIndex]['role'] == 'assistant') {
          attemptMsgs.removeAt(removableIndex);
        }

        // Reset token reduction attempts after message removal
        tokenReductionAttempts = 0;
        currentMaxTokens = modelContextLength;
        
        // Loop continues and retries
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
          errorResponseMessage
        );

        // Get updated chat from storage to ensure we have latest data
        final chatFromStorage = await _chatStorageService.getChat(_currentChat!.id);
        if (chatFromStorage != null) {
          _currentChat = chatFromStorage;
        }

        final updatedChat = _currentChat!.copyWith(
          messages: [
            ..._currentChat!.messages.take(_currentChat!.messages.length - 1),
            errorResponseMessage
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

        await _chatStorageService.addMessageToChat(_currentChat!.id, errorResponseMessage);
        
        // Get updated chat from storage to ensure we have latest data
        final chatFromStorage = await _chatStorageService.getChat(_currentChat!.id);
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
    
    // If modelObject is null, try to get it from ThemeProvider
    OpenRouterModel? finalModelObject = modelObject;
    if (finalModelObject == null && _themeProvider.modelsLoaded) {
      finalModelObject = _themeProvider.getModelById(modelId);
    }
    
    setState(() {
      _selectedModel = modelId;
      _selectedModelObject = finalModelObject;
    });
    
    if (finalModelObject != null) {
      final contextLength = finalModelObject.contextLength ?? 'unknown';
      final maxTokens = _getOptimalMaxTokensForModel(finalModelObject);
      _logger.logInfo('[ChatScreen] Model updated: ${finalModelObject.name}');
      _logger.logInfo('[ChatScreen] Context length: $contextLength tokens');
      _logger.logInfo('[ChatScreen] Optimal max_tokens: $maxTokens');
    } else {
      _logger.logWarning('[ChatScreen] Model object not available for $modelId');
    }
  }

  // Show model selection screen
  void _showModelSelection() {
    _logger.logInfo('[ChatScreen] Opening model selection screen');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModelsScreen(
          onModelSelected: (String modelId, OpenRouterModel? modelObject) {
            // ModelsScreen already handles navigation and ThemeProvider update
            // Use the passed model object for immediate use
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    
    // Darker text on dark theme, icon color on light theme
    final modelTextColor = theme.brightness == Brightness.dark
        ? Colors.grey[700] // Darker gray for dark theme
        : theme.iconTheme.color; // Icon color for light theme
    
    return AppBar(
      title: Text(
        '',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: theme.canvasColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, size: 20),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        // Current model name - with width limit and overflow
        // Only show if we have a model object (don't show ID before object loads)
        if (_selectedModelObject == null)
          SizedBox(width: isMobile ? screenWidth * 0.50 : 0)
        else if (isMobile)
          SizedBox(
            width: screenWidth * 0.50, // 50% of screen width
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  _selectedModelObject!.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: modelTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              _selectedModelObject!.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: modelTextColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

        // Model selection
        IconButton(
          icon: const Icon(Icons.smart_toy, size: 20),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModelsScreen(
                  onModelSelected: (String modelId, OpenRouterModel? modelObject) {
                    // ModelsScreen already handles navigation and ThemeProvider update
                    // Use the passed model object for immediate use
                    _updateSelectedModel(modelId, modelObject);
                  },
                  currentModel: _selectedModel,
                ),
              ),
            );
          },
          tooltip: 'Select Model',
        ),
        
        // Navigator button - only show if there are headings
        if (_hasHeadings())
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.format_list_bulleted, size: 20),
              onPressed: _toggleNavigator,
              tooltip: 'Toggle Navigator',
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.logInfo('[ChatScreen] Building ChatScreen, current chat: ${_currentChat?.id}, messages: ${_currentChat?.messages.length ?? 0}');
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
        // Use ThemeProvider's synchronous check for currently selected model
        return _themeProvider.modelSupportsImagesSelected();
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
      drawer: Drawer(
        child: Sidebar(
          width: ChatScreenConstants.sidebarWidth,
          isCollapsed: false,
          onToggleSidebar: () {
            Navigator.pop(context);
          },
          chats: _chats,
          currentChat: _currentChat,
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
      ),
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
                    Expanded(
                      child: GestureDetector(
                        onDoubleTap: () {
                          // Double-tap gesture to toggle navigator on mobile
                          if (_hasHeadings()) {
                            _toggleNavigator();
                          }
                        },
                        child: ChatMessages(
                          key: _chatMessagesKey,
                          openRouterService: _openRouterService,
                          chatStorageService: _chatStorageService,
                          chat: _currentChat,
                          selectedModel: _selectedModel,
                          onSendMessage: _handleSendMessage,
                          onMessageDeleted: _refreshChatMessages,
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
                        ),
                      ),
                    ),
                    
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
      appBar: _buildAppBar(context),
      drawer: Drawer(
        width: ChatScreenConstants.sidebarWidth,
        child: Sidebar(
          width: ChatScreenConstants.sidebarWidth,
          isCollapsed: false,
          onToggleSidebar: () {
            Navigator.pop(context);
          },
          chats: _chats,
          currentChat: _currentChat,
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
      ),
      body: Column(
        children: [
          // Chat content area with width control
          Expanded(
            child: _buildChatContentWrapper(
              context,
              child: Column(
                children: [
                  // Chat Messages
                  Expanded(
                    child: ChatMessages(
                      key: _chatMessagesKey,
                      openRouterService: _openRouterService,
                      chatStorageService: _chatStorageService,
                      chat: _currentChat,
                      selectedModel: _selectedModel,
                      onSendMessage: _handleSendMessage,
                      onMessageDeleted: _refreshChatMessages,
                      onContinueResponse: (messageId) => _continueAIResponse(messageId),
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
                      onRegenerateResponse: _regenerateResponse,
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
                    ),
                  ),
                  
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
  Widget _buildChatContentWrapper(BuildContext context, {required Widget child}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
      if (themeProvider.wideScreenMode) {
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
      _logger.logInfo('[ChatScreen] Generating continuation suggestions for message...');
      
      // Detect language from message
      final language = _detectLanguage(message.content);
      _logger.logInfo('[ChatScreen] Detected language: $language');
      
      // Get suggestions from AI with detected language
      final suggestions = await _getContinuationSuggestions(message.content, language);
      
      if (suggestions.isNotEmpty) {
        setState(() {
          _continuationSuggestions = suggestions;
          _showSuggestions = true;
        });

      }
      
    } catch (e) {
      _logger.logError('[ChatScreen] Error showing suggestions: $e');

      // Extract and format the actual server response instead of generic error message
      String errorMessage = _formatErrorMessage(e);
      _logger.logError('[ChatScreen] Formatted error message: $errorMessage');

      // Create an error message to show in the chat
      final errorMessageObject = Message(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.assistant,
        content: errorMessage,
        timestamp: DateTime.now(),
        isComplete: true,
        isError: true,
      );

      _logger.logError('[ChatScreen] Created error message object: ${errorMessageObject.content}');

      // Add the error message to the chat storage
      if (_currentChat != null) {
        await _chatStorageService.addMessageToChat(_currentChat!.id, errorMessageObject);

        // Update the current chat state
        final updatedChat = _currentChat!.copyWith(
          messages: [..._currentChat!.messages, errorMessageObject],
          updatedAt: DateTime.now(),
        );

        _updateCurrentChat(updatedChat);
      }

      // Show a snackbar to notify the user
      if (mounted) {
        const maxLength = 100;
        final displayMessage = errorMessage.length > maxLength 
            ? '${errorMessage.substring(0, maxLength)}...' 
            : errorMessage;
            
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: 'Failed to generate suggestions: $displayMessage',
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
    // Simple language detection based on common characters
    final hasCyrillic = RegExp(r'[а-яА-Я]').hasMatch(text);
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(text);
    final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    final hasJapanese = RegExp(r'[\u3040-\u309f\u30a0-\u30ff]').hasMatch(text);
    
    if (hasCyrillic) return 'ru';
    if (hasChinese) return 'zh';
    if (hasJapanese) return 'ja';
    if (hasLatin) return 'en';
    
    return 'en'; // Default
  }

  // Method to get localized system prompt based on language
  String _getLocalizedSystemPrompt(String language) {
    switch (language) {
      case 'ru':
        return 'Ты — полезный ассистент. Продолжи диалог, предложив 3 конкретных и логичных продолжения последнего сообщения. Отвечай на русском языке.';
      case 'zh':
        return '你是一个有用的助手。继续对话，为最后一条消息提供3个具体且合乎逻辑的延续。用中文回答。';
      case 'ja':
        return 'あなたは有用なアシスタントです。会話を続け、最後のメッセージに対して3つの具体的で論理的な続きを提案してください。日本語で回答してください。';
      default:
        return 'You are a helpful assistant. Continue the conversation by providing 3 specific and logical continuations of the last message. Respond in the same language as the user.';
    }
  }

  // Method to get localized user prompt based on language
  String _getLocalizedUserPrompt(String language) {
    switch (language) {
      case 'ru':
        return 'Предложи 3 конкретных и логичных продолжения для этого сообщения. Отвечай только списком, без дополнительного текста.';
      case 'zh':
        return '为这条消息提供3个具体且合乎逻辑的延续。只回答列表，不要额外文本。';
      case 'ja':
        return 'このメッセージに対して3つの具体的で論理的な続きを提案してください。リストのみで回答し、追加テキストは含めないでください。';
      default:
        return 'Provide 3 specific and logical continuations for this message. Answer only with the list, no additional text.';
    }
  }

  // Method to get continuation suggestions from AI
  Future<List<String>> _getContinuationSuggestions(String lastMessageContent, String language) async {
    try {
      _logger.logInfo('[ChatScreen] Generating continuation suggestions in $language...');
      
      // Get language-specific system prompt
      final systemPrompt = _getLocalizedSystemPrompt(language);
      final userPrompt = _getLocalizedUserPrompt(language);
      
      final suggestionPrompt = [
        {
          'role': 'system', 
          'content': systemPrompt
        },
        {
          'role': 'assistant', 
          'content': lastMessageContent
        },
        {
          'role': 'user', 
          'content': userPrompt
        },
      ];
      
      // Get model settings for suggestions
      final modelSettingsProvider = context.read<ModelSettingsProvider>();
      final modelSettings = await modelSettingsProvider.getSettings(_selectedModel, context);
      
      // Override maxTokens for suggestions to be smaller
      final suggestionSettings = modelSettings.copyWith(
        maxTokens: 500,
        temperature: 0.7,
      );
      
      // Add system prompt if it exists
      if (suggestionSettings.systemPrompt != null) {
        suggestionPrompt.insert(0, {
          'role': 'system',
          'content': suggestionSettings.systemPrompt!
        });
      }
      
      final response = await _getChatCompletionWithAdaptiveRollback(
        model: _selectedModel,
        messages: suggestionPrompt,
        modelSettings: suggestionSettings,
      );
      
      // Parse suggestions from response
      final suggestionsText = response.content;
      final suggestions = suggestionsText
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && (s.startsWith('-') || s.startsWith('1.') || s.startsWith('2.') || s.startsWith('3.') || s.startsWith('•') || s.length > 10))
          .map((s) => s.replaceFirst(RegExp(r'^[-•]\s*'), '').replaceFirst(RegExp(r'^\d+\.\s*'), ''))
          .where((s) => s.length > 5) // minSuggestionLength
          .take(4) // maxSuggestions
          .toList();
      
      _logger.logInfo('[ChatScreen] Generated ${suggestions.length} continuation suggestions');
      return suggestions;
      
    } catch (e) {
      _logger.logError('[ChatScreen] Error generating suggestions: $e');
      // Return default suggestions
      return [
        'Tell me more about this topic',
        'Can you provide examples?',
        'What are the alternatives?',
        'How does this apply in practice?'
      ];
    }
  }

  // Method to extract and format error message from DioException or other errors
  String _formatErrorMessage(Object error) {
    try {
      final errorString = error.toString();

      // Try to parse as JSON first
      try {
        final parsed = jsonDecode(errorString);
        if (parsed is Map<String, dynamic> && parsed.containsKey('error')) {
          final errorData = parsed['error'];
          if (errorData is Map<String, dynamic>) {
            final message = errorData['message'] ?? 'Unknown error';
            final code = errorData['code'] ?? '';
            return 'Error $code: $message';
          }
        }
      } catch (_) {
        // Not JSON, continue with string processing
      }

      // Clean up common error formatting
      String cleanedError = errorString
          .replaceAll('\\n', '\n')
          .replaceAll('\\t', ' ')
          .replaceAll('\\\\', '\\')
          .trim();

      // Remove common prefixes
      final prefixes = [
        'DioException [bad response]: ',
        'DioException [connection error]: ',
        'SocketException: ',
        'HttpException: ',
      ];

      for (final prefix in prefixes) {
        if (cleanedError.startsWith(prefix)) {
          cleanedError = cleanedError.substring(prefix.length);
          break;
        }
      }

      // Truncate if too long
      if (cleanedError.length > ChatScreenConstants.maxErrorLength) {
        cleanedError = '${cleanedError.substring(0, ChatScreenConstants.maxErrorLength)}...';
      }

      return cleanedError;
    } catch (e) {
      return error.toString();
    }
  }
}




