/// Microsoft Azure OpenAI provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Azure OpenAI — enterprise OpenAI via Azure.
/// Note: Uses api-key header (not Bearer). URL includes resource name.
ProviderConfig azureProvider() => ProviderConfig.basic(
  id: 'azure',
  name: 'Azure OpenAI',
  description:
      'Microsoft Azure OpenAI — enterprise OpenAI API. '
      'Requires resource name and deployment ID.',
  baseUrl: 'https://YOUR_RESOURCE_NAME.openai.azure.com',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'api-key',
    bearerPrefix: '',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
