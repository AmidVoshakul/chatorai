/// SAP AI Core provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// SAP AI Core — enterprise AI orchestration on SAP Business Technology Platform.
ProviderConfig sapAiCoreProvider() => ProviderConfig.basic(
  id: 'sap-ai-core',
  name: 'SAP AI Core',
  description:
      'SAP AI Core — enterprise AI orchestration '
      'on SAP Business Technology Platform.',
  baseUrl: 'https://api.ai.prod.eu-central-1.aws.ml.hana.ondemand.com/v2',
  auth: AuthConfig.apiKey(
    apiKey: '',
    apiKeyHeader: 'Authorization',
    bearerPrefix: 'Bearer ',
  ),
  sdk: 'openai-compatible',
  enabled: false,
);
