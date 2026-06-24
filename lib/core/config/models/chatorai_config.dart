import 'permission_section.dart';

/// Root configuration DTO for `chatorai.json`.
class ChatOrAIConfig {
  final int version;
  final Map<String, PermissionRuleConfig> permission;
  final Map<String, dynamic>? keybinding;
  final SkillConfig? skills;
  final CompactionConfig? compaction;

  const ChatOrAIConfig({
    required this.version,
    required this.permission,
    this.keybinding,
    this.skills,
    this.compaction,
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
          ? CompactionConfig.fromJson(json['compaction'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'permission': permission.map((key, value) => MapEntry(key, value.toJson())),
    if (keybinding != null) 'keybinding': keybinding,
    if (skills != null) 'skills': skills!.toJson(),
    if (compaction != null) 'compaction': compaction!.toJson(),
  };
}

/// Configuration for context compaction behaviour.
///
/// Mirrors OpenCode's `ConfigV1.Compaction` fields:
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
