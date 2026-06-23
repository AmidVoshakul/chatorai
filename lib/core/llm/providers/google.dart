/// Google AI (Gemini) provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Google AI — Gemini models (Flash, Pro).
ProviderConfig googleProvider() => ProviderConfig.full(
  id: 'google',
  name: 'Google AI',
  description: 'Google Gemini models (Flash, Pro).',
  baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'x-goog-api-key',
    bearerPrefix: '',
  ),
  sdk: 'google',
  enabled: false,
  models: [
    ModelConfig.full(
      id: 'google/gemini-2.5-pro',
      providerId: 'google',
      modelName: 'gemini-2.5-pro',
      displayName: 'Gemini 2.5 Pro',
      description: 'Google Gemini 2.5 Pro — multimodal reasoning',
      contextLength: 1048576,
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
        inputCostPer1k: 0.00125,
        outputCostPer1k: 0.005,
      ),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'google/gemini-2.5-flash',
      providerId: 'google',
      modelName: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
      description: 'Google Gemini 2.5 Flash — fast, efficient',
      contextLength: 1048576,
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
        inputCostPer1k: 0.000075,
        outputCostPer1k: 0.0003,
      ),
      enabled: true,
    ),
  ],
);
