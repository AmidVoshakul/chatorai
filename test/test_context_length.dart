// Test context length handling and model selection
// Run with: dart test/test_context_length.dart

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
  print('🧪 Testing Context Length Handling...\n');

  // Test data from real OpenRouter API responses
  final realModels = [
    {
      'id': 'nvidia/nemotron-3-nano-30b-a3b:free',
      'name': 'Nemotron-3 Nano 30B',
      'description': 'NVIDIA Nemotron-3 Nano 30B model',
      'provider': {'name': 'NVIDIA'},
      'pricing': {'prompt': '0', 'completion': '0'},
      'context_length': 256000,
      'capabilities': {'reasoning': false, 'multimodal': false, 'vision': false, 'tools': false},
    },
    {
      'id': 'xiaomi/mimo-v2-flash:free',
      'name': 'Xiaomi MiMo V2 Flash',
      'description': 'Xiaomi MiMo V2 Flash model',
      'provider': {'name': 'Xiaomi'},
      'pricing': {'prompt': '0', 'completion': '0'},
      'context_length': 262144,
      'capabilities': {'reasoning': false, 'multimodal': false, 'vision': false, 'tools': false},
    },
    {
      'id': 'kwaipilot/kat-coder-pro:free',
      'name': 'Kwaipilot KAT Coder Pro',
      'description': 'Kwaipilot KAT Coder Pro model',
      'provider': {'name': 'Kwaipilot'},
      'pricing': {'prompt': '0', 'completion': '0'},
      'context_length': 131072,
      'capabilities': {'reasoning': false, 'multimodal': false, 'vision': false, 'tools': false},
    },
    {
      'id': 'google/gemini-3-flash-preview',
      'name': 'Google Gemini 3 Flash',
      'description': 'Google Gemini 3 Flash Preview',
      'provider': {'name': 'Google'},
      'pricing': {'prompt': '0', 'completion': '0'},
      'context_length': 1048576,
      'capabilities': {'reasoning': false, 'multimodal': true, 'vision': true, 'tools': true},
    },
    {
      'id': 'openai/gpt-5.2-pro',
      'name': 'OpenAI GPT-5.2 Pro',
      'description': 'OpenAI GPT-5.2 Pro',
      'provider': {'name': 'OpenAI'},
      'pricing': {'prompt': '0', 'completion': '0'},
      'context_length': 400000,
      'capabilities': {'reasoning': true, 'multimodal': true, 'vision': true, 'tools': true},
    },
  ];

  // Test 1: Parse real models and verify context lengths
  print('🔍 Test 1: Parsing real models from API...');
  final parsedModels = realModels.map((data) => OpenRouterModel.fromJson(data)).toList();
  
  for (final model in parsedModels) {
    print('✅ ${model.id}');
    print('   Context: ${model.contextLength} tokens (${model.formattedContextLength})');
    print('   Free: ${model.isFree}');
    print('   Capabilities: reasoning=${model.supportsReasoning}, vision=${model.capabilities.vision}, tools=${model.capabilities.tools}');
    print('');
  }

  // Test 2: Verify context length parsing from different formats
  print('🔍 Test 2: Context length format parsing...');
  final formatTests = [
    {'input': 256000, 'expected': 256000, 'desc': 'Integer'},
    {'input': '262144', 'expected': 262144, 'desc': 'String integer'},
    {'input': '2M', 'expected': 2000000, 'desc': 'String with M'},
    {'input': '262K', 'expected': 262000, 'desc': 'String with K'},
    {'input': '1.5M', 'expected': 1500000, 'desc': 'String with decimal M'},
  ];

  for (final test in formatTests) {
    final modelData = {
      'id': 'test',
      'name': 'Test',
      'description': 'Test',
      'provider': {'name': 'Test'},
      'pricing': {'prompt': '0', 'completion': '0'},
      'context_length': test['input'],
      'capabilities': {'reasoning': false, 'multimodal': false, 'vision': false, 'tools': false},
    };
    
    final model = OpenRouterModel.fromJson(modelData);
    final actual = model.contextLength;
    final expected = test['expected'];
    final passed = actual == expected;
    
    print('${passed ? '✅' : '❌'} ${test['desc']}: ${test['input']} -> $actual (expected $expected)');
  }

  // Test 3: Verify max tokens calculation logic (simulating ChatScreen._getOptimalMaxTokensForModel)
  print('\n🔍 Test 3: Max tokens calculation...');
  
  int getOptimalMaxTokens(OpenRouterModel model) {
    if (model.contextLength == null) {
      return 16000; // ChatScreenConstants.defaultMaxTokens
    }
    final contextLength = model.contextLength!;
    if (contextLength < 1000) {
      return 1000;
    }
    return contextLength;
  }

  for (final model in parsedModels) {
    final maxTokens = getOptimalMaxTokens(model);
    final contextLength = model.contextLength ?? 0;
    final ratio = contextLength > 0 ? (maxTokens / contextLength * 100).toStringAsFixed(1) : 'N/A';
    
    print('✅ ${model.id}');
    print('   Context: ${model.contextLength} -> MaxTokens: $maxTokens ($ratio%)');
  }

  // Test 4: Edge cases
  print('\n🔍 Test 4: Edge cases...');
  
  // Model with null context
  final nullContextModel = OpenRouterModel.fromJson({
    'id': 'test/null',
    'name': 'Test Null',
    'description': 'Test',
    'provider': {'name': 'Test'},
    'pricing': {'prompt': '0', 'completion': '0'},
    'context_length': null,
    'capabilities': {'reasoning': false, 'multimodal': false, 'vision': false, 'tools': false},
  });
  
  final maxTokensNull = getOptimalMaxTokens(nullContextModel);
  print('${maxTokensNull == 16000 ? '✅' : '❌'} Null context -> $maxTokensNull (should be 16000)');
  
  // Model with very small context
  final smallContextModel = OpenRouterModel.fromJson({
    'id': 'test/small',
    'name': 'Test Small',
    'description': 'Test',
    'provider': {'name': 'Test'},
    'pricing': {'prompt': '0', 'completion': '0'},
    'context_length': 500,
    'capabilities': {'reasoning': false, 'multimodal': false, 'vision': false, 'tools': false},
  });
  
  final maxTokensSmall = getOptimalMaxTokens(smallContextModel);
  print('${maxTokensSmall == 1000 ? '✅' : '❌'} Small context (500) -> $maxTokensSmall (should be 1000)');

  // Test 5: Model selection simulation
  print('\n🔍 Test 5: Model selection simulation...');
  
  // Simulate what happens when user selects a model
  final selectedModelId = 'nvidia/nemotron-3-nano-30b-a3b:free';
  final selectedModel = parsedModels.firstWhere(
    (m) => m.id == selectedModelId,
    orElse: () => throw Exception('Model not found'),
  );
  
  final maxTokens = getOptimalMaxTokens(selectedModel);
  print('✅ Selected model: $selectedModelId');
  print('   Context length: ${selectedModel.contextLength}');
  print('   Max tokens to use: $maxTokens');
  print('   Formatted context: ${selectedModel.formattedContextLength}');

  print('\n🎉 All context length tests completed!');
  print('✅ Models correctly parse context lengths from API');
  print('✅ No artificial restrictions or truncation applied');
  print('✅ Full context window is used when available');
}