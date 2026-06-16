/// DeepSeek provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// DeepSeek — V3, R1 models via OpenAI-compatible API.
ProviderConfig deepseekProvider() => ProviderConfig.full(
  id: 'deepseek',
  name: 'DeepSeek',
  description: 'DeepSeek models (V3, R1) via OpenAI-compatible API.',
  baseUrl: 'https://api.deepseek.com/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [
    ModelConfig.full(
      id: 'deepseek/deepseek-chat',
      providerId: 'deepseek',
      modelName: 'deepseek-chat',
      displayName: 'DeepSeek V3',
      description: 'DeepSeek V3 — general-purpose chat model',
      contextLength: 64000,
      defaultMaxTokens: 8192,
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
        outputCostPer1k: 0.0015,
      ),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'deepseek/deepseek-reasoner',
      providerId: 'deepseek',
      modelName: 'deepseek-reasoner',
      displayName: 'DeepSeek R1',
      description: 'DeepSeek R1 — reasoning model with chain-of-thought',
      contextLength: 64000,
      defaultMaxTokens: 8192,
      capabilities: ModelCapabilities(
        reasoning: true,
        multimodal: false,
        vision: false,
        tools: false,
        streaming: true,
        jsonMode: false,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.00055,
        outputCostPer1k: 0.00219,
      ),
      enabled: true,
    ),
  ],
);
