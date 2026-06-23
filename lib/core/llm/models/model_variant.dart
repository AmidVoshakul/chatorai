/// Model variant configuration.
///
/// A variant represents a specific configuration of a model with particular
/// parameters like temperature, maxTokens, etc. Some providers expose multiple
/// variants of the same base model (e.g., gpt-4-turbo, gpt-4o-mini).
///
/// Follows OpenCode patterns: immutable, serializable, schema-driven.
library;

import 'package:equatable/equatable.dart';

/// Model variant - a specific configuration of a model.
///
/// Each variant has its own ID, parameters, and potentially pricing.
/// The [id] should be globally unique across all providers.
class ModelVariant extends Equatable {
  /// Unique identifier for this variant (e.g., 'gpt-4o-mini').
  final String id;

  /// Human-readable name (e.g., 'GPT-4o Mini').
  final String name;

  /// Description of this variant.
  final String? description;

  /// Temperature parameter (0.0 - 2.0). Controls randomness.
  /// Default: 1.0
  final double temperature;

  /// Maximum tokens in the response.
  /// null means provider default.
  final int? maxTokens;

  /// Top-p parameter (nucleus sampling). 0.0 - 1.0.
  /// Default: 1.0
  final double? topP;

  /// Frequency penalty. -2.0 - 2.0.
  final double? frequencyPenalty;

  /// Presence penalty. -2.0 - 2.0.
  final double? presencePenalty;

  /// Stop sequences.
  final List<String>? stopSequences;

  /// Whether this variant supports reasoning/thinking.
  final bool supportsReasoning;

  /// Whether this variant supports multimodal input (images).
  final bool supportsMultimodal;

  /// Whether this variant supports tool/function calling.
  final bool supportsTools;

  /// Maximum context length for this variant.
  /// If null, uses parent ModelConfig's contextLength.
  final int? contextLength;

  /// Pricing information (per 1K tokens).
  /// If null, uses parent ModelConfig's pricing.
  final ModelPricing? pricing;

  /// Headers to override or add for this variant.
  ///
  /// Follows OpenCode pattern where variants can specify custom headers
  /// (e.g., `anthropic-beta` for thinking, `X-DS-Search` for DeepSeek).
  final Map<String, String>? headers;

  /// Body parameters to override or add for this variant.
  ///
  /// Follows OpenCode pattern where variants can specify custom body fields
  /// (e.g., `reasoning` config, `prompt_cache_key` for OpenRouter).
  final Map<String, dynamic>? body;

  const ModelVariant._({
    required this.id,
    required this.name,
    this.description,
    this.temperature = 1.0,
    this.maxTokens,
    this.topP,
    this.frequencyPenalty,
    this.presencePenalty,
    this.stopSequences,
    this.supportsReasoning = false,
    this.supportsMultimodal = false,
    this.supportsTools = true,
    this.contextLength,
    this.pricing,
    this.headers,
    this.body,
  });

