/// Perplexity provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Perplexity — online LLM with web search integration.
ProviderConfig perplexityProvider() => ProviderConfig.full(
  id: 'perplexity',
  name: 'Perplexity',
  description: 'Perplexity AI — online LLM with web search.',
  baseUrl: 'https://api.perplexity.ai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [
    ModelConfig.full(
      id: 'perplexity/sonar-pro',
      providerId: 'perplexity',
      modelName: 'sonar-pro',
      displayName: 'Sonar Pro',
      description: 'Perplexity Sonar Pro — online with web search',
      contextLength: 200000,
      defaultMaxTokens: 8192,
      capabilities: ModelCapabilities(
        reasoning: false,
        multimodal: false,
        vision: false,
        tools: false,
        streaming: true,
        jsonMode: false,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.001,
        outputCostPer1k: 0.003,
      ),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'perplexity/sonar',
      providerId: 'perplexity',
      modelName: 'sonar',
      displayName: 'Sonar',
      description: 'Perplexity Sonar — lightweight online model',
      contextLength: 127000,
      defaultMaxTokens: 8192,
      capabilities: ModelCapabilities(
        reasoning: false,
        multimodal: false,
        vision: false,
        tools: false,
        streaming: true,
        jsonMode: false,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.0005,
        outputCostPer1k: 0.001,
      ),
      enabled: true,
    ),
  ],
);
