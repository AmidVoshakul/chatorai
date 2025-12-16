import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/utils/message_utils.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_message.dart' as chat_msg;
import 'package:gen_ui_chat_ai/widgets/chat/reasoning_message.dart' as reasoning_msg;
import 'package:gen_ui_chat_ai/widgets/chat/loading_indicator.dart';

// Import min function
import 'dart:math' show min;

// Initialize logger for this widget
final _logger = LogTags.chatService;

class ChatMessages extends StatefulWidget {
  final Chat? chat;
  final OpenRouterService openRouterService;
  final ChatStorageService chatStorageService;
  final String? selectedModel;
  final Function(String) onSendMessage; // Add callback for sending messages
  final Function() onMessageDeleted; // Add callback for message deletion
  final Function(String)? onContinueResponse; // Add callback for continuing response
  final ScrollController? scrollController; // External scroll controller

  const ChatMessages({
    super.key,
    required this.openRouterService,
    required this.chatStorageService,
    this.chat,
    this.selectedModel,
    required this.onSendMessage,
    required this.onMessageDeleted,
    this.onContinueResponse,
    this.scrollController,
  });

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  late List<Message> _messages;
  late ScrollController _scrollController;
  bool _isStreaming = false;
  bool _isWaitingForResponse = false; // Новое состояние - ожидание ответа
  String _selectedModel = 'openai/gpt-oss-20b:free';

  @override
  void initState() {
    super.initState();
    _logger.logInfo('[ChatMessages] Initializing ChatMessages with chat: ${widget.chat?.id}, messages: ${widget.chat?.messages.length ?? 0}');
    
    // Use external scroll controller if provided, otherwise create new one
    _scrollController = widget.scrollController ?? ScrollController();
    
    _loadMessages();
    if (widget.selectedModel != null) {
      _selectedModel = widget.selectedModel!;
    }
  }

