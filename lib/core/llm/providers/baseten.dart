/// Baseten provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Baseten — serverless inference for open-source and custom models.
ProviderConfig basetenProvider() => ProviderConfig.basic(
  id: 'baseten',
  name: 'Baseten',
  description:
      'Baseten — serverless inference for open-source '
      'and custom models.',
  baseUrl: 'https://inference.baseten.co/v1',
  auth: AuthConfig.apiKey(apiKey: ''),
  sdk: 'openai-compatible',
  enabled: false,
);
