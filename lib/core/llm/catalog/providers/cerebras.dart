/// Cerebras provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Cerebras — ultra-fast inference on Wafer-Scale hardware.
ProviderConfig cerebrasProvider() => ProviderConfig.basic(
  id: 'cerebras',
  name: 'Cerebras',
  description: 'Cerebras — ultra-fast inference on Wafer-Scale hardware.',
  baseUrl: 'https://api.cerebras.ai/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
