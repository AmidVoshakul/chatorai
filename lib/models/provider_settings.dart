/// Per-provider settings stored locally.
class ProviderSettings {
  final bool enabled;
  final String? apiKey;
  final String? baseUrl;
  final List<String> selectedModelIds;

  const ProviderSettings({
    this.enabled = false,
    this.apiKey,
    this.baseUrl,
    this.selectedModelIds = const [],
  });

  ProviderSettings copyWith({
    bool? enabled,
    String? apiKey,
    String? baseUrl,
    List<String>? selectedModelIds,
  }) {
    return ProviderSettings(
      enabled: enabled ?? this.enabled,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      selectedModelIds: selectedModelIds ?? this.selectedModelIds,
    );
  }
}
