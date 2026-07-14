/// Kilo AI provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Kilo AI — multi-provider API gateway.
ProviderConfig kiloProvider() => ProviderConfig.full(
  id: 'kilo',
  name: 'Kilo AI',
  description: 'Kilo AI — multi-provider API gateway.',
  baseUrl: 'https://api.kilo.ai/api/gateway',
  auth: AuthConfig.apiKey(apiKey: ''),
  sdk: 'openai-compatible',
  enabled: false,
  models: [],
);
