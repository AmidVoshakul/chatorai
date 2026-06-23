/// LM Studio (local) provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// LM Studio — local GUI for running open-source LLMs.
ProviderConfig lmstudioProvider() => ProviderConfig.basic(
  id: 'lmstudio',
  name: 'LM Studio',
  description:
      'LM Studio — local GUI for running open-source LLMs '
      'with OpenAI-compatible API.',
  baseUrl: 'http://127.0.0.1:1234/v1',
  auth: const AuthConfig.none(),
  sdk: 'openai-compatible',
  enabled: false,
);
