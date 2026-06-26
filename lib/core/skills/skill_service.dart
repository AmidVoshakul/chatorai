import 'dart:async';

import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/skills/skill_file_watcher.dart';
import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_source.dart';
import 'package:flutter/foundation.dart';

import 'skill_cache.dart';
import 'skill_discovery.dart';
import 'skill_plugin.dart';

/// Central service for skill discovery, caching, and retrieval.
///
/// Combines filesystem discovery (via SkillDiscovery) with static SkillPlugin
/// contributions. Provides permission filtering and change detection.
class SkillService {
  final List<SkillSource> sources;
  final List<SkillPlugin> plugins;
  final PermissionService _permissionService;

  late final SkillDiscovery _discovery;
  bool _initialized = false;

  SkillService({
    required this.sources,
    this.plugins = const [],
    required PermissionService permissionService,
  }) : _permissionService = permissionService {
    _discovery = SkillDiscovery(
      sources: sources,
      cache: SkillCache(),
      watcher: SkillFileWatcher(),
      onChanged: () => _initialized = false,
    );
  }

  /// Ensure discovery is initialized.
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _discovery.getAll();
      _initialized = true;
    }
  }

  /// List all skills from all sources and plugins (deduplicated by name).
  /// Plugin skills take precedence over discovered skills on name conflict.
  Future<List<SkillInfo>> listAll() async {
    final discovered = await _discovery.getAll();
    final pluginSkills = plugins.expand((p) => p.skills).toList();

    final map = <String, SkillInfo>{};
    for (final s in discovered) {
      map[s.name] = s;
    }
    for (final s in pluginSkills) {
      map[s.name] = s;
    }

    return map.values.toList();
  }

  /// Get a skill by exact name.
  Future<SkillInfo?> getByName(String name) async {
    final all = await listAll();
    try {
      return all.firstWhere((s) => s.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get skills available for a given agent, filtered by permission.
  Future<List<SkillInfo>> availableForAgent(String agentName) async {
    await _ensureInitialized();
    final all = await listAll();
    final allowed = <SkillInfo>[];

    for (final skill in all) {
      try {
        final pattern = 'skill:name=${skill.name}';
        if (_permissionService.isAllowed('skill', pattern)) {
          allowed.add(skill);
        }
      } catch (e) {
        debugPrint(
          '[SkillService] Permission check failed for skill ${skill.name}: $e',
        );
      }
    }
    return allowed;
  }

  /// Refresh all sources (bypass cache).
  Future<void> refresh() async {
    _initialized = false;
    await _discovery.refresh();
    _initialized = true;
  }

  /// Release resources.
  void dispose() {
    _discovery.dispose();
  }

  /// Clear all caches and reset initialization state.
  Future<void> clearCache() async {
    _initialized = false;
    await _discovery.clearCache();
  }
}
