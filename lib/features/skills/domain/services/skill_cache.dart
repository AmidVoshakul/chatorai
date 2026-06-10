import 'package:chatorai/features/skills/data/models/skill_info.dart';

/// Simple cache for discovered skills per source.
class SkillCache {
  final Map<String, List<SkillInfo>> _bySource = {};

  List<SkillInfo>? get(String sourceKey) => _bySource[sourceKey];

  void set(String sourceKey, List<SkillInfo> skills) {
    _bySource[sourceKey] = List.unmodifiable(skills);
  }

  void clear() {
    _bySource.clear();
  }

  /// Remove a specific source from the cache.
  void removeSource(String sourceKey) {
    _bySource.remove(sourceKey);
  }

  /// Get all skills from all sources (merged).
  List<SkillInfo> mergeAll(Iterable<List<SkillInfo>> allLists) {
    final all = <SkillInfo>[];
    for (final list in allLists) {
      all.addAll(list);
    }
    // Deduplicate by name (last write wins, but here just keep first)
    final seen = <String>{};
    final unique = <SkillInfo>[];
    for (final skill in all) {
      if (!seen.contains(skill.name)) {
        seen.add(skill.name);
        unique.add(skill);
      }
    }
    return unique;
  }
}
