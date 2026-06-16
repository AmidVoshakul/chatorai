/// Anthropic (Claude) provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Anthropic — Claude models (Sonnet, Opus, Haiku).
ProviderConfig anthropicProvider() => ProviderConfig.full(
  id: 'anthropic',
  name: 'Anthropic',
  description:
      'Anthropic Claude models (Sonnet, Opus, Haiku) with '
      'extended reasoning support.',
  baseUrl: 'https://api.anthropic.com/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'x-api-key',
    bearerPrefix: '',
  ),
  defaultHeaders: const {'anthropic-version': '2023-06-01'},
  sdk: 'anthropic',
  enabled: false,
  models: [
    ModelConfig.full(
      id: 'anthropic/claude-sonnet-4-20250514',
      providerId: 'anthropic',
      modelName: 'claude-sonnet-4-20250514',
      displayName: 'Claude Sonnet 4',
      description: 'Anthropic Claude Sonnet 4 — balanced performance',
      contextLength: 200000,
      defaultMaxTokens: 8192,
      capabilities: ModelCapabilities(
        reasoning: true,
        multimodal: true,
        vision: true,
        tools: true,
        streaming: true,
        jsonMode: true,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.003,
        outputCostPer1k: 0.015,
      ),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'anthropic/claude-haiku-4-20250514',
      providerId: 'anthropic',
      modelName: 'claude-haiku-4-20250514',
      displayName: 'Claude Haiku 4',
      description: 'Anthropic Claude Haiku 4 — fast, lightweight',
      contextLength: 200000,
      defaultMaxTokens: 8192,
      capabilities: ModelCapabilities(
        reasoning: false,
        multimodal: true,
        vision: true,
        tools: true,
        streaming: true,
        jsonMode: true,
      ),
      pricing: const ModelPricing(
        inputCostPer1k: 0.0008,
        outputCostPer1k: 0.004,
      ),
      enabled: true,
    ),
  ],
);
