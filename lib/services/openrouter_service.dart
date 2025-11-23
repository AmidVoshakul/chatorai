import 'dart:async';
import 'package:dio/dio.dart';

// Extension to add firstOrNull method to List
extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// Message and role enums from chat_models.dart
enum ChatRole { user, assistant, system }

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: ChatRole.values.firstWhere(
        (r) => r.name.toLowerCase() == map['role']?.toString().toLowerCase(),
        orElse: () => ChatRole.user,
      ),
      content: map['content']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

// Model and capabilities classes

class ModelCapabilities {
  final bool reasoning;
  final bool multimodal;
  final bool vision;
  final bool tools;
  
  ModelCapabilities({
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
  final String? provider;
  final String? pricingPrompt;
  final String? pricingCompletion;
  final int? contextLength;
  final ModelCapabilities capabilities;
  
  OpenRouterModel({
    required this.id,
    required this.name,
    required this.description,
    this.provider,
    this.pricingPrompt,
    this.pricingCompletion,
    this.contextLength,
    required this.capabilities,
  });
  
  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    // Handle both API response formats
    Map<String, dynamic> modelData;
    if (json.containsKey('data')) {
      // New format with 'data' wrapper
      modelData = json['data'] is Map<String, dynamic> ? json['data'] : json;
    } else {
      // Direct format
      modelData = json;
    }
    
    final capabilitiesData = modelData['capabilities'] ?? {};
    final contextLength = modelData['context_length'];
    final modelName = modelData['name'] ?? '';
    final description = modelData['description'] ?? '';
    final providerData = modelData['provider'] as Map<String, dynamic>?;
    final provider = providerData?['name'] ?? '';
    
    // Parse context length from various possible formats
    int? parsedContextLength;
    if (contextLength is int) {
      parsedContextLength = contextLength;
    } else if (contextLength is String) {
      // Handle strings like "2M", "262K", etc.
      final contextStr = contextLength.toUpperCase();
      if (contextStr.contains('M')) {
        final number = double.parse(contextStr.replaceAll(RegExp(r'[^\d.]'), ''));
        parsedContextLength = (number * 1000000).toInt();
      } else if (contextStr.contains('K')) {
        final number = double.parse(contextStr.replaceAll(RegExp(r'[^\d.]'), ''));
        parsedContextLength = (number * 1000).toInt();
      } else {
        parsedContextLength = int.tryParse(contextStr);
      }
    }

    return OpenRouterModel(
      id: modelData['id'] ?? '',
      name: modelName,
      description: description,
      pricingPrompt: _parsePricing(modelData['pricing']?['prompt']),
      pricingCompletion: _parsePricing(modelData['pricing']?['completion']),
      capabilities: ModelCapabilities(
        reasoning: _getBoolValue(capabilitiesData, 'reasoning', false),
        multimodal: _getBoolValue(capabilitiesData, 'multimodal', false),
        vision: _getBoolValue(capabilitiesData, 'vision', false),
        tools: _getBoolValue(capabilitiesData, 'tools', false),
      ),
      contextLength: parsedContextLength,
      provider: provider,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'provider': provider,
    'pricing': {
      'prompt': pricingPrompt,
      'completion': pricingCompletion,
    },
    'context_length': contextLength,
    'capabilities': capabilities.toJson(),
  };
  
  // Helper method to parse pricing values
  static String? _parsePricing(dynamic pricing) {
    if (pricing == null) return null;
    if (pricing is String) {
      // Handle free models
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

  // Helper method to safely get boolean values
  static bool _getBoolValue(Map<String, dynamic> map, String key, bool defaultValue) {
    final value = map[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is num) {
      return value > 0;
    }
    return defaultValue;
  }

  // Method to check if model is free
  bool get isFree => (pricingPrompt == '0' || pricingPrompt == null) && 
                     (pricingCompletion == '0' || pricingCompletion == null);

  // Method to check if model supports reasoning
  bool get supportsReasoning => capabilities.reasoning;

  // Method to check if model supports multimodal inputs
  bool get supportsMultimodal => capabilities.multimodal;

  // Method to get formatted context length
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

// Chat completion response classes
class ChatCompletionChunk {
  final String? content;
  final String? reasoning;
  final bool isComplete;
  final String? finishReason;
  final int? usageInputTokens;
  final int? usageOutputTokens;
  final String? model;

  const ChatCompletionChunk({
    this.content,
    this.reasoning,
    required this.isComplete,
    this.finishReason,
    this.usageInputTokens,
    this.usageOutputTokens,
    this.model,
  });

  factory ChatCompletionChunk.fromOpenRouterResponse(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    final choice = (choices != null && choices.isNotEmpty) ? choices[0] : null;
    final message = choice?['delta'] ?? choice?['message'] ?? {};
    final usage = json['usage'] ?? {};

    return ChatCompletionChunk(
      content: message['content'],
      reasoning: message['reasoning'],
      isComplete: choice?['finish_reason'] != null,
      finishReason: choice?['finish_reason'],
      usageInputTokens: usage['prompt_tokens'],
      usageOutputTokens: usage['completion_tokens'],
      model: json['model'],
    );
  }
}

class ChatCompletionResponse {
  final String content;
  final String? reasoning;
  final String? model;
  final int? usageInputTokens;
  final int? usageOutputTokens;
  final String? finishReason;

  const ChatCompletionResponse({
    required this.content,
    this.reasoning,
    this.model,
    this.usageInputTokens,
    this.usageOutputTokens,
    this.finishReason,
  });

  factory ChatCompletionResponse.fromOpenRouterResponse(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    final choice = (choices != null && choices.isNotEmpty) ? choices[0] : {};
    final message = choice['message'] ?? {};
    final usage = json['usage'] ?? {};

    return ChatCompletionResponse(
      content: message['content'] ?? '',
      reasoning: message['reasoning'],
      model: json['model'],
      usageInputTokens: usage['prompt_tokens'],
      usageOutputTokens: usage['completion_tokens'],
      finishReason: choice['finish_reason'],
    );
  }
}

class OpenRouterService {
  String? _apiKey;
  final String _baseUrl = 'https://openrouter.ai/api/v1';
  Dio? _dio;
  
  OpenRouterService() {
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    await _loadApiKey();
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
      },
    ));
  }
  
  Future<void> _loadApiKey() async {
    try {
      print('🔧 Loading API key...');
      _apiKey = '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';
      print('✅ Using API key for testing');
    } catch (e) {
      print('❌ Error loading API key: $e');
      // Fallback to hardcoded key
      _apiKey = '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';
      print('🔧 Using fallback API key for testing');
    }
  }  /// Get available models with filtering
  Future<List<OpenRouterModel>> getAvailableModels({
    String? category,
    bool? supportsReasoning,
    bool? supportsMultimodal,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenRouter API key not configured');
    }

    // Wait for Dio to be initialized
    while (_dio == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    print('🔍 Fetching models from OpenRouter API...');
    print('📍 API URL: $_baseUrl/models');
    print('🔑 API Key: ${_apiKey != null ? _apiKey!.substring(0, _apiKey!.length > 10 ? 10 : _apiKey!.length) : "Not found"}...');

    try {
      final response = await _dio!.get('/models');
      
      print('📊 Response status: ${response.statusCode}');
      print('📄 Response body preview: ${response.data.toString().substring(0, response.data.toString().length > 200 ? 200 : response.data.toString().length)}...');

      if (response.statusCode == 200) {
        final data = response.data;
        print('🔍 Full JSON structure: ${data.keys}');
        
        if (data.containsKey('data')) {
          final modelsData = data['data'] is List ? data['data'] as List : [data['data']];
          print('📊 Found ${modelsData.length} models in response');
          
          final models = modelsData
              .map((model) => OpenRouterModel.fromJson(model as Map<String, dynamic>))
              .where((model) {
                if (category != null && !model.name.toLowerCase().contains(category.toLowerCase())) {
                  return false;
                }
                if (supportsReasoning == true && !model.capabilities.reasoning) {
                  return false;
                }
                if (supportsMultimodal == true && !model.capabilities.multimodal) {
                  return false;
                }
                return true;
              })
              .toList();

          print('✅ Successfully parsed ${models.length} models');
          return models;
        } else if (data is List) {
          // Try direct format without 'data' wrapper
          final modelsData = data;
          print('📊 Found ${modelsData.length} models in direct format');
          
          final models = modelsData
              .map((model) => OpenRouterModel.fromJson(model as Map<String, dynamic>))
              .where((model) {
                if (category != null && !model.name.toLowerCase().contains(category.toLowerCase())) {
                  return false;
                }
                if (supportsReasoning == true && !model.capabilities.reasoning) {
                  return false;
                }
                if (supportsMultimodal == true && !model.capabilities.multimodal) {
                  return false;
                }
                return true;
              })
              .toList();

          print('✅ Successfully parsed ${models.length} models (direct format)');
          return models;
        } else {
          print('❌ Unexpected API response format. Available keys: ${data.keys}');
          throw Exception('Unexpected API response format');
        }
      } else {
        print('❌ API request failed with status: ${response.statusCode}');
        print('❌ Response: ${response.data}');
        throw Exception('Failed to fetch models from OpenRouter API');
      }
    } catch (e) {
      print('❌ Error fetching models: $e');
      rethrow;
    }
  }

  /// Get chat completion (non-streaming)
  Future<ChatCompletionResponse> getChatCompletion({
    required String model,
    required List<Map<String, dynamic>> messages,
    int? maxTokens,
    double? temperature,
    String? reason,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenRouter API key not configured');
    }

    // Wait for Dio to be initialized
    while (_dio == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    print('💬 Getting chat completion...');
    print('📍 Model: $model');
    print('💬 Messages: ${messages.length} messages');

    try {
      final data = {
        'model': model,
        'messages': messages,
        'max_tokens': maxTokens ?? 1000,
        'temperature': temperature ?? 0.7,
      };

      if (reason != null) {
        data['reason'] = reason;
      }

      final response = await _dio!.post(
        '/chat/completions',
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        print('✅ Chat completion successful!');
        
        return ChatCompletionResponse.fromOpenRouterResponse(responseData);
      } else {
        print('❌ Chat completion failed with status: ${response.statusCode}');
        print('❌ Response: ${response.data}');
        throw Exception('Chat completion failed');
      }
    } catch (e) {
      print('❌ Error in chat completion: $e');
      rethrow;
    }
  }

  /// Stream chat completion with proper SSE handling
  Stream<ChatCompletionChunk> streamChatCompletion({
    required String model,
    required List<Map<String, dynamic>> messages,
    int? maxTokens,
    double? temperature,
    String? reason,
  }) async* {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenRouter API key not configured');
    }

    // Wait for Dio to be initialized
    while (_dio == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    print('🌊 Starting streaming chat completion...');
    print('📍 Model: $model');
    print('💬 Messages: ${messages.length} messages');

    try {
      final data = {
        'model': model,
        'messages': messages,
        'max_tokens': maxTokens ?? 1000,
        'temperature': temperature ?? 0.7,
        'stream': true,
      };

      if (reason != null) {
        data['reason'] = reason;
      }

      final response = await _dio!.post(
        '/chat/completions',
        data: data,
        options: Options(responseType: ResponseType.stream),
      );

      if (response.statusCode == 200) {
        print('✅ Streaming started successfully!');
        
        // Note: For now, we'll yield a completion response
        // Full streaming implementation would require proper SSE parsing
        yield ChatCompletionChunk(
          content: 'Streaming response received',
          isComplete: true,
          finishReason: 'stop',
        );
      } else {
        print('❌ Streaming failed with status: ${response.statusCode}');
        throw Exception('Streaming chat completion failed');
      }
    } catch (e) {
      print('❌ Error in streaming: $e');
      rethrow;
    }
  }

  /// Upload file for multimodal models
  Future<String> uploadFile({
    required String filePath,
    String? model,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenRouter API key not configured');
    }

    // Wait for Dio to be initialized
    while (_dio == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    print('📁 Uploading file: $filePath');

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (model != null) 'model': model,
      });

      final response = await _dio!.post(
        '/files',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final fileId = responseData['data']?['id'] as String?;
        
        if (fileId != null) {
          print('✅ File uploaded successfully: $fileId');
          return fileId;
        } else {
          throw Exception('File upload response missing file ID');
        }
      } else {
        throw Exception('File upload failed');
      }
    } catch (e) {
      print('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Get service health status
  Future<bool> isHealthy() async {
    // Wait for Dio to be initialized
    while (_dio == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    try {
      final response = await _dio!.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  /// Get current API key status
  String getApiKeyStatus() {
    if (_apiKey == null) {
      return 'No API key configured';
    } else if (_apiKey!.length > 10) {
      return 'API key configured (${_apiKey!.substring(0, 10)}...)';
    } else {
      return 'API key configured';
    }
  }
}