class ModelSettings {
  final String modelId;
  final double temperature;
  final String? systemPrompt;
  final bool stream;
  final bool reasoningEnabled;

  const ModelSettings({
    required this.modelId,
    this.temperature = 1.0,
    this.systemPrompt,
    this.stream = true,
    this.reasoningEnabled = true,
  });

  factory ModelSettings.defaultForModel(
    String modelId, {
    double? defaultTemperature,
  }) {
    return ModelSettings(
      modelId: modelId,
      temperature: defaultTemperature ?? 1.0,
      stream: true,
      reasoningEnabled: true,
    );
  }

  ModelSettings copyWith({
    String? modelId,
    double? temperature,
    String? systemPrompt,
    bool? stream,
    bool? reasoningEnabled,
  }) {
    return ModelSettings(
      modelId: modelId ?? this.modelId,
      temperature: temperature ?? this.temperature,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      stream: stream ?? this.stream,
      reasoningEnabled: reasoningEnabled ?? this.reasoningEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'temperature': temperature,
      'systemPrompt': systemPrompt,
      'stream': stream,
      'reasoningEnabled': reasoningEnabled,
    };
  }

  factory ModelSettings.fromJson(Map<String, dynamic> json) {
    return ModelSettings(
      modelId: json['modelId'] as String,
      temperature: (json['temperature'] ?? 1.0).toDouble(),
      systemPrompt: json['systemPrompt'] as String?,
      stream: json['stream'] ?? true,
      reasoningEnabled: json['reasoningEnabled'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModelSettings &&
        other.modelId == modelId &&
        other.temperature == temperature &&
        other.systemPrompt == systemPrompt &&
        other.stream == stream &&
        other.reasoningEnabled == reasoningEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      modelId,
      temperature,
      systemPrompt,
      stream,
      reasoningEnabled,
    );
  }

  @override
  String toString() {
    return 'ModelSettings(modelId: $modelId, temperature: $temperature, systemPrompt: $systemPrompt, stream: $stream, reasoningEnabled: $reasoningEnabled)';
  }
}
