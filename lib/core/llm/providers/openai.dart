/// OpenAI provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// OpenAI — GPT-4o, GPT-4o-mini, o1, o3-mini and more.
ProviderConfig openaiProvider() => ProviderConfig.full(
  id: 'openai',
  name: 'OpenAI',
  description: 'OpenAI GPT-4o, GPT-4o-mini, o1, o3-mini and more.',
  baseUrl: 'https://api.openai.com/v1',
  auth: AuthConfig.apiKey(apiKey: ''),
  sdk: 'openai',
  enabled: false,
  models: [],
);
