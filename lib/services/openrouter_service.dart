import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

// Initialize logger for this service
final _logger = LogTags.openRouter;

// ===========================================================================
// CONSTANTS
// ===========================================================================

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

// ===========================================================================
// MODEL CAPABILITIES
// ===========================================================================

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

// ===========================================================================
// OPENROUTER MODEL
// ===========================================================================

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

// ===========================================================================
// RESPONSE CLASSES
// ===========================================================================

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

// ===========================================================================
// OPENROUTER CLIENT INTERFACE
// ===========================================================================

/// Minimal interface used by the UI layer to call OpenRouter service.
/// This allows tests to inject fakes without needing to initialize the full
/// network-backed OpenRouterService.
abstract class OpenRouterClient {
  Future<ChatCompletionResponse> getChatCompletion({
    required String model,
    required List<Map<String, dynamic>> messages,
    int? maxTokens,
    double? temperature,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    String? reason,
    bool includeReasoning = false,
  });

  Future<void> streamChatCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    int? maxTokens,
    double? temperature,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    bool includeReasoning = false,
    required Function(String) onChunk,
    required Function(String) onCompletion,
    Function(String)? onReasoning,
    VoidCallback? onStopped,
  });

  bool isReady();

  void stopGeneration();
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

// ===========================================================================
// OPENROUTER SERVICE IMPLEMENTATION
// ===========================================================================

class OpenRouterService implements OpenRouterClient {
  bool _isConnected = true;
  String? _apiKey;
  final String _baseUrl;
  final OpenRouterConfig _config;
  Dio? _dio;
  CancelToken? _cancelToken;

  // Caching
  final Map<String, List<OpenRouterModel>> _modelsCache = {};
  DateTime? _modelsCacheTimestamp;

  // Initialization tracking
  Completer<void> _initCompleter = Completer<void>();
  bool _isInitialized = false;

  OpenRouterService({
    OpenRouterConfig? config,
    String? baseUrl,
    bool isConnected = true,
  }) : _config = config ?? const OpenRouterConfig(),
       _isConnected = isConnected,
       _baseUrl = baseUrl ?? OpenRouterConstants.baseUrl {
    _initializeService();
  }

  /// Reinitialize service after API key or baseUrl change
  Future<void> reinitialize() async {
    _isInitialized = false;
    _dio = null;
    // Complete previous completer if it hasn't been completed yet
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
    // Create new completer for the next initialization
    _initCompleter = Completer<void>();
    await _initializeService();
    // Wait for the new initialization to complete
    await _initCompleter.future;
  }

  static const String _prefApiKey = 'openrouter_api_key';
  static const String _prefBaseUrl = 'openrouter_base_url';

  // ===========================================================================
  // PUBLIC API: Save API key to SharedPreferences (for release builds)
  // ===========================================================================

