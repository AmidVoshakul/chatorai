/// Perplexity provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Perplexity — online LLM with web search integration.
ProviderConfig perplexityProvider() => ProviderConfig.full(
  id: 'perplexity',
  name: 'Perplexity',
  description: 'Perplexity AI — online LLM with web search.',
  baseUrl: 'https://api.perplexity.ai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [],
);
