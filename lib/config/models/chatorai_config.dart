import 'package:chatorai/config/models/permission_section.dart';

/// Root configuration DTO for `chatorai.json`.
class ChatOrAIConfig {
  final int version;
  final Map<String, PermissionRuleConfig> permission;
  final Map<String, dynamic>? provider;
  final Map<String, dynamic>? keybinding;

  const ChatOrAIConfig({
    required this.version,
    required this.permission,
    this.provider,
    this.keybinding,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'permission': permission.map((key, value) => MapEntry(key, value.toJson())),
    if (provider != null) 'provider': provider,
    if (keybinding != null) 'keybinding': keybinding,
  };
}
