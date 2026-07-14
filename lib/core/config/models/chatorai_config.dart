import 'package:chatorai/core/mcp/mcp_config.dart';

import 'permission_section.dart';

class FormatterEntryConfig {
  final bool? disabled;
  final List<String>? command;
  final Map<String, String>? environment;
  final List<String>? extensions;

  const FormatterEntryConfig({
    this.disabled,
    this.command,
    this.environment,
    this.extensions,
  });

  factory FormatterEntryConfig.fromJson(Map<String, dynamic> json) {
    return FormatterEntryConfig(
      disabled: json['disabled'] as bool?,
      command: (json['command'] as List<dynamic>?)?.cast<String>(),
      environment: (json['environment'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
      extensions: (json['extensions'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (disabled != null) 'disabled': disabled,
    if (command != null) 'command': command,
    if (environment != null) 'environment': environment,
    if (extensions != null) 'extensions': extensions,
  };
}

class FormatterConfig {
  final Map<String, FormatterEntryConfig> formatters;

  const FormatterConfig({this.formatters = const {}});

  factory FormatterConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FormatterConfig();
    final formatters = <String, FormatterEntryConfig>{};
    for (final entry in json.entries) {
      if (entry.value is Map<String, dynamic>) {
        formatters[entry.key] = FormatterEntryConfig.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }
    return FormatterConfig(formatters: formatters);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    for (final entry in formatters.entries) {
      map[entry.key] = entry.value.toJson();
    }
    return map;
  }
}

class ChatOrAIConfig {
  final int version;
  final Map<String, PermissionRuleConfig> permission;
  final Map<String, dynamic>? keybinding;
  final SkillConfig? skills;
  final CompactionConfig? compaction;
  final FormatterConfig? formatter;
  final McpConfig? mcp;
  final AgentSectionConfig? agent;
  final Map<String, dynamic>? tools;

  const ChatOrAIConfig({
    required this.version,
    required this.permission,
    this.keybinding,
    this.skills,
    this.compaction,
    this.formatter,
    this.mcp,
    this.agent,
    this.tools,
  });

  factory ChatOrAIConfig.fromJson(Map<String, dynamic> json) {
    final permissionJson = json['permission'] as Map<String, dynamic>? ?? {};
    final permission = <String, PermissionRuleConfig>{};
    for (final entry in permissionJson.entries) {
      permission[entry.key] = PermissionRuleConfig.fromJson(entry.value);
    }
    return ChatOrAIConfig(
      version: json['version'] as int? ?? 0,
      permission: permission,
      keybinding: json['keybinding'] as Map<String, dynamic>?,
      skills: json['skills'] != null
          ? SkillConfig.fromJson(json['skills'] as Map<String, dynamic>)
          : null,
      compaction: json['compaction'] != null
          ? CompactionConfig.fromJson(
              json['compaction'] as Map<String, dynamic>,
            )
          : null,
      formatter: json['formatter'] != null
          ? FormatterConfig.fromJson(json['formatter'] as Map<String, dynamic>?)
          : null,
      mcp: json['mcp'] != null
          ? McpConfig.fromJson(json['mcp'] as Map<String, dynamic>?)
          : null,
      agent: json['agent'] != null
          ? AgentSectionConfig.fromJson(json['agent'] as Map<String, dynamic>)
          : null,
      tools: json['tools'] is Map
          ? Map<String, dynamic>.from(json['tools'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'permission': permission.map((key, value) => MapEntry(key, value.toJson())),
    if (keybinding != null) 'keybinding': keybinding,
    if (skills != null) 'skills': skills!.toJson(),
    if (compaction != null) 'compaction': compaction!.toJson(),
    if (formatter != null) 'formatter': formatter!.toJson(),
    if (mcp != null) 'mcp': mcp!.toJson(),
    if (agent != null) 'agent': agent!.toJson(),
    if (tools != null) 'tools': tools,
  };
}

/// Configuration for context compaction behaviour.
///
/// Mirrors fields:
/// - `auto` — enable automatic pre-send overflow compaction
/// - `prune` — enable post-compaction tool-output pruning
/// - `keep.tokens` — minimum recent tokens to preserve verbatim
/// - `buffer` — reserved tokens for the next model response
class CompactionConfig {
  final bool auto;
  final bool prune;
  final int keepTokens;
  final int buffer;

  const CompactionConfig({
    this.auto = true,
    this.prune = false,
    this.keepTokens = 8000,
    this.buffer = 20000,
  });

  factory CompactionConfig.fromJson(Map<String, dynamic> json) {
    final keep = json['keep'] as Map<String, dynamic>? ?? {};
    return CompactionConfig(
      auto: json['auto'] as bool? ?? true,
      prune: json['prune'] as bool? ?? false,
      keepTokens: keep['tokens'] as int? ?? 8000,
      buffer: json['buffer'] as int? ?? 20000,
    );
  }

  Map<String, dynamic> toJson() => {
    'auto': auto,
    'prune': prune,
    'keep': {'tokens': keepTokens},
    'buffer': buffer,
  };
}

/// Configuration for skill sources.
class SkillConfig {
  final List<String> paths;
  final List<Map<String, dynamic>> urls;

  const SkillConfig({this.paths = const [], this.urls = const []});

  factory SkillConfig.fromJson(Map<String, dynamic> json) {
    final paths = <String>[];
    final urls = <Map<String, dynamic>>[];

    if (json['paths'] is List) {
      paths.addAll((json['paths'] as List).cast<String>());
    }
    if (json['urls'] is List) {
      for (final url in json['urls'] as List) {
        if (url is String) {
          urls.add({'url': url});
        } else if (url is Map<String, dynamic>) {
          urls.add(url);
        }
      }
    }

    return SkillConfig(paths: paths, urls: urls);
  }

  Map<String, dynamic> toJson() => {
    if (paths.isNotEmpty) 'paths': paths,
    if (urls.isNotEmpty) 'urls': urls,
  };
}

/// Configuration for a single agent override in chatorai.json.
class AgentConfig {
  final String? name;
  final String? description;
  final String? prompt;
  final bool? disabled;
  final bool? hidden;
  final int? maxSteps;
  final double? temperature;
  final String? model;
  final Map<String, dynamic>? permission;
  final Map<String, dynamic>? tools;

  const AgentConfig({
    this.name,
    this.description,
    this.prompt,
    this.disabled,
    this.hidden,
    this.maxSteps,
    this.temperature,
    this.model,
    this.permission,
    this.tools,
  });

  factory AgentConfig.fromJson(Map<String, dynamic> json) {
    return AgentConfig(
      name: json['name'] as String?,
      description: json['description'] as String?,
      prompt: json['prompt'] as String?,
      disabled: json['disabled'] as bool?,
      hidden: json['hidden'] as bool?,
      maxSteps: json['max_steps'] is int
          ? (json['max_steps'] as int > 0 ? json['max_steps'] as int : null)
          : (json['maxSteps'] is int
                ? (json['maxSteps'] as int > 0 ? json['maxSteps'] as int : null)
                : null),
      temperature: json['temperature'] is double
          ? json['temperature'] as double
          : (json['temperature'] is int
                ? (json['temperature'] as int).toDouble()
                : null),
      model: json['model'] as String?,
      permission: json['permission'] as Map<String, dynamic>?,
      tools: json['tools'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (prompt != null) 'prompt': prompt,
    if (disabled != null) 'disabled': disabled,
    if (hidden != null) 'hidden': hidden,
    if (maxSteps != null) 'max_steps': maxSteps,
    if (temperature != null) 'temperature': temperature,
    if (model != null) 'model': model,
    if (permission != null) 'permission': permission,
    if (tools != null) 'tools': tools,
  };
}

/// Agent section in chatorai.json.
class AgentSectionConfig {
  final Map<String, AgentConfig> agents;

  const AgentSectionConfig({this.agents = const {}});

  factory AgentSectionConfig.fromJson(Map<String, dynamic> json) {
    final agents = <String, AgentConfig>{};
    for (final entry in json.entries) {
      if (entry.value is Map<String, dynamic>) {
        agents[entry.key] = AgentConfig.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }
    return AgentSectionConfig(agents: agents);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    for (final entry in agents.entries) {
      map[entry.key] = entry.value.toJson();
    }
    return map;
  }
}
