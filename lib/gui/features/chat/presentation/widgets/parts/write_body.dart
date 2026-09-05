import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/core/chat/chat/tool_result_part.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/parts/tool_icon.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/gui/shared/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

// ===========================================================================
// WriteBody — public widget
// ===========================================================================

class WriteBody extends StatelessWidget {
  final ThemeData theme;
  final ToolResultPart part;
  final Map<int, List<LspDiagnostic>> diagnosticsByLine;
  final void Function(LspDiagnostic) onDiagnosticTap;

  const WriteBody({
    super.key,
    required this.theme,
    required this.part,
    this.diagnosticsByLine = const {},
    required this.onDiagnosticTap,
  });

  @override
  Widget build(BuildContext context) {
    if (part.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                part.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.error,
                  fontSize: ChatoraiFontSizes.sm,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final input = part.input ?? {};
    final content = input['content'] as String? ?? '';
    final path =
        input['path'] as String? ??
        input['filePath'] as String? ??
        input['file_path'] as String? ??
        '';
    final lines = content.split('\n');

    final iconData = toolIcon(part.toolName);
    final title = 'Write ${path.replaceAll('/', '/\u200B')}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(color: diffBgColor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, iconData, title),
          if (lines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 10),
              child: _WriteContent(lines: lines),
            ),
          if (diagnosticsByLine.isNotEmpty)
            _DiagnosticFooter(
              diagnosticsByLine: diagnosticsByLine,
              isLoadingDiagnostics: false,
              onDiagnosticTap: onDiagnosticTap,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, IconData iconData, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(iconData, size: 14, color: theme.colorScheme.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.muted,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// _WriteContent — line-numbered content body
// ===========================================================================

class _WriteContent extends StatelessWidget {
  final List<String> lines;

  const _WriteContent({required this.lines});

  @override
  Widget build(BuildContext context) {
    final maxDigits = lines.length.toString().length;
    final gutterWidth = maxDigits * 8.0 + 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines.length; i++)
          _WriteLine(
            lineNumber: i + 1,
            text: lines[i],
            gutterWidth: gutterWidth,
          ),
      ],
    );
  }
}

// ===========================================================================
// _WriteLine — single content row with line number
// ===========================================================================

class _WriteLine extends StatelessWidget {
  final int lineNumber;
  final String text;
  final double gutterWidth;

  const _WriteLine({
    required this.lineNumber,
    required this.text,
    required this.gutterWidth,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: gutterWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            child: Text(
              lineNumber.toString(),
              textAlign: TextAlign.right,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: ChatoraiFontSizes.mono(
                ChatoraiFontSizes.sm,
                color: cs.muted,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: Text(
              text,
              style: ChatoraiFontSizes.mono(
                ChatoraiFontSizes.md,
                color: cs.dim,
              ),
              softWrap: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// _DiagnosticFooter — inline footer for write body diagnostics
// ===========================================================================

class _DiagnosticFooter extends StatelessWidget {
  final Map<int, List<LspDiagnostic>> diagnosticsByLine;
  final bool isLoadingDiagnostics;
  final void Function(LspDiagnostic) onDiagnosticTap;

  const _DiagnosticFooter({
    required this.diagnosticsByLine,
    required this.isLoadingDiagnostics,
    required this.onDiagnosticTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (isLoadingDiagnostics) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.muted),
        ),
      );
    }

    if (diagnosticsByLine.isEmpty) return const SizedBox.shrink();

    int errors = 0;
    int warnings = 0;
    for (final diags in diagnosticsByLine.values) {
      for (final d in diags) {
        if (d.severity == 1) {
          errors++;
        } else if (d.severity == 2) {
          warnings++;
        }
      }
    }

    if (errors == 0 && warnings == 0) return const SizedBox.shrink();

    final parts = <String>[];
    if (errors > 0) {
      parts.add('$errors ${errors == 1 ? 'error' : 'errors'}');
    }
    if (warnings > 0) {
      parts.add('$warnings ${warnings == 1 ? 'warning' : 'warnings'}');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(
        children: [
          Icon(
            errors > 0 ? Icons.error : Icons.warning_amber_rounded,
            size: 12,
            color: errors > 0 ? cs.error : cs.tertiary,
          ),
          const SizedBox(width: 4),
          Text(
            parts.join(', '),
            style: TextStyle(
              fontSize: 10,
              color: errors > 0 ? cs.error : cs.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}
