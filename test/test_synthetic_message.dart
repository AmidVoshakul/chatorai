import 'package:test/test.dart';
import 'package:chatorai/core/chat/chat_models.dart';

void main() {
  group('Message.synthetic', () {
    test('defaults to false', () {
      final message = Message(
        role: MessageRole.user,
        content: 'Hello',
        timestamp: DateTime.now(),
      );
      expect(message.synthetic, isFalse);
    });

    test('can be set to true via constructor', () {
      final message = Message(
        role: MessageRole.user,
        content: 'Synthetic',
        timestamp: DateTime.now(),
        synthetic: true,
      );
      expect(message.synthetic, isTrue);
    });

    test('copyWith preserves synthetic when not provided', () {
      final message = Message(
        role: MessageRole.user,
        content: 'Hello',
        timestamp: DateTime.now(),
        synthetic: false,
      );
      final copy = message.copyWith();
      expect(copy.synthetic, isFalse);
    });

    test('copyWith updates synthetic field to true', () {
      final message = Message(
        role: MessageRole.user,
        content: 'Hello',
        timestamp: DateTime.now(),
        synthetic: false,
      );
      final copy = message.copyWith(synthetic: true);
      expect(copy.synthetic, isTrue);
    });

    test('copyWith updates synthetic field to false', () {
      final message = Message(
        role: MessageRole.user,
        content: 'Synthetic',
        timestamp: DateTime.now(),
        synthetic: true,
      );
      final copy = message.copyWith(synthetic: false);
      expect(copy.synthetic, isFalse);
    });

    test('toJson preserves synthetic field when true', () {
      final message = Message(
        role: MessageRole.user,
        content: 'Synthetic',
        timestamp: DateTime.now(),
        synthetic: true,
      );
      final json = message.toJson();
      expect(json['synthetic'], isTrue);
    });

    test('toJson preserves synthetic field when false', () {
      final message = Message(
        role: MessageRole.user,
        content: 'Normal',
        timestamp: DateTime.now(),
        synthetic: false,
      );
      final json = message.toJson();
      expect(json['synthetic'], isFalse);
    });

    test('fromJson restores synthetic field when true', () {
      final json = {
        'id': '1',
        'role': 'user',
        'content': 'Synthetic',
        'timestamp': DateTime.now().toIso8601String(),
        'isComplete': true,
        'isError': false,
        'synthetic': true,
      };
      final message = Message.fromJson(json);
      expect(message.synthetic, isTrue);
    });

    test('fromJson defaults synthetic to false when missing', () {
      final json = {
        'id': '1',
        'role': 'user',
        'content': 'Normal',
        'timestamp': DateTime.now().toIso8601String(),
        'isComplete': true,
        'isError': false,
      };
      final message = Message.fromJson(json);
      expect(message.synthetic, isFalse);
    });

    test('roundtrip preserves synthetic true', () {
      final original = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Synthetic message',
        timestamp: DateTime(2024, 1, 1),
        synthetic: true,
      );
      final restored = Message.fromJson(original.toJson());
      expect(restored.synthetic, isTrue);
      expect(restored, equals(original));
    });

    test('roundtrip preserves synthetic false', () {
      final original = Message(
        id: 'msg-2',
        role: MessageRole.assistant,
        content: 'Normal message',
        timestamp: DateTime(2024, 1, 1),
        synthetic: false,
      );
      final restored = Message.fromJson(original.toJson());
      expect(restored.synthetic, isFalse);
      expect(restored, equals(original));
    });

    test('equality considers synthetic field', () {
      final msg1 = Message(
        role: MessageRole.user,
        content: 'Same',
        timestamp: DateTime.now(),
        synthetic: false,
      );
      final msg2 = Message(
        role: MessageRole.user,
        content: 'Same',
        timestamp: DateTime.now(),
        synthetic: true,
      );
      expect(msg1, isNot(equals(msg2)));
    });

    test('hashCode includes synthetic field', () {
      final msg1 = Message(
        role: MessageRole.user,
        content: 'Same',
        timestamp: DateTime.now(),
        synthetic: false,
      );
      final msg2 = Message(
        role: MessageRole.user,
        content: 'Same',
        timestamp: DateTime.now(),
        synthetic: true,
      );
      expect(msg1.hashCode, isNot(equals(msg2.hashCode)));
    });
  });

  group('chat messages synthetic filter', () {
    test('filters out synthetic messages from display list', () {
      final messages = [
        Message(
          id: '1',
          role: MessageRole.user,
          content: 'Normal',
          timestamp: DateTime.now(),
          synthetic: false,
        ),
        Message(
          id: '2',
          role: MessageRole.user,
          content: 'Synthetic',
          timestamp: DateTime.now(),
          synthetic: true,
        ),
        Message(
          id: '3',
          role: MessageRole.assistant,
          content: 'Another normal',
          timestamp: DateTime.now(),
          synthetic: false,
        ),
      ];

      final filtered = messages.where((m) => !m.synthetic).toList();
      expect(filtered.length, equals(2));
      expect(filtered.map((m) => m.id), equals(['1', '3']));
    });

    test('empty list when all messages are synthetic', () {
      final messages = [
        Message(
          id: '1',
          role: MessageRole.user,
          content: 'Syn1',
          timestamp: DateTime.now(),
          synthetic: true,
        ),
        Message(
          id: '2',
          role: MessageRole.user,
          content: 'Syn2',
          timestamp: DateTime.now(),
          synthetic: true,
        ),
      ];

      final filtered = messages.where((m) => !m.synthetic).toList();
      expect(filtered, isEmpty);
    });

    test('all messages pass filter when none are synthetic', () {
      final messages = [
        Message(
          id: '1',
          role: MessageRole.user,
          content: 'A',
          timestamp: DateTime.now(),
          synthetic: false,
        ),
        Message(
          id: '2',
          role: MessageRole.assistant,
          content: 'B',
          timestamp: DateTime.now(),
          synthetic: false,
        ),
      ];

      final filtered = messages.where((m) => !m.synthetic).toList();
      expect(filtered.length, equals(2));
    });
  });
}
