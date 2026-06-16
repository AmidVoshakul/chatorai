/// Kilo AI provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Kilo AI — multi-provider API gateway.
ProviderConfig kiloProvider() => ProviderConfig.full(
  id: 'kilo',
  name: 'Kilo AI',
  description: 'Kilo AI — multi-provider API gateway.',
  baseUrl: 'https://api.kilo.ai/api/gateway',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [
    ModelConfig.full(
      id: 'kilo/kilo-13b',
      providerId: 'kilo',
      modelName: 'kilo-13b',
      displayName: 'Kilo 13B',
      description: 'Kilo AI 13B — lightweight gateway model',
      contextLength: 8192,
      defaultMaxTokens: 4096,
      capabilities: ModelCapabilities(
        reasoning: false,
        multimodal: false,
        vision: false,
        tools: true,
        streaming: true,
        jsonMode: true,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.0005,
        outputCostPer1k: 0.0005,
      ),
      enabled: true,
    ),
  ],
);
