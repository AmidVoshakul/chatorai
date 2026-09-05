import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/chat/chat/chat_message.dart';

void main() {
  group('AssistantMessage.copyWith', () {
    late AssistantMessage original;
    late DateTime timestamp;

    setUp(() {
      timestamp = DateTime(2024, 1, 15, 10, 30);
      original = AssistantMessage(
        id: 'msg_123',
        parts: [TextPart(content: 'Hello, world!')],
        model: 'claude-3-5-sonnet',
        isStreaming: false,
        continuationSuggestions: ['Continue', 'Explain more'],
        timestamp: timestamp,
        tokensInput: 100,
        tokensOutput: 900,
        tokensReasoning: 50,
        contextLength: 200000,
      );
    });

    test('copyWith with no arguments preserves all fields', () {
      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.timestamp, original.timestamp);
      expect(copied.parts, original.parts);
      expect(copied.model, original.model);
      expect(copied.isStreaming, original.isStreaming);
      expect(copied.continuationSuggestions, original.continuationSuggestions);
      expect(copied.tokensInput, original.tokensInput);
      expect(copied.tokensOutput, original.tokensOutput);
      expect(copied.tokensReasoning, original.tokensReasoning);
      expect(copied.contextLength, original.contextLength);
    });

    test('copyWith preserves id and timestamp even when not specified', () {
      final copied = original.copyWith();

      expect(copied.id, 'msg_123');
      expect(copied.timestamp, timestamp);
    });

    test('copyWith can override parts', () {
      final newParts = [
        TextPart(content: 'New content'),
        TextPart(content: 'More content'),
      ];
      final copied = original.copyWith(parts: newParts);

      expect(copied.parts, newParts);
      expect(copied.parts.length, 2);
      expect(copied.model, original.model);
      expect(copied.isStreaming, original.isStreaming);
    });

    test('copyWith can override model', () {
      final copied = original.copyWith(model: 'gpt-4o');

      expect(copied.model, 'gpt-4o');
      expect(copied.parts, original.parts);
      expect(copied.isStreaming, original.isStreaming);
      expect(copied.continuationSuggestions, original.continuationSuggestions);
    });

    test('copyWith can override isStreaming', () {
      final copied = original.copyWith(isStreaming: true);

      expect(copied.isStreaming, true);
      expect(copied.parts, original.parts);
      expect(copied.model, original.model);
    });

    test('copyWith can override continuationSuggestions', () {
      final newSuggestions = ['Suggestion 1'];
      final copied = original.copyWith(continuationSuggestions: newSuggestions);

      expect(copied.continuationSuggestions, newSuggestions);
      expect(copied.parts, original.parts);
      expect(copied.model, original.model);
    });

    test('copyWith can override tokensInput', () {
      final copied = original.copyWith(tokensInput: 500);

      expect(copied.tokensInput, 500);
      expect(copied.tokensOutput, original.tokensOutput);
      expect(copied.tokensReasoning, original.tokensReasoning);
    });

    test('copyWith can override contextLength', () {
      final copied = original.copyWith(contextLength: 100000);

      expect(copied.contextLength, 100000);
      expect(copied.parts, original.parts);
      expect(copied.model, original.model);
    });

    test('copyWith with multiple overrides', () {
      final copied = original.copyWith(
        model: 'new-model',
        isStreaming: true,
        tokensInput: 200,
      );

      expect(copied.model, 'new-model');
      expect(copied.isStreaming, true);
      expect(copied.tokensInput, 200);
      expect(copied.tokensOutput, original.tokensOutput);
      expect(copied.tokensReasoning, original.tokensReasoning);
    });

    test('copyWith does not reset fields when null is passed', () {
      final copied = original.copyWith(model: null);

      expect(copied.model, original.model);
    });

    test('original message is not mutated', () {
      original.copyWith(
        model: 'mutated-model',
        isStreaming: true,
        tokensInput: 9999,
      );

      expect(original.model, 'claude-3-5-sonnet');
      expect(original.isStreaming, false);
      expect(original.tokensInput, 100);
    });

    test('copyWith creates a new instance', () {
      final copied = original.copyWith();

      expect(identical(original, copied), false);
      expect(original.id, copied.id);
      expect(original.timestamp, copied.timestamp);
    });
  });

  group('AssistantMessage with default values', () {
    test('creates instance with default values', () {
      final timestamp = DateTime.now();
      final message = AssistantMessage(id: 'msg_default', timestamp: timestamp);

      expect(message.id, 'msg_default');
      expect(message.timestamp, timestamp);
      expect(message.parts, isEmpty);
      expect(message.model, isNull);
      expect(message.isStreaming, false);
      expect(message.continuationSuggestions, isEmpty);
      expect(message.tokensInput, isNull);
      expect(message.tokensOutput, isNull);
      expect(message.tokensReasoning, isNull);
      expect(message.contextLength, isNull);
    });

    test('copyWith on default instance preserves defaults', () {
      final timestamp = DateTime.now();
      final message = AssistantMessage(id: 'msg_default', timestamp: timestamp);

      final copied = message.copyWith();

      expect(copied.id, message.id);
      expect(copied.timestamp, message.timestamp);
      expect(copied.parts, isEmpty);
      expect(copied.model, isNull);
      expect(copied.isStreaming, false);
    });
  });

  group('AssistantMessage.toJson and fromJson roundtrip', () {
    late AssistantMessage original;

    setUp(() {
      original = AssistantMessage(
        id: 'msg_json',
        parts: [TextPart(content: 'Test content')],
        model: 'claude-3-5-sonnet',
        isStreaming: false,
        continuationSuggestions: ['Option 1', 'Option 2'],
        timestamp: DateTime(2024, 1, 15),
        tokensInput: 100,
        tokensOutput: 400,
        tokensReasoning: 25,
        contextLength: 100000,
      );
    });

    test('toJson produces correct map', () {
      final json = original.toJson();

      expect(json['type'], 'assistant');
      expect(json['id'], 'msg_json');
      expect(json['model'], 'claude-3-5-sonnet');
      expect(json['isStreaming'], false);
      expect(json['continuationSuggestions'], ['Option 1', 'Option 2']);
      expect(json['tokensInput'], 100);
      expect(json['tokensOutput'], 400);
      expect(json['tokensReasoning'], 25);
      expect(json['contextLength'], 100000);
      expect(json['parts'], isA<List>());
    });

    test('fromJson restores message correctly', () {
      final json = original.toJson();
      final restored = AssistantMessage.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.model, original.model);
      expect(restored.isStreaming, original.isStreaming);
      expect(
        restored.continuationSuggestions,
        original.continuationSuggestions,
      );
      expect(restored.tokensInput, original.tokensInput);
      expect(restored.tokensOutput, original.tokensOutput);
      expect(restored.tokensReasoning, original.tokensReasoning);
      expect(restored.contextLength, original.contextLength);
    });

    test('fromJson handles missing optional fields', () {
      final minimalJson = {
        'type': 'assistant',
        'id': 'msg_minimal',
        'timestamp': DateTime(2024, 1, 15).toIso8601String(),
      };

      final message = AssistantMessage.fromJson(minimalJson);

      expect(message.id, 'msg_minimal');
      expect(message.parts, isEmpty);
      expect(message.model, isNull);
      expect(message.isStreaming, false);
      expect(message.continuationSuggestions, isEmpty);
    });
  });
}
