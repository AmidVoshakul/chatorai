import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return const AgentDefinition(
      id: 'build',
      name: 'Build',
      description: 'Default agent. Executes tools with standard permissions.',
      mode: AgentMode.primary,
      hidden: false,
      systemPrompt:
          'You are the build agent. Execute tasks using available tools.',
    );
  }
}

final currentAgentProvider =
    NotifierProvider<CurrentAgentNotifier, AgentDefinition>(
      CurrentAgentNotifier.new,
    );
