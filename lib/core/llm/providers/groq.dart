/// Groq provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Groq — LPU inference engine (fast inference for Llama, Mixtral, etc.).
ProviderConfig groqProvider() => ProviderConfig.full(
  id: 'groq',
  name: 'Groq',
  description:
      'Groq LPU inference engine — extremely fast inference '
      'for Llama, Mixtral and other open models.',
  baseUrl: 'https://api.groq.com/openai/v1',
  auth: AuthConfig.apiKey(apiKey: ''),
  sdk: 'openai-compatible',
  enabled: false,
  models: [],
);
