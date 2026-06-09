import 'dart:io';

import 'package:chatorai/features/tools/data/models/tool.dart';
import 'package:path/path.dart' as p;

import 'path_sandbox.dart';

ToolDef createGrepTool() {
  return ToolDef(
    id: 'grep',
    description: 'Search file contents by regex',
    inputSchema: {
      'type': 'object',
      'properties': {
        'pattern': {'type': 'string', 'description': 'Regex pattern to search'},
        'path': {
          'type': 'string',
          'description': 'Root directory to search in',
        },
        'case_sensitive': {
          'type': 'boolean',
          'description': 'Case sensitive search',
        },
        'max_matches': {
          'type': 'integer',
          'description': 'Maximum matches to return',
        },
      },
      'required': ['pattern'],
    },
    execute: (input, ctx) async {
      final pattern = input['pattern'] as String?;
      if (pattern == null) throw ArgumentError('pattern is required');

      final root = input['path'] as String? ?? Directory.current.path;
      final regex = RegExp(
        pattern,
        caseSensitive: input['case_sensitive'] == true,
      );
      final maxMatches = input['max_matches'] as int? ?? 50;

      final results = <String>[];
      final safeRoot = resolveSafePath(root);
      final dir = Directory(safeRoot);
      if (!dir.existsSync()) {
        return ToolOutput(
          'Error: directory not found: $root',
          metadata: {'error': true},
        );
      }

      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (results.length >= maxMatches) break;
        if (entity is File) {
          try {
            final content = await entity.readAsString();
            final lines = content.split('\n');
            for (final line in lines) {
              if (results.length >= maxMatches) break;
              if (regex.hasMatch(line)) {
                final relative = p.relative(entity.path, from: safeRoot);
                results.add('$relative: $line');
              }
            }
          } catch (_) {}
        }
      }

      return ToolOutput(
        results.join('\n'),
        metadata: {'count': results.length},
      );
    },
  );
}
