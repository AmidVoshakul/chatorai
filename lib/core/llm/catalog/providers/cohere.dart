/// Cohere provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Cohere — Command R/R+ models.
ProviderConfig cohereProvider() => ProviderConfig.full(
  id: 'cohere',
  name: 'Cohere',
  description: 'Cohere Command R/R+ models.',
  baseUrl: 'https://api.cohere.com/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [
    ModelConfig.full(
      id: 'cohere/command-r-plus-08-2024',
      providerId: 'cohere',
      modelName: 'command-r-plus-08-2024',
      displayName: 'Command R+',
      description: 'Cohere Command R+ — flagship RAG model',
      contextLength: 128000,
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
        inputCostPer1k: 0.0025,
        outputCostPer1k: 0.01,
      ),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'cohere/command-r-08-2024',
      providerId: 'cohere',
      modelName: 'command-r-08-2024',
      displayName: 'Command R',
      description: 'Cohere Command R — efficient RAG model',
      contextLength: 128000,
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
        outputCostPer1k: 0.0015,
      ),
      enabled: true,
    ),
  ],
);
