/// GitHub Copilot provider definition.
library;

import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

/// GitHub Copilot — AI assistant via GitHub.
ProviderConfig githubCopilotProvider() => ProviderConfig.basic(
  id: 'github-copilot',
  name: 'GitHub Copilot',
  description: 'GitHub Copilot — AI assistant via GitHub API.',
  baseUrl: 'https://api.githubcopilot.com',
  auth: AuthConfig.apiKey(apiKey: ''),
  sdk: 'openai-compatible',
  enabled: false,
);
