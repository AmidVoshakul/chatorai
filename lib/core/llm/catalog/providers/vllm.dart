/// vLLM (local) provider definition.
library;

import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';

/// vLLM — high-throughput local inference server.
ProviderConfig vllmProvider() => ProviderConfig.basic(
  id: 'vllm',
  name: 'vLLM',
  description:
      'vLLM — high-throughput local inference server '
      'with OpenAI-compatible API.',
  baseUrl: 'http://localhost:8000/v1',
  auth: const AuthConfig.none(),
  sdk: 'openai-compatible',
  enabled: false,
);
