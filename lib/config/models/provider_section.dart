/// Placeholder for provider configuration section.
///
/// TODO: Implement real provider models (OpenRouter config, API endpoints,
/// rate limits, model routing). Currently stores raw openrouter Map.
class ProviderSection {
  final Map<String, dynamic>? openrouter;

  const ProviderSection({this.openrouter});

  factory ProviderSection.fromJson(Map<String, dynamic>? json) {
    return ProviderSection(
      openrouter: json?['openrouter'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (openrouter != null) 'openrouter': openrouter,
  };
}
