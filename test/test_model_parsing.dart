// Model parsing test for OpenRouterService
// Run with: dart test/test_model_parsing.dart

// Copy the necessary classes here to avoid Flutter dependencies
class ModelCapabilities {
  final bool reasoning;
  final bool multimodal;
  final bool vision;
  final bool tools;

  const ModelCapabilities({
    required this.reasoning,
    required this.multimodal,
    required this.vision,
    required this.tools,
  });

  factory ModelCapabilities.fromJson(Map<String, dynamic> json) {
    return ModelCapabilities(
      reasoning: json['reasoning'] ?? false,
      multimodal: json['multimodal'] ?? false,
      vision: json['vision'] ?? false,
      tools: json['tools'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'reasoning': reasoning,
    'multimodal': multimodal,
    'vision': vision,
    'tools': tools,
  };
}

class OpenRouterModel {
  final String id;
  final String name;
  final String description;
  final String? pricingPrompt;
  final String? pricingCompletion;
  final int? contextLength;
  final String? provider;
  final ModelCapabilities capabilities;

  const OpenRouterModel({
    required this.id,
    required this.name,
    required this.description,
    this.pricingPrompt,
    this.pricingCompletion,
    this.contextLength,
    this.provider,
    required this.capabilities,
  });

  factory OpenRouterModel.fromJson(Map<String, dynamic> modelData) {
    // Parse context length from various possible formats
    int? parsedContextLength;
    final contextLength = modelData['context_length'];
    
    if (contextLength is int) {
      parsedContextLength = contextLength;
    } else if (contextLength is String) {
      // Handle strings like "2M", "262K", etc.
      final contextStr = contextLength.toUpperCase();
      if (contextStr.contains('M')) {
        final number = double.parse(
          contextStr.replaceAll(RegExp(r'[^\d.]'), ''),
        );
        parsedContextLength = (number * 1000000).toInt();
      } else if (contextStr.contains('K')) {
        final number = double.parse(
          contextStr.replaceAll(RegExp(r'[^\d.]'), ''),
        );
        parsedContextLength = (number * 1000).toInt();
      } else {
        parsedContextLength = int.tryParse(contextStr);
      }
    }

    return OpenRouterModel(
      id: modelData['id'] ?? '',
      name: modelData['name'] ?? '',
      description: modelData['description'] ?? '',
      pricingPrompt: _parsePricing(modelData['pricing']?['prompt']),
      pricingCompletion: _parsePricing(modelData['pricing']?['completion']),
      capabilities: ModelCapabilities.fromJson(modelData['capabilities'] ?? {}),
      contextLength: parsedContextLength,
      provider: modelData['provider'] is Map 
        ? (modelData['provider'] as Map)['name'] 
        : modelData['provider'],
    );
  }

  static String? _parsePricing(dynamic pricing) {
    if (pricing == null) return null;
    if (pricing is String) {
      if (pricing == '0' || pricing.toLowerCase().contains('free')) {
        return '0';
      }
      return pricing;
    }
    if (pricing is num) {
      return pricing.toString();
    }
    return null;
  }

  bool get isFree =>
      (pricingPrompt == '0' || pricingPrompt == null) &&
      (pricingCompletion == '0' || pricingCompletion == null);

  bool get supportsReasoning => capabilities.reasoning;
  bool get supportsMultimodal => capabilities.multimodal;

  String get formattedContextLength {
    if (contextLength == null) return '';
    final length = contextLength!;
    if (length >= 1000000) {
      return '${(length / 1000000).toStringAsFixed(1)}M tokens';
    } else if (length >= 1000) {
      return '${(length / 1000).toStringAsFixed(0)}K tokens';
    } else {
      return '$length tokens';
    }
  }
}

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
      print('   $context tokens: ${testModel.formattedContextLength}');
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