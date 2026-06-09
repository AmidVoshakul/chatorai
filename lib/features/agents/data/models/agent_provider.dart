import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/agents/data/models/agent_registry.dart';

class CurrentAgentNotifier extends Notifier<AgentDefinition> {
  @override
  AgentDefinition build() {
    return AgentRegistry().get('build')!;
  }

  void setAgent(AgentDefinition agent) {
    state = agent;
  }
}

final currentAgentProvider =
    NotifierProvider<CurrentAgentNotifier, AgentDefinition>(
      CurrentAgentNotifier.new,
    );
