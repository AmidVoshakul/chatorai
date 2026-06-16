/// Groq provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Groq — LPU inference engine (fast inference for Llama, Mixtral, etc.).
ProviderConfig groqProvider() => ProviderConfig.full(
  id: 'groq',
  name: 'Groq',
  description:
      'Groq LPU inference engine — extremely fast inference '
      'for Llama, Mixtral and other open models.',
  baseUrl: 'https://api.groq.com/openai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [
    ModelConfig.full(
      id: 'groq/llama-3.3-70b-versatile',
      providerId: 'groq',
      modelName: 'llama-3.3-70b-versatile',
      displayName: 'Llama 3.3 70B',
      description: 'Meta Llama 3.3 70B — versatile, high-quality',
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
      pricing: const ModelPricing(
        inputCostPer1k: 0.00059,
        outputCostPer1k: 0.00079,
      ),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'groq/llama-3.1-8b-instant',
      providerId: 'groq',
      modelName: 'llama-3.1-8b-instant',
      displayName: 'Llama 3.1 8B',
      description: 'Meta Llama 3.1 8B — fast, lightweight',
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
      pricing: const ModelPricing(
        inputCostPer1k: 0.00005,
        outputCostPer1k: 0.00008,
      ),
      enabled: true,
    ),
    ModelConfig.full(
      id: 'groq/deepseek-r1-distill-llama-70b',
      providerId: 'groq',
      modelName: 'deepseek-r1-distill-llama-70b',
      displayName: 'DeepSeek R1 Distill Llama 70B',
      description: 'DeepSeek R1 distilled into Llama 3.3 70B',
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
      pricing: const ModelPricing(
        inputCostPer1k: 0.00075,
        outputCostPer1k: 0.00099,
      ),
      enabled: true,
    ),
  ],
);
