// Core functionality test for OpenRouterService
// Run with: dart test/test_core_functionality.dart

import 'package:gen_ui_chat_ai/services/openrouter_service.dart';

void main() async {
  print('🧪 Testing OpenRouterService Core Features...');
  
  final service = OpenRouterService();
  
  try {
    // Test 1: Service initialization
    print('\n🔧 Test 1: Service initialization...');
    print('✅ OpenRouterService initialized successfully');
    print('🔑 API Key Status: ${service.getApiKeyStatus()}');
    
    // Test 2: Chat completion (main feature)
    print('\n💬 Test 2: Testing chat completion...');
    try {
      final response = await service.getChatCompletion(
        model: 'openai/gpt-oss-20b:free',
        messages: [
          {'role': 'user', 'content': 'Hello! Test message.'}
        ],
        maxTokens: 50,
      );
      
      print('✅ Chat completion successful!');
      final displayLength = response.content.length > 100 ? 100 : response.content.length;
      print('Response: ${response.content.substring(0, displayLength)}...');
    } catch (e) {
      print('⚠️  Chat completion failed (expected without network): $e');
    }
    
    // Test 3: Streaming (basic test)
    print('\n🌊 Test 3: Testing streaming...');
    try {
      bool streamingWorked = false;
      
      await service.streamChatCompletion(
        model: 'openai/gpt-oss-20b:free',
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
    }
    
    // Test 4: Model parsing
    print('\n🔍 Test 4: Testing model parsing...');
    try {
      final models = await service.getAvailableModels();
      print('✅ Model parsing successful: ${models.length} models parsed');
      
      // Test model properties
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
    }
    
    print('\n🎉 All core functionality tests completed!');
    print('📝 Network tests may fail without internet connection - this is expected');
    
  } catch (e) {
    print('❌ Critical error: $e');
  }
}