import 'package:chatorai/core/skills/skill_info.dart';

/// A plugin that provides built-in skills.
///
/// Plugins are discovered and registered at app startup. They contribute
/// [SkillInfo] objects that are merged with discovered skills.
abstract class SkillPlugin {
  /// Unique plugin identifier.
  String get id;

  /// Human-readable name.
  String get name;

  /// Short description of what this plugin provides.
  String get description;

  /// List of skills provided by this plugin.
  List<SkillInfo> get skills;

  /// Called once when the plugin is registered. Use for initialization.
  Future<void> initialize() async {}
}
