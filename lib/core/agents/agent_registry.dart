import 'dart:async';
import 'dart:io';

import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

enum AgentMode { primary, subagent, all }

/// Sentinel value passed to streamText when maxSteps is null.
/// ai_sdk_dart breaks its step loop when tool results are empty,
/// so this effectively means "unlimited".
const int unlimitedMaxSteps = 999;

class AgentDefinition {
  final String id;
  final String name;
  final String? description;
  final AgentMode mode;
  final String? systemPrompt;
  final PermissionRuleset permissions;
  final bool hidden;
  final int? maxSteps;
  final double? temperature;
  final String? model;

  const AgentDefinition({
    required this.id,
    required this.name,
    this.description,
    this.mode = AgentMode.subagent,
    this.systemPrompt,
    this.permissions = const PermissionRuleset(),
    this.hidden = false,
    this.maxSteps,
    this.temperature,
    this.model,
  });

  /// Returns a copy with the given fields replaced.
  ///
  /// Note: `null` for any field means "keep existing value", not "unset".
  /// To create an unlimited-steps definition, use
  /// `AgentDefinition(id: ..., maxSteps: null, ...)` directly.
  AgentDefinition copyWith({
    String? id,
    String? name,
    String? description,
    AgentMode? mode,
    String? systemPrompt,
    PermissionRuleset? permissions,
    bool? hidden,
    int? maxSteps,
    double? temperature,
    String? model,
  }) {
    return AgentDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mode: mode ?? this.mode,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      permissions: permissions ?? this.permissions,
      hidden: hidden ?? this.hidden,
      maxSteps: maxSteps ?? this.maxSteps,
      temperature: temperature ?? this.temperature,
      model: model ?? this.model,
    );
  }
}

extension AgentDefinitionX on AgentDefinition {
  bool isVisibleTo(AgentMode caller) {
    if (hidden) return false;
    if (mode == AgentMode.subagent) return true;
    if (caller == AgentMode.primary) {
      return mode == AgentMode.subagent || mode == AgentMode.primary;
    }
    if (caller == AgentMode.subagent || caller == AgentMode.all) {
      return mode == AgentMode.subagent;
    }
    return false;
  }
}

