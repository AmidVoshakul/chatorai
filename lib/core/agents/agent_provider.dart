import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/skills/skill_file_watcher.dart';
import 'package:chatorai/shared/utils/chatorai_roots.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class CurrentAgentNotifier extends Notifier<AgentDefinition> {
  static const String _lastAgentKey = 'last_used_agent_id';
  bool _initialized = false;

  @override
  AgentDefinition build() {
    if (!_initialized) {
      _initialized = true;
      _loadSavedAgent();
    }
    // Return build agent as default, fall back gracefully if registry not initialized
    final registry = AgentRegistry();
    if (registry.isInitialized) {
      return registry.get('build') ?? _getDefaultBuildAgent();
    }
    return _getDefaultBuildAgent();
  }

  Future<void> _loadSavedAgent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_lastAgentKey);
      if (savedId != null && savedId.isNotEmpty) {
        final agent = AgentRegistry().get(savedId);
        if (agent != null) {
          state = agent;
          return;
        }
      }
    } catch (_) {
      // Ignore — fall back to build default
    }
  }

  void setAgent(AgentDefinition agent) {
    state = agent;
    _saveAgentId(agent.id);
  }

  Future<void> _saveAgentId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastAgentKey, id);
    } catch (_) {
      // Ignore — persistence is best-effort
    }
  }

  AgentDefinition _getDefaultBuildAgent() {
    return builtInAgents['build']!;
  }
}

final currentAgentProvider =
    NotifierProvider<CurrentAgentNotifier, AgentDefinition>(
      CurrentAgentNotifier.new,
    );

/// Bumped after [AgentRegistry] reloads from disk, for consumers that need to
/// re-read registry data on change.
class AgentsVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final agentsVersionProvider = NotifierProvider<AgentsVersion, int>(
  AgentsVersion.new,
);

/// Installs file watchers over the project and global agent directories so
/// [AgentRegistry] hot-reloads when agent files are added, edited or deleted.
final agentHotReloadProvider = Provider<void>((ref) {
  final watcher = SkillFileWatcher();

  Future<void> scheduleReload() async {
    try {
      ChatOrAIConfig? config;
      try {
        config = await ref.read(configProvider.future);
      } catch (_) {
        config = null;
      }
      await AgentRegistry().reload(config);
      ref.read(agentsVersionProvider.notifier).bump();
      LogTags.agentLoader.logInfo('Agent registry reloaded from disk');
    } catch (e) {
      LogTags.agentLoader.logWarning('Agent hot-reload failed: $e');
    }
  }

  void watchDir(String dir) =>
      watcher.watch(dir, scheduleReload, fileName: '*.md');

  for (final root in projectChatoraiRoots()) {
    watchDir(p.join(root, 'agents'));
  }
  try {
    watchDir(p.join(XdgPaths.configHome, 'agents'));
  } catch (_) {
    // Mobile before the platform path cache is initialized: only the project
    // directories are watched.
  }

  ref.onDispose(watcher.stopAll);
});
