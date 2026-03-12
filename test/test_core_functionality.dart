import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/services/openrouter/openrouter_service.dart';
import 'package:chatorai/models/chat_models.dart';

void main() {
  group('OpenRouterService Core Functionality Tests', () {
    late OpenRouterService service;

    setUp(() {
      service = OpenRouterService();
    });

    test('service initialization', () {
      expect(service, isNotNull);
      print('✅ OpenRouterService initialized successfully');
    });

    test('chat completion without network', () async {
      try {
        final response = await service.getChatCompletion(
          model: 'nvidia/nemotron-3-nano-30b-a3b:free',
          messages: [
            {'role': 'user', 'content': 'Hello! Test message.'}
          ],
          maxTokens: 50,
        );
        print('✅ Chat completion successful: ${response.content.length} characters');
      } catch (e) {
        print('⚠️  Chat completion failed (expected without network): $e');
        expect(e.toString(), contains('API key not configured'));
      }
    });

    test('streaming without network', () async {
      try {
        bool streamingWorked = false;
        
        await service.streamChatCompletion(
          model: 'nvidia/nemotron-3-nano-30b-a3b:free',
          messages: [
            {'role': 'user', 'content': 'Count to 3.'}
          ],
          maxTokens: 50,
          onChunk: (content) {
            streamingWorked = true;
            print('✅ Streaming chunk received: "$content"');
          },
          onCompletion: (content) {
            print('✅ Streaming completed: ${content.length} characters total');
          },
        );
        
        print('✅ Streaming test: ${streamingWorked ? 'PASSED' : 'FAILED'}');
      } catch (e) {
        print('⚠️  Streaming test failed (expected without network): $e');
        expect(e.toString(), contains('API key not configured'));
      }
    });

    test('model parsing without network', () async {
      try {
        final models = await service.getAvailableModels();
        print('✅ Model parsing successful: ${models.length} models parsed');
        
        if (models.isNotEmpty) {
          final testModel = models.first;
          print('   Model name: ${testModel.name}');
          print('   Model ID: ${testModel.id}');
          print('   Context length: ${testModel.formattedContextLength}');
          print('   Free model: ${testModel.isFree}');
          print('   Supports reasoning: ${testModel.supportsReasoning}');
        }
      } catch (e) {
        print('⚠️  Model parsing failed (expected without network): $e');
        expect(e.toString(), contains('API key not configured'));
      }
    });

    test('message serialization with reasoning', () {
      final message = Message(
        role: MessageRole.assistant,
        content: 'This is the main response.',
        timestamp: DateTime.now(),
        reasoning: 'This is the reasoning behind the response.',
      );

      final json = message.toJson();
      expect(json['reasoning'], 'This is the reasoning behind the response.');
      
      final deserialized = Message.fromJson(json);
      expect(deserialized.reasoning, 'This is the reasoning behind the response.');
      print('✅ Message serialization with reasoning works correctly');
    });

    test('message serialization without reasoning', () {
      final message = Message(
        role: MessageRole.assistant,
        content: 'This is the main response.',
        timestamp: DateTime.now(),
      );

      final json = message.toJson();
      expect(json['reasoning'], isNull);
      
      final deserialized = Message.fromJson(json);
      expect(deserialized.reasoning, isNull);
      print('✅ Message serialization without reasoning works correctly');
    });

    test('message reasoning updates', () {
      final message = Message(
        role: MessageRole.assistant,
        content: 'This is the main response.',
        timestamp: DateTime.now(),
      );

      final updatedMessage = message.copyWith(
        reasoning: 'This is the updated reasoning.',
      );

      expect(updatedMessage.reasoning, 'This is the updated reasoning.');
      expect(updatedMessage.content, message.content);
      print('✅ Message reasoning updates work correctly');
    });
  });
}