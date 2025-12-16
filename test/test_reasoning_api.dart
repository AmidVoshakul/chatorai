import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';

// Mock logger for testing
class MockLogger {
  final String tag;
  MockLogger(this.tag);

  void logInfo(String message) => print('[INFO] $tag: $message');
  void logDebug(String message) => print('[DEBUG] $tag: $message');
  void logVerbose(String message) => print('[VERBOSE] $tag: $message');
  void logWarning(String message) => print('[WARNING] $tag: $message');
  void logError(String message) => print('[ERROR] $tag: $message');
}

void main() {
  group('OpenRouterService Reasoning Tests', () {
    late OpenRouterService openRouterService;

    setUp(() {
      openRouterService = OpenRouterService();
    });

    // Test 1: ChatCompletionResponse parsing with reasoning
    test('parses ChatCompletionResponse with reasoning correctly', () {
      final jsonResponse = {
        'choices': [
          {
            'message': {
              'content': 'This is the main response.',
              'reasoning': 'This is the reasoning behind the response.',
            },
            'finish_reason': 'stop',
          }
        ],
        'usage': {
          'prompt_tokens': 100,
          'completion_tokens': 50,
        },
        'model': 'test-model',
      };

      final response = ChatCompletionResponse.fromOpenRouterResponse(jsonResponse);

      expect(response.content, 'This is the main response.');
      expect(response.reasoning, 'This is the reasoning behind the response.');
      expect(response.finishReason, 'stop');
      expect(response.usageInputTokens, 100);
      expect(response.usageOutputTokens, 50);
      expect(response.model, 'test-model');
    });

    // Test 2: ChatCompletionResponse parsing without reasoning
    test('parses ChatCompletionResponse without reasoning correctly', () {
      final jsonResponse = {
        'choices': [
          {
            'message': {
              'content': 'This is a response without reasoning.',
            },
            'finish_reason': 'stop',
          }
        ],
        'usage': {
          'prompt_tokens': 100,
          'completion_tokens': 50,
        },
        'model': 'test-model',
      };

      final response = ChatCompletionResponse.fromOpenRouterResponse(jsonResponse);

      expect(response.content, 'This is a response without reasoning.');
      expect(response.reasoning, isNull);
      expect(response.finishReason, 'stop');
      expect(response.usageInputTokens, 100);
      expect(response.usageOutputTokens, 50);
      expect(response.model, 'test-model');
    });

    // Test 3: ChatCompletionChunk parsing with reasoning
    test('parses ChatCompletionChunk with reasoning correctly', () {
      final jsonResponse = {
        'choices': [
          {
            'delta': {
              'content': 'This is a chunk of the response.',
              'reasoning': 'This is reasoning for this chunk.',
            },
            'finish_reason': null,
          }
        ],
        'usage': {
          'prompt_tokens': 100,
          'completion_tokens': 10,
        },
        'model': 'test-model',
      };

      final chunk = ChatCompletionChunk.fromOpenRouterResponse(jsonResponse);

      expect(chunk.content, 'This is a chunk of the response.');
      expect(chunk.reasoning, 'This is reasoning for this chunk.');
      expect(chunk.isComplete, false);
      expect(chunk.usageInputTokens, 100);
      expect(chunk.usageOutputTokens, 10);
      expect(chunk.model, 'test-model');
    });

    // Test 4: ChatCompletionChunk parsing without reasoning
    test('parses ChatCompletionChunk without reasoning correctly', () {
      final jsonResponse = {
        'choices': [
          {
            'delta': {
              'content': 'This is a chunk without reasoning.',
            },
            'finish_reason': null,
          }
        ],
        'usage': {
          'prompt_tokens': 100,
          'completion_tokens': 10,
        },
        'model': 'test-model',
      };

      final chunk = ChatCompletionChunk.fromOpenRouterResponse(jsonResponse);

      expect(chunk.content, 'This is a chunk without reasoning.');
      expect(chunk.reasoning, isNull);
      expect(chunk.isComplete, false);
      expect(chunk.usageInputTokens, 100);
      expect(chunk.usageOutputTokens, 10);
      expect(chunk.model, 'test-model');
    });

    // Test 5: ChatCompletionChunk parsing with completion
    test('parses ChatCompletionChunk with completion correctly', () {
      final jsonResponse = {
        'choices': [
          {
            'delta': {
              'content': 'This is the final chunk.',
              'reasoning': 'This is the final reasoning.',
            },
            'finish_reason': 'stop',
          }
        ],
        'usage': {
          'prompt_tokens': 100,
          'completion_tokens': 50,
        },
        'model': 'test-model',
      };

      final chunk = ChatCompletionChunk.fromOpenRouterResponse(jsonResponse);

      expect(chunk.content, 'This is the final chunk.');
      expect(chunk.reasoning, 'This is the final reasoning.');
      expect(chunk.isComplete, true);
      expect(chunk.finishReason, 'stop');
      expect(chunk.usageInputTokens, 100);
      expect(chunk.usageOutputTokens, 50);
      expect(chunk.model, 'test-model');
    });

    // Test 6: Message model with reasoning
    test('creates Message with reasoning correctly', () {
      final message = Message(
        id: 'test-message-id',
        role: MessageRole.assistant,
        content: 'This is the main response.',
        reasoning: 'This is the reasoning behind the response.',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(message.content, 'This is the main response.');
      expect(message.reasoning, 'This is the reasoning behind the response.');
      expect(message.isComplete, true);
      expect(message.role, MessageRole.assistant);
    });

    // Test 7: Message model without reasoning
    test('creates Message without reasoning correctly', () {
      final message = Message(
        id: 'test-message-id',
        role: MessageRole.assistant,
        content: 'This is a response without reasoning.',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(message.content, 'This is a response without reasoning.');
      expect(message.reasoning, isNull);
      expect(message.isComplete, true);
      expect(message.role, MessageRole.assistant);
    });

    // Test 8: Message model copyWith with reasoning
    test('updates Message with reasoning using copyWith', () {
      final originalMessage = Message(
        id: 'test-message-id',
        role: MessageRole.assistant,
        content: 'Original content.',
        timestamp: DateTime.now(),
        isComplete: false,
      );

      final updatedMessage = originalMessage.copyWith(
        reasoning: 'Updated reasoning.',
        isComplete: true,
      );

      expect(updatedMessage.content, 'Original content.');
      expect(updatedMessage.reasoning, 'Updated reasoning.');
      expect(updatedMessage.isComplete, true);
      expect(updatedMessage.role, MessageRole.assistant);
    });

    // Test 9: Message model copyWith without reasoning
    test('updates Message without reasoning using copyWith', () {
      final originalMessage = Message(
        id: 'test-message-id',
        role: MessageRole.assistant,
        content: 'Original content.',
        reasoning: 'Original reasoning.',
        timestamp: DateTime.now(),
        isComplete: false,
      );

      final updatedMessage = originalMessage.copyWith(
        content: 'Updated content.',
        isComplete: true,
      );

      expect(updatedMessage.content, 'Updated content.');
      expect(updatedMessage.reasoning, 'Original reasoning.');
      expect(updatedMessage.isComplete, true);
      expect(updatedMessage.role, MessageRole.assistant);
    });

    // Test 10: Message model JSON serialization with reasoning
    test('serializes and deserializes Message with reasoning correctly', () {
      final originalMessage = Message(
        id: 'test-message-id',
        role: MessageRole.assistant,
        content: 'This is the main response.',
        reasoning: 'This is the reasoning behind the response.',
        timestamp: DateTime(2023, 1, 1, 12, 0, 0),
        isComplete: true,
      );

      final json = originalMessage.toJson();
      final deserializedMessage = Message.fromJson(json);

      expect(deserializedMessage.id, originalMessage.id);
      expect(deserializedMessage.role, originalMessage.role);
      expect(deserializedMessage.content, originalMessage.content);
      expect(deserializedMessage.reasoning, originalMessage.reasoning);
      expect(deserializedMessage.isComplete, originalMessage.isComplete);
      expect(deserializedMessage.timestamp, originalMessage.timestamp);
    });

    // Test 11: Message model JSON serialization without reasoning
    test('serializes and deserializes Message without reasoning correctly', () {
      final originalMessage = Message(
        id: 'test-message-id',
        role: MessageRole.assistant,
        content: 'This is a response without reasoning.',
        timestamp: DateTime(2023, 1, 1, 12, 0, 0),
        isComplete: true,
      );

      final json = originalMessage.toJson();
      final deserializedMessage = Message.fromJson(json);

      expect(deserializedMessage.id, originalMessage.id);
      expect(deserializedMessage.role, originalMessage.role);
      expect(deserializedMessage.content, originalMessage.content);
      expect(deserializedMessage.reasoning, isNull);
      expect(deserializedMessage.isComplete, originalMessage.isComplete);
      expect(deserializedMessage.timestamp, originalMessage.timestamp);
    });

    // Test 12: Reasoning content handling
    test('handles reasoning content correctly', () {
      final reasoningText = '''
        This is a detailed reasoning text that explains the thought process behind the answer.
        It includes multiple steps and considerations that led to the final conclusion.
        The reasoning should be displayed in a separate section from the main response.
      ''';

      final message = Message(
        id: 'test-message-id',
        role: MessageRole.assistant,
        content: 'Final answer based on the reasoning above.',
        reasoning: reasoningText,
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(message.reasoning, reasoningText);
      expect(message.content, 'Final answer based on the reasoning above.');
      expect(message.reasoning!.contains('detailed reasoning'), true);
    });

    // Test 13: Empty reasoning handling
    test('handles empty reasoning correctly', () {
      final message = Message(
        id: 'test-message-id',
        role: MessageRole.assistant,
        content: 'Response with empty reasoning.',
        reasoning: '',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(message.reasoning, '');
      expect(message.content, 'Response with empty reasoning.');
    });

    // Test 14: Null reasoning handling
    test('handles null reasoning correctly', () {
      final message = Message(
        id: 'test-message-id',
        role: MessageRole.assistant,
        content: 'Response with null reasoning.',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      expect(message.reasoning, isNull);
      expect(message.content, 'Response with null reasoning.');
    });

    // Test 15: Reasoning update scenarios
    test('handles reasoning updates correctly', () {
      var message = Message(
        id: 'test-message-id',
        role: MessageRole.assistant,
        content: 'Initial response.',
        timestamp: DateTime.now(),
        isComplete: false,
      );

      // Add reasoning
      message = message.copyWith(reasoning: 'Initial reasoning.');
      expect(message.reasoning, 'Initial reasoning.');

      // Update reasoning
      message = message.copyWith(reasoning: 'Updated reasoning.');
      expect(message.reasoning, 'Updated reasoning.');

      // Clear reasoning
      message = message.copyWith(reasoning: '');
      expect(message.reasoning, '');

      // Remove reasoning
      message = message.copyWith(reasoning: null);
      expect(message.reasoning, isNull);
    });
  });
}
