import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_models.dart';

void main() {
  group('Message Model Tests', () {
    test('creates message with auto-generated ID', () {
      final message = Message(
        role: MessageRole.user,
        content: 'Hello world',
        timestamp: DateTime(2025, 12, 27, 10, 0, 0),
      );

      expect(message.id, isNotNull);
      expect(message.id, isNotEmpty);
      expect(message.role, MessageRole.user);
      expect(message.content, 'Hello world');
      expect(message.isComplete, false);
      expect(message.isError, false);
    });

    test('creates message with custom ID', () {
      final message = Message(
        id: 'custom-id-123',
        role: MessageRole.assistant,
        content: 'Response',
        timestamp: DateTime(2025, 12, 27, 10, 0, 0),
        isComplete: true,
      );

      expect(message.id, 'custom-id-123');
      expect(message.role, MessageRole.assistant);
      expect(message.isComplete, true);
    });

    test('creates message with reasoning', () {
      final message = Message(
        role: MessageRole.assistant,
        content: 'Final answer',
        reasoning: 'Step-by-step reasoning',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(message.reasoning, 'Step-by-step reasoning');
      expect(message.content, 'Final answer');
    });

    test('creates message with image data', () {
      final message = Message(
        role: MessageRole.user,
        content: 'What is in this image?',
        imageData: 'base64encodeddata',
        imageType: 'image/jpeg',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(message.imageData, 'base64encodeddata');
      expect(message.imageType, 'image/jpeg');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Original content',
        timestamp: DateTime(2025, 12, 27, 10, 0, 0),
        isComplete: false,
      );

      final updated = original.copyWith(
        content: 'Updated content',
        isComplete: true,
      );

      expect(updated.id, original.id);
      expect(updated.role, original.role);
      expect(updated.content, 'Updated content');
      expect(updated.timestamp, original.timestamp);
      expect(updated.isComplete, true);
      expect(updated.isError, false);
    });

    test('copyWith preserves all fields when no parameters provided', () {
      final original = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: 'Test',
        timestamp: DateTime(2025, 12, 27, 10, 0, 0),
        isComplete: true,
        isError: false,
        model: 'gpt-4',
        reasoning: 'Thinking...',
        imageData: 'data',
        imageType: 'png',
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.role, original.role);
      expect(copy.content, original.content);
      expect(copy.timestamp, original.timestamp);
      expect(copy.isComplete, original.isComplete);
      expect(copy.isError, original.isError);
      expect(copy.model, original.model);
      expect(copy.reasoning, original.reasoning);
      expect(copy.imageData, original.imageData);
      expect(copy.imageType, original.imageType);
    });

    test('equality works correctly', () {
      final timestamp = DateTime(2025, 12, 27, 10, 0, 0);
      final msg1 = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Test',
        timestamp: timestamp,
        isComplete: true,
      );
      final msg2 = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Test',
        timestamp: timestamp,
        isComplete: true,
      );
      final msg3 = Message(
        id: 'msg-2',
        role: MessageRole.user,
        content: 'Test',
        timestamp: timestamp,
        isComplete: true,
      );

      expect(msg1 == msg2, true);
      expect(msg1 == msg3, false);
    });

    test('hash code is consistent', () {
      final timestamp = DateTime(2025, 12, 27, 10, 0, 0);
      final msg1 = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Test',
        timestamp: timestamp,
        isComplete: true,
      );
      final msg2 = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Test',
        timestamp: timestamp,
        isComplete: true,
      );

      expect(msg1.hashCode, msg2.hashCode);
    });

    test('MessageRole enum has correct display names', () {
      expect(MessageRole.user.displayName, 'You');
      expect(MessageRole.assistant.displayName, 'AI');
      expect(MessageRole.system.displayName, 'System');
    });

    test('MessageRole enum has correct colors', () {
      expect(MessageRole.user.color, Colors.blue);
      expect(MessageRole.assistant.color, Colors.green);
      expect(MessageRole.system.color, Colors.orange);
    });

    test('message with error flag', () {
      final errorMessage = Message(
        role: MessageRole.assistant,
        content: 'Error occurred',
        timestamp: DateTime.now(),
        isComplete: true,
        isError: true,
      );

      expect(errorMessage.isError, true);
      expect(errorMessage.content, 'Error occurred');
    });

    test('message with model name', () {
      final assistantMessage = Message(
        role: MessageRole.assistant,
        content: 'Response',
        timestamp: DateTime.now(),
        isComplete: true,
        model: 'gpt-4-turbo',
      );

      expect(assistantMessage.model, 'gpt-4-turbo');
    });

    test('empty content message', () {
      final message = Message(
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isComplete: false,
      );

      expect(message.content, '');
      expect(message.isComplete, false);
    });

    test('long content message', () {
      final longContent = 'A' * 10000;
      final message = Message(
        role: MessageRole.assistant,
        content: longContent,
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(message.content.length, 10000);
      expect(message.isComplete, true);
    });

    test('message with all optional fields', () {
      final timestamp = DateTime(2025, 12, 27, 10, 0, 0);
      final message = Message(
        id: 'full-msg',
        role: MessageRole.assistant,
        content: 'Full response',
        timestamp: timestamp,
        isComplete: true,
        isError: false,
        model: 'gpt-4',
        reasoning: 'This is the reasoning',
        imageData: 'base64data',
        imageType: 'image/png',
      );

      expect(message.id, 'full-msg');
      expect(message.role, MessageRole.assistant);
      expect(message.content, 'Full response');
      expect(message.timestamp, timestamp);
      expect(message.isComplete, true);
      expect(message.isError, false);
      expect(message.model, 'gpt-4');
      expect(message.reasoning, 'This is the reasoning');
      expect(message.imageData, 'base64data');
      expect(message.imageType, 'image/png');
    });
  });
}
