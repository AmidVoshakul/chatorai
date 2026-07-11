/// Together AI provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

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
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
