import 'dart:io';

import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

ToolDef createGlobTool() {
  return ToolDef(
    id: 'glob',
    description: 'Find files by glob pattern',
    inputSchema: {
      'type': 'object',
      'properties': {
        'pattern': {
          'type': 'string',
          'description': 'Glob pattern (e.g. **/*.dart)',
        },
        'path': {
          'type': 'string',
          'description': 'Root directory to search in',
        },
      },
      'required': ['pattern'],
    },
    execute: (input, ctx) async {
      final pattern = input['pattern'] as String?;
      if (pattern == null) {
        return ToolOutput(
          'Error: pattern is required',
          metadata: {'error': true},
        );
      }

      final root = input['path'] as String? ?? Directory.current.path;
      final safeRoot = resolveSafePath(root);
      final dir = Directory(safeRoot);
      if (!dir.existsSync()) {
        return ToolOutput(
          'Error: directory not found: $safeRoot',
          metadata: {'error': true},
        );
      }

      await ctx.ask(permission: 'glob', patterns: [pattern]);

      final globMatcher = Glob(pattern, recursive: true);
      final matchFiles = <File>[];
      final gitignore = _loadGitignore(safeRoot);

      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final rel = p.relative(entity.path, from: safeRoot);
        final relPosix = p.posix.joinAll(p.split(rel));
        if (gitignore.any((g) => g.matches(relPosix))) continue;
        if (globMatcher.matches(rel) || globMatcher.matches(relPosix)) {
          matchFiles.add(entity);
          if (matchFiles.length >= 1000) break;
        }
      }

      if (matchFiles.isEmpty) {
        return ToolOutput('No files matching pattern: $pattern');
      }

      // Sort by modification time descending (most recent first)
      matchFiles.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      final matches = matchFiles
          .map((f) => p.relative(f.path, from: safeRoot))
          .toList();

      return ToolOutput(
        matches.join('\n'),
        metadata: {'count': matches.length},
      );
    },
  );
}

List<Glob> _loadGitignore(String root) {
  final result = <Glob>[];
  final file = File(p.join(root, '.gitignore'));
  if (!file.existsSync()) return result;
  try {
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      try {
        result.add(Glob(trimmed, recursive: true));
      } catch (_) {}
    }
  } catch (_) {}
  return result;
}
