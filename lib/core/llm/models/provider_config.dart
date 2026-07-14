/// Provider configuration for AI services.
///
/// Top-level configuration for an AI provider (OpenAI, Anthropic, Google, etc.).
/// Contains authentication, base URL, and the list of available models.
///
/// catalog patterns: immutable, serializable, schema-driven.
library;

import 'package:equatable/equatable.dart';

import 'auth_config.dart';
import 'model_config.dart';

/// Provider configuration - the root of the catalog.
///
/// Each provider (OpenAI, Anthropic, Google, etc.) has a ProviderConfig that
/// defines how to connect to it and what models are available.
///
/// The [id] should be a stable, unique identifier (e.g., 'openai', 'anthropic').
class ProviderConfig extends Equatable {
  /// Unique provider identifier (lowercase, no spaces).
  /// Examples: 'openai', 'anthropic', 'google', 'ollama', 'openrouter'
  final String id;

  /// Human-readable display name.
  final String name;

  /// Provider description.
  final String? description;

  /// Base URL for API requests.
  /// For OpenAI: 'https://api.openai.com/v1'
  /// For local Ollama: 'http://localhost:11434'
  final String baseUrl;

  /// Authentication configuration.
  final AuthConfig auth;

  /// Available models for this provider.
  final List<ModelConfig> models;

  /// Whether this provider is currently enabled.
  final bool enabled;

  /// When the provider was added to the catalog.
  final DateTime? addedAt;

  /// Default headers to send with every request.
  final Map<String, String> defaultHeaders;

  /// Default body parameters to include in every request.
  ///
  /// (e.g., `max_tokens`, `reasoning` config for Anthropic).
  final Map<String, dynamic>? defaultBody;

  /// Request timeout (in seconds).
  final int? timeoutSeconds;

  /// Maximum retries for failed requests.
  final int? maxRetries;

  /// Whether this provider supports streaming by default.
  final bool supportsStreaming;

  /// Provider-specific metadata (rate limits, regions, etc.).
  final Map<String, dynamic> metadata;

  /// The SDK/type identifier for this provider.
  /// Examples: 'openai', 'anthropic', 'google', 'openai-compatible'
  final String sdk;

  const ProviderConfig._({
    required this.id,
    required this.name,
    this.description,
    required this.baseUrl,
    required this.auth,
    required this.models,
    this.sdk = 'openai-compatible',
    this.enabled = true,
    this.addedAt,
    this.defaultHeaders = const {},
    this.defaultBody,
    this.timeoutSeconds,
    this.maxRetries,
    this.supportsStreaming = true,
    this.metadata = const {},
  });

  /// Create a basic provider configuration.
  ///
  /// [models] can be empty initially and populated later via API fetch.
  /// [auth] defaults to [AuthConfig.none] if not provided.
  factory ProviderConfig.basic({
    required String id,
    required String name,
    required String baseUrl,
    AuthConfig? auth,
    String? sdk,
    String? description,
    List<ModelConfig>? models,
    bool enabled = true,
  }) {
    return ProviderConfig._(
      id: id,
      name: name,
      baseUrl: baseUrl,
      description: description,
      auth: auth ?? const AuthConfig.none(),
      sdk: sdk ?? 'openai-compatible',
      models: models ?? const [],
      enabled: enabled,
    );
  }

  /// Create a full provider configuration with all options.
  factory ProviderConfig.full({
    required String id,
    required String name,
    required String baseUrl,
    required AuthConfig auth,
    String? sdk,
    String? description,
    List<ModelConfig>? models,
    bool enabled = true,
    Map<String, String>? defaultHeaders,
    Map<String, dynamic>? defaultBody,
    int? timeoutSeconds,
    int? maxRetries,
    bool? supportsStreaming,
    Map<String, dynamic>? metadata,
    DateTime? addedAt,
  }) {
    return ProviderConfig._(
      id: id,
      name: name,
      baseUrl: baseUrl,
      description: description,
      auth: auth,
      sdk: sdk ?? 'openai-compatible',
      models: models ?? const [],
      enabled: enabled,
      addedAt: addedAt,
      defaultHeaders: defaultHeaders ?? const {},
      defaultBody: defaultBody,
      timeoutSeconds: timeoutSeconds,
      maxRetries: maxRetries,
      supportsStreaming: supportsStreaming ?? true,
      metadata: metadata ?? const {},
    );
  }

  /// Get all enabled models.
  List<ModelConfig> get enabledModels =>
      models.where((m) => m.enabled).toList();

  /// Get model by name within this provider.
  ///
  /// [modelName] is the model identifier as stored in this provider's catalog
  /// (e.g., 'gpt-4o', 'claude-3-opus', 'openai/gpt-4o' if the provider uses
  /// slashes in model names). Does not accept full provider-prefixed IDs.
  ///
  /// Returns null if no model with this name exists in the provider.
  ModelConfig? getModel(String modelName) {
    try {
      return models.firstWhere((m) => m.modelName == modelName);
    } catch (_) {
      try {
        return models.firstWhere((m) => m.modelName.endsWith('/$modelName'));
      } catch (_) {
        return null;
      }
    }
  }

  /// Get model by variant ID.
  ModelConfig? getModelByVariantId(String variantId) {
    for (final model in models) {
      if (model.variants.any((v) => v.id == variantId)) {
        return model;
      }
    }
    return null;
  }

