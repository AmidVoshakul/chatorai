import 'dart:convert';
import 'package:chatorai/core/lsp/lsp_service.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/truncation_service.dart';
import 'package:chatorai/shared/utils/logger.dart';

ToolDef createLspTool(LspService lspService) {
  return ToolDef(
    id: 'lsp',
    description:
        'Language Server Protocol tool for code intelligence. '
        'Provides hover, diagnostics, definition, and references '
        'for supported languages (currently Dart). '
        'Use when you need to understand code, find errors, or navigate.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'filePath': {
          'type': 'string',
          'description': 'Path to the source file to analyze',
        },
        'action': {
          'type': 'string',
          'enum': [
            'diagnostics',
            'hover',
            'definition',
            'references',
            'symbols',
          ],
          'description': 'LSP action to perform',
        },
        'line': {
          'type': 'integer',
          'description':
              'Line number (0-based) for hover/definition/references',
        },
        'character': {
          'type': 'integer',
          'description':
              'Character position (0-based) for hover/definition/references',
        },
      },
      'required': ['filePath'],
    },
    execute: (input, ctx) async {
      final filePath = input['filePath'] as String?;
      if (filePath == null || filePath.isEmpty) {
        return ToolOutput('filePath is required', metadata: {'error': true});
      }

      final action = input['action'] as String? ?? 'diagnostics';
      final truncation = TruncationService.instance;

      try {
        switch (action) {
          case 'diagnostics':
            final diagnostics = await lspService.diagnostics(filePath).toList();
            final errors = diagnostics.where((d) => d.severity == 1).length;
            final warnings = diagnostics.where((d) => d.severity == 2).length;

            final result = {
              'file': filePath,
              'action': 'diagnostics',
              'summary': {
                'errors': errors,
                'warnings': warnings,
                'total': diagnostics.length,
              },
              'diagnostics': diagnostics.map((d) => d.toJson()).toList(),
            };

            return ToolOutput(
              truncation.truncate(
                const JsonEncoder.withIndent('  ').convert(result),
              ),
              metadata: {
                'filePath': filePath,
                'action': 'diagnostics',
                'errorCount': errors,
                'warningCount': warnings,
                if (errors > 0) 'error': true,
              },
              title: 'LSP diagnostics: $filePath',
            );

          case 'hover':
            final line = input['line'] as int? ?? 0;
            final character = input['character'] as int? ?? 0;
            final hoverResult = await lspService.hover(
              filePath,
              line,
              character,
            );

            if (hoverResult == null) {
              return ToolOutput(
                'No hover information available',
                metadata: {'filePath': filePath, 'action': 'hover'},
              );
            }

            return ToolOutput(
              truncation.truncate(
                const JsonEncoder.withIndent('  ').convert(hoverResult),
              ),
              metadata: {
                'filePath': filePath,
                'action': 'hover',
                'line': line,
                'character': character,
              },
              title: 'LSP hover: $filePath:$line:$character',
            );

          case 'definition':
            final line = input['line'] as int? ?? 0;
            final character = input['character'] as int? ?? 0;
            final defs = await lspService.definition(filePath, line, character);

            return ToolOutput(
              truncation.truncate(
                const JsonEncoder.withIndent('  ').convert(defs),
              ),
              metadata: {
                'filePath': filePath,
                'action': 'definition',
                'line': line,
                'character': character,
                'count': defs.length,
              },
              title: 'LSP definition: $filePath:$line:$character',
            );

          case 'references':
            final line = input['line'] as int? ?? 0;
            final character = input['character'] as int? ?? 0;
            final refs = await lspService.references(filePath, line, character);

            return ToolOutput(
              truncation.truncate(
                const JsonEncoder.withIndent('  ').convert(refs),
              ),
              metadata: {
                'filePath': filePath,
                'action': 'references',
                'line': line,
                'character': character,
                'count': refs.length,
              },
              title: 'LSP references: $filePath:$line:$character',
            );

          default:
            return ToolOutput(
              'Unsupported action: $action',
              metadata: {'error': true, 'filePath': filePath},
            );
        }
      } catch (e, st) {
        LogTags.lsp.logError('LSP tool error', e, st);
        return ToolOutput(
          'LSP error: $e',
          metadata: {'error': true, 'filePath': filePath, 'action': action},
        );
      }
    },
  );
}
