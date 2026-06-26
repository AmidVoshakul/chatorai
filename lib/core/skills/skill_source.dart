import 'package:chatorai/core/skills/skill_info.dart';

/// Abstract source of skills.
///
/// A skill source is responsible for discovering [SkillInfo] objects from a
/// particular location (filesystem, HTTP, embedded, etc.).
abstract class SkillSource {
  /// Unique identifier for this source (used for caching keys).
  String get key;

  /// Discovers all skills available from this source.
  ///
  /// May throw [SkillError] on failure.
  Future<List<SkillInfo>> discover();
}
