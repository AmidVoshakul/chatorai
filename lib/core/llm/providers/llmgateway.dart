/// LLM Gateway provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// LLM Gateway — unified API gateway for multiple LLM providers.
ProviderConfig llmgatewayProvider() => ProviderConfig.basic(
  id: 'llmgateway',
  name: 'LLM Gateway',
  description:
      'LLM Gateway — unified API gateway for multiple '
      'LLM providers with routing and fallback.',
  baseUrl: 'https://api.llmgateway.io/v1',
  auth: AuthConfig.apiKey(apiKey: ''),
  sdk: 'openai-compatible',
  enabled: false,
);
