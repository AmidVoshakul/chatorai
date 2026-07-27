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

class LspServerEntryConfig {
  final bool? disabled;
  final List<String>? command;
  final List<String>? args;
  final Map<String, String>? environment;
  final List<String>? extensions;
  final String? languageId;
  final Map<String, dynamic>? initialization;
  final bool? autoInstall;

  const LspServerEntryConfig({
    this.disabled,
    this.command,
    this.args,
    this.environment,
    this.extensions,
    this.languageId,
    this.initialization,
    this.autoInstall,
  });

  factory LspServerEntryConfig.fromJson(Map<String, dynamic> json) {
    return LspServerEntryConfig(
      disabled: json['disabled'] as bool?,
      command: (json['command'] as List<dynamic>?)?.cast<String>(),
      args: (json['args'] as List<dynamic>?)?.cast<String>(),
      environment: (json['environment'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
      extensions: (json['extensions'] as List<dynamic>?)?.cast<String>(),
      languageId: json['languageId'] as String?,
      initialization: json['initialization'] as Map<String, dynamic>?,
      autoInstall: json['autoInstall'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (disabled != null) 'disabled': disabled,
    if (command != null) 'command': command,
    if (args != null) 'args': args,
    if (environment != null) 'environment': environment,
    if (extensions != null) 'extensions': extensions,
    if (languageId != null) 'languageId': languageId,
    if (initialization != null) 'initialization': initialization,
    if (autoInstall != null) 'autoInstall': autoInstall,
  };
}

class LspConfig {
  final bool enabled;
  final Map<String, LspServerEntryConfig> servers;

  const LspConfig({this.enabled = true, this.servers = const {}});

  factory LspConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LspConfig();
    final servers = <String, LspServerEntryConfig>{};
    for (final entry in json.entries) {
      if (entry.key == 'enabled') continue;
      if (entry.value is Map<String, dynamic>) {
        servers[entry.key] = LspServerEntryConfig.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }
    final enabled = json['enabled'];
    return LspConfig(
      enabled: enabled is bool ? enabled : true,
      servers: servers,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (!enabled) map['enabled'] = enabled;
    for (final entry in servers.entries) {
      map[entry.key] = entry.value.toJson();
    }
    return map;
  }
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
  final LspConfig? lsp;
  final McpConfig? mcp;
  final AgentSectionConfig? agent;
  final Map<String, dynamic>? tools;
  final List<String> instructions;
  final ProviderSectionConfig? provider;

  const ChatOrAIConfig({
    required this.version,
    required this.permission,
    this.keybinding,
    this.skills,
    this.compaction,
    this.formatter,
    this.lsp,
    this.mcp,
    this.agent,
    this.tools,
    this.instructions = const [],
    this.provider,
  });

  factory ChatOrAIConfig.fromJson(Map<String, dynamic> json) {
    final permissionJson =
        (json['permission'] as Map?)?.cast<String, dynamic>() ?? {};
    final permission = <String, PermissionRuleConfig>{};
    for (final entry in permissionJson.entries) {
      permission[entry.key] = PermissionRuleConfig.fromJson(entry.value);
    }
    final lspRaw = json['lsp'];
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
      lsp: lspRaw == null
          ? null
          : (lspRaw is bool
                ? LspConfig(enabled: lspRaw)
                : (lspRaw is Map
                      ? LspConfig.fromJson(Map<String, dynamic>.from(lspRaw))
                      : null)),
      mcp: json['mcp'] != null
          ? McpConfig.fromJson(json['mcp'] as Map<String, dynamic>?)
          : null,
      agent: json['agent'] != null
          ? AgentSectionConfig.fromJson(json['agent'] as Map<String, dynamic>)
          : null,
      tools: json['tools'] is Map
          ? Map<String, dynamic>.from(json['tools'] as Map)
          : null,
      instructions: json['instructions'] is List
          ? List<String>.from(json['instructions'] as List)
          : const [],
      provider: json['provider'] is Map<String, dynamic>
          ? ProviderSectionConfig.fromJson(
              json['provider'] as Map<String, dynamic>,
            )
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
    if (lsp != null) 'lsp': lsp!.toJson(),
    if (mcp != null) 'mcp': mcp!.toJson(),
    if (agent != null) 'agent': agent!.toJson(),
    if (tools != null) 'tools': tools,
    if (instructions.isNotEmpty) 'instructions': instructions,
    if (provider != null) 'provider': provider!.toJson(),
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

/// Provider section in chatorai.json.
///
/// Each entry key is a provider ID (e.g. "openrouter", "nvidia"). chatorai
/// treats every config provider as OpenAI-compatible. `apiKey` supports the
/// `{env:VAR}` substitution syntax.
class ProviderSectionConfig {
  final Map<String, ProviderEntryConfig> providers;

  const ProviderSectionConfig({this.providers = const {}});

  factory ProviderSectionConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProviderSectionConfig();
    final providers = <String, ProviderEntryConfig>{};
    for (final entry in json.entries) {
      if (entry.value is Map<String, dynamic>) {
        providers[entry.key] = ProviderEntryConfig.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }
    return ProviderSectionConfig(providers: providers);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    for (final entry in providers.entries) {
      map[entry.key] = entry.value.toJson();
    }
    return map;
  }
}

/// A single provider entry in the `provider` section.
class ProviderEntryConfig {
  final String? name;
  final ProviderOptionsConfig? options;
  final Map<String, ProviderModelConfig> models;

  const ProviderEntryConfig({this.name, this.options, this.models = const {}});

  factory ProviderEntryConfig.fromJson(Map<String, dynamic> json) {
    final models = <String, ProviderModelConfig>{};
    final modelsJson = json['models'] as Map<String, dynamic>?;
    if (modelsJson != null) {
      for (final entry in modelsJson.entries) {
        if (entry.value is Map<String, dynamic>) {
          models[entry.key] = ProviderModelConfig.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    }
    return ProviderEntryConfig(
      name: json['name'] as String?,
      options: json['options'] is Map<String, dynamic>
          ? ProviderOptionsConfig.fromJson(
              json['options'] as Map<String, dynamic>,
            )
          : null,
      models: models,
    );
  }

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (options != null) 'options': options!.toJson(),
    if (models.isNotEmpty)
      'models': {
        for (final entry in models.entries) entry.key: entry.value.toJson(),
      },
  };
}

/// Provider-level options (baseURL, apiKey, temperature, plus extras).
class ProviderOptionsConfig {
  final String? baseURL;
  final String? apiKey;
  final double? temperature;
  final Map<String, dynamic> extra;

  const ProviderOptionsConfig({
    this.baseURL,
    this.apiKey,
    this.temperature,
    this.extra = const {},
  });

  factory ProviderOptionsConfig.fromJson(Map<String, dynamic> json) {
    final known = {'baseURL', 'apiKey', 'temperature'};
    final extra = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!known.contains(entry.key)) extra[entry.key] = entry.value;
    }
    final apiKey = json['apiKey'];
    if (apiKey != null && apiKey is! String) {
      throw const FormatException('Provider apiKey must be a string');
    }
    final temp = json['temperature'];
    if (temp != null && temp is! num) {
      throw const FormatException('Provider temperature must be a number');
    }
    return ProviderOptionsConfig(
      baseURL: json['baseURL'] as String?,
      apiKey: apiKey as String?,
      temperature: temp is num ? temp.toDouble() : null,
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => {
    if (baseURL != null) 'baseURL': baseURL,
    if (apiKey != null) 'apiKey': apiKey,
    if (temperature != null) 'temperature': temperature,
    for (final entry in extra.entries)
      if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
  };

  static const _knownKeys = {'baseURL', 'apiKey', 'temperature'};
}

/// A model declaration within a provider entry.
class ProviderModelConfig {
  final String? name;
  final ProviderLimitConfig? limit;

  const ProviderModelConfig({this.name, this.limit});

  factory ProviderModelConfig.fromJson(Map<String, dynamic> json) {
    return ProviderModelConfig(
      name: json['name'] as String?,
      limit: json['limit'] is Map<String, dynamic>
          ? ProviderLimitConfig.fromJson(json['limit'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (limit != null) 'limit': limit!.toJson(),
  };
}

/// Context/output token limits for a model.
class ProviderLimitConfig {
  final int? context;
  final int? output;

  const ProviderLimitConfig({this.context, this.output});

  factory ProviderLimitConfig.fromJson(Map<String, dynamic> json) {
    return ProviderLimitConfig(
      context: json['context'] as int?,
      output: json['output'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (context != null) 'context': context,
    if (output != null) 'output': output,
  };
}