final Map<String, AgentDefinition> builtInAgents = {
  'build': const AgentDefinition(
    id: 'build',
    name: 'build',
    description: 'Build agent. Executes tools with standard permissions.',
    mode: AgentMode.primary,
    hidden: false,
    permissions: PermissionRuleset(
      rules: [
        // Default allow for all tools, but specific overrides
        PermissionRule(
          permission: '*',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'plan_enter',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'plan_exit',
          pattern: '*',
          action: PermissionAction.deny,
        ),
      ],
    ),
  ),
  'plan': const AgentDefinition(
    id: 'plan',
    name: 'plan',
    description:
        'Planning agent. No file editing — only analysis and planning.',
    mode: AgentMode.primary,
    hidden: false,
    systemPrompt: '''
You are ChatORAI in PLAN mode. Your role is that of a system architect and strategic engineer, not a code implementer.

Expertise:

- Designing solution architecture before implementation begins
- Analyze the problem, identify requirements, limitations and assumptions
- Decompose the task into logical stages and subtasks
- Offer suitable technologies, patterns and tools
- Assess risks, bottlenecks and potential difficulties

Behavior:

- You think structurally, consistently and logically
- Explain why this or that approach was chosen
- Don't write code unless it's required to explain the architecture
- Avoid premature implementation
- Ask clarifying questions if necessary
- Minimize uncertainty and ambiguity

Response format:

1. Brief understanding of the task
2. Proposed architecture/approach
3. Breakdown into stages
4. Tools and technologies (if applicable)
5. Potential risks and nuances
6. (Optional) Questions for clarification

Main goal:
Create a clear, implementable and logical plan that can be directly transferred to implementation mode (code).

- Always structure the problem first, don't jump straight to solutions
- If the task is not completely clear, ask clarifying questions before creating a plan
- Prefer simple and reliable solutions instead of overly complex ones
- Break the plan into small, logically completed steps
- Explicitly indicate dependencies between stages
- Consider scalability and future support
- Suggest alternatives if there are several reasonable approaches
- Do not write full code - only pseudocode or examples if necessary
- Avoid "magic" - all decisions must be explainable
- Highlight potential risks and bottlenecks
- Think like an engineer who delegates a task to another developer
- Create a plan in .chatorai/plans and ask the user, check the reliability plan. 

Delegation:
You can delegate implementation and exploration tasks to specialized subagents using the `task` tool. 
Available subagents: explore (codebase exploration), general (general-purpose tasks), and custom subagents configured in .chatorai/agents/.
''',
    permissions: PermissionRuleset(
      rules: [
        PermissionRule(
          permission: 'edit',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'write',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'apply_patch',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'shell',
          pattern: '*',
          action: PermissionAction.ask,
        ),
        PermissionRule(
          permission: 'write',
          pattern: '.chatorai/plans/*.md',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'edit',
          pattern: '.chatorai/plans/*.md',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'external_directory',
          pattern: '.chatorai/plans/*.md',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'read',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'glob',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'grep',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'question',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        // PermissionRule(
        //   permission: 'plan_enter',
        //   pattern: '*',
        //   action: PermissionAction.allow,
        // ),
        PermissionRule(
          permission: 'plan_exit',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'websearch',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'webfetch',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'task',
          pattern: '*',
          action: PermissionAction.allow,
        ),
      ],
    ),
  ),
  'explore': const AgentDefinition(
    id: 'explore',
    name: 'explore',
    description: 'Read-only exploration. Uses read, glob, grep only.',
    mode: AgentMode.subagent,
    hidden: false,
    systemPrompt: '''
You are a file search specialist. You excel at thoroughly navigating and exploring codebases.

Your strengths:

- Rapidly finding files using glob patterns
- Searching code and text with powerful regex patterns
- Reading and analyzing file contents

Guidelines:

- Use Glob for broad file pattern matching
- Use Grep for searching file contents with regex
- Use Read when you know the specific file path you need to read
- Use shell for file operations like copying, moving, or listing directory contents
- Adapt your search approach based on the thoroughness level specified by the caller
- Return file paths as absolute paths in your final response
- For clear communication, avoid using emojis
- Do not create any files, or run shell commands that modify the user's system state in any way

Complete the user's search request efficiently and report your findings clearly.
''',
    permissions: PermissionRuleset(
      rules: [
        PermissionRule(
          permission: '*',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'shell',
          pattern: '*',
          action: PermissionAction.ask,
        ),
        PermissionRule(
          permission: 'write',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'edit',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'apply_patch',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'task',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'todowrite',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'question',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'plan_enter',
          pattern: '*',
          action: PermissionAction.deny,
        ),
        PermissionRule(
          permission: 'plan_exit',
          pattern: '*',
          action: PermissionAction.deny,
        ),
      ],
    ),
  ),
  'general': const AgentDefinition(
    id: 'general',
    name: 'general',
    description:
        'General-purpose agent for researching complex questions and executing multi-step tasks. Use this agent to execute multiple units of work in parallel.',
    mode: AgentMode.subagent,
    hidden: false,
    systemPrompt:
        'You are a general-purpose agent. Complete the given task using available tools.',
    permissions: PermissionRuleset(
      rules: [
        PermissionRule(
          permission: '*',
          pattern: '*',
          action: PermissionAction.allow,
        ),
        PermissionRule(
          permission: 'todowrite',
          pattern: '*',
          action: PermissionAction.deny,
        ),
      ],
    ),
  ),
  // Hidden agents - deny all by default
  'summary': const AgentDefinition(
    id: 'summary',
    name: 'summary',
    description: 'Generates PR-style summary for conversations.',
    mode: AgentMode.primary,
    hidden: true,
    systemPrompt: '''
Summarize what was done in this conversation. Write like a pull request description.

Rules:

- 2-3 sentences max
- Describe the changes made, not the process
- Do not mention running tests, builds, or other validation steps
- Do not explain what the user asked for
- Write in first person (I added..., I fixed...)
- Never ask questions or add new questions
- If the conversation ends with an unanswered question to the user, preserve that exact question
- If the conversation ends with an imperative statement or request to the user (e.g. "Now please run the command and paste the console output"), always include that exact request in the summary
''',
    permissions: PermissionRuleset(
      rules: [
        PermissionRule(
          permission: '*',
          pattern: '*',
          action: PermissionAction.deny,
        ),
      ],
    ),
  ),
  'title': const AgentDefinition(
    id: 'title',
    name: 'title',
    description: 'Generates short titles for conversations.',
    mode: AgentMode.primary,
    hidden: true,
    temperature: 0.5,
    systemPrompt: '''
You are a title generator. You output ONLY a thread title. Nothing else.

<task>
Generate a brief title that would help the user find this conversation later.

Follow all rules in <rules>
Use the <examples> so you know what a good title looks like.
Your output must be:

- A single line
- ≤60 characters
- No explanations
</task>

<rules>
- you MUST use the same language as the user message you are summarizing
- Title must be grammatically correct and read naturally - no word salad
- Never include tool names in the title (e.g. "read tool", "shell tool", "edit tool")
- Focus on the main topic or question the user needs to retrieve
- Vary your phrasing - avoid repetitive patterns like always starting with "Analyzing"
- When a file is mentioned, focus on WHAT the user wants to do WITH the file, not just that they shared it
- Keep exact: technical terms, numbers, filenames, HTTP codes
- Remove: the, this, my, a, an
- Never assume tech stack
- Never use tools
- NEVER respond to questions, just generate a title for the conversation
- The title should NEVER include "summarizing" or "generating" when generating a title
- DO NOT SAY YOU CANNOT GENERATE A TITLE OR COMPLAIN ABOUT THE INPUT
- Always output something meaningful, even if the input is minimal.
- If the user message is short or conversational (e.g. "hello", "lol", "what's up", "hey"):
  → create a title that reflects the user's tone or intent (such as Greeting, Quick check-in, Light chat, Intro message, etc.)
</rules>
''',
    permissions: PermissionRuleset(
      rules: [
        PermissionRule(
          permission: '*',
          pattern: '*',
          action: PermissionAction.deny,
        ),
      ],
    ),
  ),
  'compaction': const AgentDefinition(
    id: 'compaction',
    name: 'compaction',
    description:
        'Context compaction agent for summarizing conversation history.',
    mode: AgentMode.primary,
    hidden: true,
    systemPrompt: '''
You are an anchored context summarization assistant for coding sessions.

Summarize only the conversation history you are given. The newest turns may be kept verbatim outside your summary, so focus on the older context that still matters for continuing the work.

If the prompt includes a <previous-summary> block, treat it as the current anchored summary. Update it with the new history by preserving still-true details, removing stale details, and merging in new facts.

Always follow the exact output structure requested by the user prompt. Keep every section, preserve exact file paths and identifiers when known, and prefer terse bullets over paragraphs.

Do not answer the conversation itself. Do not mention that you are summarizing, compacting, or merging context. Respond in the same language as the conversation.
''',
    permissions: PermissionRuleset(
      rules: [
        PermissionRule(
          permission: '*',
          pattern: '*',
          action: PermissionAction.deny,
        ),
      ],
    ),
  ),
};

/// Parses an AGENT.md file into an [AgentDefinition].
///
/// Expects YAML frontmatter between `---` delimiters, followed by markdown body.
/// Required fields in frontmatter: `description` (string).
class AgentParser {
  static AgentDefinition parse(String filePath, String content) {
    final lines = content.split('\n');

    int? fmStart, fmEnd;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        if (fmStart == null) {
          fmStart = i;
        } else {
          fmEnd = i;
          break;
        }
      }
    }

    if (fmStart == null || fmEnd == null) {
      throw FormatException('Missing frontmatter delimiters (---)', filePath);
    }

    final frontMatterLines = lines.sublist(fmStart + 1, fmEnd);
    final bodyLines = lines.sublist(fmEnd + 1);
    final body = bodyLines.join('\n').trimLeft();

    final fileName = p.basename(filePath);
    final agentId = fileName.replaceAll('.md', '').toLowerCase();

    final frontMatterStr = frontMatterLines.join('\n');
    YamlMap? yaml;
    try {
      yaml = loadYaml(frontMatterStr) as YamlMap?;
    } catch (e) {
      throw FormatException('YAML parse error: $e', filePath);
    }

    if (yaml == null) {
      throw FormatException('Empty frontmatter', filePath);
    }

    final name = yaml['name']?.toString() ?? agentId;
    final description = yaml['description']?.toString();

    if (description == null || description.isEmpty) {
      throw FormatException('Missing or empty "description" field', filePath);
    }

    final modeValue = yaml['mode'];
    final modeStr = (modeValue != null ? modeValue.toString() : 'subagent')
        .toLowerCase();
    final mode = switch (modeStr) {
      'primary' => AgentMode.primary,
      'subagent' => AgentMode.subagent,
      'all' => AgentMode.all,
      _ => AgentMode.primary,
    };

    final maxSteps = yaml['max_steps'] is int
        ? yaml['max_steps'] as int
        : (yaml['maxSteps'] is int ? yaml['maxSteps'] as int : null);

    if (maxSteps != null && maxSteps <= 0) {
      throw FormatException(
        'max_steps must be a positive integer or null (got $maxSteps)',
        filePath,
      );
    }

    final hidden = yaml['hidden'] as bool? ?? false;
    final systemPrompt = body.isNotEmpty ? body : null;
    final model = yaml['model']?.toString();
    final temperature = yaml['temperature'] is double
        ? yaml['temperature'] as double
        : (yaml['temperature'] is int
              ? (yaml['temperature'] as int).toDouble()
              : null);

    PermissionRuleset permissions = const PermissionRuleset();
    if (yaml['permission'] != null) {
      final permYaml = yaml['permission'];
      if (permYaml is Map) {
        final rules = PermissionRuleset.fromConfig(
          Map<String, dynamic>.from(permYaml),
        );
        permissions = PermissionRuleset(rules: rules);
      }
    }

    // Shorthand: top-level `task: true` → permission allow
    if (yaml['task'] == true) {
      final rules = List<PermissionRule>.from(permissions.rules);
      rules.add(
        const PermissionRule(
          permission: 'task',
          pattern: '*',
          action: PermissionAction.allow,
        ),
      );
      permissions = PermissionRuleset(rules: rules);
    }

    // Shorthand: `tools: { task: true, ... }` → permission allows/denies
    if (yaml['tools'] is Map) {
      final toolsMap = yaml['tools'] as Map;
      final rules = List<PermissionRule>.from(permissions.rules);
      for (final entry in toolsMap.entries) {
        final toolName = entry.key.toString();
        final action = resolveToolAction(entry.value);
        if (action == null) continue;
        rules.add(
          PermissionRule(permission: toolName, pattern: '*', action: action),
        );
      }
      permissions = PermissionRuleset(rules: rules);
    }

    return AgentDefinition(
      id: agentId,
      name: name,
      description: description,
      mode: mode,
      systemPrompt: systemPrompt,
      hidden: hidden,
      maxSteps: maxSteps,
      temperature: temperature,
      model: model,
      permissions: permissions,
    );
  }
}

