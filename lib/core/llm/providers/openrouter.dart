/// OpenRouter provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// OpenRouter — unified API gateway (200+ models, single key).
ProviderConfig openrouterProvider() => ProviderConfig.basic(
  id: 'openrouter',
  name: 'OpenRouter',
  description:
      'Unified API gateway supporting 200+ models from OpenAI, '
      'Anthropic, Google, and more. Single API key for many providers.',
  baseUrl: 'https://openrouter.ai/api/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
  ),
  sdk: 'openai-compatible',
  enabled: true,
);
