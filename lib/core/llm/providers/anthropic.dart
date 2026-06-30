/// Anthropic (Claude) provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Anthropic — Claude models (Sonnet, Opus, Haiku).
ProviderConfig anthropicProvider() => ProviderConfig.full(
  id: 'anthropic',
  name: 'Anthropic',
  description:
      'Anthropic Claude models (Sonnet, Opus, Haiku) with '
      'extended reasoning support.',
  baseUrl: 'https://api.anthropic.com/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'x-api-key',
    bearerPrefix: '',
  ),
  defaultHeaders: const {'anthropic-version': '2023-06-01'},
  sdk: 'anthropic',
  enabled: false,
  models: [],
);
