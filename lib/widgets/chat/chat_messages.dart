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
    
    // Initialize with a welcome message and sample user message
    _messages = [
      Message(
        role: MessageRole.assistant,
        content: '''## Modern Chat Interface Design 🎨

Here are the current **design trends** and **best practices** for chat interfaces:

### Key Design Principles

1. **Clean Typography**
   - Use readable fonts like **Roboto**, **Inter**, or **SF Pro**
   - Maintain proper line height (1.4-1.6)
   - Ensure adequate font size (14-16px for body text)

2. **Visual Hierarchy**
   ```dart
   // Example message bubble styling
   BoxDecoration(
     borderRadius: BorderRadius.circular(12),
     color: Colors.blue.withOpacity(0.1),
     boxShadow: [
       BoxShadow(
         color: Colors.black.withOpacity(0.05),
         blurRadius: 5,
         offset: Offset(0, 2),
       ),
     ],
   )
   ```

3. **Consistent Spacing**
   - Use `EdgeInsets.all(16)` for message padding
   - Maintain `8-12px` margin between messages
   - Consistent border radius for rounded corners

### Modern Features

- **Real-time typing indicators** ⚡
- **Message reactions** (👍👎❤️✨🚀)
- **Threaded conversations** 🧵
- **Rich media support** (images, videos, files) 📸🎥📁
- **Voice messages** 🎙️
- **Dark/light theme support** 🌓

### Color Palette Comparison

| Theme | Primary | Background | Card | Text |
|-------|---------|------------|------|------|
| Light | #FF7F00 | #F8F9FA | #FFFFFF | #333333 |
| Dark | #FF7F00 | #0A0A0A | #1A1A1A | #E0E0E0 |

### Code Examples

```javascript
// JavaScript example
const messageBubble = {
  padding: '12px 16px',
  borderRadius: '12px',
  backgroundColor: 'rgba(0, 123, 255, 0.1)',
  marginBottom: '8px'
};
```

```css
/* CSS example */
.message-bubble {
  padding: 12px 16px;
  border-radius: 12px;
  background-color: rgba(0, 123, 255, 0.1); background-color: rgba(0, 123, 255, 0.1);
  margin-bottom: 8px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}
```

### Accessibility Considerations

- High contrast color schemes 🌈
- Screen reader compatibility 👂
- Keyboard navigation ⌨️
- Proper ARIA labels 🏷️

### Emoji Support Test 🎉

Here are some commonly used emojis in chat interfaces:
- Reactions: 👍👎❤️😂😢😡
- Status: ✅❌🔄⏳⏰
- Actions: 💬📞📧📷📹📍
- Objects: 📱💻📺⌚🔋🔋

Would you like me to elaborate on any specific aspect?''',
        timestamp: DateTime.now(),
        isComplete: true,
      ),
      Message(
        role: MessageRole.user,
        content: 'Hi! I need help with designing a modern chat interface. Can you provide some insights on current design trends and best practices?',
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