  /// Обновление сообщения в списке
  void _updateMessageContent(String messageId, String newContent) {
    setState(() {
      final index = _messages.indexWhere((message) => message.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(content: newContent);
        _logger.logDebug('Message updated: ${_messages[index].content.substring(0, _messages[index].content.length > 30 ? 30 : _messages[index].content.length)}...');
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatMessages oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.logDebug('[ChatMessages] Widget updated, checking for changes...');
    _logger.logDebug('[ChatMessages] Old chat: ${oldWidget.chat?.id}, New chat: ${widget.chat?.id}');
    _logger.logDebug('[ChatMessages] Old messages: ${oldWidget.chat?.messages.length ?? 0}, New messages: ${widget.chat?.messages.length ?? 0}');
    
    // Check for reasoning content changes
    if (widget.chat != null && oldWidget.chat != null &&
        widget.chat!.messages.length == oldWidget.chat!.messages.length) {
      for (int i = 0; i < widget.chat!.messages.length; i++) {
        final oldMessage = oldWidget.chat!.messages[i];
        final newMessage = widget.chat!.messages[i];
        if (oldMessage.reasoning != newMessage.reasoning) {
          _logger.logInfo('[ChatMessages] Reasoning content changed for message $i: old="${oldMessage.reasoning}", new="${newMessage.reasoning}"');
        }
      }
    }
    
    if (oldWidget.chat?.id != widget.chat?.id) {
      _logger.logInfo('[ChatMessages] Chat ID changed, loading messages');
      _loadMessages();
    } else if (oldWidget.chat?.messages.length != widget.chat?.messages.length) {
      _logger.logInfo('[ChatMessages] Message count changed, reloading');
      _loadMessages();
    } else if (widget.chat != null && oldWidget.chat != null &&
              widget.chat!.messages.isNotEmpty && 
              oldWidget.chat!.messages.isNotEmpty &&
              oldWidget.chat!.messages.last.content != widget.chat!.messages.last.content) {
      _logger.logInfo('[ChatMessages] Message content changed, reloading');
      _loadMessages();
    }
    
    // Log details about each message
    if (widget.chat != null) {
      for (int i = 0; i < widget.chat!.messages.length; i++) {
        final message = widget.chat!.messages[i];
        _logger.logDebug('[ChatMessages] Message $i: role=${message.role}, content="${message.content.substring(0, min(50, message.content.length))}${message.content.length > 50 ? '...' : ''}", reasoning="${message.reasoning?.substring(0, min(50, message.reasoning!.length)) ?? 'null'}${message.reasoning != null && message.reasoning!.length > 50 ? '...' : ''}"');
      }
    }
    
    if (oldWidget.selectedModel != widget.selectedModel && widget.selectedModel != null) {
      _selectedModel = widget.selectedModel!;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    _logger.logDebug('[ChatMessages] Loading messages from chat widget...');
    _logger.logDebug('[ChatMessages] Chat object: ${widget.chat}');
    _logger.logDebug('[ChatMessages] Chat messages count: ${widget.chat?.messages.length ?? 0}');
    
    final messages = widget.chat?.messages ?? [];
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      _logger.logDebug('[ChatMessages] Message $i: role=${message.role}, content="${message.content.substring(0, min(30, message.content.length))}...", reasoning="${message.reasoning}"');
    }
    
    setState(() {
      _messages = messages;
      _logger.logInfo('[ChatMessages] Messages loaded: ${_messages.length}');
    });
  }

  void _addUserMessage(String content) {
    _logger.logInfo('[ChatMessages] Adding user message: $content');
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      isComplete: true,
    );
    
    setState(() {
      _messages.add(userMessage);
      _logger.logInfo('[ChatMessages] User message added to state, total messages: ${_messages.length}');
    });
    
    // Notify parent to handle AI response
    _logger.logDebug('[ChatMessages] Notifying parent about new message');
    widget.onSendMessage(content);
  }

  void _addAssistantMessage() {
    _logger.logInfo('[ChatMessages] Creating assistant message placeholder');
    
    setState(() {
      // Новое состояние - ожидание ответа
      _isWaitingForResponse = true;
      _isStreaming = false;
      _logger.logInfo('[ChatMessages] Waiting for response animation shown: _isWaitingForResponse=$_isWaitingForResponse, _isStreaming=$_isStreaming');
      _logger.logDebug('[ChatMessages] Messages count: ${_messages.length}, Total items: ${_messages.length + (_isWaitingForResponse ? 1 : 0)}');
    });
  }

  void _updateAssistantMessage(String content) {
    final displayLength = content.length > 50 ? 50 : content.length;
    _logger.logInfo('[ChatMessages] Updating assistant message with content: ${content.substring(0, displayLength)}...');
    
    setState(() {
      // Если это первое обновление (начало потока), переключаемся с анимации на сообщение
      if (_isWaitingForResponse) {
        _logger.logInfo('[ChatMessages] First update received! Switching from waiting animation to streaming message');
        _isWaitingForResponse = false;
        _isStreaming = true;
        
        // Создаем первое сообщение
        final assistantMessage = Message(
          role: MessageRole.assistant,
          content: content,
          timestamp: DateTime.now(),
          isComplete: false,
        );
        _messages.add(assistantMessage);
        _logger.logInfo('[ChatMessages] Added first message to stream: _isWaitingForResponse=$_isWaitingForResponse, _isStreaming=$_isStreaming');
      } else if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
        // Обновляем существующее сообщение
        _messages.last = _messages.last.copyWith(content: content);
        _logger.logInfo('[ChatMessages] Assistant message updated, content length: ${content.length}');
      } else {
        _logger.logWarning('[ChatMessages] WARNING: No assistant message to update');
      }
    });
  }

  void _completeAssistantMessage() {
    if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
      setState(() {
        _messages.last = _messages.last.copyWith(isComplete: true);
        _isStreaming = false;
        _isWaitingForResponse = false;
      });
    }
  }

