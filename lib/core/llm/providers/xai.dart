/// xAI (Grok) provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// xAI — Grok models.
ProviderConfig xaiProvider() => ProviderConfig.full(
  id: 'xai',
  name: 'xAI',
  description: 'xAI Grok models.',
  baseUrl: 'https://api.x.ai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
  ),
  sdk: 'openai-compatible',
  enabled: false,
  models: [],
);
