/// Fireworks AI provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Fireworks AI — fast inference for open-source and custom models.
ProviderConfig fireworksProvider() => ProviderConfig.basic(
  id: 'fireworks',
  name: 'Fireworks AI',
  description:
      'Fireworks AI — fast inference for open-source '
      'and custom models.',
  baseUrl: 'https://api.fireworks.ai/inference/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
