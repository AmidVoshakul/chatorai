import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/data/repositories/chat_storage_service.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests to ensure ChatStorageService still works after deprecation.
///
/// ChatStorageService is marked @Deprecated in favor of SessionRepository,
/// but it must remain functional during the migration period.
void main() {
  group('ChatStorageService (deprecated) regression', () {
    late ChatStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = ChatStorageService();
    });

    test('can create chats', () async {
      final chat = storage.newChat();
      expect(chat.id, isNotNull);
      expect(chat.title, 'Новый чат');
      expect(chat.messages, isEmpty);

      await storage.addChat(chat);
      final retrieved = await storage.getChat(chat.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, chat.id);
    });

    test('can add messages to chats', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      final message = Message(
        role: MessageRole.user,
        content: 'Hello from regression test',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      await storage.addMessageToChat(chat.id, message);

      final retrieved = await storage.getChat(chat.id);
      expect(retrieved!.messages.length, 1);
      expect(retrieved.messages.first.content, 'Hello from regression test');
    });

    test('can update chats', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      final updatedChat = chat.copyWith(
        title: 'Updated Title',
        updatedAt: DateTime.now(),
      );
      await storage.updateChat(updatedChat);

      final retrieved = await storage.getChat(chat.id);
      expect(retrieved!.title, 'Updated Title');
    });

    test('can delete chats', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      await storage.deleteChat(chat.id);

      final retrieved = await storage.getChat(chat.id);
      expect(retrieved, isNull);
    });

    test('can rename chats', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      await storage.renameChat(chat.id, 'Renamed Chat');

      final retrieved = await storage.getChat(chat.id);
      expect(retrieved!.title, 'Renamed Chat');
    });

    test('can update messages in chats', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: 'Original',
        timestamp: DateTime.now(),
        isComplete: false,
      );
      await storage.addMessageToChat(chat.id, message);

      final updatedMessage = message.copyWith(
        content: 'Updated',
        isComplete: true,
      );
      await storage.updateMessageInChat(chat.id, message.id, updatedMessage);

      final retrieved = await storage.getChat(chat.id);
      expect(retrieved!.messages.first.content, 'Updated');
      expect(retrieved.messages.first.isComplete, true);
    });

    test('can delete messages from chats', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      final msg1 = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'First',
        timestamp: DateTime.now(),
        isComplete: true,
      );
      final msg2 = Message(
        id: 'msg-2',
        role: MessageRole.assistant,
        content: 'Second',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      await storage.addMessageToChat(chat.id, msg1);
      await storage.addMessageToChat(chat.id, msg2);
      await storage.deleteMessageFromChat(chat.id, 'msg-1');

      final retrieved = await storage.getChat(chat.id);
      expect(retrieved!.messages.length, 1);
      expect(retrieved.messages.first.id, 'msg-2');
    });

    test('getChats returns all chats sorted by updatedAt DESC', () async {
      final chat1 = storage.newChat();
      await storage.addChat(chat1);

      await Future.delayed(const Duration(milliseconds: 10));

      final chat2 = storage.newChat();
      await storage.addChat(chat2);

      final allChats = await storage.getChats();
      expect(allChats.length, 2);
      // Most recently updated first
      expect(allChats.first.id, chat2.id);
    });

    test('handles non-existent chat gracefully', () async {
      final chat = await storage.getChat('non-existent-id');
      expect(chat, isNull);
    });

    test('handles non-existent chat deletion gracefully', () async {
      // Should not throw
      await storage.deleteChat('non-existent-id');
    });

    test('handles non-existent message deletion gracefully', () async {
      final chat = storage.newChat();
      await storage.addChat(chat);

      // Should not throw
      await storage.deleteMessageFromChat(chat.id, 'non-existent-msg');

      final retrieved = await storage.getChat(chat.id);
      expect(retrieved!.messages, isEmpty);
    });

    test('handles empty storage gracefully', () async {
      final chats = await storage.getChats();
      expect(chats, isEmpty);
    });
  });
}
