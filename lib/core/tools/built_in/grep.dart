import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';
import 'package:chatorai/core/workspace/workspace_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/core/tools/built_in/tool_path_resolve.dart';

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

      final root = input['path'] as String? ?? workspaceRuntimeCurrent.path;
      final includePattern = input['include'] as String?;
      final regex = RegExp(
        pattern,
        caseSensitive: input['case_sensitive'] == true,
      );
      final maxMatches = input['max_matches'] as int? ?? 50;

      final results = <String>[];
      final resolved = await resolveToolPath(
        ctx: ctx,
        userPath: root,
        toolName: 'grep',
      );
      if (resolved.isError) return resolved.error!;
      final safeRoot = resolved.path!;
      if (!isWithinAnyRoot(safeRoot, managedReadRoots)) {
        await ctx.ask(permission: 'grep', patterns: [pattern]);
      }
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
          if (includePattern != null) {
            final relative = p.relative(entity.path, from: safeRoot);
            final globRegex = _globToRegex(includePattern);
            if (!RegExp(globRegex).hasMatch(relative)) {
              continue;
            }
          }
          String content;
          try {
            content = await entity.readAsString(encoding: utf8);
          } on FileSystemException catch (e) {
            if (kDebugMode) {
              LogTags.permission.logWarning(
                'grep: skipping $entity — ${e.message}',
              );
            }
            continue;
          }
          final lines = content.split('\n');
          for (int lineNum = 0; lineNum < lines.length; lineNum++) {
            if (results.length >= maxMatches) break;
            final line = lines[lineNum];
            if (regex.hasMatch(line)) {
              final relative = p.relative(entity.path, from: safeRoot);
              results.add('$relative:${lineNum + 1}: $line');
            }
          }
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
