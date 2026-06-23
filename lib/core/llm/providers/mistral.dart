/// Mistral AI provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Mistral AI — Mistral Large, Small, Nemo, Codestral.
ProviderConfig mistralProvider() => ProviderConfig.full(
  id: 'mistral',
  name: 'Mistral AI',
  description: 'Mistral AI models (Mistral Large, Small, Nemo, Codestral).',
  baseUrl: 'https://api.mistral.ai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [
    ModelConfig.full(
      id: 'mistral/mistral-large-2411',
      providerId: 'mistral',
      modelName: 'mistral-large-2411',
      displayName: 'Mistral Large',
      description: 'Mistral Large — flagship model',
      contextLength: 131072,
      defaultMaxTokens: 8192,
      capabilities: ModelCapabilities(
        reasoning: false,
        multimodal: false,
        vision: true,
        tools: true,
        streaming: true,
        jsonMode: true,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.002,
        outputCostPer1k: 0.006,
      ),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'mistral/mistral-small-2501',
      providerId: 'mistral',
      modelName: 'mistral-small-2501',
      displayName: 'Mistral Small',
      description: 'Mistral Small — lightweight, efficient',
      contextLength: 131072,
      defaultMaxTokens: 8192,
      capabilities: ModelCapabilities(
        reasoning: false,
        multimodal: false,
        vision: true,
        tools: true,
        streaming: true,
        jsonMode: true,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.001,
        outputCostPer1k: 0.003,
      ),
      enabled: true,
    ),
  ],
);
