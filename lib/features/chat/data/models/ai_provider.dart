/// Represents a supported AI provider configuration.
class AiProvider {
  final String id;
  final String name;
  final bool requiresApiKey;
  final String baseUrl;
  final String? iconPath;

  const AiProvider({
    required this.id,
    required this.name,
    this.requiresApiKey = true,
    required this.baseUrl,
    this.iconPath,
  });
}

/// Static list of all built-in AI providers.
class AiProviders {
  static const List<AiProvider> all = [
    AiProvider(
      id: 'openrouter',
      name: 'OpenRouter',
      baseUrl: 'https://openrouter.ai/api/v1',
    ),
    AiProvider(
      id: 'openai',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
    ),
    AiProvider(
      id: 'anthropic',
      name: 'Anthropic',
      baseUrl: 'https://api.anthropic.com/v1',
    ),
    AiProvider(
      id: 'google',
      name: 'Google AI',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    ),
    AiProvider(
      id: 'ollama',
      name: 'Ollama',
      requiresApiKey: false,
      baseUrl: 'http://localhost:11434',
    ),
    AiProvider(
      id: 'groq',
      name: 'Groq',
      baseUrl: 'https://api.groq.com/openai/v1',
    ),
  ];
}
