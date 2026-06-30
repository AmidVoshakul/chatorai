/// Mistral AI provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
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
  models: [],
);
