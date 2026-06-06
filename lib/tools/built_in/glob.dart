import 'dart:io';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import '../tool.dart';
import 'path_sandbox.dart';

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
      if (pattern == null) throw ArgumentError('pattern is required');

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
      final matches = <String>[];
      final gitignore = _loadGitignore(safeRoot);

      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final rel = p.relative(entity.path, from: safeRoot);
        final relPosix = p.posix.joinAll(p.split(rel));
        if (gitignore.any((g) => g.matches(relPosix))) continue;
        if (globMatcher.matches(rel) || globMatcher.matches(relPosix)) {
          matches.add(rel);
          if (matches.length >= 1000) break;
        }
      }

      if (matches.isEmpty) {
        return ToolOutput('No files matching pattern: $pattern');
      }

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
