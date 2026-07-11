import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrentAgentNotifier extends Notifier<AgentDefinition> {
  @override
  AgentDefinition build() {
    // Return build agent as default, fall back gracefully if registry not initialized
    final registry = AgentRegistry();
    if (registry.isInitialized) {
      return registry.get('build') ?? _getDefaultBuildAgent();
    }
    return _getDefaultBuildAgent();
  }

  void setAgent(AgentDefinition agent) {
    state = agent;
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