  /// Create a basic variant with required fields.
  factory ModelVariant.basic({
    required String id,
    required String name,
    String? description,
    double temperature = 1.0,
    int? maxTokens,
    bool supportsReasoning = false,
    bool supportsMultimodal = false,
    bool supportsTools = true,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    return ModelVariant._(
      id: id,
      name: name,
      description: description,
      temperature: temperature,
      maxTokens: maxTokens,
      supportsReasoning: supportsReasoning,
      supportsMultimodal: supportsMultimodal,
      supportsTools: supportsTools,
      headers: headers,
      body: body,
    );
  }

  /// Create a variant with full configuration.
  factory ModelVariant.full({
    required String id,
    required String name,
    String? description,
    double temperature = 1.0,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    List<String>? stopSequences,
    bool supportsReasoning = false,
    bool supportsMultimodal = false,
    bool supportsTools = true,
    int? contextLength,
    ModelPricing? pricing,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    return ModelVariant._(
      id: id,
      name: name,
      description: description,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      stopSequences: stopSequences,
      supportsReasoning: supportsReasoning,
      supportsMultimodal: supportsMultimodal,
      supportsTools: supportsTools,
      contextLength: contextLength,
      pricing: pricing,
      headers: headers,
      body: body,
    );
  }

  /// Create a copy with modified fields.
  ModelVariant copyWith({
    String? id,
    String? name,
    String? description,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    List<String>? stopSequences,
    bool? supportsReasoning,
    bool? supportsMultimodal,
    bool? supportsTools,
    int? contextLength,
    ModelPricing? pricing,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool clearHeaders = false,
    bool clearBody = false,
  }) {
    return ModelVariant._(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      stopSequences: stopSequences ?? this.stopSequences,
      supportsReasoning: supportsReasoning ?? this.supportsReasoning,
      supportsMultimodal: supportsMultimodal ?? this.supportsMultimodal,
      supportsTools: supportsTools ?? this.supportsTools,
      contextLength: contextLength ?? this.contextLength,
      pricing: pricing ?? this.pricing,
      headers: clearHeaders ? headers : (headers ?? this.headers),
      body: clearBody ? body : (body ?? this.body),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    temperature,
    maxTokens,
    topP,
    frequencyPenalty,
    presencePenalty,
    stopSequences,
    supportsReasoning,
    supportsMultimodal,
    supportsTools,
    contextLength,
    pricing,
    headers,
    body,
  ];

  /// Serialize to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'temperature': temperature,
      if (maxTokens != null) 'maxTokens': maxTokens,
      if (topP != null) 'topP': topP,
      if (frequencyPenalty != null) 'frequencyPenalty': frequencyPenalty,
      if (presencePenalty != null) 'presencePenalty': presencePenalty,
      if (stopSequences != null) 'stopSequences': stopSequences,
      'supportsReasoning': supportsReasoning,
      'supportsMultimodal': supportsMultimodal,
      'supportsTools': supportsTools,
      if (contextLength != null) 'contextLength': contextLength,
      if (pricing != null) 'pricing': pricing!.toJson(),
      if (headers != null && headers!.isNotEmpty) 'headers': headers,
      if (body != null && body!.isNotEmpty) 'body': body,
    };
  }

  /// Deserialize from JSON.
  factory ModelVariant.fromJson(Map<String, dynamic> json) {
    return ModelVariant._(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 1.0,
      maxTokens: json['maxTokens'] as int?,
      topP: (json['topP'] as num?)?.toDouble(),
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble(),
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble(),
      stopSequences: (json['stopSequences'] as List<dynamic>?)?.cast<String>(),
      supportsReasoning: json['supportsReasoning'] as bool? ?? false,
      supportsMultimodal: json['supportsMultimodal'] as bool? ?? false,
      supportsTools: json['supportsTools'] as bool? ?? true,
      contextLength: json['contextLength'] as int?,
      pricing: json['pricing'] != null
          ? ModelPricing.fromJson(json['pricing'] as Map<String, dynamic>)
          : null,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as String),
      ),
      body: json['body'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'ModelVariant(id: $id, name: $name, temperature: $temperature, '
        'supportsReasoning: $supportsReasoning, supportsMultimodal: $supportsMultimodal)';
  }
}

/// Pricing information for a model.
///
/// Cost per 1K tokens (input and output may differ).
class ModelPricing extends Equatable {
  /// Cost per 1K input tokens (in USD).
  final double? inputCostPer1k;

  /// Cost per 1K output tokens (in USD).
  final double? outputCostPer1k;

  const ModelPricing._({this.inputCostPer1k, this.outputCostPer1k});

  /// Create pricing with both input and output costs.
  const factory ModelPricing({
    required double inputCostPer1k,
    required double outputCostPer1k,
  }) = ModelPricing._;

  /// Create pricing with only input cost (output same as input).
  factory ModelPricing.unified(double costPer1k) {
    return ModelPricing._(
      inputCostPer1k: costPer1k,
      outputCostPer1k: costPer1k,
    );
  }

  /// Create a copy with modified fields.
  ModelPricing copyWith({double? inputCostPer1k, double? outputCostPer1k}) {
    return ModelPricing._(
      inputCostPer1k: inputCostPer1k ?? this.inputCostPer1k,
      outputCostPer1k: outputCostPer1k ?? this.outputCostPer1k,
    );
  }

  @override
  List<Object?> get props => [inputCostPer1k, outputCostPer1k];

  /// Serialize to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (inputCostPer1k != null) 'inputCostPer1k': inputCostPer1k,
      if (outputCostPer1k != null) 'outputCostPer1k': outputCostPer1k,
    };
  }

  /// Deserialize from JSON.
  factory ModelPricing.fromJson(Map<String, dynamic> json) {
    return ModelPricing._(
      inputCostPer1k: (json['inputCostPer1k'] as num?)?.toDouble(),
      outputCostPer1k: (json['outputCostPer1k'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'ModelPricing(input: \$${inputCostPer1k ?? 'N/A'}/1k, '
        'output: \$${outputCostPer1k ?? 'N/A'}/1k)';
  }
}
