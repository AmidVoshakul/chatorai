import 'package:flutter_test/flutter_test.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';

void main() {
  // Simple test to verify message models work correctly
  test('Message model creates correctly', () {
    final message = Message(
      id: 'test-msg',
      content: 'Test message content',
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    expect(message.id, equals('test-msg'));
    expect(message.content, equals('Test message content'));
    expect(message.role, equals(MessageRole.user));
    expect(message.timestamp, isInstanceOf<DateTime>());

    print('✅ Message model test passed');
  });

  test('Chat model creates correctly', () {
    final messages = [
      Message(
        id: 'msg1',
        content: 'First message',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
      Message(
        id: 'msg2',
        content: 'Second message',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    ];

    final chat = Chat(
      id: 'test-chat',
      title: 'Test Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: messages,
    );

    expect(chat.id, equals('test-chat'));
    expect(chat.title, equals('Test Chat'));
    expect(chat.messages.length, equals(2));
    expect(chat.messages.first.id, equals('msg1'));

    print('✅ Chat model test passed');
  });

  // Test message deletion logic without database
  test('Message deletion from list works correctly', () {
    final messages = [
      Message(
        id: 'msg1',
        content: 'First message',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
      Message(
        id: 'msg2',
        content: 'Second message',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
      Message(
        id: 'msg3',
        content: 'Third message',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
    ];

    // Simulate deletion of msg2
    final updatedMessages = messages.where((message) => message.id != 'msg2').toList();

    expect(updatedMessages.length, equals(2));
    expect(updatedMessages.first.id, equals('msg1'));
    expect(updatedMessages.last.id, equals('msg3'));

    print('✅ Message deletion from list test passed');
  });
}