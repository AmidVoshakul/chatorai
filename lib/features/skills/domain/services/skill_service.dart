import 'dart:async';
import 'dart:io';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:chatorai/features/skills/domain/services/skill_cache.dart';
import 'package:chatorai/features/skills/domain/services/skill_source.dart';
import 'package:chatorai/features/skills/domain/services/directory_source.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:path/path.dart' as p;

/// Central service for skill discovery, caching, and retrieval.
class SkillService {
  final List<SkillSource> _sources;
  final SkillCache _cache;
  final PermissionService _permissionService;
  bool _initialized = false;
  final Map<String, StreamSubscription> _watchers = {};
  final Map<String, Timer> _debounceTimers = {};

  SkillService({
    required List<SkillSource> sources,
    required PermissionService permissionService,
  }) : _sources = List.unmodifiable(sources),
       _cache = SkillCache(),
       _permissionService = permissionService {
    // Start watching all directory sources immediately
    for (final source in _sources) {
      if (source is DirectorySource) {
        _startWatching(source);
      }
    }
  }

  /// Ensure all sources have been discovered and cached.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    for (final source in _sources) {
      final cached = _cache.get(source.key);
      if (cached != null) continue;
      try {
        final skills = await source.discover();
        _cache.set(source.key, skills);
      } catch (e) {
        LogTags.skills.logWarning(
          'Failed to discover from source ${source.key}: $e',
        );
      }
    }
    _initialized = true;
  }

  /// List all skills from all sources (deduplicated).
  Future<List<SkillInfo>> listAll() async {
    await _ensureInitialized();
    final allLists = _sources.map((s) => _cache.get(s.key) ?? const []);
    return _cache.mergeAll(allLists);
  }

  /// Get a skill by name across all sources.
  Future<SkillInfo?> getByName(String name) async {
    await _ensureInitialized();
    final all = await listAll();
    try {
      return all.firstWhere((s) => s.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get available skills for an agent (filtered by permission).
  /// The [agentName] is used to scope permission checks (e.g., "code-reviewer").
  Future<List<SkillInfo>> availableForAgent(String agentName) async {
    await _ensureInitialized();
    final all = await listAll();
    final allowed = <SkillInfo>[];
    for (final skill in all) {
      // Check permission: pattern "skill:name=<skill.name>"
      final pattern = 'skill:name=${skill.name}';
      if (_permissionService.isAllowed('skill', pattern)) {
        allowed.add(skill);
      }
    }
    return allowed;
  }

  /// Clear the cache and reset initialization state.
  void clearCache() {
    _cache.clear();
    _initialized = false;
  }

  /// Clear the cache for a specific source (used by file watcher).
  void _clearSourceCache(String sourceKey) {
    LogTags.skills.logInfo(
      'Invalidating cache for source $sourceKey due to file changes',
    );
    _cache.removeSource(sourceKey);
    // Mark as uninitialized so next call re-discovers all sources
    _initialized = false;
  }

  /// Set up file watcher for a directory source.
  void _startWatching(DirectorySource source) {
    try {
      final dir = Directory(source.path);
      if (!dir.existsSync()) return;

      // Debounce timer duration
      const debounceDuration = Duration(milliseconds: 250);

      final subscription = dir
          .watch(recursive: true)
          .listen(
            (event) {
              // Only care about SKILL.md changes
              if (p.basename(event.path) != 'SKILL.md') return;

              // Cancel previous timer
              final key = source.key;
              _debounceTimers[key]?.cancel();

              // Set new debounce timer
              final timer = Timer(debounceDuration, () {
                _clearSourceCache(key);
                // Also mark as uninitialized so next call re-discovers
                _initialized = false;
              });
              _debounceTimers[key] = timer;
            },
            onError: (e) {
              LogTags.skills.logWarning(
                'File watcher error for ${source.path}: $e',
              );
            },
          );

      _watchers[source.key] = subscription;
      LogTags.skills.logInfo('Started file watcher for ${source.path}');
    } catch (e) {
      LogTags.skills.logWarning(
        'Failed to start file watcher for ${source.path}: $e',
      );
    }
  }

  /// Dispose resources (call when app shuts down).
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    for (final sub in _watchers.values) {
      sub.cancel();
    }
    _watchers.clear();
  }
}
