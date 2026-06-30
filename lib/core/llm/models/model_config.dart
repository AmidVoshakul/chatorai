/// Model configuration for AI providers.
///
/// Defines a model's capabilities, pricing, context length, and available variants.
/// Follows OpenCode catalog patterns: immutable, serializable, schema-driven.
library;

import 'package:equatable/equatable.dart';

import 'model_variant.dart';
export 'model_variant.dart';

/// Capabilities of an AI model.
class ModelCapabilities extends Equatable {
  /// Supports reasoning/thinking output (like o1, Claude thinking).
  final bool reasoning;

  /// Supports multimodal input (images, PDFs, etc.).
  final bool multimodal;

  /// Supports vision (image understanding).
  final bool vision;

  /// Supports function/tool calling.
  final bool tools;

  /// Supports streaming responses.
  final bool streaming;

  /// Supports JSON mode (structured output).
  final bool jsonMode;

  const ModelCapabilities._({
    this.reasoning = false,
    this.multimodal = false,
    this.vision = false,
    this.tools = true,
    this.streaming = true,
    this.jsonMode = false,
  });

  /// Basic capabilities (tools + streaming).
  const factory ModelCapabilities.basic() = ModelCapabilities._;

  /// Full capabilities (all features enabled).
  factory ModelCapabilities.full() {
    return const ModelCapabilities._(
      reasoning: true,
      multimodal: true,
      vision: true,
      tools: true,
      streaming: true,
      jsonMode: true,
    );
  }

  /// Create capabilities with specific flags.
  factory ModelCapabilities({
    bool reasoning = false,
    bool multimodal = false,
    bool vision = false,
    bool tools = true,
    bool streaming = true,
    bool jsonMode = false,
  }) {
    return ModelCapabilities._(
      reasoning: reasoning,
      multimodal: multimodal,
      vision: vision,
      tools: tools,
      streaming: streaming,
      jsonMode: jsonMode,
    );
  }

  /// Create a copy with modified fields.
  ModelCapabilities copyWith({
    bool? reasoning,
    bool? multimodal,
    bool? vision,
    bool? tools,
    bool? streaming,
    bool? jsonMode,
  }) {
    return ModelCapabilities._(
      reasoning: reasoning ?? this.reasoning,
      multimodal: multimodal ?? this.multimodal,
      vision: vision ?? this.vision,
      tools: tools ?? this.tools,
      streaming: streaming ?? this.streaming,
      jsonMode: jsonMode ?? this.jsonMode,
    );
  }

  @override
  List<Object?> get props => [
    reasoning,
    multimodal,
    vision,
    tools,
    streaming,
    jsonMode,
  ];

  /// Serialize to JSON.
  Map<String, dynamic> toJson() {
    return {
      'reasoning': reasoning,
      'multimodal': multimodal,
      'vision': vision,
      'tools': tools,
      'streaming': streaming,
      'jsonMode': jsonMode,
    };
  }

