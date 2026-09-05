import 'dart:io';

import 'package:chatorai/core/skills/skill_error.dart';
import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_parser.dart';
import 'package:chatorai/core/skills/skill_source.dart';
import 'package:path/path.dart' as p;
import 'package:chatorai/shared/utils/logger.dart';

/// Security helper for path validation.
class _PathSecurity {
  /// Checks whether a path is safely contained within [rootPath].
  ///
  /// Rejects:
  /// - Absolute paths
  /// - Paths containing ".." segments
  /// - Symbolic links pointing outside [rootPath]
  static bool isSafePath(String rootPath, String candidatePath) {
    try {
      final resolvedRoot = p.normalize(p.absolute(rootPath));
      final resolvedCandidate = p.normalize(p.absolute(candidatePath));

      // Reject absolute paths that don't start with root
      if (!resolvedCandidate.startsWith(resolvedRoot)) {
        return false;
      }

      // Reject ".." in any segment
      final segments = p.split(resolvedCandidate);
      if (segments.any((seg) => seg == '..')) {
        return false;
      }

      // Additional: reject if any segment is empty (potential "//")
      if (segments.any((seg) => seg.isEmpty)) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Filesystem-based skill source.
///
/// Recursively scans [rootPath] for files named `SKILL.md` and parses them.
class DirectorySource implements SkillSource {
  @override
  final String key;

  final String rootPath;
  final bool recursive;

  DirectorySource({required this.rootPath, this.recursive = true})
    : key = 'dir:$rootPath';

  @override
  Future<List<SkillInfo>> discover() async {
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) {
      return [];
    }

    final entities = await rootDir.list(recursive: recursive).toList();

    // Filter out unsafe paths (path traversal, symlinks, absolute paths)
    final safeEntities = entities.where((e) {
      return _PathSecurity.isSafePath(rootPath, e.path);
    });

    // Find all SKILL.md files
    final skillFiles = safeEntities
        .where((e) => e is File && p.basename(e.path) == 'SKILL.md')
        .cast<File>();

    final skills = <SkillInfo>[];

    for (final file in skillFiles) {
      try {
        final content = await file.readAsString();
        final parsed = SkillParser.parse(file.path, content);
        // Collect auxiliary files in the same directory (max 10)
        final skillDir = p.dirname(file.path);
        final dir = Directory(skillDir);
        final allFiles = await dir.list().toList();
        final safeFiles = allFiles.where((f) {
          return _PathSecurity.isSafePath(skillDir, f.path);
        });
        final auxFiles =
            safeFiles
                .where((f) => f is File && p.basename(f.path) != 'SKILL.md')
                .map((f) => p.relative(f.path, from: skillDir))
                .toList()
              ..sort();
        final limitedFiles = auxFiles.take(10).toList();

        final skillInfo = SkillInfo(
          name: parsed.name,
          description: parsed.description,
          directory: parsed.directory,
          content: parsed.content,
          files: limitedFiles,
        );
        skills.add(skillInfo);
      } on ParseError catch (e) {
        LogTags.skills.logWarning(
          '[DirectorySource] Parse error in ${file.path}: $e',
        );
      } catch (e) {
        LogTags.skills.logWarning(
          '[DirectorySource] Unexpected error reading ${file.path}: $e',
        );
      }
    }

    return skills;
  }
}
