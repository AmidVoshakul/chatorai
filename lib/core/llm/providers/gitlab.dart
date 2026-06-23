/// GitLab AI provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// GitLab AI — AI features via GitLab API.
ProviderConfig gitlabProvider() => ProviderConfig.basic(
  id: 'gitlab',
  name: 'GitLab AI',
  description: 'GitLab AI — AI-assisted features via GitLab API.',
  baseUrl: 'https://gitlab.com/api/v4/ai',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
