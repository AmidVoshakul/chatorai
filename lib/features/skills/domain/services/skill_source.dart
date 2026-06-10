import 'package:chatorai/features/skills/data/models/skill_info.dart';

/// Abstract source for skill discovery.
abstract class SkillSource {
  /// Unique key for this source (used for caching).
  String get key;

  /// Discover skills from this source.
  Future<List<SkillInfo>> discover();
}
