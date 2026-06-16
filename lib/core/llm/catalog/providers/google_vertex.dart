/// Google Vertex AI provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// Google Vertex AI — enterprise Gemini via GCP.
/// Note: Uses OAuth2/ADC authentication. Basic AuthConfig is a placeholder.
ProviderConfig googleVertexProvider() => ProviderConfig.basic(
  id: 'google-vertex',
  name: 'Google Vertex AI',
  description:
      'Google Vertex AI — enterprise Gemini models '
      'via Google Cloud Platform.',
  baseUrl: 'https://LOCATION-aiplatform.googleapis.com',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
