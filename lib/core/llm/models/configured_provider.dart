/// Internal helper to carry provider display data through the UI layer.
///
/// Replaces the legacy [AiProvider] usage in the settings screen.
class ConfiguredProvider {
  final String id;
  final String name;
  final String? baseUrl;
  final bool enabled;
  final String? iconPath;

  const ConfiguredProvider({
    required this.id,
    required this.name,
    this.baseUrl,
    required this.enabled,
    this.iconPath,
  });
}
