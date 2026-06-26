import 'package:chatorai/core/skills/skill_info.dart';

/// In-memory cache for discovered skills.
///
/// Keys are source identifiers (e.g., directory paths). Values are immutable
/// lists of [SkillInfo]. Cache is not persistent across app restarts.
class SkillCache {
  final Map<String, List<SkillInfo>> _cache = {};

  /// Retrieves cached skills for [sourceId], or null if not cached.
  List<SkillInfo>? get(String sourceId) => _cache[sourceId];

  /// Stores skills for a source, replacing any existing entry.
  void set(String sourceId, List<SkillInfo> skills) {
    _cache[sourceId] = List.unmodifiable(skills);
  }

  /// Removes and returns cached skills for [sourceId].
  List<SkillInfo>? removeSource(String sourceId) {
    return _cache.remove(sourceId);
  }

  /// Clears entire cache.
  void clear() {
    _cache.clear();
  }

  /// Checks whether a source is currently cached.
  bool has(String sourceId) => _cache.containsKey(sourceId);

  /// Number of cached sources (for diagnostics).
  int get sourceCount => _cache.length;
}
