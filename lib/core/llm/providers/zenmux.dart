/// ZenMux provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// ZenMux — multi-provider AI gateway.
ProviderConfig zenmuxProvider() => ProviderConfig.basic(
  id: 'zenmux',
  name: 'ZenMux',
  description: 'ZenMux — multi-provider AI API gateway.',
  baseUrl: 'https://zenmux.ai/api/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
