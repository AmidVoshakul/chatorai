/// Hugging Face provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Hugging Face — community models via Inference API.
ProviderConfig huggingfaceProvider() => ProviderConfig.basic(
  id: 'huggingface',
  name: 'Hugging Face',
  description: 'Hugging Face — community models via Inference API.',
  baseUrl: 'https://router.huggingface.co/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
