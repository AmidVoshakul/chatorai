/// OpenCode Zen provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// OpenCode Zen — unified API from the OpenCode project.
ProviderConfig opencodeProvider() => ProviderConfig.basic(
  id: 'opencode',
  name: 'OpenCode Zen',
  description: 'OpenCode Zen — unified API from the OpenCode project.',
  baseUrl: 'https://opencode.ai/zen/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
