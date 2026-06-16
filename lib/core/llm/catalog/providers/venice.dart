/// Venice AI provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Venice AI — privacy-focused AI API.
ProviderConfig veniceProvider() => ProviderConfig.basic(
  id: 'venice',
  name: 'Venice AI',
  description: 'Venice AI — privacy-focused AI API.',
  baseUrl: 'https://api.venice.ai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
