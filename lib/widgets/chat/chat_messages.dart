import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_message.dart';

class ChatMessages extends StatefulWidget {
  const ChatMessages({Key? key}) : super(key: key);

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  late List<Message> _messages;
  bool _isStreaming = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Initialize with a welcome message
    _messages = [
      Message(
        role: MessageRole.assistant,
        content: 'Hello! I\'m your AI assistant. How can I help you today?',
        timestamp: DateTime.now(),
        isComplete: true,
      ),
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                if (index < _messages.length) {
                  final message = _messages[index];
                  final isLastMessage = index == _messages.length - 1;
                  
                  return ChatMessage(
                    message: message,
                    isStreaming: _isStreaming && isLastMessage,
                    onRetry: () {
                      // Handle retry
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
