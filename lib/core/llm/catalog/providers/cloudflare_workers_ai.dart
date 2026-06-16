/// Cloudflare Workers AI provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Cloudflare Workers AI — serverless AI inference on Cloudflare.
ProviderConfig cloudflareWorkersAiProvider() => ProviderConfig.basic(
  id: 'cloudflare-workers-ai',
  name: 'Cloudflare Workers AI',
  description:
      'Cloudflare Workers AI — serverless AI inference '
      'on Cloudflare global network.',
  baseUrl: 'https://api.cloudflare.com/client/v4/accounts/ACCOUNT_ID/ai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
