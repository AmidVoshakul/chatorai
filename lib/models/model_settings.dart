// ===========================================================================
// MODEL SETTINGS CLASS
// ===========================================================================

class ModelSettings {
  final String modelId;
  final double temperature;
  final int maxTokens;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final String? systemPrompt;
  final bool stream;
  final int? maxContextLength;
  final bool reasoningEnabled;

  // Model capabilities from API
  final int? apiMaxTokens;
  final double? apiMaxTemperature;
  final double? apiMinTemperature;
  final int? apiContextLength;

  const ModelSettings({
    required this.modelId,
    this.temperature = 1.0,
    this.maxTokens = 4096,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.systemPrompt,
    this.stream = true,
    this.maxContextLength,
    this.reasoningEnabled = true,
    this.apiMaxTokens,
    this.apiMaxTemperature,
    this.apiMinTemperature,
    this.apiContextLength,
  });

  /// Default settings for a new model
  factory ModelSettings.defaultForModel(String modelId) {
    return ModelSettings(
      modelId: modelId,
      temperature: 1.0,
      maxTokens: 4096,
      topP: 1.0,
      frequencyPenalty: 0.0,
      presencePenalty: 0.0,
      stream: true,
      reasoningEnabled: true,
    );
  }

  /// Create settings from API model information
  factory ModelSettings.fromApiModel(
    String modelId,
    int? contextLength,
    int? maxTokens,
  ) {
    // Use provided maxTokens or fall back to 97% of contextLength (to avoid 400 errors)
    // or default to 4096
    final apiLimit = contextLength ?? 4096;
    final safeMaxTokens = maxTokens ?? (apiLimit * 0.97).toInt();
    final defaultTemperature = 1.0;

    return ModelSettings(
      modelId: modelId,
      temperature: defaultTemperature,
      maxTokens: safeMaxTokens,
      topP: 1.0,
      frequencyPenalty: 0.0,
      presencePenalty: 0.0,
      stream: true,
      reasoningEnabled: true,
      maxContextLength: contextLength,
      apiMaxTokens: maxTokens ?? contextLength,
      apiContextLength: contextLength,
      apiMaxTemperature: 2.0, // Common max
      apiMinTemperature: 0.0, // Common min
    );
  }

  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  ModelSettings copyWith({
    String? modelId,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    String? systemPrompt,
    bool? stream,
    int? maxContextLength,
    bool? reasoningEnabled,
    int? apiMaxTokens,
    double? apiMaxTemperature,
    double? apiMinTemperature,
    int? apiContextLength,
  }) {
    return ModelSettings(
      modelId: modelId ?? this.modelId,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      stream: stream ?? this.stream,
      maxContextLength: maxContextLength ?? this.maxContextLength,
      reasoningEnabled: reasoningEnabled ?? this.reasoningEnabled,
      apiMaxTokens: apiMaxTokens ?? this.apiMaxTokens,
      apiMaxTemperature: apiMaxTemperature ?? this.apiMaxTemperature,
      apiMinTemperature: apiMinTemperature ?? this.apiMinTemperature,
      apiContextLength: apiContextLength ?? this.apiContextLength,
    );
  }

  // ===========================================================================
  // SERIALIZATION
  // ===========================================================================

  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'topP': topP,
      'frequencyPenalty': frequencyPenalty,
      'presencePenalty': presencePenalty,
      'systemPrompt': systemPrompt,
      'stream': stream,
      'maxContextLength': maxContextLength,
      'reasoningEnabled': reasoningEnabled,
      'apiMaxTokens': apiMaxTokens,
      'apiMaxTemperature': apiMaxTemperature,
      'apiMinTemperature': apiMinTemperature,
      'apiContextLength': apiContextLength,
    };
  }

  factory ModelSettings.fromJson(Map<String, dynamic> json) {
    return ModelSettings(
      modelId: json['modelId'],
      temperature: (json['temperature'] ?? 1.0).toDouble(),
      maxTokens: json['maxTokens'] ?? 4096,
      topP: (json['topP'] ?? 1.0).toDouble(),
      frequencyPenalty: (json['frequencyPenalty'] ?? 0.0).toDouble(),
      presencePenalty: (json['presencePenalty'] ?? 0.0).toDouble(),
      systemPrompt: json['systemPrompt'],
      stream: json['stream'] ?? true,
      maxContextLength: json['maxContextLength'],
      reasoningEnabled: json['reasoningEnabled'] ?? true,
      apiMaxTokens: json['apiMaxTokens'],
      apiMaxTemperature: json['apiMaxTemperature']?.toDouble(),
      apiMinTemperature: json['apiMinTemperature']?.toDouble(),
      apiContextLength: json['apiContextLength'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ModelSettings &&
        other.modelId == modelId &&
        other.temperature == temperature &&
        other.maxTokens == maxTokens &&
        other.topP == topP &&
        other.frequencyPenalty == frequencyPenalty &&
        other.presencePenalty == presencePenalty &&
        other.systemPrompt == systemPrompt &&
        other.stream == stream &&
        other.maxContextLength == maxContextLength &&
        other.reasoningEnabled == reasoningEnabled &&
        other.apiMaxTokens == apiMaxTokens &&
        other.apiMaxTemperature == apiMaxTemperature &&
        other.apiMinTemperature == apiMinTemperature &&
        other.apiContextLength == apiContextLength;
  }

  @override
  int get hashCode {
    return Object.hash(
      modelId,
      temperature,
      maxTokens,
      topP,
      frequencyPenalty,
      presencePenalty,
      systemPrompt,
      stream,
      maxContextLength,
      reasoningEnabled,
      apiMaxTokens,
      apiMaxTemperature,
      apiMinTemperature,
      apiContextLength,
    );
  }

  @override
  String toString() {
    return 'ModelSettings(modelId: $modelId, temperature: $temperature, maxTokens: $maxTokens, topP: $topP, frequencyPenalty: $frequencyPenalty, presencePenalty: $presencePenalty, systemPrompt: $systemPrompt, stream: $stream, maxContextLength: $maxContextLength, apiMaxTokens: $apiMaxTokens, apiMaxTemperature: $apiMaxTemperature, apiMinTemperature: $apiMinTemperature, apiContextLength: $apiContextLength)';
  }
}
