import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_message.dart' as ChatMsg;

class ChatMessages extends StatefulWidget {
  final Chat? chat;
  final OpenRouterService openRouterService;
  final String? selectedModel;
  final Function(String) onSendMessage; // Add callback for sending messages

  const ChatMessages({
    Key? key,
    required this.openRouterService,
    this.chat,
    this.selectedModel,
    required this.onSendMessage,
  }) : super(key: key);

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  late List<Message> _messages;
  bool _isStreaming = false;
  final ScrollController _scrollController = ScrollController();
  String _selectedModel = 'x-ai/grok-4.1-fast:free';

  @override
  void initState() {
    super.initState();
    print('[ChatMessages] 🎯 Initializing ChatMessages with chat: ${widget.chat?.id}, messages: ${widget.chat?.messages.length ?? 0}');
    _loadMessages();
    if (widget.selectedModel != null) {
      _selectedModel = widget.selectedModel!;
    }
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
    
    _scrollToBottom();
    // Notify parent to handle AI response
    print('[ChatMessages] Notifying parent about new message');
    widget.onSendMessage(content);
  }

  void _addAssistantMessage() {
    print('[ChatMessages] Creating assistant message placeholder');
    final assistantMessage = Message(
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isComplete: false,
    );
    
    setState(() {
      _messages.add(assistantMessage);
      _isStreaming = true;
      print('[ChatMessages] Assistant message placeholder added, streaming: $_isStreaming');
    });
    
    _scrollToBottom();
  }

  void _updateAssistantMessage(String content) {
    final displayLength = min(50, content.length);
    print('[ChatMessages] Updating assistant message with content: ${content.substring(0, displayLength)}...');
    if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
      setState(() {
        _messages.last = _messages.last.copyWith(content: content);
        print('[ChatMessages] Assistant message updated, content length: ${content.length}');
      });
    } else {
      print('[ChatMessages] WARNING: No assistant message to update');
    }
  }

  void _completeAssistantMessage() {
    if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
      setState(() {
        _messages.last = _messages.last.copyWith(isComplete: true);
        _isStreaming = false;
      });
    }
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
              itemCount: _messages.length + (_isStreaming ? 1 : 0),
              itemBuilder: (context, index) {
                print('[ChatMessages] 📋 Rendering item $index of ${_messages.length + (_isStreaming ? 1 : 0)}');
                if (index < _messages.length) {
                  final message = _messages[index];
                  final isLastMessage = index == _messages.length - 1;
                  
                  return ChatMsg.ChatMessage(
                    message: message,
                    isStreaming: _isStreaming && isLastMessage,
                    onRetry: () {
                      if (message.role == MessageRole.user) {
                        _sendToAI(message.content);
                      }
                    },
                  );
                } else {
                  // Streaming message placeholder
                  return Container();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
