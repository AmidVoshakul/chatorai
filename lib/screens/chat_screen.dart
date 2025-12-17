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
  
  // Suggestion Configuration
  static const int maxSuggestions = 4;
  static const int minSuggestionLength = 5;
  static const int maxSuggestionTextLength = 100;
  
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
  
  // Continuation Suggestions
  static const String continuationSystemPrompt = 'You are a helpful assistant. Based on the previous conversation, suggest 3-4 different ways the user might want to continue the conversation. Each suggestion should be a short question or prompt (1-2 sentences max). Return only the suggestions separated by newlines, no additional text.';
  static const String continuationUserPrompt = 'Please suggest different ways I could continue this conversation.';
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
  late ChatScrollUtils _chatScrollUtils;
  String _selectedModel = ChatScreenConstants.defaultModelId;
  OpenRouterModel? _selectedModelObject;
  bool _isSuggestionsLoading = false;
  bool _showSuggestions = false;
  List<String> _continuationSuggestions = [];
  
  // State variables for managing reasoning updates
  String _pendingContent = '';
  String _accumulatedReasoning = ''; // Accumulate reasoning in memory

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
    
    // Initialize scroll utilities after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollUtils = ChatScrollUtils(
        scrollController: _messageScrollController,
        animationDuration: ChatScreenConstants.scrollAnimationDuration,
        animationCurve: Curves.easeOut,
      );
      _chatScrollUtils.initialize();
      _logger.logInfo('[ChatScreen] ChatScrollUtils initialized');
    });

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
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatStorageService.getChats();
      setState(() {
        _chats = chats;
        if (_chats.isNotEmpty && _currentChat == null) {
          _selectChat(_chats.first.id);
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
  }

  void _selectChat(String chatId) {
    _logger.logInfo('[ChatScreen] Selecting chat: $chatId');
    final chat = _chats.firstWhere((c) => c.id == chatId);
    setState(() {
      _currentChat = chat;
    });
    
    // Auto-scroll to bottom when chat is loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      _chatScrollUtils.onNewMessages();
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
    
    // Hide continuation suggestions when user sends a new message
    if (_showSuggestions) {
      setState(() {
        _showSuggestions = false;
        _continuationSuggestions.clear();
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

    // Send message to AI and handle streaming response
    _sendToAI(message);
  }

  Future<void> _sendToAI(String userMessage) async {
    _logger.logInfo('[ChatScreen] Starting _sendToAI with message: $userMessage');
    if (_currentChat == null) {
      _logger.logError('[ChatScreen] No current chat available in _sendToAI');
      return;
    }
    _logger.logInfo('[ChatScreen] Current chat available, proceeding with AI processing');

    // Reset accumulators for new stream
    _accumulatedReasoning = '';
    _pendingContent = '';
    
    try {
      // Add assistant message placeholder
      final assistantMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isComplete: false,
        model: _selectedModel,
      );

      // Update chat storage and local state immediately
      await _chatStorageService.addMessageToChat(_currentChat!.id, assistantMessage);
      
      final updatedChat = _currentChat!.copyWith(
        messages: [..._currentChat!.messages, assistantMessage],
        updatedAt: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _currentChat = updatedChat;
        });
        
        // Auto-scroll after adding message
        _chatScrollUtils.onNewMessages();
        _logger.logInfo('[ChatScreen] Auto-scroll triggered after adding message');
      }

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
    
    // Auto-scroll after adding continuation message
    _chatScrollUtils.onNewMessages();
    _logger.logInfo('[ChatScreen] Auto-scroll triggered after adding continuation message');

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
  Future<void> _handleStreamingResponse({
    required List<Map<String, String>> messages,
    required bool isContinuation,
    required String modelId,
    required int maxTokens,
  }) async {
    final streamType = isContinuation ? 'Continuation' : 'AI';
    _logger.logInfo('[ChatScreen] Starting $streamType streaming...');
    
    // Reset accumulators
    _accumulatedReasoning = '';
    _pendingContent = '';
    
    try {
      await _openRouterService.streamChatCompletion(
        messages: messages,
        model: modelId,
        maxTokens: maxTokens,
        includeReasoning: true,
        onChunk: (content) {
          // Don't skip empty chunks - they might be important for some models
          final displayLength = content.length > 50 ? 50 : content.length;
          _logger.logInfo('[ChatScreen] $streamType chunk: ${content.substring(0, displayLength)}...');
          print('[DEBUG] [ChatScreen] Content chunk: "${content.substring(0, content.length > 20 ? 20 : content.length)}${content.length > 20 ? '...' : ''}"');
          
          // Accumulate content in memory
          _pendingContent += content;
          print('[DEBUG] [ChatScreen] Accumulated content length: ${_pendingContent.length}');
          
          // Update UI immediately
          if (mounted) {
            print('[DEBUG] [ChatScreen] setState called for content chunk, length: ${_pendingContent.length}, chatId: ${_currentChat?.id}');
            setState(() {
              final lastMessage = _currentChat!.messages.last;
              final updatedMessage = lastMessage.copyWith(content: _pendingContent);
              final updatedMessages = List<Message>.from(_currentChat!.messages);
              updatedMessages[updatedMessages.length - 1] = updatedMessage;
              _currentChat = _currentChat!.copyWith(
                messages: updatedMessages,
                updatedAt: DateTime.now(),
              );
            });
            print('[DEBUG] [ChatScreen] setState completed, chat messages count: ${_currentChat?.messages.length}, last message content length: ${_currentChat?.messages.last.content.length}');
            print('[DEBUG] [ChatScreen] Chat object ID: ${_currentChat?.id}, pointer: ${_currentChat.hashCode}');
          }
        },
        onReasoning: (reasoning) {
          if (reasoning.isNotEmpty) {
            _logger.logInfo('[ChatScreen] $streamType reasoning: ${reasoning.substring(0, reasoning.length > 50 ? 50 : reasoning.length)}...');
            print('[DEBUG] [ChatScreen] Reasoning chunk: "${reasoning.substring(0, reasoning.length > 30 ? 30 : reasoning.length)}${reasoning.length > 30 ? '...' : ''}"');
            
            // Accumulate reasoning
            _accumulatedReasoning += reasoning;
            print('[DEBUG] [ChatScreen] Accumulated reasoning length: ${_accumulatedReasoning.length}');
            
            // Update UI immediately (don't save to storage yet)
            if (mounted) {
              setState(() {
                final lastMessage = _currentChat!.messages.last;
                final updatedMessage = lastMessage.copyWith(reasoning: _accumulatedReasoning);
                final updatedMessages = List<Message>.from(_currentChat!.messages);
                updatedMessages[updatedMessages.length - 1] = updatedMessage;
                _currentChat = _currentChat!.copyWith(
                  messages: updatedMessages,
                  updatedAt: DateTime.now(),
                );
              });
            }
          }
        },
        onCompletion: (fullContent) {
          print('[DEBUG] [ChatScreen] $streamType completed, saving to storage...');
          print('[DEBUG] [ChatScreen] Final reasoning length: ${_accumulatedReasoning.length}');
          print('[DEBUG] [ChatScreen] Final content length: ${_pendingContent.length}');
          
          // Save accumulated data to storage
          final lastMessage = _currentChat!.messages.last;
          final completedMessage = lastMessage.copyWith(
            content: _pendingContent,
            reasoning: _accumulatedReasoning,
            isComplete: true,
          );
          
          _chatStorageService.updateMessageInChat(
            _currentChat!.id, 
            completedMessage.id, 
            completedMessage
          ).then((_) {
            final updatedChat = _currentChat!.copyWith(
              messages: [
                ..._currentChat!.messages.take(_currentChat!.messages.length - 1),
                completedMessage
              ],
              updatedAt: DateTime.now(),
            );
            
            if (mounted) {
              setState(() {
                _currentChat = updatedChat;
              });
            }
            
            print('[DEBUG] [ChatScreen] Message saved to storage with full reasoning and content');
            
            // Show continuation suggestions after completion (only for regular AI responses)
            if (!isContinuation) {
              _showContinuationSuggestions(completedMessage);
            }
            
            // Reset accumulators
            _accumulatedReasoning = '';
            _pendingContent = '';
          });
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

    if (isMobile) {
      return _buildMobileLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
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

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Model name
                    Text(
                      modelName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
            ),
          ),
          // Continuation Suggestions
          if (_showSuggestions && _continuationSuggestions.isNotEmpty &&
              _currentChat?.messages.isNotEmpty == true &&
              !_currentChat!.messages.last.isError)
            _buildContinuationSuggestions(),
          ChatInput(
            onSendMessage: _handleSendMessage,
            onToggleStreaming: _handleToggleStreaming,
            focusNode: _chatInputFocusNode,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
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
                // Header
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

                      // Current model name
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
                  ),
                ),
                
                // Continuation Suggestions
                if (_showSuggestions && _continuationSuggestions.isNotEmpty &&
                    _currentChat?.messages.isNotEmpty == true &&
                    !_currentChat!.messages.last.isError)
                  _buildContinuationSuggestions(),
                
                // Input Area
                ChatInput(
                  onSendMessage: _handleSendMessage,
                  onToggleStreaming: _handleToggleStreaming,
                  focusNode: _chatInputFocusNode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to build continuation suggestions widget
  Widget _buildContinuationSuggestions() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _showSuggestions ? null : 0,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Continue the conversation:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                // Only show hint text on desktop (not on mobile/narrow screens)
                if (MediaQuery.of(context).size.width >= ChatScreenConstants.mobileBreakpoint)
                  Text(
                    'Tap suggestion or send your message',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      _showSuggestions = false;
                      _continuationSuggestions.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Suggestions
            Column(
              children: _continuationSuggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Send the suggestion as a new message
                        _handleSendMessage(suggestion);
                        
                        // Hide suggestions
                        setState(() {
                          _showSuggestions = false;
                          _continuationSuggestions.clear();
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward, size: 14, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
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
        final displayMessage = errorMessage.length > ChatScreenConstants.maxSuggestionTextLength 
            ? '${errorMessage.substring(0, ChatScreenConstants.maxSuggestionTextLength)}...' 
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
          'content': ChatScreenConstants.continuationSystemPrompt
        },
        {
          'role': 'assistant', 
          'content': lastMessageContent
        },
        {
          'role': 'user', 
          'content': ChatScreenConstants.continuationUserPrompt
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
          .where((s) => s.length > ChatScreenConstants.minSuggestionLength)
          .take(ChatScreenConstants.maxSuggestions)
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




