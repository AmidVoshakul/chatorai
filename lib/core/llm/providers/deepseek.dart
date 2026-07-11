/// DeepSeek provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// DeepSeek — V3, R1 models via OpenAI-compatible API.
ProviderConfig deepseekProvider() => ProviderConfig.full(
  id: 'deepseek',
  name: 'DeepSeek',
  description: 'DeepSeek models (V3, R1) via OpenAI-compatible API.',
  baseUrl: 'https://api.deepseek.com/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [],
);
