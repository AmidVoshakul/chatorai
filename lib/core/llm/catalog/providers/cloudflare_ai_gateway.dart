/// Cloudflare AI Gateway provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Cloudflare AI Gateway — unified gateway for multiple AI providers.
ProviderConfig cloudflareAiGatewayProvider() => ProviderConfig.basic(
  id: 'cloudflare-ai-gateway',
  name: 'Cloudflare AI Gateway',
  description:
      'Cloudflare AI Gateway — unified gateway for '
      'multiple AI providers with caching and logging.',
  baseUrl: 'https://gateway.ai.cloudflare.com/v1/ACCOUNT_ID/GATEWAY_ID',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
