/// 302.AI provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// 302.AI — multi-model API gateway.
ProviderConfig ai302Provider() => ProviderConfig.basic(
  id: '302ai',
  name: '302.AI',
  description: '302.AI — multi-model API gateway.',
  baseUrl: 'https://api.302.ai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