  // Анимация "три точки" ожидания ответа
  Widget _buildWaitingAnimation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Используем унифицированный индикатор загрузки
          ChatLoadingIndicator(
            size: 12,
          ),
        ],
      ),
    );
  }

  Future<void> _sendToAI(String userMessage) async {
    _logger.logInfo('[ChatMessages] Starting _sendToAI with message: $userMessage');
    _addAssistantMessage();
    
    try {
      _logger.logInfo('[ChatMessages] Calling streamChatCompletion...');
      await widget.openRouterService.streamChatCompletion(
        messages: [
          ..._messages
            .where((msg) => msg.role != MessageRole.assistant || !msg.isComplete)
            .map((msg) => {
              'role': msg.role.name,
              'content': msg.content,
            })
            ,
        ],
        model: _selectedModel,
        onChunk: (content) {
          _updateAssistantMessage(content);
        },
        onCompletion: (fullResponse) {
          _completeAssistantMessage();
          // Notify parent that chat has been updated
        },
      );
    } catch (e) {
      _logger.logError('[ChatMessages] Error in _sendToAI: $e');

      // Remove the waiting animation
      setState(() {
        _isWaitingForResponse = false;
        _isStreaming = false;
      });

      // Add error message to the chat
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: e.toString(),
        timestamp: DateTime.now(),
        isComplete: true,
        isError: true,
      );

      setState(() {
        _messages.add(errorMessage);
      });
    }
  }

  void _handleDeleteMessage(Message message) async {
    _logger.logInfo('[ChatMessages] Deleting message: ${message.id}');
    
    final bool deleted = await MessageUtils.deleteMessage(
      chatId: widget.chat?.id ?? '',
      messageId: message.id,
      chatStorageService: widget.chatStorageService,
      context: context,
    );
    
    if (deleted) {
      // Сообщение успешно удалено из базы данных
      _logger.logInfo('[ChatMessages] Message deleted from database, refreshing UI...');
      
      // Удаляем сообщение из локального списка
      setState(() {
        _messages.remove(message);
        _logger.logInfo('[ChatMessages] UI updated, now ${_messages.length} messages in local list');
      });
      
      // Сообщаем родительскому компоненту
      widget.onMessageDeleted();
    } else {
      _logger.logError('[ChatMessages] Failed to delete message from database');
    }
  }

  void selectModel(String modelId) {
    setState(() {
      _selectedModel = modelId;
    });
  }

  // Public method to send messages from outside (e.g., from chat input)
  void sendMessage(String content) {
    _addUserMessage(content);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                _logger.logVerbose('[ChatMessages] Rendering item $index of ${_messages.length} | _isWaitingForResponse=$_isWaitingForResponse | _isStreaming=$_isStreaming');
                
                if (index >= _messages.length) {
                  // Safety check
                  return Container();
                }
                
                final message = _messages[index];
                final isLastMessage = index == _messages.length - 1;
                final isAssistantMessage = message.role == MessageRole.assistant;
                final isEmptyAssistantMessage = isAssistantMessage && message.content.isEmpty;
                
                // Показываем анимацию для пустого assistant сообщения
                if (isEmptyAssistantMessage && !message.isComplete) {
                  _logger.logDebug('[ChatMessages] Showing waiting animation for empty assistant message at index $index');
                  return _buildWaitingAnimation();
                }
                
                // Check if we should show reasoning first
                if (message.reasoning != null && message.reasoning!.isNotEmpty) {
                  _logger.logInfo('[ChatMessages] Creating ReasoningMessage for message $index with reasoning length: ${message.reasoning!.length}');
                  _logger.logDebug('[ChatMessages] Reasoning content: "${message.reasoning!.substring(0, min(100, message.reasoning!.length))}${message.reasoning!.length > 100 ? '...' : ''}"');
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show reasoning message first
                      reasoning_msg.ReasoningMessage(
                        key: ValueKey(message.id),
                        reasoning: message.reasoning!,
                        isStreaming: _isStreaming && isLastMessage,
                      ),
                      const SizedBox(height: 8),
                      // Then show the main message content
                      chat_msg.ChatMessage(
                        message: message,
                        isStreaming: _isStreaming && isLastMessage,
                        isLastMessage: isLastMessage,
                        onRetry: () {
                          if (message.role == MessageRole.user) {
                            _sendToAI(message.content);
                          }
                        },
                        chatId: widget.chat?.id ?? '',
                        chatStorageService: widget.chatStorageService,
                        onMessageDeleted: widget.onMessageDeleted,
                        onMessageUpdated: (newContent) {
                          _updateMessageContent(message.id, newContent);
                        },
                        onDelete: () {
                          _handleDeleteMessage(message);
                        },
                        onContinueResponse: message.role == MessageRole.assistant 
                            ? () => widget.onContinueResponse?.call(message.id)
                            : null,
                      ),
                    ],
                  );
                } else {
                  _logger.logDebug('[ChatMessages] No reasoning for message $index. Reasoning: ${message.reasoning}');
                }
                
                return chat_msg.ChatMessage(
                  message: message,
                  isStreaming: _isStreaming && isLastMessage,
                  isLastMessage: isLastMessage,
                  onRetry: () {
                    if (message.role == MessageRole.user) {
                      _sendToAI(message.content);
                    }
                  },
                  chatId: widget.chat?.id ?? '',
                  chatStorageService: widget.chatStorageService,
                  onMessageDeleted: widget.onMessageDeleted,
                  onMessageUpdated: (newContent) {
                    _updateMessageContent(message.id, newContent);
                  },
                  onDelete: () {
                    _handleDeleteMessage(message);
                  },
                  onContinueResponse: message.role == MessageRole.assistant 
                      ? () => widget.onContinueResponse?.call(message.id)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
