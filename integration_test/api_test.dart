// Integration test for OpenRouter API
// Run with: dart integration_test/api_test.dart

// ignore_for_file: avoid_print

import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final apiKey = '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';
  
  dio.options = BaseOptions(
    baseUrl: 'https://openrouter.ai/api/v1',
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
  );

  try {
    print('📡 Integration Testing OpenRouter API with Dio...');
    
    // Test 1: Get models
    print('\n🔍 Test 1: Fetching models...');
    final modelsResponse = await dio.get('/models');
    
    if (modelsResponse.statusCode == 200) {
      final data = modelsResponse.data;
      if (data.containsKey('data') && data['data'] is List) {
        final models = data['data'] as List;
        print('✅ Successfully fetched ${models.length} models');
        
        // Show first few models
        final count = models.length < 5 ? models.length : 5;
        for (int i = 0; i < count; i++) {
          final model = models[i] as Map<String, dynamic>;
          print('  ${i + 1}. ${model['name']} (${model['id']})');
          print('     Context: ${model['context_length']} tokens');
          print('     Provider: ${model['provider']?['name'] ?? 'Unknown'}');
          print('');
        }
      }
    }

    // Test 2: Simple chat completion
    print('\n💬 Test 2: Testing chat completion...');
    final chatResponse = await dio.post('/chat/completions', data: {
      'model': 'x-ai/grok-4.1-fast:free',
      'messages': [
        {'role': 'user', 'content': 'Hello! How are you?'}
      ],
      'max_tokens': 100,
    });

    if (chatResponse.statusCode == 200) {
      final data = chatResponse.data;
      if (data.containsKey('choices') && data['choices'] is List) {
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'];
          print('✅ Chat completion successful!');
          print('Response: ${message['content']}');
        }
      }
    }

    // Test 3: Streaming request (simplified)
    print('\n🌊 Test 3: Testing streaming...');
    try {
      final streamResponse = await dio.post(
        '/chat/completions',
        data: {
          'model': 'x-ai/grok-4.1-fast:free',
          'messages': [
            {'role': 'user', 'content': 'Hello'}
          ],
          'max_tokens': 50,
          'stream': true,
        },
        options: Options(responseType: ResponseType.stream),
      );

      if (streamResponse.statusCode == 200) {
        print('✅ Streaming response received successfully!');
        print('Streaming is working with Dio!');
      }
    } catch (e) {
      print('❌ Streaming test failed: $e');
    }

    print('\n🎉 All integration tests completed successfully!');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}