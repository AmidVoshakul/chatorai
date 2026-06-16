/// xAI (Grok) provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// xAI — Grok models.
ProviderConfig xaiProvider() => ProviderConfig.full(
  id: 'xai',
  name: 'xAI',
  description: 'xAI Grok models.',
  baseUrl: 'https://api.x.ai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [
    ModelConfig.full(
      id: 'xai/grok-2',
      providerId: 'xai',
      modelName: 'grok-2',
      displayName: 'Grok 2',
      description: 'xAI Grok 2 — general-purpose chat model',
      contextLength: 131072,
      defaultMaxTokens: 8192,
      capabilities: ModelCapabilities(
        reasoning: false,
        multimodal: false,
        vision: false,
        tools: true,
        streaming: true,
        jsonMode: true,
      ),
      pricing: const ModelPricing(inputCostPer1k: 0.002, outputCostPer1k: 0.01),
      enabled: true,
    ),
  ],
);
