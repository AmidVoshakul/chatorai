import 'permission_section.dart';

/// Root configuration DTO for `chatorai.json`.
class ChatOrAIConfig {
  final int version;
  final Map<String, PermissionRuleConfig> permission;
  final Map<String, dynamic>? provider;
  final Map<String, dynamic>? keybinding;
  final SkillConfig? skills;

  const ChatOrAIConfig({
    required this.version,
    required this.permission,
    this.provider,
    this.keybinding,
    this.skills,
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
      provider: json['provider'] as Map<String, dynamic>?,
      keybinding: json['keybinding'] as Map<String, dynamic>?,
      skills: json['skills'] != null
          ? SkillConfig.fromJson(json['skills'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'permission': permission.map((key, value) => MapEntry(key, value.toJson())),
    if (provider != null) 'provider': provider,
    if (keybinding != null) 'keybinding': keybinding,
    if (skills != null) 'skills': skills!.toJson(),
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
