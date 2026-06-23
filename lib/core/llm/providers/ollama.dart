/// Ollama (local) provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// Ollama — local LLM server. No API key needed.
ProviderConfig ollamaProvider() => ProviderConfig.basic(
  id: 'ollama',
  name: 'Ollama',
  description:
      'Local Ollama server — run open-source LLMs on your '
      'own machine. No API key needed.',
  baseUrl: 'http://localhost:11434',
  auth: const AuthConfig.none(),
  sdk: 'openai-compatible',
  enabled: true,
);
