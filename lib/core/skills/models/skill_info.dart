import 'package:flutter/foundation.dart';

/// Represents a discovered skill with its metadata and content.
@immutable
class SkillInfo {
  final String name;
  final String description;
  final String directory; // Absolute path to skill directory
  final String content; // Full markdown content (SKILL.md)
  final List<String> files; // Related files in the skill directory (max 10)

  const SkillInfo({
    required this.name,
    required this.description,
    required this.directory,
    required this.content,
    this.files = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          directory == other.directory &&
          content == other.content &&
          listEquals(files, other.files);

  @override
  int get hashCode =>
      name.hashCode ^
      description.hashCode ^
      directory.hashCode ^
      content.hashCode ^
      files.hashCode;
}
