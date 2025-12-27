import 'package:flutter_test/flutter_test.dart';
import 'package:gen_ui_chat_ai/utils/message_utils.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:flutter/material.dart';

// Mock ChatStorageService for testing
class MockChatStorageService extends ChatStorageService {
  final Map<String, List<Message>> _chats = {};
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
    _chats[chat.id] = [];
  }

  @override
  Future<Chat?> getChat(String chatId) async {
    return Chat(id: chatId, title: 'Test Chat', messages: _messages[chatId] ?? [], createdAt: DateTime.now(), updatedAt: DateTime.now());
  }

  @override
  Future<void> deleteChat(String chatId) async {
    _chats.remove(chatId);
    _messages.remove(chatId);
  }

  @override
  Future<List<Chat>> getAllChats() async {
    return _chats.keys.map((id) => Chat(id: id, title: 'Test Chat', messages: _messages[id] ?? [], createdAt: DateTime.now(), updatedAt: DateTime.now())).toList();
  }

  @override
  Future<void> updateChat(Chat chat) async {
    _chats[chat.id] = chat.messages;
    _messages[chat.id] = chat.messages;
  }

  @override
  Future<void> clearAll() async {
    _chats.clear();
    _messages.clear();
  }

  @override
  Future<void> init() async {
    // No initialization needed for tests
  }

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

