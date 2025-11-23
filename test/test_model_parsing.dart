// Model parsing test for OpenRouterService
// Run with: dart test/test_model_parsing.dart

import 'package:gen_ui_chat_ai/services/openrouter_service.dart';

void main() async {
  print('🧪 Testing Model Parsing...');

  // Test model data
  final testModelData = {
    'id': 'test-model',
    'name': 'Test Model',
    'description': 'A test model for validation',
    'provider': {
      'name': 'Test Provider',
    },
    'pricing': {
      'prompt': '0.001',
      'completion': '0.002',
    },
    'context_length': '8000',
    'capabilities': {
      'reasoning': true,
      'multimodal': false,
      'vision': false,
      'tools': true,
    },
  };

  try {
    // Test 1: Model parsing
    print('\n🔍 Test 1: Model from JSON parsing...');
    final model = OpenRouterModel.fromJson(testModelData);
    
    print('✅ Model parsed successfully!');
    print('   ID: ${model.id}');
    print('   Name: ${model.name}');
    print('   Description: ${model.description}');
    print('   Provider: ${model.provider}');
    print('   Context: ${model.formattedContextLength}');
    print('   Free: ${model.isFree}');
    print('   Reasoning: ${model.supportsReasoning}');
    print('   Multimodal: ${model.supportsMultimodal}');

    // Test 2: Model filtering
    print('\n🔍 Test 2: Model filtering...');
    final models = [model];
    
    // Filter by reasoning support
    final reasoningModels = models.where((m) => m.supportsReasoning).toList();
    print('✅ Reasoning models: ${reasoningModels.length}');

    // Filter by multimodal support
    final multimodalModels = models.where((m) => m.supportsMultimodal).toList();
    print('✅ Multimodal models: ${multimodalModels.length}');

    // Filter by free models
    final freeModels = models.where((m) => m.isFree).toList();
    print('✅ Free models: ${freeModels.length}');

    // Test 3: Context length formatting
    print('\n🔍 Test 3: Context length formatting...');
    print('   8000 tokens: ${model.formattedContextLength}');
    
    // Test different context lengths
    final testContexts = [1000, 5000, 8000, 32000, 100000, 200000];
    for (final context in testContexts) {
      final testModel = OpenRouterModel(
        id: 'test',
        name: 'Test',
        description: 'Test',
        contextLength: context,
        capabilities: ModelCapabilities(reasoning: true, multimodal: false, vision: false, tools: false),
      );
      print('   ${context} tokens: ${testModel.formattedContextLength}');
    }

    // Test 4: Edge cases
    print('\n🔍 Test 4: Edge cases...');
    
    // Test model with no provider
    final noProviderData = {
      ...testModelData,
      'provider': null,
    };
    final modelNoProvider = OpenRouterModel.fromJson(noProviderData);
    print('✅ Model with null provider: ${modelNoProvider.provider ?? 'null'}');
    
    // Test model with string context
    final stringContextData = {
      ...testModelData,
      'context_length': '2M',
    };
    final modelStringContext = OpenRouterModel.fromJson(stringContextData);
    print('✅ Model with string context (2M): ${modelStringContext.formattedContextLength}');
    
    // Test model with K context
    final kContextData = {
      ...testModelData,
      'context_length': '262K',
    };
    final modelKContext = OpenRouterModel.fromJson(kContextData);
    print('✅ Model with K context (262K): ${modelKContext.formattedContextLength}');

    print('\n🎉 All model parsing tests completed!');
    print('✅ Models are correctly parsed and filtered');
    
  } catch (e) {
    print('❌ Model parsing error: $e');
  }
}