/// Cohere provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Cohere — Command R/R+ models.
ProviderConfig cohereProvider() => ProviderConfig.full(
  id: 'cohere',
  name: 'Cohere',
  description: 'Cohere Command R/R+ models.',
  baseUrl: 'https://api.cohere.com/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [],
);
