/// Alibaba (DashScope) provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Alibaba — DashScope (Qwen models).
ProviderConfig alibabaProvider() => ProviderConfig.basic(
  id: 'alibaba',
  name: 'Alibaba',
  description: 'Alibaba DashScope — Qwen models via OpenAI-compatible API.',
  baseUrl: 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
