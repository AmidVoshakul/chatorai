// Unit tests for OpenRouterService
// Run with: dart test/test_api_dio.dart

import 'package:gen_ui_chat_ai/services/openrouter_service.dart';

void main() async {
  print('🧪 Unit Testing OpenRouterService...');
  
  final service = OpenRouterService();
  
  try {
    // Test 1: Service initialization
    print('\n🔧 Test 1: Service initialization...');
    print('✅ OpenRouterService initialized successfully');
    print('🔑 API Key Status: ${service.getApiKeyStatus()}');
    
    // Test 2: Health check
    print('\n� Test 2: Service health check...');
    final isHealthy = await service.isHealthy();
    print('✅ Service health: ${isHealthy ? 'Healthy' : 'Unhealthy'}');
    
    // Test 3: Fetch models
    print('\n🔍 Test 3: Fetching models...');
    try {
      final models = await service.getAvailableModels();
      print('✅ Successfully fetched ${models.length} models');
      
      // Show first few models
      final count = models.length < 3 ? models.length : 3;
      for (int i = 0; i < count; i++) {
        final model = models[i];
        print('  ${i + 1}. ${model.name} (${model.id})');
        print('     Context: ${model.formattedContextLength}');
        print('     Free: ${model.isFree}');
        print('     Reasoning: ${model.supportsReasoning}');
        print('');
      }
    } catch (e) {
      print('❌ Error fetching models: $e');
    }
    
    // Test 4: Chat completion
    print('\n💬 Test 4: Testing chat completion...');
    try {
      final response = await service.getChatCompletion(
        model: 'x-ai/grok-4.1-fast:free',
        messages: [
          {'role': 'user', 'content': 'Hello! Test message.'}
        ],
        maxTokens: 50,
      );
      
      print('✅ Chat completion successful!');
      print('Response: ${response.content.substring(0, min(response.content.length, 100))}...');
    } catch (e) {
      print('❌ Chat completion failed: $e');
    }
    
    // Test 5: Streaming (basic test)
    print('\n🌊 Test 5: Testing streaming...');
    try {
      final stream = service.streamChatCompletion(
        model: 'x-ai/grok-4.1-fast:free',
        messages: [
          {'role': 'user', 'content': 'Count to 3.'}
        ],
        maxTokens: 50,
      );
      
      int chunkCount = 0;
      await for (final chunk in stream) {
        chunkCount++;
        if (chunk.content != null) {
          print('Chunk $chunkCount: ${chunk.content!.substring(0, min(chunk.content!.length, 30))}...');
        }
        if (chunk.isComplete) break;
      }
      
      print('✅ Streaming test completed with $chunkCount chunks');
    } catch (e) {
      print('❌ Streaming test failed: $e');
    }
    
    print('\n🎉 All unit tests completed!');
    
  } catch (e) {
    print('❌ Unit test error: $e');
  }
}

// Helper function for min
int min(int a, int b) => a < b ? a : b;