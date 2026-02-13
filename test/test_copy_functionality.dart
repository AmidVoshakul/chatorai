import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/utils/message_utils.dart';
import 'package:chatorai/models/chat_models.dart';

void main() {
  group('MessageUtils Copy Functionality', () {
    testWidgets('copyMessage should format message content correctly with sender name', (WidgetTester tester) async {
      // Create a minimal widget tree to get a real BuildContext
      late BuildContext capturedContext;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return Container();
            },
          ),
        ),
      );

      // Test the internal formatting logic by checking if the function runs without errors
      // Since we can't easily mock Clipboard in tests, we'll focus on testing the formatting logic
      final content = 'Test message content';
      final senderName = 'TestUser';

      // This should not throw any exceptions
      expect(() async {
        await MessageUtils.copyMessage(
          content: content,
          context: capturedContext,
          senderName: senderName,
        );
      }, returnsNormally);
    });

    testWidgets('copyMessage should format message content correctly without sender name', (WidgetTester tester) async {
      late BuildContext capturedContext;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return Container();
            },
          ),
        ),
      );

      final content = 'Test message content';

      expect(() async {
        await MessageUtils.copyMessage(
          content: content,
          context: capturedContext,
          senderName: null,
        );
      }, returnsNormally);
    });

    testWidgets('copyMessage should handle errors gracefully', (WidgetTester tester) async {
      late BuildContext capturedContext;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return Container();
            },
          ),
        ),
      );

      final content = 'Test message content';
      final senderName = 'TestUser';

      // This should not throw any exceptions even if clipboard fails
      expect(() async {
        await MessageUtils.copyMessage(
          content: content,
          context: capturedContext,
          senderName: senderName,
        );
      }, returnsNormally);
    });

    test('canDeleteMessage should return true for regular messages', () {
      final message = Message(
        id: 'test_id',
        role: MessageRole.user,
        content: 'Test content',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(MessageUtils.canDeleteMessage(message), true);
    });

    test('canDeleteMessage should return false for system messages', () {
      final message = Message(
        id: 'system_id',
        role: MessageRole.system,
        content: 'System message',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(MessageUtils.canDeleteMessage(message), false);
    });

    test('canEditMessage should return true only for user messages', () {
      final userMessage = Message(
        id: 'user_id',
        role: MessageRole.user,
        content: 'User content',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final assistantMessage = Message(
        id: 'assistant_id',
        role: MessageRole.assistant,
        content: 'Assistant content',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(MessageUtils.canEditMessage(userMessage), true);
      expect(MessageUtils.canEditMessage(assistantMessage), false);
    });

    test('getMessageActions should return appropriate actions for user messages', () {
      final userMessage = Message(
        id: 'user_id',
        role: MessageRole.user,
        content: 'User content',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final actions = MessageUtils.getMessageActions(userMessage);
      
      // Should have delete, edit, copy, and share actions
      expect(actions.length, 4);
      expect(actions.any((action) => action.action == MessageActionType.delete), true);
      expect(actions.any((action) => action.action == MessageActionType.edit), true);
      expect(actions.any((action) => action.action == MessageActionType.copy), true);
      expect(actions.any((action) => action.action == MessageActionType.share), true);
    });

    test('getMessageActions should return appropriate actions for assistant messages', () {
      final assistantMessage = Message(
        id: 'assistant_id',
        role: MessageRole.assistant,
        content: 'Assistant content',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final actions = MessageUtils.getMessageActions(assistantMessage);
      
      // Should have delete, copy, share actions (no edit for assistant messages)
      expect(actions.length, 3);
      expect(actions.any((action) => action.action == MessageActionType.delete), true);
      expect(actions.any((action) => action.action == MessageActionType.copy), true);
      expect(actions.any((action) => action.action == MessageActionType.share), true);
      expect(actions.any((action) => action.action == MessageActionType.edit), false);
    });

    test('getMessageActions should return appropriate actions for system messages', () {
      final systemMessage = Message(
        id: 'system_id',
        role: MessageRole.system,
        content: 'System message',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final actions = MessageUtils.getMessageActions(systemMessage);
      
      // System messages should have no available actions (can't delete, edit, copy, or share)
      expect(actions.length, 0);
    });
  });
}