/// Nvidia NIM provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Nvidia NIM — optimized inference for Nvidia-accelerated models.
ProviderConfig nvidiaProvider() => ProviderConfig.basic(
  id: 'nvidia',
  name: 'Nvidia NIM',
  description:
      'Nvidia NIM — optimized inference for open and '
      'Nvidia-optimized models.',
  baseUrl: 'https://integrate.api.nvidia.com/v1',
  auth: AuthConfig.apiKey(
    apiKey: '',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
