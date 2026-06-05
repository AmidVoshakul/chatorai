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

  const OpenRouterModel({
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
    Map<String, dynamic> modelData;
    if (json.containsKey('data')) {
      modelData = json['data'] is Map<String, dynamic> ? json['data'] : json;
    } else {
      modelData = json;
    }

    final architecture = modelData['architecture'] ?? {};
    final inputModalities = architecture['input_modalities'] ?? [];
    final modality = architecture['modality'] ?? '';

    final supportedParameters = modelData['supported_parameters'] ?? [];

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

    final providerRaw = modelData['provider'];
    String? provider;
    if (providerRaw is Map<String, dynamic>) {
      provider = providerRaw['name'] as String?;
    } else if (providerRaw is Map) {
      final providerMap = Map<String, dynamic>.from(providerRaw);
      provider = providerMap['name'] as String?;
    } else if (providerRaw is String) {
      provider = providerRaw;
    } else {
      final modelId = modelData['id'] as String?;
      if (modelId != null && modelId.contains('/')) {
        final parts = modelId.split('/');
        if (parts.length >= 2) {
          provider = parts[0];
        }
      }
    }

    int? parsedContextLength;
    if (contextLength is int) {
      parsedContextLength = contextLength;
    } else if (contextLength is String) {
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'provider': provider,
    'pricing': {'prompt': pricingPrompt, 'completion': pricingCompletion},
    'context_length': contextLength,
    'capabilities': capabilities.toJson(),
  };
}