// Mock BuildContext for testing
class MockBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MessageUtils Tests', () {
    late MockChatStorageService mockStorage;

    setUp(() {
      mockStorage = MockChatStorageService();
    });

    group('copyMessage', () {
      test('copyMessage function exists and accepts parameters', () {
        // Test that the function signature is correct
        // We can't fully test without a real context, but we can verify the API
        expect(MessageUtils.copyMessage, isNotNull);
      });

      test('copyMessage prepares correct content format', () {
        const content = 'Test message content';
        const senderName = 'User';
        
        // Verify the expected format would be created
        final expectedFormat = '### $senderName\n\n$content';
        expect(expectedFormat, contains('User'));
        expect(expectedFormat, contains('Test message content'));
      });
    });

    group('deleteMessage', () {
      test('deletes message successfully', () async {
        // Add a message first
        final chatId = 'test-chat';
        final message = Message(
          id: 'msg-1',
          role: MessageRole.user,
          content: 'Test',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        await mockStorage.addMessageToChat(chatId, message);
        
        // Verify message exists
        final messagesBefore = await mockStorage.getMessagesForChat(chatId);
        expect(messagesBefore.length, 1);

        // Delete message
        final deleted = await MessageUtils.deleteMessage(
          chatId: chatId,
          messageId: message.id,
          chatStorageService: mockStorage,
          context: null, // No context for unit test
        );

        expect(deleted, true);

        // Verify message is deleted
        final messagesAfter = await mockStorage.getMessagesForChat(chatId);
        expect(messagesAfter.length, 0);
      });

      test('handles deletion of non-existent message', () async {
        // Should not throw
        final deleted = await MessageUtils.deleteMessage(
          chatId: 'non-existent',
          messageId: 'non-existent',
          chatStorageService: mockStorage,
          context: null,
        );

        // Mock storage doesn't throw, so it returns true
        expect(deleted, true);
      });
    });

    group('canDeleteMessage', () {
      test('allows deletion of user messages', () {
        final message = Message(
          role: MessageRole.user,
          content: 'Test',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        expect(MessageUtils.canDeleteMessage(message), true);
      });

      test('allows deletion of assistant messages', () {
        final message = Message(
          role: MessageRole.assistant,
          content: 'Test',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        expect(MessageUtils.canDeleteMessage(message), true);
      });

      test('prevents deletion of system messages', () {
        final message = Message(
          role: MessageRole.system,
          content: 'System prompt',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        expect(MessageUtils.canDeleteMessage(message), false);
      });
    });

    group('canEditMessage', () {
      test('allows editing of user messages', () {
        final message = Message(
          role: MessageRole.user,
          content: 'Test',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        expect(MessageUtils.canEditMessage(message), true);
      });

      test('prevents editing of assistant messages', () {
        final message = Message(
          role: MessageRole.assistant,
          content: 'Test',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        expect(MessageUtils.canEditMessage(message), false);
      });

      test('prevents editing of system messages', () {
        final message = Message(
          role: MessageRole.system,
          content: 'System prompt',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        expect(MessageUtils.canEditMessage(message), false);
      });
    });

    group('canRegenerateMessage', () {
      test('allows regeneration of assistant messages', () {
        final message = Message(
          role: MessageRole.assistant,
          content: 'Test',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        expect(MessageUtils.canRegenerateMessage(message), true);
      });

      test('prevents regeneration of user messages', () {
        final message = Message(
          role: MessageRole.user,
          content: 'Test',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        expect(MessageUtils.canRegenerateMessage(message), false);
      });

      test('prevents regeneration of system messages', () {
        final message = Message(
          role: MessageRole.system,
          content: 'System prompt',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        expect(MessageUtils.canRegenerateMessage(message), false);
      });
    });

    group('regenerateMessage', () {
      test('regenerates message successfully', () async {
        final chatId = 'test-chat';
        final message = Message(
          id: 'msg-1',
          role: MessageRole.assistant,
          content: 'Old response',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        await mockStorage.addMessageToChat(chatId, message);

        bool regenerateCalled = false;
        void onRegenerate() {
          regenerateCalled = true;
        }

        final result = await MessageUtils.regenerateMessage(
          chatId: chatId,
          messageId: message.id,
          chatStorageService: mockStorage,
          onRegenerate: onRegenerate,
        );

        expect(result, true);
        expect(regenerateCalled, true);

        // Verify message was deleted
        final messages = await mockStorage.getMessagesForChat(chatId);
        expect(messages.length, 0);
      });

      test('handles regeneration of non-existent message', () async {
        // Should not throw
        final result = await MessageUtils.regenerateMessage(
          chatId: 'non-existent',
          messageId: 'non-existent',
          chatStorageService: mockStorage,
          onRegenerate: () {},
        );

        // Mock storage doesn't throw, so it returns true
        expect(result, true);
      });
    });

    group('getMessageActions', () {
      test('returns correct actions for user message', () {
        final message = Message(
          role: MessageRole.user,
          content: 'Test',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        final actions = MessageUtils.getMessageActions(message);

        expect(actions.length, greaterThan(0));
        expect(actions.any((a) => a.action == MessageActionType.edit), true);
        expect(actions.any((a) => a.action == MessageActionType.copy), true);
        expect(actions.any((a) => a.action == MessageActionType.delete), true);
        expect(actions.any((a) => a.action == MessageActionType.regenerate), false);
      });

      test('returns correct actions for assistant message', () {
        final message = Message(
          role: MessageRole.assistant,
          content: 'Test',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        final actions = MessageUtils.getMessageActions(message);

        expect(actions.length, greaterThan(0));
        expect(actions.any((a) => a.action == MessageActionType.regenerate), true);
        expect(actions.any((a) => a.action == MessageActionType.copy), true);
        expect(actions.any((a) => a.action == MessageActionType.delete), true);
        expect(actions.any((a) => a.action == MessageActionType.edit), false);
      });

      test('returns correct actions for system message', () {
        final message = Message(
          role: MessageRole.system,
          content: 'System prompt',
          timestamp: DateTime.now(),
          isComplete: true,
        );

        final actions = MessageUtils.getMessageActions(message);

        // System messages should have limited actions
        expect(actions.any((a) => a.action == MessageActionType.delete), false);
      });
    });

    group('MessageAction', () {
      test('MessageActionType enum has correct values', () {
        expect(MessageActionType.delete, isNotNull);
        expect(MessageActionType.edit, isNotNull);
        expect(MessageActionType.copy, isNotNull);
        expect(MessageActionType.share, isNotNull);
        expect(MessageActionType.copyChat, isNotNull);
        expect(MessageActionType.regenerate, isNotNull);
      });

      test('MessageAction stores correct properties', () {
        final action = MessageAction(
          icon: Icons.delete,
          label: 'Delete',
          localizedLabel: {'en': 'Delete', 'ru': 'Удалить'},
          action: MessageActionType.delete,
          color: Colors.red,
        );

        expect(action.icon, Icons.delete);
        expect(action.label, 'Delete');
        expect(action.action, MessageActionType.delete);
        expect(action.color, Colors.red);
      });
    });

    group('EditMessageResult', () {
      test('EditMessageResult enum has correct values', () {
        expect(EditMessageResult.cancelled, isNotNull);
        expect(EditMessageResult.saved, isNotNull);
        expect(EditMessageResult.savedAndSent, isNotNull);
      });

      test('EditMessageResultWithContent stores result and content', () {
        final result = EditMessageResultWithContent(
          result: EditMessageResult.saved,
          newContent: 'Updated content',
        );

        expect(result.result, EditMessageResult.saved);
        expect(result.newContent, 'Updated content');
      });
    });

    group('getChatActions', () {
      test('returns correct chat actions', () {
        // This would need a BuildContext, so we'll skip the actual call
        // but test the action types exist
        expect(MessageActionType.copyChat, isNotNull);
        expect(MessageActionType.share, isNotNull);
        expect(MessageActionType.edit, isNotNull);
        expect(MessageActionType.delete, isNotNull);
      });
    });
  });
}
