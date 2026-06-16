/// Together AI provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Together AI — cloud platform for open-source models.
ProviderConfig togetheraiProvider() => ProviderConfig.basic(
  id: 'togetherai',
  name: 'Together AI',
  description:
      'Together AI — cloud platform for open-source models '
      '(Llama, Mistral, DeepSeek, and more).',
  baseUrl: 'https://api.together.xyz/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