  /// Build per-provider options for a model call.
  ///
  /// Merges provider default body, model metadata (under the `providerOptions`
  /// key), and variant body in order (later wins). This follows the 
  /// pattern where each provider contributes its specific body fields
  /// (e.g., `thinkingConfig` for Anthropic Claude, `reasoningEffort` for
  /// OpenAI, or `promptCacheKey` for Bedrock).
  Map<String, dynamic> buildProviderOptions(
    ModelConfig model, {
    ModelVariant? variant,
  }) {
    final options = <String, dynamic>{
      if (defaultBody != null) ...?defaultBody,
      if (model.metadata['providerOptions'] is Map)
        ...(model.metadata['providerOptions'] as Map<String, dynamic>),
      if (variant != null && variant.body != null) ...?variant.body,
    };
    return options;
  }

  /// Build per-provider headers for a model call.
  ///
  /// Merges provider default headers, variant headers, and override headers
  /// inject provider-specific headers (e.g., `anthropic-beta` for thinking).
  Map<String, String> buildProviderHeaders({
    ModelVariant? variant,
    Map<String, String>? overrideHeaders,
  }) {
    final headers = <String, String>{
      ...defaultHeaders,
      if (variant != null && variant.headers != null) ...?variant.headers,
      ...?overrideHeaders,
    };
    return headers;
  }

  /// Add a model to the provider.
  ProviderConfig addModel(ModelConfig model) {
    final updatedModels = List<ModelConfig>.from(models)..add(model);
    return copyWith(models: updatedModels);
  }

  /// Remove a model from the provider.
  ProviderConfig removeModel(String modelId) {
    final updatedModels = models.where((m) => m.id != modelId).toList();
    return copyWith(models: updatedModels);
  }

  /// Update a model in the provider.
  ProviderConfig updateModel(String modelId, ModelConfig updatedModel) {
    final updatedModels = models
        .map((m) => m.id == modelId ? updatedModel : m)
        .toList();
    return copyWith(models: updatedModels);
  }

  /// Create a copy with modified fields.
  ProviderConfig copyWith({
    String? id,
    String? name,
    String? description,
    String? baseUrl,
    AuthConfig? auth,
    String? sdk,
    List<ModelConfig>? models,
    bool? enabled,
    DateTime? addedAt,
    Map<String, String>? defaultHeaders,
    Map<String, dynamic>? defaultBody,
    int? timeoutSeconds,
    int? maxRetries,
    bool? supportsStreaming,
    Map<String, dynamic>? metadata,
    bool clearDefaultBody = false,
  }) {
    return ProviderConfig._(
      id: id ?? this.id,
      name: name ?? this.name,
      sdk: sdk ?? this.sdk,
      baseUrl: baseUrl ?? this.baseUrl,
      auth: auth ?? this.auth,
      models: models ?? this.models,
      enabled: enabled ?? this.enabled,
      addedAt: addedAt ?? this.addedAt,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      defaultBody: clearDefaultBody
          ? defaultBody
          : (defaultBody ?? this.defaultBody),
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      maxRetries: maxRetries ?? this.maxRetries,
      supportsStreaming: supportsStreaming ?? this.supportsStreaming,
      metadata: metadata ?? this.metadata,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    sdk,
    baseUrl,
    auth,
    models,
    enabled,
    addedAt,
    defaultHeaders,
    defaultBody,
    timeoutSeconds,
    maxRetries,
    supportsStreaming,
    metadata,
  ];

  /// Serialize to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sdk': sdk,
      if (description != null) 'description': description,
      'baseUrl': baseUrl,
      if (auth.type != AuthType.none) 'auth': auth.toJson(),
      if (models.isNotEmpty) 'models': models.map((m) => m.toJson()).toList(),
      'enabled': enabled,
      if (addedAt != null) 'addedAt': addedAt!.toIso8601String(),
      if (defaultHeaders.isNotEmpty) 'defaultHeaders': defaultHeaders,
      if (defaultBody != null && defaultBody!.isNotEmpty)
        'defaultBody': defaultBody,
      if (timeoutSeconds != null) 'timeoutSeconds': timeoutSeconds,
      if (maxRetries != null) 'maxRetries': maxRetries,
      'supportsStreaming': supportsStreaming,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  /// Deserialize from JSON.
  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    final modelsList = json['models'] as List<dynamic>?;
    return ProviderConfig._(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sdk: json['sdk'] as String? ?? 'openai-compatible',
      baseUrl: json['baseUrl'] as String,
      auth: json['auth'] != null
          ? AuthConfig.fromJson(json['auth'] as Map<String, dynamic>)
          : const AuthConfig.none(),
      models: modelsList != null
          ? modelsList
                .map((m) => ModelConfig.fromJson(m as Map<String, dynamic>))
                .toList()
          : const [],
      enabled: json['enabled'] as bool? ?? true,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : null,
      defaultHeaders: (json['defaultHeaders'] as Map<String, dynamic>?) != null
          ? Map<String, String>.from(json['defaultHeaders'] as Map)
          : const {},
      defaultBody: json['defaultBody'] as Map<String, dynamic>?,
      timeoutSeconds: json['timeoutSeconds'] as int?,
      maxRetries: json['maxRetries'] as int?,
      supportsStreaming: json['supportsStreaming'] as bool? ?? true,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  String toString() {
    return 'ProviderConfig(id: $id, name: $name, baseUrl: $baseUrl, '
        'models: ${models.length}, enabled: $enabled)';
  }
}
