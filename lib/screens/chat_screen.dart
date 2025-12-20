// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/widgets/sidebar/sidebar.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_input.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_messages.dart';
import 'package:gen_ui_chat_ai/widgets/chat/continuation_suggestions.dart';
import 'package:gen_ui_chat_ai/widgets/chat/welcome_questions_data.dart';
import 'package:gen_ui_chat_ai/screens/models_screen.dart';
import 'package:gen_ui_chat_ai/utils/chat_scroll_utils.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';

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
  static const int defaultMaxTokens = 2046;
  static const int minMaxTokens = 1000;
  static const int maxMaxTokens = 16000;
  static const double tokenContextRatio = 0.2; // 20% of context length
  
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

  const ChatScreen({
    super.key,
    this.initialModel,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late ChatStorageService _chatStorageService;
  late OpenRouterService _openRouterService;
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
  
  @override
  void initState() {
    super.initState();
    _logger.logInfo('[ChatScreen] Initializing ChatScreen services...');
    _chatStorageService = ChatStorageService();
    _logger.logInfo('[ChatScreen] ChatStorageService initialized');
    _openRouterService = OpenRouterService();
    _logger.logInfo('[ChatScreen] OpenRouterService initialized');
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _logger.logInfo('[ChatScreen] ThemeProvider accessed');
    
    // Initialize scroll controller
    _messageScrollController = ScrollController();
    _logger.logInfo('[ChatScreen] ScrollController initialized');
    
    // Initialize scroll utilities immediately (no need to wait for frame)
    _chatScrollUtils = ChatScrollUtils(
      scrollController: _messageScrollController,
      animationDuration: ChatScreenConstants.scrollAnimationDuration,
      animationCurve: Curves.easeOut,
    );
    _chatScrollUtils!.initialize();
    _logger.logInfo('[ChatScreen] ChatScrollUtils initialized');

    _loadChats();

    // Initialize model selection from ThemeProvider
    _initializeModelSelection();

    // Listen to ThemeProvider changes to update loading state
    _themeProvider.addListener(_onThemeProviderChange);
  }

  // Listen for ThemeProvider changes to update loading state
  void _onThemeProviderChange() {
    // Update the loading state when models finish loading
    if (mounted) {
      setState(() {
        // This will trigger a rebuild and update the loading indicator
      });
    }
  }

  // Initialize model selection from ThemeProvider
  void _initializeModelSelection() {
    // Set initial model from ThemeProvider
    _selectedModel = _themeProvider.selectedModelId;
    _selectedModelObject = _themeProvider.selectedModelObject;

    // If models are already loaded, find the selected model
    if (_themeProvider.modelsLoaded && _themeProvider.availableModels.isNotEmpty) {
      _selectedModelObject = _themeProvider.getModelById(_selectedModel);
      if (_selectedModelObject != null) {
        _logger.logInfo('[ChatScreen] Using selected model: ${_selectedModelObject!.name}');
      } else {
        _logger.logWarning('[ChatScreen] Selected model not found in available models, using first available');
        _selectedModelObject = _themeProvider.availableModels.first;
        _selectedModel = _selectedModelObject!.id;
      }
    } else if (_themeProvider.isLoadingModels) {
      // Wait for models to be loaded
      Future.delayed(ChatScreenConstants.modelLoadWaitTime, () {
        if (mounted && _themeProvider.modelsLoaded && _themeProvider.availableModels.isNotEmpty) {
          _selectedModelObject = _themeProvider.getModelById(_selectedModel);
          if (_selectedModelObject == null) {
            _selectedModelObject = _themeProvider.availableModels.first;
            _selectedModel = _selectedModelObject!.id;
          }
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    // Remove listener to prevent memory leaks
    _themeProvider.removeListener(_onThemeProviderChange);
    _titleController.dispose();
    _chatScrollUtils?.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatStorageService.getChats();
      setState(() {
        _chats = chats;
        if (_chats.isNotEmpty && _currentChat == null) {
          _selectChat(_chats.first.id);
        } else if (_chats.isEmpty) {
          // No chats, hide welcome suggestions
          setState(() {
            _showWelcomeSuggestions = false;
            _welcomeSuggestions.clear();
          });
        }
      });
    } catch (e) {
      _logger.logError('[ChatScreen] Error loading chats: $e');
    }
  }

  Future<void> _createNewChat() async {
    _logger.logInfo('[ChatScreen] Creating new chat...');
    final newChat = _chatStorageService.newChat();
    await _chatStorageService.addChat(newChat);
    await _loadChats();
    _selectChat(newChat.id);
    
    // Show welcome suggestions for new chat
    _showWelcomeSuggestionsForNewChat();
  }

  void _showWelcomeSuggestionsForNewChat() {
    // Generate random welcome questions
    final questions = WelcomeQuestionsData.getRandomQuestions(count: 4);
    
    setState(() {
      _welcomeSuggestions = questions;
      _showWelcomeSuggestions = true;
      // Hide continuation suggestions if they're showing
      _showSuggestions = false;
      _continuationSuggestions.clear();
    });
  }

  void _selectChat(String chatId) {
    _logger.logInfo('[ChatScreen] Selecting chat: $chatId');
    final chat = _chats.firstWhere((c) => c.id == chatId);
    
    // Reset scroll state before switching
    _chatScrollUtils?.reset();
    
    setState(() {
      _currentChat = chat;
    });
    
    // Show welcome suggestions if chat is empty
    if (chat.messages.isEmpty) {
      _showWelcomeSuggestionsForNewChat();
    } else {
      // Hide welcome suggestions if chat has messages
      setState(() {
        _showWelcomeSuggestions = false;
        _welcomeSuggestions.clear();
      });
    }
    
    // Auto-scroll to bottom when chat is loaded
    // Используем Future.microtask для гарантированного вызова после setState
    Future.microtask(() {
      _logger.logInfo('[ChatScreen] Microtask: scrolling to bottom');
      _chatScrollUtils?.scrollToBottom();
    });
    
    _logger.logInfo('[ChatScreen] Chat selected: ${chat.title}');
    
    // Close sidebar on narrow screens when switching chats
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < ChatScreenConstants.mobileBreakpoint) {
      if (!_isSidebarCollapsed) {
        setState(() {
          _isSidebarCollapsed = true;
        });
      }
      // Force rebuild to ensure visual update
      Future.delayed(ChatScreenConstants.sidebarUpdateDelay, () {
        setState(() {});
      });
    } else {
      // On wide screens, ensure sidebar stays open
      if (_isSidebarCollapsed) {
        setState(() {
          _isSidebarCollapsed = false;
        });
      }
    }
    
    // Focus on input field after a small delay to ensure UI updates
    Future.delayed(Duration.zero, () {
      _logger.logInfo('[ChatScreen] Focusing on input field');
      FocusScope.of(context).requestFocus(_chatInputFocusNode);
    });
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
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: currentLanguage == 'en' 
            ? 'Chat deleted successfully' 
            : 'Чат успешно удален',
        icon: Icons.delete,
      );
      
      if (_currentChat?.id == chatId) {
        if (_chats.isNotEmpty) {
          _selectChat(_chats.first.id);
        } else {
          setState(() {
            _currentChat = null;
          });
        }
      }
    }
  }

  void _handleSendMessage(String message) async {
    _logger.logInfo('[ChatScreen] Received message to send: $message');
    
    // Reset scroll lock before sending new message
    // Это единственное место, где сбрасываем флаг для нового user intent
    _chatScrollUtils?.resetAutoScrollLock();
    print('[CHAT_SCREEN] Auto-scroll lock reset before sending');
    
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
      // Force rebuild to ensure visual update
      Future.delayed(ChatScreenConstants.sidebarUpdateDelay, () {
        setState(() {});
      });
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
      content: message,
      timestamp: DateTime.now(),
      isComplete: true,
    );

    _logger.logInfo('[ChatScreen] Created user message: ${userMessage.id}');
    
    // Add user message to chat storage
    await _chatStorageService.addMessageToChat(_currentChat!.id, userMessage);
    _logger.logInfo('[ChatScreen] Message saved to storage');
    
    // Update local state immediately
    final updatedChat = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, userMessage],
      updatedAt: DateTime.now(),
    );
    setState(() {
      _currentChat = updatedChat;
    });

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
    
    final chatWithAssistant = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, assistantMessage],
      updatedAt: DateTime.now(),
    );
    setState(() {
      _currentChat = chatWithAssistant;
    });

    // CRITICAL: Scroll to indicator AFTER it appears
    // Используем post-frame callback для гарантированного вызова после обновления UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.logInfo('[ChatScreen] PostFrame: scrolling to indicator');
      _chatScrollUtils?.scrollToIndicator();
    });

    // Start streaming
    _sendToAI(message);
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

      final updatedChat = _currentChat!.copyWith(
        messages: [..._currentChat!.messages, errorMessage],
        updatedAt: DateTime.now(),
      );
      setState(() {
        _currentChat = updatedChat;
      });
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
          setState(() {
            _currentChat = _currentChat!.copyWith(
              messages: [..._currentChat!.messages, retryMessage],
              updatedAt: DateTime.now(),
            );
          });

          await Future.delayed(delay);

          // Remove retry message and retry
          final messagesWithoutRetry = _currentChat!.messages
              .where((msg) => msg.content != retryMessage.content)
              .toList();

          setState(() {
            _currentChat = _currentChat!.copyWith(
              messages: messagesWithoutRetry,
              updatedAt: DateTime.now(),
            );
          });

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

          final updatedChat = _currentChat!.copyWith(
            messages: [..._currentChat!.messages, errorMessage],
            updatedAt: DateTime.now(),
          );

          if (mounted) {
            setState(() {
              _currentChat = updatedChat;
            });
          }
        }
      } else {
        // Re-throw non-rate-limit errors
        rethrow;
      }
    }
  }

  Future<void> _streamAIResponse() async {
    _logger.logInfo('[ChatScreen] Starting AI response streaming...');
    if (_currentChat == null) {
      _logger.logError('[ChatScreen] No current chat available');
      return;
    }
    _logger.logInfo('[ChatScreen] Current chat available, proceeding...');

    final messages = _currentChat!.messages
        .map((msg) => {
          'role': msg.role.name,
          'content': msg.content
        })
        .toList();
    
    _logger.logInfo('[ChatScreen] Sending ${messages.length} messages to AI service');
    
    final selectedModel = _selectedModel;
    final optimalMaxTokens = _selectedModelObject != null 
        ? _getOptimalMaxTokensForModel(_selectedModelObject!)
        : _getOptimalMaxTokensFromId(selectedModel);
    
    _logger.logInfo('[ChatScreen] Using model: $selectedModel with max_tokens: $optimalMaxTokens');
    
    await _handleStreamingResponse(
      messages: messages,
      isContinuation: false,
      modelId: selectedModel,
      maxTokens: optimalMaxTokens,
    );
  }



  // Method to add assistant message from ChatMessages
  void addAssistantMessage() {
    if (_currentChat == null) return;

    final assistantMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isComplete: false,
    );

    // Update chat storage and local state immediately
    _chatStorageService.addMessageToChat(_currentChat!.id, assistantMessage);
    
    final updatedChat = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, assistantMessage],
      updatedAt: DateTime.now(),
    );
    if (mounted) {
      setState(() {
        _currentChat = updatedChat;
      });
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
          setState(() {
            _currentChat = updatedChat;
          });
        }
      });
    }
  }

  void _handleToggleStreaming(bool isStreaming) {
    _logger.logInfo('[ChatScreen] Streaming toggled: $isStreaming');
  }

  void _refreshChatMessages() async {
    _logger.logInfo('[ChatScreen] Refreshing chat messages after deletion');
    
    if (_currentChat != null) {
      try {
        // Reload the chat from storage to get updated messages
        final updatedChat = await _chatStorageService.getChat(_currentChat!.id);
        if (updatedChat != null) {
          setState(() {
            _currentChat = updatedChat;
            _logger.logInfo('[ChatScreen] Chat messages refreshed, now ${updatedChat.messages.length} messages');
          });
        } else {
          _logger.logError('[ChatScreen] Failed to reload chat after deletion');
        }
      } catch (e) {
        _logger.logError('[ChatScreen] Error refreshing chat messages: $e');
      }
    }
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
    
    final updatedChat = _currentChat!.copyWith(
      messages: [..._currentChat!.messages, continuationMessage],
      updatedAt: DateTime.now(),
    );
    
    setState(() {
      _currentChat = updatedChat;
    });
    
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
    
    final optimalMaxTokens = _selectedModelObject != null 
        ? _getOptimalMaxTokensForModel(_selectedModelObject!)
        : _getOptimalMaxTokensFromId(_selectedModel);
    
    _logger.logInfo('[ChatScreen] Using model: $_selectedModel with max_tokens: $optimalMaxTokens for continuation');
    
    await _handleStreamingResponse(
      messages: continuationPrompt,
      isContinuation: true,
      modelId: _selectedModel,
      maxTokens: optimalMaxTokens,
    );
  }

  // Method to get optimal max tokens for different models based on their context length
  int _getOptimalMaxTokensForModel(OpenRouterModel model) {
    if (model.contextLength == null) {
      return ChatScreenConstants.defaultMaxTokens;
    }
    
    final contextLength = model.contextLength!;
    
    // Use configured ratio of context length as max tokens
    final maxTokens = (contextLength * ChatScreenConstants.tokenContextRatio).toInt();
    
    // Set reasonable bounds
    if (maxTokens < ChatScreenConstants.minMaxTokens) {
      return ChatScreenConstants.minMaxTokens;
    } else if (maxTokens > ChatScreenConstants.maxMaxTokens) {
      return ChatScreenConstants.maxMaxTokens;
    } else {
      return maxTokens;
    }
  }

  /// Shared method to handle streaming responses (both regular and continuation)
  /// 
  /// CRITICAL: This method implements proper Flutter streaming architecture:
  /// 1. Each chunk creates NEW Message object
  /// 2. Each chunk creates NEW List
  /// 3. setState() is called on every chunk
  /// 4. No mutation of existing objects
  Future<void> _handleStreamingResponse({
    required List<Map<String, String>> messages,
    required bool isContinuation,
    required String modelId,
    required int maxTokens,
  }) async {
    final streamType = isContinuation ? 'Continuation' : 'AI';
    _logger.logInfo('[ChatScreen] Starting $streamType streaming...');
    
    // Local accumulators for this stream (not state variables)
    String accumulatedContent = '';
    String accumulatedReasoning = '';
    
    try {
      await _openRouterService.streamChatCompletion(
        messages: messages,
        model: modelId,
        maxTokens: maxTokens,
        includeReasoning: true,
        onChunk: (content) {
          if (content.isEmpty) return;
          
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
            setState(() {
              _currentChat = newChat;
            });
          }
        },
        onReasoning: (reasoning) {
          if (reasoning.isEmpty) return;
          
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
            setState(() {
              _currentChat = newChat;
            });
          }
        },
        onCompletion: (fullContent) {
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
            setState(() {
              _currentChat = newChat;
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
    } catch (e) {
      _logger.logError('[ChatScreen] Error in $streamType streaming: $e');
      await _handleStreamingError(e, isContinuation);
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

        final updatedChat = _currentChat!.copyWith(
          messages: [
            ..._currentChat!.messages.take(_currentChat!.messages.length - 1),
            errorResponseMessage
          ],
          updatedAt: DateTime.now(),
        );
        
        if (mounted) {
          setState(() {
            _currentChat = updatedChat;
          });
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
        
        final updatedChat = _currentChat!.copyWith(
          messages: [..._currentChat!.messages, errorResponseMessage],
          updatedAt: DateTime.now(),
        );
        
        if (mounted) {
          setState(() {
            _currentChat = updatedChat;
          });
        }
      }
    }
  }

  void _updateSelectedModel(String modelId, OpenRouterModel? modelObject) {
    setState(() {
      _selectedModel = modelId;
      _selectedModelObject = modelObject;
    });
    
    if (modelObject != null) {
      final contextLength = modelObject.contextLength ?? 'unknown';
      final maxTokens = _getOptimalMaxTokensForModel(modelObject);
      _logger.logInfo('[ChatScreen] Model updated: ${modelObject.name}');
      _logger.logInfo('[ChatScreen] Context length: $contextLength tokens');
      _logger.logInfo('[ChatScreen] Optimal max_tokens: $maxTokens');
    }
  }

  // Fallback function to determine max tokens based on model ID pattern
  int _getOptimalMaxTokensFromId(String modelId) {
    // Models with large context windows
    if (modelId.contains('grok') || 
        modelId.contains('claude') || 
        modelId.contains('gpt-4') ||
        modelId.contains('gemini')) {
      return 8000; // Higher limit for models with large context
    }
    
    // Standard models
    if (modelId.contains('gpt-3.5') || 
        modelId.contains('llama') || 
        modelId.contains('mistral')) {
      return 4096; // Medium limit for standard models
    }
    
    // Default limit
    return 2046;
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
      focusNode: _chatInputFocusNode,
    );

    if (isMobile) {
      return _buildMobileLayout(context, chatInput);
    } else {
      return _buildDesktopLayout(context, chatInput);
    }
  }

  Widget _buildMobileLayout(BuildContext context, Widget chatInput) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
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
        actions: [
          // Current model display with loading state
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final isLoading = themeProvider.isLoadingModels;
                final modelName = _selectedModelObject?.name ?? _selectedModel;
                final screenWidth = MediaQuery.of(context).size.width;

                // Calculate max width based on screen size
                // Mobile: 35% of screen width (more space for model names)
                // Desktop: 40% of screen width (more generous)
                final maxWidth = screenWidth < 800 
                    ? screenWidth * 0.55 
                    : screenWidth * 0.4;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Model name with constraints
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Text(
                        modelName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                    // Loading indicator
                    if (isLoading) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          
          // Model selection button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.smart_toy),
              onPressed: () async {
                // Handle sidebar based on screen width before navigation
                final screenWidth = MediaQuery.of(context).size.width;
                if (screenWidth < ChatScreenConstants.mobileBreakpoint) {
                  if (!_isSidebarCollapsed) {
                    setState(() {
                      _isSidebarCollapsed = true;
                    });
                  }
                  // Force rebuild to ensure visual update
                  Future.delayed(ChatScreenConstants.sidebarUpdateDelay, () {
                    setState(() {});
                  });
                } else {
                  // On wide screens, ensure sidebar stays open
                  if (_isSidebarCollapsed) {
                    setState(() {
                      _isSidebarCollapsed = false;
                    });
                  }
                }
                
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModelsScreen(
                      onModelSelected: (String modelId) {
                        // Update the model selection
                        _updateSelectedModel(modelId, null);
                      },
                      currentModel: _selectedModel,
                    ),
                  ),
                );

                // Handle result if a model object was returned
                if (result is OpenRouterModel) {
                  _updateSelectedModel(result.id, result);
                }
              },
              tooltip: 'Navigate to Models',
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Sidebar(
          width: ChatScreenConstants.sidebarWidth,
          isCollapsed: false,
          onToggleSidebar: () {
            Navigator.pop(context);
          },
          chats: _chats,
          currentChat: _currentChat,
          onChatSelect: _selectChat,
          onChatDelete: _deleteChat,
          onNewChat: _createNewChat,
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
                      welcomeSuggestions: _welcomeSuggestions,
                      showWelcomeSuggestions: _showWelcomeSuggestions,
                      onWelcomeSuggestionsClose: () {
                        setState(() {
                          _showWelcomeSuggestions = false;
                          _welcomeSuggestions.clear();
                        });
                      },
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

  Widget _buildDesktopLayout(BuildContext context, Widget chatInput) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            width: _isSidebarCollapsed ? ChatScreenConstants.sidebarCollapsedWidth : ChatScreenConstants.sidebarWidth,
            isCollapsed: _isSidebarCollapsed,
            onToggleSidebar: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
            chats: _chats,
            currentChat: _currentChat,
            onChatSelect: _selectChat,
            onChatDelete: _deleteChat,
            onNewChat: _createNewChat,
          ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header - always full width
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),

                      // Current model name - no truncation on desktop
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          _selectedModelObject?.name ?? _selectedModel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.smart_toy),
                        onPressed: () {
                          // Handle sidebar based on screen width before navigation
                          final screenWidth = MediaQuery.of(context).size.width;
                          if (screenWidth < ChatScreenConstants.mobileBreakpoint) {
                            if (!_isSidebarCollapsed) {
                              setState(() {
                                _isSidebarCollapsed = true;
                              });
                            }
                            // Force rebuild to ensure visual update
                            Future.delayed(ChatScreenConstants.sidebarUpdateDelay, () {
                              setState(() {});
                            });
                          } else {
                            // On wide screens, ensure sidebar stays open
                            if (_isSidebarCollapsed) {
                              setState(() {
                                _isSidebarCollapsed = false;
                              });
                            }
                          }
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModelsScreen(
                                onModelSelected: (String modelId) {
                                  // For now, just update the model ID
                                  // In a full implementation, we would pass the model object
                                  _updateSelectedModel(modelId, null);
                                  Navigator.pop(context);
                                },
                                currentModel: _selectedModel,
                              ),
                            ),
                          );
                        },
                        tooltip: 'Navigate to Models',
                      ),
                    ],
                  ),
                ),
                
                // Chat content area with width control
                Expanded(
                  child: _buildChatContentWrapper(
                    context,
                    child: Column(
                      children: [
                        // Chat Messages
                        Expanded(
                          child: ChatMessages(
                            openRouterService: _openRouterService,
                            chatStorageService: _chatStorageService,
                            chat: _currentChat,
                            selectedModel: _selectedModel,
                            onSendMessage: _handleSendMessage,
                            onMessageDeleted: _refreshChatMessages,
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
                            welcomeSuggestions: _welcomeSuggestions,
                            showWelcomeSuggestions: _showWelcomeSuggestions,
                            onWelcomeSuggestionsClose: () {
                              setState(() {
                                _showWelcomeSuggestions = false;
                                _welcomeSuggestions.clear();
                              });
                            },
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
        ],
      ),
    );
  }

  /// Widget to wrap chat content with responsive width
  Widget _buildChatContentWrapper(BuildContext context, {required Widget child}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Only apply width constraints on desktop (wide screens)
    if (screenWidth >= ChatScreenConstants.mobileBreakpoint) {
      // If wide screen mode is enabled, use full width
      if (themeProvider.wideScreenMode) {
        return child;
      } else {
        // Use 75% width by default on desktop
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            width: screenWidth * 0.75,
            child: child,
          ),
        );
      }
    } else {
      // On mobile, always use full width
      return child;
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
      
      // Get suggestions from AI
      final suggestions = await _getContinuationSuggestions(message.content);
      
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

        setState(() {
          _currentChat = updatedChat;
        });
      }

      // Show a snackbar to notify the user
      if (mounted) {
        final displayMessage = errorMessage.length > ContinuationSuggestionsConstants.maxSuggestionTextLength 
            ? '${errorMessage.substring(0, ContinuationSuggestionsConstants.maxSuggestionTextLength)}...' 
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

  // Method to get continuation suggestions from AI
  Future<List<String>> _getContinuationSuggestions(String lastMessageContent) async {
    try {
      _logger.logInfo('[ChatScreen] Generating continuation suggestions...');
      
      final suggestionPrompt = [
        {
          'role': 'system', 
          'content': ContinuationSuggestionsConstants.systemPrompt
        },
        {
          'role': 'assistant', 
          'content': lastMessageContent
        },
        {
          'role': 'user', 
          'content': ContinuationSuggestionsConstants.userPrompt
        },
      ];
      
      final response = await _openRouterService.getChatCompletion(
        model: _selectedModel,
        messages: suggestionPrompt,
        maxTokens: 500,
        temperature: 0.7,
      );
      
      // Parse suggestions from response
      final suggestionsText = response.content;
      final suggestions = suggestionsText
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && (s.startsWith('-') || s.startsWith('1.') || s.startsWith('2.') || s.startsWith('3.') || s.startsWith('•') || s.length > 10))
          .map((s) => s.replaceFirst(RegExp(r'^[-•]\s*'), '').replaceFirst(RegExp(r'^\d+\.\s*'), ''))
          .where((s) => s.length > ContinuationSuggestionsConstants.minSuggestionLength)
          .take(ContinuationSuggestionsConstants.maxSuggestions)
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




