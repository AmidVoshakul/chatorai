import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/data/models/chat/message_converter.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';

void main() {
  group('message_converter', () {
    test('converts user message with imageData and imageType', () {
      final legacy = Message(
        role: MessageRole.user,
        content: 'Check this image',
        timestamp: DateTime(2025, 6, 1),
        isComplete: true,
        imageData: 'base64encodeddata',
        imageType: 'image/jpeg',
      );

      final converted = messageToChatMessage(legacy) as UserMessage;

      expect(converted.content, 'Check this image');
      expect(converted.imageData, 'base64encodeddata');
      expect(converted.imageType, 'image/jpeg');
    });

    test('converts user message with attachedDocPath', () {
      final legacy = Message(
        role: MessageRole.user,
        content: 'Read this doc',
        timestamp: DateTime(2025, 6, 1),
        isComplete: true,
        attachedDocPath: '/home/user/.local/share/chatorai/attachments/123_report.pdf',
      );

      final converted = messageToChatMessage(legacy) as UserMessage;

      expect(converted.content, 'Read this doc');
      expect(converted.attachedDocPath, '/home/user/.local/share/chatorai/attachments/123_report.pdf');
      expect(converted.attachedDocName, '123_report.pdf');
    });

    test('converts user message with attachedDocPath on linux path', () {
      final legacy = Message(
        role: MessageRole.user,
        content: 'Analyze this file',
        timestamp: DateTime(2025, 6, 1),
        isComplete: true,
        attachedDocPath: '/home/user/.local/share/chatorai/attachments/456_document.docx',
      );

      final converted = messageToChatMessage(legacy) as UserMessage;

      expect(converted.attachedDocName, '456_document.docx');
    });

    test('converts user message without image or doc', () {
      final legacy = Message(
        role: MessageRole.user,
        content: 'Just text',
        timestamp: DateTime(2025, 6, 1),
        isComplete: true,
      );

      final converted = messageToChatMessage(legacy) as UserMessage;

      expect(converted.content, 'Just text');
      expect(converted.imageData, isNull);
      expect(converted.imageType, isNull);
      expect(converted.attachedDocPath, isNull);
      expect(converted.attachedDocName, isNull);
    });

    test('attachedDocName uses p.basename for cross-platform safety', () {
      // Simulate a Windows path (p.join normalizes to / on all platforms)
      final legacy = Message(
        role: MessageRole.user,
        content: 'test',
        timestamp: DateTime(2025, 6, 1),
        isComplete: true,
        attachedDocPath: 'C:/Users/user/chatorai/attachments/doc.pdf',
      );

      final converted = messageToChatMessage(legacy) as UserMessage;

      // p.basename handles both / and \ separators
      expect(converted.attachedDocName, 'doc.pdf');
    });

    test('toJson/fromJson roundtrip preserves imageData and attachedDocPath', () {
      final original = UserMessage(
        id: 'test-msg-1',
        content: 'Hello with attachment',
        imageData: 'base64img',
        imageType: 'image/png',
        attachedDocName: 'doc.pdf',
        attachedDocPath: '/path/to/doc.pdf',
        timestamp: DateTime(2025, 6, 1),
      );

      final json = original.toJson();
      final restored = UserMessage.fromJson(json);

      expect(restored.content, original.content);
      expect(restored.imageData, 'base64img');
      expect(restored.imageType, 'image/png');
      expect(restored.attachedDocName, 'doc.pdf');
      expect(restored.attachedDocPath, '/path/to/doc.pdf');
    });
  });
}