/// Agent registry loaded from markdown files.
class AgentRegistry {
  static final AgentRegistry _instance = AgentRegistry._();
  AgentRegistry._();
  factory AgentRegistry() => _instance;

  final Map<String, AgentDefinition> _agents = {};
  bool _initialized = false;
  Completer<void>? _initCompleter;

  Future<void> init([ChatOrAIConfig? config]) async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();
    try {
      // 1. Built-in fallback (always available)
      _agents.addAll(builtInAgents);

      // 2. Load custom agents (override built-in)
      final customAgents = await _loadCustomAgents();
      _agents.addAll(customAgents);

      // 3. Apply JSON overrides
      if (config != null) {
        applyOverrides(_agents, config);
      }

      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      rethrow;
    }
  }

  bool get isInitialized => _initialized;

  AgentDefinition? get(String id) {
    if (!_initialized) return null;
    return _agents[id];
  }

  List<AgentDefinition> getPrimaryAgents() {
    if (!_initialized) return [];
    return _agents.values
        .where((a) => a.mode == AgentMode.primary && !a.hidden)
        .toList();
  }

  List<AgentDefinition> getSubagents() {
    if (!_initialized) return [];
    return _agents.values
        .where((a) => a.mode == AgentMode.subagent && !a.hidden)
        .toList();
  }

  List<AgentDefinition> getVisibleAgents() {
    if (!_initialized) return [];
    return _agents.values.where((a) => !a.hidden).toList();
  }

  List<AgentDefinition> getDelegatableAgents() {
    if (!_initialized) return [];
    return _agents.values
        .where((a) => a.mode == AgentMode.subagent && !a.hidden)
        .toList();
  }

  List<String> getAllIds() {
    if (!_initialized) return [];
    return _agents.keys.toList();
  }

  static Future<Map<String, AgentDefinition>> _loadCustomAgents() async {
    final agents = <String, AgentDefinition>{};

    // Project agents
    final projectDir = Directory('.chatorai/agents');
    if (projectDir.existsSync()) {
      await for (final entity in projectDir.list()) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.md')) continue;
        try {
          final content = await entity.readAsString();
          final agent = AgentParser.parse(entity.path, content);
          agents[agent.id] = agent;
          LogTags.agentLoader.logInfo('Loaded project agent: ${agent.id}');
        } catch (e) {
          LogTags.agentLoader.logWarning(
            'Failed to load project agent ${entity.path}: $e',
          );
        }
      }
    }

    // Global agents
    final globalDir = Directory(p.join(XdgPaths.configHome, 'agents'));
    if (globalDir.existsSync()) {
      await for (final entity in globalDir.list()) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.md')) continue;
        try {
          final content = await entity.readAsString();
          final agent = AgentParser.parse(entity.path, content);
          agents[agent.id] = agent;
          LogTags.agentLoader.logInfo('Loaded global agent: ${agent.id}');
        } catch (e) {
          LogTags.agentLoader.logWarning(
            'Failed to load global agent ${entity.path}: $e',
          );
        }
      }
    }

    return agents;
  }

  static void applyOverrides(
    Map<String, AgentDefinition> agents,
    ChatOrAIConfig config,
  ) {
    final agentSection = config.agent;
    if (agentSection == null) return;

    for (final entry in agentSection.agents.entries) {
      final agentId = entry.key;
      final override = entry.value;
      final existing = agents[agentId];

      if (override.disabled == true) {
        agents.remove(agentId);
        LogTags.agentLoader.logInfo('Removed disabled agent: $agentId');
        continue;
      }

      if (existing == null) {
        agents[agentId] = AgentDefinition(
          id: agentId,
          name: override.name ?? agentId,
          description: override.description,
          mode: AgentMode.all,
          hidden: override.hidden ?? false,
          maxSteps: override.maxSteps,
          model: override.model,
          temperature: override.temperature,
        );
        LogTags.agentLoader.logInfo('Created new agent from config: $agentId');
        continue;
      }

      final overriddenPermissions = override.permission != null
          ? PermissionRuleset(
              rules: PermissionRuleset.fromConfig(override.permission!),
            )
          : existing.permissions;

      final toolsEnabled = <PermissionRule>[];
      if (override.tools != null) {
        for (final entry in override.tools!.entries) {
          final action = resolveToolAction(entry.value);
          if (action == null) continue;
          toolsEnabled.add(
            PermissionRule(permission: entry.key, pattern: '*', action: action),
          );
        }
      }

      final finalPermissions = toolsEnabled.isNotEmpty
          ? PermissionRuleset(
              rules: [...overriddenPermissions.rules, ...toolsEnabled],
            )
          : overriddenPermissions;

      agents[agentId] = existing.copyWith(
        name: override.name ?? existing.name,
        description: override.description ?? existing.description,
        systemPrompt: override.prompt ?? existing.systemPrompt,
        hidden: override.hidden ?? existing.hidden,
        maxSteps: override.maxSteps ?? existing.maxSteps,
        temperature: override.temperature ?? existing.temperature,
        model: override.model ?? existing.model,
        permissions: finalPermissions,
      );
      LogTags.agentLoader.logInfo('Applied override to agent: $agentId');
    }
  }
}
