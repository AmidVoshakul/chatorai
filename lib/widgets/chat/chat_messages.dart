import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/utils/message_utils.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_message.dart' as ChatMsg;

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
    Key? key,
    required this.openRouterService,
    required this.chatStorageService,
    this.chat,
    this.selectedModel,
    required this.onSendMessage,
    required this.onMessageDeleted,
    this.onContinueResponse,
    this.scrollController,
  }) : super(key: key);

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  late List<Message> _messages;
  late ScrollController _scrollController;
  bool _isStreaming = false;
  bool _isWaitingForResponse = false; // Новое состояние - ожидание ответа
  String _selectedModel = 'x-ai/grok-4.1-fast:free';

  @override
  void initState() {
    super.initState();
    print('[ChatMessages] 🎯 Initializing ChatMessages with chat: ${widget.chat?.id}, messages: ${widget.chat?.messages.length ?? 0}');
    
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
        print('[ChatMessages] 📝 Message updated: ${_messages[index].content.substring(0, _messages[index].content.length > 30 ? 30 : _messages[index].content.length)}...');
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatMessages oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('[ChatMessages] 🔄 Widget updated, checking for changes...');
    print('[ChatMessages] 🔄 Old chat: ${oldWidget.chat?.id}, New chat: ${widget.chat?.id}');
    print('[ChatMessages] 🔄 Old messages: ${oldWidget.chat?.messages.length ?? 0}, New messages: ${widget.chat?.messages.length ?? 0}');
    
    if (oldWidget.chat?.id != widget.chat?.id) {
      print('[ChatMessages] 🔄 Chat ID changed, loading messages');
      _loadMessages();
    } else if (oldWidget.chat?.messages.length != widget.chat?.messages.length) {
      print('[ChatMessages] 🔄 Message count changed, reloading');
      _loadMessages();
    } else if (widget.chat != null && oldWidget.chat != null &&
              widget.chat!.messages.isNotEmpty && 
              oldWidget.chat!.messages.isNotEmpty &&
              oldWidget.chat!.messages.last.content != widget.chat!.messages.last.content) {
      print('[ChatMessages] 🔄 Message content changed, reloading');
      _loadMessages();
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
    print('[ChatMessages] 📥 Loading messages from chat widget...');
    print('[ChatMessages] 📥 Chat object: ${widget.chat}');
    print('[ChatMessages] 📥 Chat messages count: ${widget.chat?.messages.length ?? 0}');
    setState(() {
      _messages = widget.chat?.messages ?? [];
      print('[ChatMessages] 📥 Messages loaded: ${_messages.length}');
    });
  }

  void _addUserMessage(String content) {
    print('[ChatMessages] Adding user message: $content');
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      isComplete: true,
    );
    
    setState(() {
      _messages.add(userMessage);
      print('[ChatMessages] User message added to state, total messages: ${_messages.length}');
    });
    
    // Notify parent to handle AI response
    print('[ChatMessages] Notifying parent about new message');
    widget.onSendMessage(content);
  }

  void _addAssistantMessage() {
    print('[ChatMessages] 🚀 Creating assistant message placeholder');
    
    setState(() {
      // Новое состояние - ожидание ответа
      _isWaitingForResponse = true;
      _isStreaming = false;
      print('[ChatMessages] ✅ Waiting for response animation shown: _isWaitingForResponse=$_isWaitingForResponse, _isStreaming=$_isStreaming');
      print('[ChatMessages] 📊 Messages count: ${_messages.length}, Total items: ${_messages.length + (_isWaitingForResponse ? 1 : 0)}');
    });
  }

  void _updateAssistantMessage(String content) {
    final displayLength = content.length > 50 ? 50 : content.length;
    print('[ChatMessages] 🌊 Updating assistant message with content: ${content.substring(0, displayLength)}...');
    
    setState(() {
      // Если это первое обновление (начало потока), переключаемся с анимации на сообщение
      if (_isWaitingForResponse) {
        print('[ChatMessages] 🎉 First update received! Switching from waiting animation to streaming message');
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
        print('[ChatMessages] ✅ Added first message to stream: _isWaitingForResponse=$_isWaitingForResponse, _isStreaming=$_isStreaming');
      } else if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
        // Обновляем существующее сообщение
        _messages.last = _messages.last.copyWith(content: content);
        print('[ChatMessages] ✏️ Assistant message updated, content length: ${content.length}');
      } else {
        print('[ChatMessages] ⚠️ WARNING: No assistant message to update');
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
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Анимация "три точки" без аватара
          Container(
            constraints: const BoxConstraints(
              maxWidth: 120,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkTheme ? Color(0xFF2A2A2A) : Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpinKitThreeBounce(
                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                  size: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToAI(String userMessage) async {
    print('[ChatMessages] 🚀 Starting _sendToAI with message: $userMessage');
    _addAssistantMessage();
    
    try {
      print('[ChatMessages] 🌊 Calling streamChatCompletion...');
      await widget.openRouterService.streamChatCompletion(
        messages: [
          ..._messages
            .where((msg) => msg.role != MessageRole.assistant || !msg.isComplete)
            .map((msg) => {
              'role': msg.role.name,
              'content': msg.content,
            })
            .toList(),
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
      _updateAssistantMessage("Извините, произошла ошибка при обработке запроса. Пожалуйста, попробуйте еще раз.");
      _completeAssistantMessage();
    }
  }

  void _handleDeleteMessage(Message message) async {
    print('[ChatMessages] 🗑️ Deleting message: ${message.id}');
    
    final bool deleted = await MessageUtils.deleteMessage(
      chatId: widget.chat?.id ?? '',
      messageId: message.id,
      chatStorageService: widget.chatStorageService,
      context: context,
    );
    
    if (deleted) {
      // Сообщение успешно удалено из базы данных
      print('[ChatMessages] ✅ Message deleted from database, refreshing UI...');
      
      // Удаляем сообщение из локального списка
      setState(() {
        _messages.remove(message);
        print('[ChatMessages] 📱 UI updated, now ${_messages.length} messages in local list');
      });
      
      // Сообщаем родительскому компоненту
      widget.onMessageDeleted();
    } else {
      print('[ChatMessages] ❌ Failed to delete message from database');
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
                print('[ChatMessages] 📋 Rendering item $index of ${_messages.length} | _isWaitingForResponse=$_isWaitingForResponse | _isStreaming=$_isStreaming');
                
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
                  print('[ChatMessages] 🎯 Showing waiting animation for empty assistant message at index $index');
                  return _buildWaitingAnimation();
                }
                
                return ChatMsg.ChatMessage(
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
