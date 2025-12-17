import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

// Initialize logger for this service
final _logger = LogTags.openRouter;

// Constants for configuration
class OpenRouterConstants {
  static const String baseUrl = 'https://openrouter.ai/api/v1';
  static const Duration defaultConnectTimeout = Duration(seconds: 30);
  static const Duration defaultReceiveTimeout = Duration(seconds: 30);
  static const Duration initializationWaitDelay = Duration(milliseconds: 100);
  static const int maxRetryAttempts = 3;
  static const Duration baseRetryDelay = Duration(seconds: 1);
  static const int modelsCacheDurationMinutes = 15;
  static const int chunkProcessingDelayMs = 5;
  
  // API endpoints
  static const String modelsEndpoint = '/models';
  static const String completionsEndpoint = '/chat/completions';
  static const String filesEndpoint = '/files';
  static const String healthEndpoint = '/health';
  
  // Environment variables
  static const String envApiKey = 'OPENROUTER_API_KEY';
  static const String envBaseUrl = 'OPENROUTER_BASE_URL';
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
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ModelCapabilities &&
        other.reasoning == reasoning &&
        other.multimodal == multimodal &&
        other.vision == vision &&
        other.tools == tools;
  }

  @override
  int get hashCode {
    return Object.hash(reasoning, multimodal, vision, tools);
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is OpenRouterModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.provider == provider &&
        other.pricingPrompt == pricingPrompt &&
        other.pricingCompletion == pricingCompletion &&
        other.contextLength == contextLength &&
        other.capabilities == capabilities;
  }

  @override
  int get hashCode {
    // Use a more robust hash code calculation
    // Combine all fields that define model identity
    return Object.hash(
      id,
      name,
      description,
      provider,
      pricingPrompt,
      pricingCompletion,
      contextLength,
      capabilities,
    );
  }

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

    // Extract architecture information
    final architecture = modelData['architecture'] ?? {};
    final inputModalities = architecture['input_modalities'] ?? [];
    final modality = architecture['modality'] ?? '';

    // Extract supported parameters
    final supportedParameters = modelData['supported_parameters'] ?? [];

    // Determine capabilities based on architecture and supported parameters
    final isMultimodal =
        inputModalities.contains('image') || modality.contains('image');
    final hasVision =
        inputModalities.contains('image') || modality.contains('image');
    final hasTools =
        supportedParameters.contains('tools') ||
        supportedParameters.contains('tool_choice');
    final hasReasoning =
        supportedParameters.contains('reasoning') ||
        supportedParameters.contains('include_reasoning');

    final contextLength = modelData['context_length'];
    final modelName = modelData['name'] ?? '';
    final description = modelData['description'] ?? '';

    // Extract provider from model ID if provider field is null
    final providerRaw = modelData['provider'];
    String? provider;
    if (providerRaw is Map<String, dynamic>) {
      provider = providerRaw['name'] as String?;
      _logger.logDebug('[OpenRouter] Provider (Map): $provider');
    } else if (providerRaw is Map) {
      final providerMap = Map<String, dynamic>.from(providerRaw);
      provider = providerMap['name'] as String?;
      _logger.logDebug('[OpenRouter] Provider (Map<dynamic>): $provider');
    } else if (providerRaw is String) {
      provider = providerRaw;
      _logger.logDebug('[OpenRouter] Provider (String): $provider');
    } else {
      // Extract provider from model ID
      final modelId = modelData['id'] as String?;
      if (modelId != null && modelId.contains('/')) {
        final parts = modelId.split('/');
        if (parts.length >= 2) {
          provider = parts[0];
          // _logger.logDebug(
          //   '[OpenRouter] Provider extracted from ID: $provider',
          // );
        }
      }

      if (provider == null) {
        _logger.logDebug(
          '[OpenRouter] Provider raw type: ${providerRaw?.runtimeType}, value: $providerRaw',
        );
      }
    }

    // Parse context length from various possible formats
    int? parsedContextLength;
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
    } else {
      parsedContextLength = null;
    }

    return OpenRouterModel(
      id: modelData['id'] ?? '',
      name: modelName,
      description: description,
      pricingPrompt: _parsePricing(modelData['pricing']?['prompt']),
      pricingCompletion: _parsePricing(modelData['pricing']?['completion']),
      capabilities: ModelCapabilities(
        reasoning: hasReasoning,
        multimodal: isMultimodal,
        vision: hasVision,
        tools: hasTools,
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
    'pricing': {'prompt': pricingPrompt, 'completion': pricingCompletion},
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

  // Method to check if model is free
  bool get isFree =>
      (pricingPrompt == '0' || pricingPrompt == null) &&
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

  factory ChatCompletionChunk.fromOpenRouterResponse(
    Map<String, dynamic> json,
  ) {
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

  factory ChatCompletionResponse.fromOpenRouterResponse(
    Map<String, dynamic> json,
  ) {
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

/// Configuration for OpenRouterService
class OpenRouterConfig {
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final int maxRetryAttempts;
  final Duration baseRetryDelay;
  final bool enableCaching;

  const OpenRouterConfig({
    this.connectTimeout = OpenRouterConstants.defaultConnectTimeout,
    this.receiveTimeout = OpenRouterConstants.defaultReceiveTimeout,
    this.maxRetryAttempts = OpenRouterConstants.maxRetryAttempts,
    this.baseRetryDelay = OpenRouterConstants.baseRetryDelay,
    this.enableCaching = true,
  });
}

class OpenRouterService {
  String? _apiKey;
  final String _baseUrl;
  final OpenRouterConfig _config;
  Dio? _dio;
  
  // Caching
  final Map<String, List<OpenRouterModel>> _modelsCache = {};
  DateTime? _modelsCacheTimestamp;
  final Map<String, String> _fileCache = {};

  OpenRouterService({OpenRouterConfig? config, String? baseUrl})
      : _config = config ?? const OpenRouterConfig(),
        _baseUrl = baseUrl ?? OpenRouterConstants.baseUrl {
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _loadApiKey();

    // Get base URL from environment variables, fallback to default
    final baseUrl = dotenv.env[OpenRouterConstants.envBaseUrl] ?? _baseUrl;

    _logger.logInfo('[OpenRouter] Initializing Dio with base URL: $baseUrl');

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _config.connectTimeout,
        receiveTimeout: _config.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
        },
      ),
    );

    _logger.logInfo('[OpenRouter] Service initialization complete');
  }

  Future<void> _loadApiKey() async {
    try {
      _logger.logDebug('[OpenRouter] Loading API key from .env file...');

      // Load environment variables from .env file
      await dotenv.load(fileName: '.env');

      // Get API key from environment variables
      _apiKey = dotenv.env[OpenRouterConstants.envApiKey];
      final baseUrl = dotenv.env[OpenRouterConstants.envBaseUrl];

      if (_apiKey != null && _apiKey!.isNotEmpty) {
        _logger.logInfo(
          '[OpenRouter] API key loaded successfully from .env file',
        );
        if (baseUrl != null && baseUrl.isNotEmpty) {
          _logger.logInfo('[OpenRouter] Base URL loaded: $baseUrl');
        }
      } else {
        _logger.logError(
          '[OpenRouter] API key not found in .env file. Please add ${OpenRouterConstants.envApiKey} to your .env file.',
        );
        _logger.logDebug('[OpenRouter] Available environment variables:');
        dotenv.env.forEach((key, value) {
          _logger.logDebug(
            '[OpenRouter]   $key: ${value.length > 10 ? '${value.substring(0, 10)}...' : value}',
          );
        });
        throw Exception(
          'OpenRouter API key not configured. Please add ${OpenRouterConstants.envApiKey} to your .env file.',
        );
      }
    } catch (e) {
      _logger.logError('[OpenRouter] Error loading .env file: $e');
      throw Exception('Failed to load .env file: $e');
    }
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Wait for Dio to be initialized
  Future<void> _waitForInitialization() async {
    while (_dio == null) {
      await Future<void>.delayed(OpenRouterConstants.initializationWaitDelay);
    }
  }

  /// Extract error message from DioException
  Future<String> _extractErrorMessage(DioException e) async {
    String errorMessage = 'Unknown error';
    
    if (e.response?.data == null) return errorMessage;

    try {
      if (e.response!.data is String) {
        errorMessage = e.response!.data as String;
      } else if (e.response!.data is Map) {
        final errorData = Map<String, dynamic>.from(e.response!.data);
        errorMessage = errorData['error']?['message'] ??
            errorData['message'] ??
            errorData.toString();
      } else if (e.response!.data is ResponseBody) {
        final responseBody = e.response!.data as ResponseBody;
        final errorText = await utf8.decodeStream(responseBody.stream);
        errorMessage = errorText;
      }
    } catch (err) {
      _logger.logError('[OpenRouter] Error parsing error response: $err');
    }

    return errorMessage;
  }

  /// Retry mechanism with exponential backoff
  Future<T> _retryWithBackoff<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxAttempts) {
      try {
        attempt++;
        if (attempt > 1) {
          _logger.logInfo(
            '[OpenRouter] Retry attempt $attempt/$maxAttempts for $operationName',
          );
        }
        return await operation();
      } catch (e) {
        lastException = e as Exception;
        
        if (e is DioException && e.response?.statusCode == 429) {
          // Rate limit - wait longer
          final delay = Duration(seconds: pow(2, attempt).toInt());
          _logger.logWarning(
            '[OpenRouter] Rate limit hit, waiting ${delay.inSeconds}s before retry...',
          );
          await Future.delayed(delay);
        } else if (attempt < maxAttempts) {
          // Other errors - exponential backoff
          final delay = Duration(seconds: attempt);
          _logger.logWarning(
            '[OpenRouter] Error on attempt $attempt, waiting ${delay.inSeconds}s before retry...',
          );
          await Future.delayed(delay);
        }
      }
    }

    // All attempts failed
    throw lastException!;
  }

  /// Clear expired cache
  void _clearExpiredCache() {
    if (_modelsCacheTimestamp == null) return;
    
    final age = DateTime.now().difference(_modelsCacheTimestamp!).inMinutes;
    if (age > OpenRouterConstants.modelsCacheDurationMinutes) {
      _logger.logInfo('[OpenRouter] Clearing expired models cache');
      _modelsCache.clear();
      _modelsCacheTimestamp = null;
    }
  }

  // ===========================================================================
  // PUBLIC API METHODS
  // ===========================================================================

  /// Get available models with filtering, deduplication, and caching
  Future<List<OpenRouterModel>> getAvailableModels({
    String? category,
    bool? supportsReasoning,
    bool? supportsMultimodal,
    bool forceRefresh = false,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenRouter API key not configured');
    }

    await _waitForInitialization();

    // Check cache first
    if (_config.enableCaching && !forceRefresh) {
      _clearExpiredCache();
      final cacheKey = _buildModelsCacheKey(category, supportsReasoning, supportsMultimodal);
      if (_modelsCache.containsKey(cacheKey)) {
        _logger.logInfo('[OpenRouter] Returning cached models');
        return _modelsCache[cacheKey]!;
      }
    }

    _logger.logInfo('[OpenRouter] Fetching models from OpenRouter API...');
    _logger.logDebug(
      '[OpenRouter] API URL: ${dotenv.env[OpenRouterConstants.envBaseUrl] ?? _baseUrl}${OpenRouterConstants.modelsEndpoint}',
    );

    return _retryWithBackoff(
      operationName: 'getAvailableModels',
      operation: () async {
        final response = await _dio!.get(OpenRouterConstants.modelsEndpoint);

        _logger.logDebug('[OpenRouter] Response status: ${response.statusCode}');

        if (response.statusCode != 200) {
          _logger.logError(
            '[OpenRouter] API request failed with status: ${response.statusCode}',
          );
          _logger.logError('[OpenRouter] Response: ${response.data}');
          throw Exception('Failed to fetch models from OpenRouter API');
        }

        final data = response.data;
        List<OpenRouterModel> models;

        if (data.containsKey('data')) {
          final modelsData = data['data'] is List
              ? data['data'] as List
              : [data['data']];
          
          models = modelsData
              .map((model) => OpenRouterModel.fromJson(model as Map<String, dynamic>))
              .where((model) => _filterModel(model, category, supportsReasoning, supportsMultimodal))
              .toList();
        } else if (data is List) {
          models = data
              .map((model) => OpenRouterModel.fromJson(model as Map<String, dynamic>))
              .where((model) => _filterModel(model, category, supportsReasoning, supportsMultimodal))
              .toList();
        } else {
          _logger.logError(
            '[OpenRouter] Unexpected API response format. Available keys: ${data.keys}',
          );
          throw Exception('Unexpected API response format');
        }

        final uniqueModels = _deduplicateModels(models);

        _logger.logInfo(
          '[OpenRouter] Successfully parsed ${uniqueModels.length} unique models (removed ${models.length - uniqueModels.length} duplicates)',
        );

        // Cache the result
        if (_config.enableCaching) {
          final cacheKey = _buildModelsCacheKey(category, supportsReasoning, supportsMultimodal);
          _modelsCache[cacheKey] = uniqueModels;
          _modelsCacheTimestamp = DateTime.now();
          _logger.logInfo('[OpenRouter] Models cached for ${OpenRouterConstants.modelsCacheDurationMinutes} minutes');
        }

        return uniqueModels;
      },
    );
  }

  /// Get chat completion (non-streaming) with retry
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

    await _waitForInitialization();

    _logger.logInfo('[OpenRouter] Getting chat completion...');
    _logger.logDebug('[OpenRouter] Model: $model');
    _logger.logDebug('[OpenRouter] Messages: ${messages.length} messages');

    return _retryWithBackoff(
      operationName: 'getChatCompletion',
      operation: () async {
        final data = {
          'model': model,
          'messages': messages,
          'max_tokens': maxTokens ?? 8000,
          'temperature': temperature ?? 0.7,
        };

        if (reason != null) {
          data['reason'] = reason;
        }

        final response = await _dio!.post(
          OpenRouterConstants.completionsEndpoint,
          data: data,
        );

        if (response.statusCode == 200) {
          _logger.logInfo('[OpenRouter] Chat completion successful!');
          return ChatCompletionResponse.fromOpenRouterResponse(response.data);
        } else {
          final errorMessage = await _extractErrorMessage(
            DioException(
              requestOptions: RequestOptions(path: OpenRouterConstants.completionsEndpoint),
              response: response,
            ),
          );
          _logger.logError(
            '[OpenRouter] Chat completion failed with status: ${response.statusCode}',
          );
          _logger.logError('[OpenRouter] Error message: $errorMessage');
          throw Exception('Server error: $errorMessage');
        }
      },
    );
  }

  /// Upload file for multimodal models
  Future<String> uploadFile({required String filePath, String? model}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenRouter API key not configured');
    }

    await _waitForInitialization();

    _logger.logInfo('[OpenRouter] Uploading file: $filePath');

    // Check cache
    final cacheKey = '$filePath|$model';
    if (_fileCache.containsKey(cacheKey)) {
      _logger.logInfo('[OpenRouter] Returning cached file ID');
      return _fileCache[cacheKey]!;
    }

    return _retryWithBackoff(
      operationName: 'uploadFile',
      operation: () async {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
          if (model != null) 'model': model,
        });

        final response = await _dio!.post(
          OpenRouterConstants.filesEndpoint,
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        );

        if (response.statusCode == 200) {
          final responseData = response.data;
          final fileId = responseData['data']?['id'] as String?;

          if (fileId != null) {
            _logger.logInfo('[OpenRouter] File uploaded successfully: $fileId');
            _fileCache[cacheKey] = fileId;
            return fileId;
          } else {
            throw Exception('File upload response missing file ID');
          }
        } else {
          throw Exception('File upload failed');
        }
      },
    );
  }

  /// Stream chat completion for real-time responses with proper SSE parsing
  Future<void> streamChatCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    int? maxTokens,
    double? temperature,
    bool includeReasoning = false,
    required Function(String) onChunk,
    required Function(String) onCompletion,
    Function(String)? onReasoning,
  }) async {
    _logger.logInfo('[OpenRouter] Starting REAL streaming chat completion...');
    _logger.logDebug('[OpenRouter] Model: $model');
    _logger.logDebug('[OpenRouter] Messages: ${messages.length} messages');
    _logger.logDebug('[OpenRouter] Include reasoning: $includeReasoning');

    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.logError('[OpenRouter] API key not configured');
      throw Exception('OpenRouter API key not configured');
    }

    await _waitForInitialization();
    _logger.logInfo('[OpenRouter] Dio initialized');

    return _retryWithBackoff(
      operationName: 'streamChatCompletion',
      operation: () async {
        final data = {
          'model': model,
          'messages': messages,
          'stream': true,
          if (maxTokens != null) 'max_tokens': maxTokens,
          if (temperature != null) 'temperature': temperature,
          if (includeReasoning) 'include_reasoning': true,
        };

        _logger.logInfo('[OpenRouter] Making API request to OpenRouter...');
        _logger.logVerbose('[OpenRouter] Request data: ${jsonEncode(data)}');

        final response = await _dio!.post(
          OpenRouterConstants.completionsEndpoint,
          data: data,
          options: Options(responseType: ResponseType.stream),
        );

        _logger.logDebug('[OpenRouter] Response status: ${response.statusCode}');

        if (response.statusCode != 200) {
          final errorMessage = await _extractErrorMessage(
            DioException(
              requestOptions: RequestOptions(path: OpenRouterConstants.completionsEndpoint),
              response: response,
            ),
          );
          _logger.logError(
            '[OpenRouter] Streaming failed with status: ${response.statusCode}',
          );
          _logger.logError('[OpenRouter] Error message: $errorMessage');
          throw Exception('Server error: $errorMessage');
        }

        _logger.logInfo('[OpenRouter] Streaming started successfully!');

        final stream = response.data;
        
        if (stream is ResponseBody) {
          return await _processSSEStream(
            stream,
            onChunk,
            onCompletion,
            onReasoning,
            includeReasoning,
          );
        } else {
          _logger.logWarning(
            '[OpenRouter] Unknown stream type: ${stream.runtimeType}',
          );
          
          // Try to process as raw response
          if (response.data is String) {
            final responseText = response.data as String;
            _logger.logVerbose(
              '[OpenRouter] Raw response: ${responseText.substring(0, responseText.length > 200 ? 200 : responseText.length)}...',
            );
          }

          // Fallback to simulated streaming
          _logger.logWarning('[OpenRouter] Using simulation fallback');
          await _simulateStreamingResponse(onChunk, onCompletion);
        }
      },
    );
  }

  /// Get service health status
  Future<bool> isHealthy() async {
    await _waitForInitialization();

    try {
      final response = await _dio!.get(OpenRouterConstants.healthEndpoint);
      return response.statusCode == 200;
    } catch (e) {
      _logger.logError('[OpenRouter] Health check failed: $e');
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

  /// Test method to check provider field structure
  Future<void> testProviderStructure() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenRouter API key not configured');
    }

    await _waitForInitialization();

    try {
      final response = await _dio!.get(OpenRouterConstants.modelsEndpoint);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data.containsKey('data')) {
          final modelsData = data['data'] is List
              ? data['data'] as List
              : [data['data']];

          for (int i = 0; i < modelsData.length && i < 5; i++) {
            final modelData = modelsData[i] as Map<String, dynamic>;
            final providerRaw = modelData['provider'];

            _logger.logDebug('[OpenRouter] Model ${modelData['id']}:');
            _logger.logDebug(
              '[OpenRouter]   Provider type: ${providerRaw?.runtimeType}',
            );
            _logger.logDebug('[OpenRouter]   Provider value: $providerRaw');

            if (providerRaw is Map<String, dynamic>) {
              _logger.logDebug(
                '[OpenRouter]   Provider name: ${providerRaw['name']}',
              );
            } else if (providerRaw is String) {
              _logger.logDebug('[OpenRouter]   Provider string: $providerRaw');
            }
          }
        }
      }
    } catch (e) {
      _logger.logError('[OpenRouter] Error testing provider structure: $e');
    }
  }

  /// Check if OpenRouterService is ready for API calls
  bool isReady() {
    return _dio != null && _apiKey != null && _apiKey!.isNotEmpty;
  }

  /// Clear all caches
  void clearCache() {
    _modelsCache.clear();
    _modelsCacheTimestamp = null;
    _fileCache.clear();
    _logger.logInfo('[OpenRouter] All caches cleared');
  }

  // ===========================================================================
  // PRIVATE HELPER METHODS
  // ===========================================================================

  bool _filterModel(
    OpenRouterModel model,
    String? category,
    bool? supportsReasoning,
    bool? supportsMultimodal,
  ) {
    if (category != null &&
        !model.name.toLowerCase().contains(category.toLowerCase())) {
      return false;
    }
    if (supportsReasoning == true && !model.capabilities.reasoning) {
      return false;
    }
    if (supportsMultimodal == true && !model.capabilities.multimodal) {
      return false;
    }
    return true;
  }

  String _buildModelsCacheKey(
    String? category,
    bool? supportsReasoning,
    bool? supportsMultimodal,
  ) {
    return '${category ?? 'all'}_${supportsReasoning ?? false}_${supportsMultimodal ?? false}';
  }

  Future<void> _processSSEStream(
    ResponseBody stream,
    Function(String) onChunk,
    Function(String) onCompletion,
    Function(String)? onReasoning,
    bool includeReasoning,
  ) async {
    String fullContent = '';
    bool hasReasoning = false;
    int chunkCount = 0;
    int reasoningChunkCount = 0;

    print('[DEBUG] [OpenRouter] _processSSEStream START, includeReasoning: $includeReasoning');

    await for (final chunk in stream.stream) {
      final decoded = utf8.decode(chunk);
      final lines = decoded.split('\n');

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6).trim();
          
          if (dataStr.isEmpty || dataStr == '[DONE]') {
            if (dataStr == '[DONE]') {
              _logger.logInfo('[OpenRouter] Stream completed');
              print('[DEBUG] [OpenRouter] Received [DONE]');
            }
            continue;
          }

          try {
            final chunkData = jsonDecode(dataStr);
            final choices = chunkData['choices'] as List?;
            final choice = (choices != null && choices.isNotEmpty) ? choices[0] : null;
            final delta = choice?['delta'] ?? {};
            final content = delta['content'];
            final reasoning = delta['reasoning'];

            if (content != null && content is String) {
              fullContent += content;
              chunkCount++;
              onChunk(content);
              _logger.logVerbose('[OpenRouter] Content chunk: "$content"');
              print('[DEBUG] [OpenRouter] Content chunk #$chunkCount: "${content.substring(0, min(20, content.length))}${content.length > 20 ? '...' : ''}"');
            }

            if (reasoning != null && reasoning is String) {
              hasReasoning = true;
              reasoningChunkCount++;
              if (onReasoning != null) {
                onReasoning(reasoning);
              }
              _logger.logVerbose('[OpenRouter] Reasoning chunk: "$reasoning"');
              print('[DEBUG] [OpenRouter] Reasoning chunk #$reasoningChunkCount: "${reasoning.substring(0, min(20, reasoning.length))}${reasoning.length > 20 ? '...' : ''}"');
            }

            if (choice?['finish_reason'] != null) {
              _logger.logInfo('[OpenRouter] Finish reason: ${choice?['finish_reason']}');
              print('[DEBUG] [OpenRouter] Finish reason: ${choice?['finish_reason']}');
            }
          } catch (e) {
            _logger.logWarning('[OpenRouter] Failed to parse chunk: $e');
            print('[DEBUG] [OpenRouter] ERROR parsing chunk: $e');
          }
        }
      }
    }

    if (includeReasoning && !hasReasoning) {
      _logger.logInfo('[OpenRouter] Reasoning not in stream, will be available after completion');
      print('[DEBUG] [OpenRouter] No reasoning chunks received');
    }

    onCompletion(fullContent);
    _logger.logInfo('[OpenRouter] Streaming completed, total content length: ${fullContent.length}');
    print('[DEBUG] [OpenRouter] _processSSEStream END, total content: ${fullContent.length}, chunks: $chunkCount, reasoning chunks: $reasoningChunkCount');
  }

  /// Simulate streaming response for testing
  Future<void> _simulateStreamingResponse(
    Function(String) onChunk,
    Function(String) onCompletion,
  ) async {
    final simulatedResponse = "simulated streaming response.";

    for (int i = 0; i < simulatedResponse.length; i++) {
      await Future<void>.delayed(
        const Duration(milliseconds: OpenRouterConstants.chunkProcessingDelayMs),
      );
      final chunk = simulatedResponse.substring(i, i + 1);
      onChunk(chunk);
    }

    onCompletion(simulatedResponse);
  }

  /// Remove duplicate models using a more robust approach
  List<OpenRouterModel> _deduplicateModels(List<OpenRouterModel> models) {
    final Map<String, OpenRouterModel> uniqueModels = {};

    for (final model in models) {
      uniqueModels[model.id] = model;
    }

    return uniqueModels.values.toList();
  }
}
