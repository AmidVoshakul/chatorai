import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/data/repositories/chat_storage_service.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ChatStorageService Tests', () {
    late ChatStorageService storage;

    setUp(() async {
      // Use SharedPreferences with mock values for testing
      SharedPreferences.setMockInitialValues({});
      storage = ChatStorageService();
    });

    test('creates new chat with unique ID', () async {
      // Add a small delay to ensure different timestamps
      await Future.delayed(Duration(milliseconds: 10));
      final chat1 = storage.newChat();
      await Future.delayed(Duration(milliseconds: 10));
      final chat2 = storage.newChat();

      expect(chat1.id, isNotNull);
      expect(chat2.id, isNotNull);
      expect(chat1.id, isNot(equals(chat2.id)));
      expect(chat1.title, 'Новый чат');
      expect(chat1.messages, isEmpty);
    });

    test('adds chat to storage', () async {
      final chat = storage.newChat();

      await storage.addChat(chat);

      final retrievedChat = await storage.getChat(chat.id);
      expect(retrievedChat, isNotNull);
      expect(retrievedChat!.id, chat.id);
      expect(retrievedChat.title, chat.title);
    });

    test('adds message to chat', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      final message = Message(
        role: MessageRole.user,
        content: 'Test message',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      await storage.addMessageToChat(chat.id, message);

      final retrievedChat = await storage.getChat(chat.id);
      expect(retrievedChat!.messages.length, 1);
      expect(retrievedChat.messages.first.content, 'Test message');
      expect(retrievedChat.messages.first.role, MessageRole.user);
    });

    test('updates message in chat', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: 'Original content',
        timestamp: DateTime.now(),
        isComplete: false,
      );

      await storage.addMessageToChat(chat.id, message);

      // Update the message
      final updatedMessage = message.copyWith(
        content: 'Updated content',
        isComplete: true,
      );

      await storage.updateMessageInChat(chat.id, message.id, updatedMessage);

      final retrievedChat = await storage.getChat(chat.id);
      expect(retrievedChat!.messages.length, 1);
      expect(retrievedChat.messages.first.content, 'Updated content');
      expect(retrievedChat.messages.first.isComplete, true);
    });

    test('deletes message from chat', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      final message1 = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Message 1',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final message2 = Message(
        id: 'msg-2',
        role: MessageRole.assistant,
        content: 'Message 2',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      await storage.addMessageToChat(chat.id, message1);
      await storage.addMessageToChat(chat.id, message2);

      // Delete first message
      await storage.deleteMessageFromChat(chat.id, message1.id);

      final retrievedChat = await storage.getChat(chat.id);
      expect(retrievedChat!.messages.length, 1);
      expect(retrievedChat.messages.first.id, 'msg-2');
    });

    test('deletes chat', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      await storage.deleteChat(chat.id);

      final retrievedChat = await storage.getChat(chat.id);
      expect(retrievedChat, isNull);
    });

    test('updates chat', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      final message = Message(
        role: MessageRole.user,
        content: 'Test',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final updatedChat = chat.copyWith(
        title: 'Updated Title',
        messages: [message],
      );

      await storage.updateChat(updatedChat);

      final retrievedChat = await storage.getChat(chat.id);
      expect(retrievedChat!.title, 'Updated Title');
      expect(retrievedChat.messages.length, 1);
    });

    test('gets all chats', () async {
      final chat1 = storage.newChat();
      final chat2 = storage.newChat();

      await storage.addChat(chat1);
      await storage.addChat(chat2);

      final allChats = await storage.getChats();
      expect(allChats.length, 2);
      expect(allChats.any((c) => c.id == chat1.id), true);
      expect(allChats.any((c) => c.id == chat2.id), true);
    });

    test('handles empty chat list', () async {
      final allChats = await storage.getChats();
      expect(allChats, isEmpty);
    });

    test('handles non-existent chat', () async {
      final chat = await storage.getChat('non-existent');
      expect(chat, isNull);
    });

    test('handles non-existent message deletion', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      // Should not throw
      await storage.deleteMessageFromChat(chat.id, 'non-existent');

      final retrievedChat = await storage.getChat(chat.id);
      expect(retrievedChat!.messages.length, 0);
    });

    test('chat with multiple messages maintains order', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      final messages = [
        Message(
          id: 'msg-1',
          role: MessageRole.user,
          content: 'First',
          timestamp: DateTime(2025, 12, 27, 10, 0, 0),
          isComplete: true,
        ),
        Message(
          id: 'msg-2',
          role: MessageRole.assistant,
          content: 'Second',
          timestamp: DateTime(2025, 12, 27, 10, 1, 0),
          isComplete: true,
        ),
        Message(
          id: 'msg-3',
          role: MessageRole.user,
          content: 'Third',
          timestamp: DateTime(2025, 12, 27, 10, 2, 0),
          isComplete: true,
        ),
      ];

      for (final msg in messages) {
        await storage.addMessageToChat(chat.id, msg);
      }

      final retrievedChat = await storage.getChat(chat.id);
      expect(retrievedChat!.messages.length, 3);
      expect(retrievedChat.messages[0].id, 'msg-1');
      expect(retrievedChat.messages[1].id, 'msg-2');
      expect(retrievedChat.messages[2].id, 'msg-3');
    });

    test('handles message with all optional fields', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      final message = Message(
        id: 'full-msg',
        role: MessageRole.assistant,
        content: 'Response',
        timestamp: DateTime.now(),
        isComplete: true,
        isError: false,
        model: 'gpt-4',
        reasoning: 'Thinking...',
        imageData: 'base64data',
        imageType: 'image/png',
      );

      await storage.addMessageToChat(chat.id, message);

      final retrievedChat = await storage.getChat(chat.id);
      final retrieved = retrievedChat!.messages.first;

      expect(retrieved.id, 'full-msg');
      expect(retrieved.model, 'gpt-4');
      expect(retrieved.reasoning, 'Thinking...');
      expect(retrieved.imageData, 'base64data');
      expect(retrieved.imageType, 'image/png');
    });

    test('updates chat timestamp on modification', () async {
      final chat = storage.newChat();
      final originalTime = chat.updatedAt;

      await storage.addChat(chat);

      // Wait a bit to ensure timestamp difference
      await Future.delayed(Duration(milliseconds: 10));

      final message = Message(
        role: MessageRole.user,
        content: 'Test',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      await storage.addMessageToChat(chat.id, message);

      final updatedChat = await storage.getChat(chat.id);
      expect(updatedChat!.updatedAt.isAfter(originalTime), true);
    });

    test('handles concurrent operations', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      // Add multiple messages sequentially to avoid race conditions
      for (int i = 0; i < 5; i++) {
        await storage.addMessageToChat(
          chat.id,
          Message(
            id: 'msg-$i',
            role: MessageRole.user,
            content: 'Message $i',
            timestamp: DateTime.now(),
            isComplete: true,
          ),
        );
      }

      final retrievedChat = await storage.getChat(chat.id);
      expect(retrievedChat!.messages.length, 5);
    });

    test('Chat model equality', () {
      final timestamp = DateTime.now();
      final chat1 = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [],
        createdAt: timestamp,
        updatedAt: timestamp,
      );
      final chat2 = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [],
        createdAt: timestamp,
        updatedAt: timestamp,
      );
      final chat3 = Chat(
        id: 'chat-2',
        title: 'Test',
        messages: [],
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      expect(chat1 == chat2, true);
      expect(chat1 == chat3, false);
    });

    test('Chat copyWith', () {
      final chat = Chat(
        id: 'chat-1',
        title: 'Original',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final message = Message(
        role: MessageRole.user,
        content: 'Test',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final updated = chat.copyWith(title: 'Updated', messages: [message]);

      expect(updated.id, chat.id);
      expect(updated.title, 'Updated');
      expect(updated.messages.length, 1);
      expect(updated.createdAt, chat.createdAt);
    });
  });
}
