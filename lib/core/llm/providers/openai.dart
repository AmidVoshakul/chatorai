/// OpenAI provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// OpenAI — GPT-4o, GPT-4o-mini, o1, o3-mini and more.
ProviderConfig openaiProvider() => ProviderConfig.full(
  id: 'openai',
  name: 'OpenAI',
  description: 'OpenAI GPT-4o, GPT-4o-mini, o1, o3-mini and more.',
  baseUrl: 'https://api.openai.com/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai',
  enabled: false,
  models: [
    ModelConfig.full(
      id: 'openai/gpt-4o',
      providerId: 'openai',
      modelName: 'gpt-4o',
      displayName: 'GPT-4o',
      description: 'OpenAI GPT-4o — multimodal, vision, tool use',
      contextLength: 128000,
      defaultMaxTokens: 16384,
      capabilities: ModelCapabilities(
        reasoning: false,
        multimodal: true,
        vision: true,
        tools: true,
        streaming: true,
        jsonMode: true,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.0025,
        outputCostPer1k: 0.01,
      ),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'openai/gpt-4o-mini',
      providerId: 'openai',
      modelName: 'gpt-4o-mini',
      displayName: 'GPT-4o Mini',
      description: 'OpenAI GPT-4o Mini — lightweight, cost-efficient',
      contextLength: 128000,
      defaultMaxTokens: 16384,
      capabilities: ModelCapabilities(
        reasoning: false,
        multimodal: true,
        vision: true,
        tools: true,
        streaming: true,
        jsonMode: true,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.00015,
        outputCostPer1k: 0.0006,
      ),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'openai/o1',
      providerId: 'openai',
      modelName: 'o1',
      displayName: 'o1',
      description: 'OpenAI o1 — reasoning model with extended thinking',
      contextLength: 200000,
      defaultMaxTokens: 100000,
      capabilities: ModelCapabilities(
        reasoning: true,
        multimodal: false,
        vision: true,
        tools: true,
        streaming: false,
        jsonMode: false,
      ),
      pricing: const ModelPricing(inputCostPer1k: 0.015, outputCostPer1k: 0.06),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'openai/o3-mini',
      providerId: 'openai',
      modelName: 'o3-mini',
      displayName: 'o3-mini',
      description: 'OpenAI o3-mini — compact reasoning model',
      contextLength: 200000,
      defaultMaxTokens: 100000,
      capabilities: ModelCapabilities(
        reasoning: true,
        multimodal: false,
        vision: false,
        tools: true,
        streaming: false,
        jsonMode: true,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.0011,
        outputCostPer1k: 0.0044,
      ),
      enabled: true,
    ),
  ],
);
