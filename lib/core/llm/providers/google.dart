/// Google AI (Gemini) provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Google AI — Gemini models (Flash, Pro).
ProviderConfig googleProvider() => ProviderConfig.full(
  id: 'google',
  name: 'Google AI',
  description: 'Google Gemini models (Flash, Pro).',
  baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'x-goog-api-key',
    bearerPrefix: '',
  ),
  sdk: 'google',
  enabled: false,
  models: [],
);
