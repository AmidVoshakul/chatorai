import 'dart:async';

import 'package:chatorai/core/skills/directory_source.dart';
import 'package:chatorai/core/skills/skill_error.dart';
import 'package:chatorai/core/skills/skill_file_watcher.dart';
import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_source.dart';

import 'skill_cache.dart';
import 'package:chatorai/shared/utils/logger.dart';

/// Orchestrates skill discovery from multiple sources with caching and file watching.
///
/// Responsibilities:
/// - Manage a collection of [SkillSource] objects.
/// - Discover skills from all sources (with error isolation).
/// - Cache results per-source to avoid rescanning.
/// - Watch skill directories for changes and automatically invalidate cache.
/// - Provide merged list of all skills.
class SkillDiscovery {
  final List<SkillSource> sources;
  final SkillCache _cache;
  final SkillFileWatcher _watcher;
  Future<void>? _initialization;
  final void Function()? _onChanged;
  final Set<String> _watchedPaths = {};

  SkillDiscovery({
    required this.sources,
    SkillCache? cache,
    SkillFileWatcher? watcher,
    void Function()? onChanged,
  }) : _cache = cache ?? SkillCache(),
       _watcher = watcher ?? SkillFileWatcher(),
       _onChanged = onChanged;

  /// Returns all discovered skills from all sources.
  ///
  /// Discovery happens lazily on first call. Subsequent calls return cached
  /// results unless a file change invalidates the cache.
  Future<List<SkillInfo>> getAll() async {
    await _ensureInitialized();

    final allSkills = <SkillInfo>[];
    for (final source in sources) {
      final cached = _cache.get(source.key);
      if (cached != null) {
        allSkills.addAll(cached);
      } else {
        // Cache miss: discover this source now
        try {
          final skills = await source.discover();
          _cache.set(source.key, skills);
          allSkills.addAll(skills);
        } on SkillError catch (e) {
          // Log and continue; return whatever we have
          LogTags.skills.logDebug(
            '[SkillDiscovery] Error from source "$source": $e',
          );
        }
      }
    }
    // Deduplicate by skill name, first source wins
    final deduped = <String, SkillInfo>{};
    for (final skill in allSkills) {
      deduped.putIfAbsent(skill.name, () => skill);
    }
    return deduped.values.toList();
  }

  Future<void> _ensureInitialized() async {
    _initialization ??= _discoverAll().whenComplete(() {});
    await _initialization;
  }

  /// Forces a full rediscovery, bypassing cache.
  Future<void> refresh() async {
    _initialization = null;
    _cache.clear();
    // Next getAll() will trigger rediscovery
  }

  Future<void> _discoverAll() async {
    for (final source in sources) {
      try {
        final skills = await source.discover();
        _cache.set(source.key, skills);
        // Setup watching for this source if it's a DirectorySource
        if (source is DirectorySource) {
          final path = (source).rootPath;
          if (!_watchedPaths.contains(path)) {
            _watcher.watch(path, () {
              _cache.removeSource(source.key);
              if (_onChanged != null) _onChanged();
            });
            _watchedPaths.add(path);
          }
        }
      } on SkillError catch (e) {
        LogTags.skills.logDebug(
          '[SkillDiscovery] Initial discovery failed for $source: $e',
        );
      }
    }
  }

  /// Number of cached source entries (for diagnostics).
  int get cacheSize => _cache.sourceCount;

  /// Clear all caches without reinitializing.
  Future<void> clearCache() async {
    _watcher.stopAll();
    _cache.clear();
    // Restart watchers after clearing?
    // We'll restart on next discovery attempt
  }

  /// Dispose resources.
  void dispose() {
    _watcher.stopAll();
    _cache.clear();
  }
}
