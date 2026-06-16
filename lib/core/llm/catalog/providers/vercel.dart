/// Vercel AI Gateway provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Vercel AI Gateway — unified edge gateway for AI providers.
ProviderConfig vercelProvider() => ProviderConfig.basic(
  id: 'vercel',
  name: 'Vercel AI Gateway',
  description:
      'Vercel AI Gateway — unified edge gateway '
      'for AI providers with caching and rate limiting.',
  baseUrl: 'https://gateway.ai.vercel.com/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
