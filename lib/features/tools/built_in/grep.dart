import 'dart:convert';
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
        'include': {
          'type': 'string',
          'description': 'Glob pattern to include files (e.g., "*.dart")',
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
      if (pattern == null) {
        return const ToolOutput(
          'Error: pattern is required',
          metadata: {'error': true},
        );
      }

      await ctx.ask(permission: 'grep', patterns: [pattern]);

      final root = input['path'] as String? ?? Directory.current.path;
      final includePattern = input['include'] as String?;
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
          // Apply include filter if provided
          if (includePattern != null) {
            final relative = p.relative(entity.path, from: safeRoot);
            // Simple glob matching: convert glob to regex
            final globRegex = _globToRegex(includePattern);
            if (!RegExp(globRegex).hasMatch(relative)) {
              continue;
            }
          }
          try {
            final content = await entity.readAsString(encoding: utf8);
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

// Convert a simple glob pattern to a regex string
// Supports: *, ?, [seq], [!seq]
String _globToRegex(String glob) {
  final escaped = glob
      .replaceAll(r'$', r'\$')
      .replaceAll(r'^', r'\^')
      .replaceAll(r'.', r'\.')
      .replaceAll(r'|', r'\|')
      .replaceAll(r'(', r'\(')
      .replaceAll(r')', r'\)')
      .replaceAll(r'[', r'\[')
      .replaceAll(r']', r'\]')
      .replaceAll(r'+', r'\+')
      .replaceAll(r'{', r'\{')
      .replaceAll(r'}', r'\}')
      .replaceAll(r'/', r'\/');
  final star = '.*';
  final question = '.';
  // Handle * and ? after escaping other special chars
  final regex = escaped.replaceAll('*', star).replaceAll('?', question);
  return '^$regex\$';
}