  /// Save API key and optional base URL to SharedPreferences
  /// This allows users to configure the API key in the app without .env file
  Future<void> saveApiKey(String apiKey, {String? baseUrl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefApiKey, apiKey);
      if (baseUrl != null) {
        await prefs.setString(_prefBaseUrl, baseUrl);
      }
      _apiKey = apiKey;
      _logger.logInfo('[OpenRouter] API key saved to SharedPreferences');
    } catch (e) {
      _logger.logError('[OpenRouter] Failed to save API key: $e');
      rethrow;
    }
  }

  /// Get API key from SharedPreferences (if available)
  Future<String?> _getApiKeyFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefApiKey);
    } catch (e) {
      _logger.logDebug(
        '[OpenRouter] Could not read API key from SharedPreferences: $e',
      );
      return null;
    }
  }

  /// Get base URL from SharedPreferences (if available)
  Future<String?> _getBaseUrlFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefBaseUrl);
    } catch (e) {
      _logger.logDebug(
        '[OpenRouter] Could not read base URL from SharedPreferences: $e',
      );
      return null;
    }
  }

  /// Clear saved API key (for logout/reset)
  Future<void> clearSavedApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefApiKey);
      await prefs.remove(_prefBaseUrl);
      _apiKey = null;
      _logger.logInfo('[OpenRouter] Saved API key cleared');
    } catch (e) {
      _logger.logError('[OpenRouter] Failed to clear API key: $e');
    }
  }

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  void setConnectivityStatus(bool isConnected) {
    _isConnected = isConnected;
  }

  Future<void> _initializeService() async {
    try {
      await _loadApiKey();

      // Get base URL: first from SharedPreferences, then from .env (if available), then fallback to default
      String? baseUrl = await _getBaseUrlFromPrefs();
      if (baseUrl == null || baseUrl.isEmpty) {
        try {
          baseUrl = dotenv.env[OpenRouterConstants.envBaseUrl];
        } catch (e) {
          // dotenv not initialized (e.g., on mobile/desktop without .env file)
          _logger.logDebug('[OpenRouter] .env not available for baseUrl: $e');
        }
      }
      baseUrl ??= _baseUrl;

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

      _isInitialized = true;
      _initCompleter.complete();
      _logger.logInfo('[OpenRouter] Service initialization complete');
    } catch (e, stack) {
      _isInitialized = false;
      _initCompleter.completeError(e, stack);
      _logger.logError('[OpenRouter] Service initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _loadApiKey() async {
    try {
      _logger.logDebug('[OpenRouter] Loading API key...');

      String? apiKey;
      String? baseUrl;

      // Strategy 1: Load from SharedPreferences (works on all platforms)
      try {
        apiKey = await _getApiKeyFromPrefs();
        baseUrl = await _getBaseUrlFromPrefs();
        if (apiKey != null && apiKey.isNotEmpty) {
          _logger.logInfo('[OpenRouter] API key loaded from SharedPreferences');
          _apiKey = apiKey;
          if (baseUrl != null && baseUrl.isNotEmpty) {
            _logger.logInfo(
              '[OpenRouter] Base URL loaded from SharedPreferences: $baseUrl',
            );
          }
          return;
        }
      } catch (e) {
        _logger.logDebug(
          '[OpenRouter] Could not load from SharedPreferences: $e',
        );
      }

      // Strategy 2: Try to load from .env file (only on platforms where it's available)
      // This is for development convenience on desktop platforms
      bool loaded = false;
      try {
        // Only try to load .env if we're on a platform that supports file access
        // and not on Web (where .env is not bundled)
        if (!kIsWeb) {
          await dotenv.load(fileName: '.env');
          loaded = true;
          _logger.logDebug('[OpenRouter] Loaded .env from current directory');
        }
      } catch (e) {
        _logger.logDebug(
          '[OpenRouter] Could not load .env from current directory: $e',
        );
      }

      if (!loaded && !kIsWeb) {
        try {
          await dotenv.load(fileName: '../.env');
          loaded = true;
          _logger.logDebug('[OpenRouter] Loaded .env from parent directory');
        } catch (e) {
          _logger.logDebug(
            '[OpenRouter] Could not load .env from parent directory: $e',
          );
        }
      }

      if (!loaded && !kIsWeb) {
        try {
          final scriptDir = File(Platform.script.toFilePath()).parent.path;
          final envPath = path.join(scriptDir, '.env');
          await dotenv.load(fileName: envPath);
          loaded = true;
          _logger.logDebug(
            '[OpenRouter] Loaded .env from script directory: $envPath',
          );
        } catch (e) {
          _logger.logDebug(
            '[OpenRouter] Could not load .env from script directory: $e',
          );
        }
      }

      // Get API key from environment variables (only if .env was loaded)
      if (loaded) {
        apiKey = dotenv.env[OpenRouterConstants.envApiKey];
        baseUrl = dotenv.env[OpenRouterConstants.envBaseUrl];

        if (apiKey != null && apiKey.isNotEmpty) {
          _logger.logInfo(
            '[OpenRouter] API key loaded successfully from .env file',
          );
          if (baseUrl != null && baseUrl.isNotEmpty) {
            _logger.logInfo('[OpenRouter] Base URL loaded: $baseUrl');
          }
          _apiKey = apiKey;
          return;
        }
      }

      // If we reach here, no API key was found
      // This is OK - user will enter it in settings later
      _logger.logWarning(
        '[OpenRouter] API key not configured. User will need to enter it in settings.',
      );
      _apiKey = null;
    } catch (e) {
      _logger.logError('[OpenRouter] Error loading API key: $e');
      _apiKey = null;
    }
  }

  // ===========================================================================
  // PUBLIC API KEY MANAGEMENT
  // ===========================================================================

  /// Check if API key is currently configured (loaded from .env or SharedPreferences)
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Get current API key (masked for security)
  String? get maskedApiKey {
    if (_apiKey == null || _apiKey!.isEmpty) return null;
    if (_apiKey!.length <= 8) return '****';
    return '${_apiKey!.substring(0, 4)}...${_apiKey!.substring(_apiKey!.length - 4)}';
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

    if (e.response?.data == null) {
      return errorMessage;
    }

    try {
      if (e.response!.data is String) {
        errorMessage = e.response!.data as String;
      } else if (e.response!.data is Map) {
        final errorData = Map<String, dynamic>.from(e.response!.data);
        errorMessage =
            errorData['error']?['message'] ??
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

        // Don't retry on user cancellation
        if (e is DioException && e.type == DioExceptionType.cancel) {
          _logger.logInfo(
            '[OpenRouter] Request cancelled by user, not retrying',
          );
          rethrow;
        }

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

    // Проверка наличия интернет-соединения
    if (!_isConnected) {
      _logger.logWarning(
        '[OpenRouter] No internet connection, aborting models fetch',
      );
      throw Exception('No internet connection');
    }

    await _waitForInitialization();

    // Check cache first
    if (_config.enableCaching && !forceRefresh) {
      _clearExpiredCache();
      final cacheKey = _buildModelsCacheKey(
        category,
        supportsReasoning,
        supportsMultimodal,
      );
      if (_modelsCache.containsKey(cacheKey)) {
        _logger.logInfo('[OpenRouter] Returning cached models');
        return _modelsCache[cacheKey]!;
      }
    }

    _logger.logInfo('[OpenRouter] Fetching models from OpenRouter API...');
    _logger.logDebug(
      '[OpenRouter] API URL: $_baseUrl${OpenRouterConstants.modelsEndpoint}',
    );

    return _retryWithBackoff(
      operationName: 'getAvailableModels',
      operation: () async {
        final response = await _dio!.get(OpenRouterConstants.modelsEndpoint);

        _logger.logDebug(
          '[OpenRouter] Response status: ${response.statusCode}',
        );

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
              .map(
                (model) =>
                    OpenRouterModel.fromJson(model as Map<String, dynamic>),
              )
              .where(
                (model) => _filterModel(
                  model,
                  category,
                  supportsReasoning,
                  supportsMultimodal,
                ),
              )
              .toList();
        } else if (data is List) {
          models = data
              .map(
                (model) =>
                    OpenRouterModel.fromJson(model as Map<String, dynamic>),
              )
              .where(
                (model) => _filterModel(
                  model,
                  category,
                  supportsReasoning,
                  supportsMultimodal,
                ),
              )
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
          final cacheKey = _buildModelsCacheKey(
            category,
            supportsReasoning,
            supportsMultimodal,
          );
          _modelsCache[cacheKey] = uniqueModels;
          _modelsCacheTimestamp = DateTime.now();
          _logger.logInfo(
            '[OpenRouter] Models cached for ${OpenRouterConstants.modelsCacheDurationMinutes} minutes',
          );
        }

        return uniqueModels;
      },
    );
  }

  @override
  /// Get chat completion (non-streaming) with retry
  Future<ChatCompletionResponse> getChatCompletion({
    required String model,
    required List<Map<String, dynamic>> messages,
    int? maxTokens,
    double? temperature,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    String? reason,
    bool includeReasoning = false,
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
        // Build request data with all parameters
        final data = {
          'model': model,
          'messages': messages,
          if (maxTokens != null) 'max_tokens': maxTokens,
          if (temperature != null) 'temperature': temperature,
          if (topP != null) 'top_p': topP,
          if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
          if (presencePenalty != null) 'presence_penalty': presencePenalty,
          if (includeReasoning) 'include_reasoning': true,
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
              requestOptions: RequestOptions(
                path: OpenRouterConstants.completionsEndpoint,
              ),
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

  @override
  /// Stream chat completion for real-time responses with proper SSE parsing
  Future<void> streamChatCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    int? maxTokens,
    double? temperature,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    bool includeReasoning = false,
    required Function(String) onChunk,
    required Function(String) onCompletion,
    Function(String)? onReasoning,
    VoidCallback? onStopped,
  }) async {
    // Cancel any previous streaming operation
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      _logger.logInfo(
        '[OpenRouter] Starting REAL streaming chat completion...',
      );
      _logger.logDebug('[OpenRouter] Model: $model');
      _logger.logDebug('[OpenRouter] Messages: ${messages.length} messages');
      _logger.logDebug('[OpenRouter] Include reasoning: $includeReasoning');

      // Проверка наличия интернет-соединения
      if (!_isConnected) {
        _logger.logWarning(
          '[OpenRouter] No internet connection, aborting models fetch',
        );
        throw Exception('No internet connection');
      }

      if (_apiKey == null || _apiKey!.isEmpty) {
        _logger.logError('[OpenRouter] API key not configured');
        throw Exception('OpenRouter API key not configured');
      }

      await _waitForInitialization();
      _logger.logInfo('[OpenRouter] Dio initialized');

      return await _retryWithBackoff(
        operationName: 'streamChatCompletion',
        operation: () async {
          // Build request data with all parameters
          final data = {
            'model': model,
            'messages': messages,
            'stream': true,
            if (maxTokens != null) 'max_tokens': maxTokens,
            if (temperature != null) 'temperature': temperature,
            if (topP != null) 'top_p': topP,
            if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
            if (presencePenalty != null) 'presence_penalty': presencePenalty,
            if (includeReasoning) 'include_reasoning': true,
          };

          _logger.logInfo('[OpenRouter] Making API request to OpenRouter...');
          _logger.logVerbose('[OpenRouter] Request data: ${jsonEncode(data)}');

          final response = await _dio!.post(
            OpenRouterConstants.completionsEndpoint,
            data: data,
            options: Options(responseType: ResponseType.stream),
            cancelToken: _cancelToken,
          );

          if (response.statusCode != 200) {
            final errorMessage = await _extractErrorMessage(
              DioException(
                requestOptions: RequestOptions(
                  path: OpenRouterConstants.completionsEndpoint,
                ),
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
              onStopped,
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
    } finally {
      // Clean up cancel token after operation completes
      _cancelToken = null;
    }
  }

  @override
  /// Check if OpenRouterService is ready for API calls
  bool isReady() {
    return _isInitialized && _dio != null;
  }

  /// Wait for service initialization to complete
  Future<void> get initializationComplete => _initCompleter.future;

  @override
  /// Stop the current generation/streaming
  void stopGeneration() {
    if (_cancelToken != null) {
      _logger.logInfo('[OpenRouter] Stopping generation...');
      _cancelToken!.cancel('Generation stopped by user');
      _cancelToken = null;
      _logger.logInfo('[OpenRouter] Generation stopped');
    }
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
    VoidCallback? onStopped,
  ) async {
    final StringBuffer fullContent = StringBuffer();
    bool hasReasoning = false;
    String buffer = '';

    try {
      await for (final chunk in stream.stream) {
        buffer += utf8.decode(chunk);

        // Normalize line endings: handle both \r\n and \n
        buffer = buffer.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

        // Split buffer into lines - more efficient than contains/indexOf loop
        final lines = buffer.split('\n');
        // Keep unprocessed part in buffer
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.startsWith('data: ')) {
            final dataStr = trimmedLine.substring(6).trim();

            if (dataStr.isEmpty || dataStr == '[DONE]') {
              if (dataStr == '[DONE]') {
                _logger.logInfo('[OpenRouter] Stream completed');
              }
              continue;
            }

            try {
              final chunkData = jsonDecode(dataStr);
              final choices = chunkData['choices'] as List?;
              final choice = (choices != null && choices.isNotEmpty)
                  ? choices[0]
                  : null;
              final delta = choice?['delta'] ?? {};

              if (delta.containsKey('content')) {
                final content = delta['content'];
                if (content != null && content is String) {
                  fullContent.write(content);
                  onChunk(content);
                }
              }

              if (delta.containsKey('reasoning')) {
                final reasoning = delta['reasoning'];
                if (reasoning != null && reasoning is String) {
                  hasReasoning = true;
                  if (onReasoning != null) {
                    onReasoning(reasoning);
                  }
                }
              }

              if (choice?['finish_reason'] != null) {
                _logger.logInfo(
                  '[OpenRouter] Finish reason: ${choice?['finish_reason']}',
                );
              }
            } catch (e) {
              _logger.logWarning('[OpenRouter] Failed to parse chunk: $e');
            }
          }
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('cancelled')) {
        _logger.logInfo('[OpenRouter] Stream cancelled');
        if (onStopped != null) onStopped();
        return;
      }
      rethrow;
    }

    if (includeReasoning && !hasReasoning) {
      _logger.logInfo(
        '[OpenRouter] Reasoning not in stream, will be available after completion',
      );
    }

    final finalContent = fullContent.toString();
    onCompletion(finalContent);
    _logger.logInfo(
      '[OpenRouter] Streaming completed, total content length: ${finalContent.length}',
    );
  }

  /// Simulate streaming response for testing
  Future<void> _simulateStreamingResponse(
    Function(String) onChunk,
    Function(String) onCompletion,
  ) async {
    final simulatedResponse = "simulated streaming response.";

    for (int i = 0; i < simulatedResponse.length; i++) {
      await Future<void>.delayed(
        const Duration(
          milliseconds: OpenRouterConstants.chunkProcessingDelayMs,
        ),
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
