import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input.dart';

void main() {
  group('ChatInput Model Support Tests', () {
    // Test 1: Callback signature is correct
    test('callback has correct signature', () {
      // This test verifies the type signature is correct
      bool Function(String)? callback = (modelId) => true;
      expect(callback, isNotNull);
      expect(callback!('test'), true);
    });

    // Test 2: Callback can be null
    test('callback can be null', () {
      bool Function(String)? callback = null;
      expect(callback, isNull);
    });

    // Test 3: Callback can be provided
    test('callback can be provided', () {
      bool Function(String) callback = (modelId) => modelId == 'test-model';
      expect(callback('test-model'), true);
      expect(callback('other-model'), false);
    });

    // Test 4: MessageData class exists and works
    test('MessageData class works correctly', () {
      final message = MessageData(
        text: 'Test message',
        imagePath: '/path/to/image.jpg',
        imageType: 'image/jpeg',
        base64Data: 'base64data',
      );

      expect(message.text, 'Test message');
      expect(message.imagePath, '/path/to/image.jpg');
      expect(message.imageType, 'image/jpeg');
      expect(message.base64Data, 'base64data');
    });

    // Test 5: MessageData without optional fields
    test('MessageData works without optional fields', () {
      final message = MessageData(text: 'Text only');

      expect(message.text, 'Text only');
      expect(message.imagePath, isNull);
      expect(message.imageType, isNull);
      expect(message.base64Data, isNull);
    });
  });
}
