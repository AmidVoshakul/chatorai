import 'dart:io';

import 'package:chatorai/features/skills/data/models/skill_info.dart';
import 'package:path/path.dart' as p;

import 'skill_source.dart';

/// Discovers skills from a specific filesystem directory.
class DirectorySource implements SkillSource {
  final String path;
  @override
  final String key;

  DirectorySource(this.path) : key = 'dir:$path';

  @override
  Future<List<SkillInfo>> discover() async {
    final skills = <SkillInfo>[];
    final dir = Directory(path);

    if (!await dir.exists()) return skills;

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
        // Silently skip malformed skills
      }
    }

    return skills;
  }

  SkillInfo? _parseSkillFile(
    String skillName,
    String skillDir,
    String content,
  ) {
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
    // body not needed for parsing

    // Parse description
    String? description;
    for (final line in frontMatterLines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('description:')) {
        description = trimmed.substring('description:'.length).trim();
      }
    }
    if (description == null || description.isEmpty) return null;

    // Gather auxiliary files (exclude SKILL.md)
    final auxFiles = <String>[];
    try {
      final dir = Directory(skillDir);
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File && p.basename(entity.path) != 'SKILL.md') {
          auxFiles.add(p.relative(entity.path, from: skillDir));
        }
      }
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
