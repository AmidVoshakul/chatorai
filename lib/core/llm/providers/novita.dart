/// Novita AI provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Novita AI — multi-model gateway with competitive pricing.
ProviderConfig novitaProvider() => ProviderConfig.basic(
  id: 'novita',
  name: 'Novita AI',
  description: 'Novita AI — multi-model gateway with competitive pricing.',
  baseUrl: 'https://api.novita.ai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
