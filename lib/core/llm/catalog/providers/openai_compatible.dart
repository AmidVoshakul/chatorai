/// OpenAI-compatible provider template.
///
/// Generic template for any OpenAI-compatible API endpoint.
/// Users configure the base URL and API key in settings.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// OpenAI-compatible — generic template for any OpenAI-compatible API.
ProviderConfig openaiCompatibleProvider() => ProviderConfig.basic(
  id: 'openai-compatible',
  name: 'OpenAI Compatible',
  description:
      'Generic OpenAI-compatible API provider. '
      'Configure your own base URL and API key.',
  baseUrl: 'http://localhost:8080/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
