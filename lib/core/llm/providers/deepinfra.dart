/// DeepInfra provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// DeepInfra — serverless inference for open-source models.
ProviderConfig deepinfraProvider() => ProviderConfig.basic(
  id: 'deepinfra',
  name: 'DeepInfra',
  description: 'DeepInfra — serverless inference for open-source LLMs.',
  baseUrl: 'https://api.deepinfra.com/v1/openai',
  auth: AuthConfig.apiKey(apiKey: ''),
  sdk: 'openai-compatible',
  enabled: false,
);
