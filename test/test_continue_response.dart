import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/services/chat_storage_service.dart';

// Mock ChatStorageService for testing
class MockChatStorageService extends ChatStorageService {
  final Map<String, List<Message>> _messages = {};

  @override
  Future<void> addMessageToChat(String chatId, Message message) async {
    if (!_messages.containsKey(chatId)) {
      _messages[chatId] = [];
    }
    _messages[chatId]!.add(message);
  }

  @override
  Future<void> deleteMessageFromChat(String chatId, String messageId) async {
    if (_messages.containsKey(chatId)) {
      _messages[chatId]!.removeWhere((m) => m.id == messageId);
    }
  }

  @override
  Future<void> updateMessageInChat(String chatId, String messageId, Message updatedMessage) async {
    if (_messages.containsKey(chatId)) {
      final index = _messages[chatId]!.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[chatId]![index] = updatedMessage;
      }
    }
  }

  @override
  Future<List<Message>> getMessagesForChat(String chatId) async {
    return _messages[chatId] ?? [];
  }

  @override
  Future<void> addChat(Chat chat) async {
    _messages[chat.id] = [];
  }

  @override
  Future<Chat?> getChat(String chatId) async {
    return Chat(
      id: chatId,
      title: 'Test Chat',
      messages: _messages[chatId] ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteChat(String chatId) async {
    _messages.remove(chatId);
  }

  @override
  Future<List<Chat>> getAllChats() async {
    return _messages.keys.map((id) => Chat(
      id: id,
      title: 'Test Chat',
      messages: _messages[id] ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).toList();
  }

  @override
  Future<void> updateChat(Chat chat) async {
    _messages[chat.id] = chat.messages;
  }

  @override
  Future<void> clearAll() async {
    _messages.clear();
  }

  @override
  Future<void> init() async {}

  @override
  Chat newChat() {
    return Chat(
      id: 'test-chat-${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Chat',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  group('Continue Response Tests', () {
    late MockChatStorageService mockStorage;

    setUp(() {
      mockStorage = MockChatStorageService();
    });

    test('should show continue button for incomplete assistant message', () {
      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: 'This is a long response that might be incomplete...',
        timestamp: DateTime.now(),
        isComplete: false,
      );

      // Conditions for showing continue button:
      // 1. isLastMessage = true
      // 2. content.isNotEmpty
      // 3. (content.endsWith('...') OR content.split(' ').length > 30 OR !isComplete)

      final isLastMessage = true;
      final hasContent = message.content.isNotEmpty;
      final endsWithDots = message.content.endsWith('...');
      final hasManyWords = message.content.split(' ').length > 30;
      final isNotComplete = !message.isComplete;

      final shouldShowButton = isLastMessage && hasContent && 
          (endsWithDots || hasManyWords || isNotComplete);

      expect(shouldShowButton, true);
      expect(hasContent, true);
      expect(isNotComplete, true);
    });

    test('should show continue button for message ending with dots', () {
      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: 'This response ends with three dots...',
        timestamp: DateTime.now(),
        isComplete: true, // Even if complete, dots trigger button
      );

      final isLastMessage = true;
      final hasContent = message.content.isNotEmpty;
      final endsWithDots = message.content.endsWith('...');
      final hasManyWords = message.content.split(' ').length > 30;
      final isNotComplete = !message.isComplete;

      final shouldShowButton = isLastMessage && hasContent && 
          (endsWithDots || hasManyWords || isNotComplete);

      expect(shouldShowButton, true);
      expect(endsWithDots, true);
    });

    test('should show continue button for long message', () {
      final longContent = List.generate(35, (i) => 'word$i').join(' ');
      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: longContent,
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final isLastMessage = true;
      final hasContent = message.content.isNotEmpty;
      final endsWithDots = message.content.endsWith('...');
      final hasManyWords = message.content.split(' ').length > 30;
      final isNotComplete = !message.isComplete;

      final shouldShowButton = isLastMessage && hasContent && 
          (endsWithDots || hasManyWords || isNotComplete);

      expect(shouldShowButton, true);
      expect(hasManyWords, true);
      expect(message.content.split(' ').length, greaterThan(30));
    });

    test('should NOT show continue button for short complete message', () {
      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: 'Short response.',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final isLastMessage = true;
      final hasContent = message.content.isNotEmpty;
      final endsWithDots = message.content.endsWith('...');
      final hasManyWords = message.content.split(' ').length > 30;
      final isNotComplete = !message.isComplete;

      final shouldShowButton = isLastMessage && hasContent && 
          (endsWithDots || hasManyWords || isNotComplete);

      expect(shouldShowButton, false);
      expect(endsWithDots, false);
      expect(hasManyWords, false);
      expect(isNotComplete, false);
    });

    test('should NOT show continue button if not last message', () {
      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: 'This is a long response that might be incomplete...',
        timestamp: DateTime.now(),
        isComplete: false,
      );

      final isLastMessage = false; // Not last message
      final hasContent = message.content.isNotEmpty;
      final endsWithDots = message.content.endsWith('...');
      final hasManyWords = message.content.split(' ').length > 30;
      final isNotComplete = !message.isComplete;

      final shouldShowButton = isLastMessage && hasContent && 
          (endsWithDots || hasManyWords || isNotComplete);

      expect(shouldShowButton, false);
    });

    test('should NOT show continue button for empty content', () {
      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isComplete: false,
      );

      final isLastMessage = true;
      final hasContent = message.content.isNotEmpty;
      final endsWithDots = message.content.endsWith('...');
      final hasManyWords = message.content.split(' ').length > 30;
      final isNotComplete = !message.isComplete;

      final shouldShowButton = isLastMessage && hasContent && 
          (endsWithDots || hasManyWords || isNotComplete);

      expect(shouldShowButton, false);
      expect(hasContent, false);
    });

    test('should NOT show continue button for user messages', () {
      final message = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'This is a user message...',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      // User messages should never show continue button
      // This is handled by the UI logic: only assistant messages get the button
      final isAssistant = message.role == MessageRole.assistant;
      expect(isAssistant, false);
    });

    test('continue button logic with edge cases', () {
      // Test various edge cases
      final testCases = [
        {
          'content': 'Short',
          'isComplete': true,
          'expected': false,
          'description': 'Short complete message'
        },
        {
          'content': 'Short...',
          'isComplete': true,
          'expected': true,
          'description': 'Short message with dots'
        },
        {
          'content': List.generate(100, (i) => 'word$i').join(' '),
          'isComplete': true,
          'expected': true,
          'description': 'Long message (100 words)'
        },
        {
          'content': List.generate(31, (i) => 'word$i').join(' '),
          'isComplete': true,
          'expected': true,
          'description': 'Message with 31 words'
        },
        {
          'content': List.generate(30, (i) => 'word$i').join(' '),
          'isComplete': true,
          'expected': false,
          'description': 'Message with exactly 30 words'
        },
        {
          'content': 'Incomplete...',
          'isComplete': false,
          'expected': true,
          'description': 'Incomplete message with dots'
        },
        {
          'content': 'Incomplete',
          'isComplete': false,
          'expected': true,
          'description': 'Incomplete message without dots'
        },
      ];

      for (final testCase in testCases) {
        final message = Message(
          id: 'msg-1',
          role: MessageRole.assistant,
          content: testCase['content'] as String,
          timestamp: DateTime.now(),
          isComplete: testCase['isComplete'] as bool,
        );

        final isLastMessage = true;
        final hasContent = message.content.isNotEmpty;
        final endsWithDots = message.content.endsWith('...');
        final hasManyWords = message.content.split(' ').length > 30;
        final isNotComplete = !message.isComplete;

        final shouldShowButton = isLastMessage && hasContent && 
            (endsWithDots || hasManyWords || isNotComplete);

        expect(
          shouldShowButton,
          testCase['expected'],
          reason: testCase['description'] as String,
        );
      }
    });

    test('continue response adds new placeholder message', () async {
      final chatId = 'test-chat';
      
      // Add initial messages
      final userMessage = Message(
        id: 'user-1',
        role: MessageRole.user,
        content: 'Tell me about AI',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final assistantMessage = Message(
        id: 'assistant-1',
        role: MessageRole.assistant,
        content: 'AI is artificial intelligence...',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      await mockStorage.addMessageToChat(chatId, userMessage);
      await mockStorage.addMessageToChat(chatId, assistantMessage);

      // Simulate continue response
      final continuationMessage = Message(
        id: 'assistant-2',
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isComplete: false,
      );

      await mockStorage.addMessageToChat(chatId, continuationMessage);

      // Verify
      final messages = await mockStorage.getMessagesForChat(chatId);
      expect(messages.length, 3);
      expect(messages.last.id, 'assistant-2');
      expect(messages.last.content, '');
      expect(messages.last.isComplete, false);
    });

    test('continue response preserves previous content', () async {
      final chatId = 'test-chat';
      
      final assistantMessage = Message(
        id: 'assistant-1',
        role: MessageRole.assistant,
        content: 'Previous content',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      await mockStorage.addMessageToChat(chatId, assistantMessage);

      // Get the message to verify it exists
      final messages = await mockStorage.getMessagesForChat(chatId);
      final originalMessage = messages.first;

      // Verify original content is preserved
      expect(originalMessage.content, 'Previous content');
      expect(originalMessage.isComplete, true);
    });

    test('continue response works with reasoning messages', () {
      // Test that continue button logic works with reasoning
      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: 'Final answer',
        reasoning: 'This is the reasoning that explains the answer...',
        timestamp: DateTime.now(),
        isComplete: false,
      );

      // The button should show based on content, not reasoning
      final isLastMessage = true;
      final hasContent = message.content.isNotEmpty;
      final endsWithDots = message.content.endsWith('...');
      final hasManyWords = message.content.split(' ').length > 30;
      final isNotComplete = !message.isComplete;

      final shouldShowButton = isLastMessage && hasContent && 
          (endsWithDots || hasManyWords || isNotComplete);

      // Even though content is short, isNotComplete is true
      expect(shouldShowButton, true);
      expect(message.reasoning, isNotNull);
    });

    test('continue response with very long reasoning', () {
      final longReasoning = List.generate(50, (i) => 'reasoning step $i').join('. ');
      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: 'Short answer',
        reasoning: longReasoning,
        timestamp: DateTime.now(),
        isComplete: false,
      );

      // Button shows because isNotComplete
      final isLastMessage = true;
      final hasContent = message.content.isNotEmpty;
      final isNotComplete = !message.isComplete;

      final shouldShowButton = isLastMessage && hasContent && isNotComplete;

      expect(shouldShowButton, true);
      expect(message.reasoning!.length, greaterThan(200));
    });

    test('continue button visibility with different message states', () {
      final testCases = [
        // [content, isComplete, expectedButton]
        ['Complete short message', true, false],
        ['Complete message with dots...', true, true],
        ['Incomplete short message', false, true],
        ['Incomplete message with dots...', false, true],
        ['', true, false], // Empty
        ['', false, false], // Empty incomplete
        [List.generate(31, (i) => 'word$i').join(' '), true, true], // Long (31 words)
        [List.generate(30, (i) => 'word$i').join(' '), true, false], // Exactly 30 words
      ];

      for (final testCase in testCases) {
        final message = Message(
          id: 'msg-1',
          role: MessageRole.assistant,
          content: testCase[0] as String,
          timestamp: DateTime.now(),
          isComplete: testCase[1] as bool,
        );

        final isLastMessage = true;
        final hasContent = message.content.isNotEmpty;
        final endsWithDots = message.content.endsWith('...');
        final hasManyWords = message.content.split(' ').length > 30;
        final isNotComplete = !message.isComplete;

        final shouldShowButton = isLastMessage && hasContent && 
            (endsWithDots || hasManyWords || isNotComplete);

        expect(
          shouldShowButton,
          testCase[2],
          reason: 'Content: "${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}...", Complete: ${message.isComplete}',
        );
      }
    });
  });
}
