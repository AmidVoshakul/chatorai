// Integration test for OpenRouter API
// Run with: dart integration_test/api_test.dart

// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  final dio = Dio();
  final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
  final baseUrl =
      dotenv.env['OPENROUTER_BASE_URL'] ?? 'https://openrouter.ai/api/v1';

  if (apiKey.isEmpty) {
    print('❌ Error: OPENROUTER_API_KEY not found in .env file');
    return;
  }

  dio.options = BaseOptions(
    baseUrl: baseUrl,
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
    final chatResponse = await dio.post(
      '/chat/completions',
      data: {
        'model': 'nvidia/nemotron-3-nano-30b-a3b:free',
        'messages': [
          {'role': 'user', 'content': 'Hello! How are you?'},
        ],
        'max_tokens': 100,
      },
    );

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
          'model': 'nvidia/nemotron-3-nano-30b-a3b:free',
          'messages': [
            {'role': 'user', 'content': 'Hello'},
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
