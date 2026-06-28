import 'dart:convert';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/truncation_service.dart';
import 'package:chatorai/shared/utils/logger.dart';

ToolDef createFormatTool(
  FormatService formatService, [
  FormatterConfig? formatterConfig,
]) {
  return ToolDef(
    id: 'format',
    description:
        'Format source code using language-specific formatters. '
        'Supports dart, prettier, gofmt, mix, ruff, rustfmt, clang-format, '
        'ktlint, biome, zig, terraform, shfmt, nixfmt, rubocop, standardrb, '
        'htmlbeautifier, dfmt, ocamlformat, gleam, ormolu, cljfmt, latexindent, '
        'pint, air, oxfmt, uv, and more. '
        'Use chatorai.json formatter section for overrides.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'filePath': {
          'type': 'string',
          'description': 'Path to the file to format',
        },
        'formatter': {
          'type': 'string',
          'description':
              'Preferred formatter name (optional, auto-detected by file extension)',
        },
      },
      'required': ['filePath'],
    },
    execute: (input, ctx) async {
      final filePath = input['filePath'] as String?;
      if (filePath == null || filePath.isEmpty) {
        return ToolOutput('filePath is required', metadata: {'error': true});
      }

      final preferred = input['formatter'] as String?;
      final truncation = TruncationService.instance;

      try {
        final result = await formatService.formatFile(
          filePath,
          preferredFormatter: preferred,
          formatterConfig: formatterConfig,
        );

        if (result.error != null) {
          return ToolOutput(
            'Format failed: ${result.error}',
            metadata: {
              'filePath': filePath,
              'error': true,
              'formatter': result.formatter,
            },
          );
        }

        final output = {
          'file': filePath,
          'formatter': result.formatter,
          'changed': result.changed,
          'formatted': result.formattedContent,
          if (result.originalContent != null)
            'original': result.originalContent,
        };

        return ToolOutput(
          truncation.truncate(
            const JsonEncoder.withIndent('  ').convert(output),
          ),
          metadata: {
            'filePath': filePath,
            'action': 'format',
            'formatter': result.formatter,
            'changed': result.changed,
          },
          title: 'Format: $filePath',
        );
      } catch (e, st) {
        LogTags.lsp.logError('Format tool error', e, st);
        return ToolOutput(
          'Format error: $e',
          metadata: {'error': true, 'filePath': filePath},
        );
      }
    },
  );
}
