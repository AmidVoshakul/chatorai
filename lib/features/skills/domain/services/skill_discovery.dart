import 'dart:io';

import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Discovers skills from filesystem paths.
class SkillDiscovery {
  final List<String> searchPaths;

  SkillDiscovery({required this.searchPaths});

  /// Discover all skills from filesystem paths.
  /// Scans each path recursively for `<skill-name>/SKILL.md`.
  Future<List<SkillInfo>> discover() async {
    final skills = <SkillInfo>[];

    for (final searchPath in searchPaths) {
      final dir = Directory(searchPath);
      if (!await dir.exists()) continue;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        if (p.basename(entity.path) != 'SKILL.md') continue;

        final skillDir = p.dirname(entity.path);
        final skillName = p.basename(skillDir);
        try {
          final content = await entity.readAsString();
          final info = _parseSkillFile(skillName, skillDir, content);
          if (info != null) {
            skills.add(info);
          }
        } catch (e) {
          debugPrint('Failed to parse skill at ${entity.path}: $e');
        }
      }
    }

    return skills;
  }

  /// Parse a SKILL.md file, extracting frontmatter and body.
  /// Returns null if required fields are missing.
  SkillInfo? _parseSkillFile(
    String skillName,
    String skillDir,
    String content,
  ) {
    // Expect YAML frontmatter delimited by `---`
    final lines = content.split('\n');
    int frontMatterStart = -1;
    int frontMatterEnd = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        if (frontMatterStart == -1) {
          frontMatterStart = i;
        } else {
          frontMatterEnd = i;
          break;
        }
      }
    }
    if (frontMatterStart == -1 || frontMatterEnd == -1) return null;
    if (frontMatterEnd - frontMatterStart <= 1) {
      return null; // No content between delimiters
    }

    final frontMatterLines = lines.sublist(
      frontMatterStart + 1,
      frontMatterEnd,
    );
    // Body not needed for now (content kept entire file)
    // final bodyLines = lines.sublist(frontMatterEnd + 1);

    // Parse frontmatter (simple: key: value)
    String? description;
    for (final line in frontMatterLines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('description:')) {
        description = trimmed.substring('description:'.length).trim();
      }
    }

    if (description == null || description.isEmpty) return null;

    // Gather auxiliary files in skill directory (excluding SKILL.md)
    final auxFiles = <String>[];
    try {
      final dir = Directory(skillDir);
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File && p.basename(entity.path) != 'SKILL.md') {
          auxFiles.add(p.relative(entity.path, from: skillDir));
        }
      }
      // Sort and limit to 10
      auxFiles.sort();
    } catch (_) {}

    return SkillInfo(
      name: skillName,
      description: description,
      directory: skillDir,
      content: content,
      files: auxFiles.take(10).toList(),
    );
  }
}