  /// Deserialize from JSON.
  factory ModelCapabilities.fromJson(Map<String, dynamic> json) {
    return ModelCapabilities(
      reasoning: json['reasoning'] as bool? ?? false,
      multimodal: json['multimodal'] as bool? ?? false,
      vision: json['vision'] as bool? ?? false,
      tools: json['tools'] as bool? ?? true,
      streaming: json['streaming'] as bool? ?? true,
      jsonMode: json['jsonMode'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'ModelCapabilities(reasoning: $reasoning, multimodal: $multimodal, '
        'vision: $vision, tools: $tools, streaming: $streaming, jsonMode: $jsonMode)';
  }
}

/// Configuration for a single AI model.
///
/// Contains the model's metadata, capabilities, pricing, and available variants.
/// The [id] should be globally unique across all providers (e.g.,
/// 'openrouter/openai/gpt-4o').
class ModelConfig extends Equatable {
  /// Unique identifier (format: 'providerId/modelName').
  final String id;

  /// Provider ID this model belongs to.
  final String providerId;

  /// Model name as used in API calls (e.g., 'gpt-4o', 'claude-3-5-sonnet').
  final String modelName;

  /// Human-readable display name (e.g., 'GPT-4o', 'Claude 3.5 Sonnet').
  final String displayName;

  /// Description of the model.
  final String? description;

  /// Model capabilities.
  final ModelCapabilities capabilities;

  /// Maximum context length (in tokens).
  final int contextLength;

  /// Default maximum tokens for responses.
  final int? defaultMaxTokens;

  /// Pricing information.
  final ModelPricing? pricing;

  /// Available variants of this model.
  /// If empty, the model uses default parameters.
  final List<ModelVariant> variants;

  /// Whether this model is currently enabled for use.
  final bool enabled;

  /// When the model was added to the catalog.
  final DateTime? addedAt;

  /// Additional metadata (provider-specific fields).
  final Map<String, dynamic> metadata;

  const ModelConfig._({
    required this.id,
    required this.providerId,
    required this.modelName,
    required this.displayName,
    this.description,
    required this.capabilities,
    required this.contextLength,
    this.defaultMaxTokens,
    this.pricing,
    this.variants = const [],
    this.enabled = true,
    this.addedAt,
    this.metadata = const {},
  });

  /// Create a basic model configuration.
  factory ModelConfig.basic({
    required String providerId,
    required String modelName,
    required String displayName,
    String? description,
    ModelCapabilities? capabilities,
    required int contextLength,
    int? defaultMaxTokens,
    ModelPricing? pricing,
    List<ModelVariant>? variants,
    bool enabled = true,
  }) {
    return ModelConfig._(
      id: canonicalId(providerId, modelName),
      providerId: providerId,
      modelName: modelName,
      displayName: displayName,
      description: description,
      capabilities: capabilities ?? ModelCapabilities.basic(),
      contextLength: contextLength,
      defaultMaxTokens: defaultMaxTokens,
      pricing: pricing,
      variants: variants ?? const [],
      enabled: enabled,
    );
  }

  /// Create a full model configuration with all fields.
  factory ModelConfig.full({
    required String providerId,
    required String modelName,
    required String displayName,
    String? description,
    required ModelCapabilities capabilities,
    required int contextLength,
    int? defaultMaxTokens,
    ModelPricing? pricing,
    List<ModelVariant>? variants,
    bool enabled = true,
    DateTime? addedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ModelConfig._(
      id: canonicalId(providerId, modelName),
      providerId: providerId,
      modelName: modelName,
      displayName: displayName,
      description: description,
      capabilities: capabilities,
      contextLength: contextLength,
      defaultMaxTokens: defaultMaxTokens,
      pricing: pricing,
      variants: variants ?? const [],
      enabled: enabled,
      addedAt: addedAt,
      metadata: metadata ?? const {},
    );
  }

  /// Get the default variant (first one if exists, otherwise null).
  ModelVariant? get defaultVariant {
    if (variants.isEmpty) return null;
    return variants.first;
  }

  /// Get variant by ID.
  ModelVariant? getVariant(String variantId) {
    try {
      return variants.firstWhere((v) => v.id == variantId);
    } catch (e) {
      return null;
    }
  }

  /// Check if this model contains a variant with the given ID.
  /// Returns this model if found, null otherwise.
  ModelConfig? getModelByVariantId(String variantId) {
    if (variants.any((v) => v.id == variantId)) {
      return this;
    }
    return null;
  }

  /// Add a variant to this model.
  ModelConfig addModel(ModelVariant variant) {
    return copyWith(variants: [...variants, variant]);
  }

  /// Remove a variant by ID from this model.
  ModelConfig removeModel(String variantId) {
    return copyWith(
      variants: variants.where((v) => v.id != variantId).toList(),
    );
  }

  /// Update a variant in this model.
  ModelConfig updateModel(String variantId, ModelVariant updatedVariant) {
    return copyWith(
      variants: variants
          .map((v) => v.id == variantId ? updatedVariant : v)
          .toList(),
    );
  }

  /// Create a copy with modified fields.
  /// [id] is always derived from [modelName] + [providerId] — never set directly.
  ModelConfig copyWith({
    String? providerId,
    String? modelName,
    String? displayName,
    String? description,
    ModelCapabilities? capabilities,
    int? contextLength,
    int? defaultMaxTokens,
    ModelPricing? pricing,
    List<ModelVariant>? variants,
    bool? enabled,
    DateTime? addedAt,
    Map<String, dynamic>? metadata,
  }) {
    final newProviderId = providerId ?? this.providerId;
    final newModelName = modelName ?? this.modelName;
    return ModelConfig._(
      id: canonicalId(newProviderId, newModelName),
      providerId: newProviderId,
      modelName: newModelName,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      capabilities: capabilities ?? this.capabilities,
      contextLength: contextLength ?? this.contextLength,
      defaultMaxTokens: defaultMaxTokens ?? this.defaultMaxTokens,
      pricing: pricing ?? this.pricing,
      variants: variants ?? this.variants,
      enabled: enabled ?? this.enabled,
      addedAt: addedAt ?? this.addedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    providerId,
    modelName,
    displayName,
    description,
    capabilities,
    contextLength,
    defaultMaxTokens,
    pricing,
    variants,
    enabled,
    addedAt,
    metadata,
  ];

  /// Serialize to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'modelName': modelName,
      'displayName': displayName,
      if (description != null) 'description': description,
      'capabilities': capabilities.toJson(),
      'contextLength': contextLength,
      if (defaultMaxTokens != null) 'defaultMaxTokens': defaultMaxTokens,
      if (pricing != null) 'pricing': pricing!.toJson(),
      if (variants.isNotEmpty)
        'variants': variants.map((v) => v.toJson()).toList(),
      'enabled': enabled,
      if (addedAt != null) 'addedAt': addedAt!.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  /// Deserialize from JSON.
  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    final variantsList = json['variants'] as List<dynamic>?;
    final providerId = json['providerId'] as String;
    final modelName = json['modelName'] as String;
    return ModelConfig._(
      id: canonicalId(providerId, modelName),
      providerId: providerId,
      modelName: modelName,
      displayName: json['displayName'] as String,
      description: json['description'] as String?,
      capabilities: ModelCapabilities.fromJson(
        json['capabilities'] as Map<String, dynamic>,
      ),
      contextLength: json['contextLength'] as int,
      defaultMaxTokens: json['defaultMaxTokens'] as int?,
      pricing: json['pricing'] != null
          ? ModelPricing.fromJson(json['pricing'] as Map<String, dynamic>)
          : null,
      variants: variantsList != null
          ? variantsList
                .map((v) => ModelVariant.fromJson(v as Map<String, dynamic>))
                .toList()
          : const [],
      enabled: json['enabled'] as bool? ?? true,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : null,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  static String canonicalId(String providerId, String modelName) {
    return '$providerId/$modelName';
  }

  @override
  String toString() {
    return 'ModelConfig(id: $id, providerId: $providerId, modelName: $modelName, '
        'displayName: $displayName, contextLength: $contextLength, '
        'capabilities: $capabilities, variants: ${variants.length})';
  }
}
