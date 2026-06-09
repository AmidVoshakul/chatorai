import 'package:chatorai/core/permission/ruleset.dart';

enum AgentMode { primary, subagent, all }

class AgentDefinition {
  final String id;
  final String name;
  final String? description;
  final AgentMode mode;
  final String? systemPrompt;
  final String? prompt;
  final String? modelOverride;
  final PermissionRuleset permissions;
  final bool hidden;
  final String? color;
  final int maxSteps;

  const AgentDefinition({
    required this.id,
    required this.name,
    this.description,
    this.mode = AgentMode.subagent,
    this.systemPrompt,
    this.prompt,
    this.modelOverride,
    this.permissions = const PermissionRuleset(),
    this.hidden = false,
    this.color,
    this.maxSteps = 5,
  });
}

class AgentRegistry {
  static final AgentRegistry _instance = AgentRegistry._();
  AgentRegistry._();
  factory AgentRegistry() => _instance;

  final Map<String, AgentDefinition> _agents = {
    'build': AgentDefinition(
      id: 'build',
      name: 'Build',
      description: 'Default agent. Executes tools with standard permissions.',
      mode: AgentMode.primary,
      hidden: false,
      systemPrompt:
          'You are the build agent. Execute tasks using available tools. Ask for permission when required.',
      maxSteps: 25,
    ),
    'plan': AgentDefinition(
      id: 'plan',
      name: 'Plan',
      description:
          'Planning agent. No file editing — only analysis and planning.',
      mode: AgentMode.primary,
      hidden: false,
      systemPrompt:
          'You are the planning agent. Analyze, plan, and report. NEVER use edit, write, or apply_patch tools.',
      maxSteps: 10,
    ),
    'general': AgentDefinition(
      id: 'general',
      name: 'General',
      description: 'General-purpose subagent for multi-step tasks.',
      mode: AgentMode.subagent,
      hidden: false,
      systemPrompt:
          'You are a general-purpose agent. Complete the given task using available tools.',
      maxSteps: 10,
    ),
    'explore': AgentDefinition(
      id: 'explore',
      name: 'Explore',
      description: 'Read-only exploration. Uses read, glob, grep only.',
      mode: AgentMode.subagent,
      hidden: false,
      systemPrompt:
          'You are an exploration agent. Use read, glob, grep tools only. NEVER edit, write, or modify files.',
      maxSteps: 10,
    ),
    'compaction': AgentDefinition(
      id: 'compaction',
      name: 'Compaction',
      description: 'Context compaction agent. Summarizes conversation.',
      mode: AgentMode.subagent,
      hidden: false,
      systemPrompt:
          'Summarize the following conversation context concisely. Preserve key decisions, errors, and code references.',
      maxSteps: 3,
    ),
    'title': AgentDefinition(
      id: 'title',
      name: 'Title',
      description: 'Generates short titles (hidden).',
      mode: AgentMode.primary,
      hidden: true,
      systemPrompt:
          'Generate a ≤60 character title for this conversation. Same language as user. No tool names.',
      maxSteps: 1,
    ),
    'summary': AgentDefinition(
      id: 'summary',
      name: 'Summary',
      description: 'Generates structured summaries (hidden).',
      mode: AgentMode.primary,
      hidden: true,
      systemPrompt:
          'Generate a PR-style summary: Key Decisions, Files Changed, Commands Run, Outcomes.',
      maxSteps: 1,
    ),
  };

  AgentDefinition? get(String id) => _agents[id];

  /// Primary agents (build, plan) — visible in agent switcher button.
  List<AgentDefinition> getPrimaryAgents() => _agents.values
      .where((a) => a.mode == AgentMode.primary && !a.hidden)
      .toList();

  /// Subagents (explore, general, compaction) — shown in @-mention popup.
  List<AgentDefinition> getSubagents() => _agents.values
      .where((a) => a.mode == AgentMode.subagent && !a.hidden)
      .toList();

  /// All non-hidden agents.
  List<AgentDefinition> getVisibleAgents() =>
      _agents.values.where((a) => !a.hidden).toList();
}
