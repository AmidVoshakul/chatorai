import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

import 'diff_parser.dart';
import 'tool_icon.dart';
import 'tool_title.dart';

// ===========================================================================
// DiffBody — public widget
// ===========================================================================

class DiffBody extends StatelessWidget {
  final ThemeData theme;
  final String? oldSource;
  final String? newSource;
  final String? patch;
  final String? filePath;
  final String? toolName;
  final bool displayFull;
  final bool isError;
  final bool isLoadingDiagnostics;
  final Map<int, List<LspDiagnostic>> diagnosticsByLine;
  final VoidCallback? onFetchDiagnostics;
  final void Function(LspDiagnostic) onDiagnosticTap;
  final int contextLines;
  final int? fileStartLine;

  const DiffBody({
    super.key,
    required this.theme,
    this.oldSource,
    this.newSource,
    this.patch,
    this.filePath,
    this.toolName,
    required this.displayFull,
    required this.isError,
    this.isLoadingDiagnostics = false,
    this.diagnosticsByLine = const {},
    this.onFetchDiagnostics,
    required this.onDiagnosticTap,
    this.contextLines = 4,
    this.fileStartLine,
  });

  List<DiffHunk> get _hunks => parseUnifiedDiff(
    patch: patch,
    oldSource: oldSource,
    newSource: newSource,
    contextLines: contextLines,
    fileStartLine: fileStartLine,
  );

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                filePath ?? '',
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

    final hasDiff = _hunks.isNotEmpty;
    if (!hasDiff || !displayFull) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(color: diffBgColor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDiffHeader(theme),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DiffTable(
                  hunks: _hunks,
                  diagnosticsByLine: diagnosticsByLine,
                  onDiagnosticTap: onDiagnosticTap,
                  isLoadingDiagnostics: isLoadingDiagnostics,
                ),
                _DiagnosticFooter(
                  diagnosticsByLine: diagnosticsByLine,
                  isLoadingDiagnostics: isLoadingDiagnostics,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffHeader(ThemeData theme) {
    final iconData = toolIcon(toolName ?? '');
    final title = toolName != null && filePath != null
        ? toolTitle(toolName!, {'file_path': filePath!})
        : '';
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
      child: Row(
        children: [
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
// _DiagnosticFooter
// ===========================================================================

class _DiagnosticFooter extends StatelessWidget {
  final Map<int, List<LspDiagnostic>> diagnosticsByLine;
  final bool isLoadingDiagnostics;

  const _DiagnosticFooter({
    required this.diagnosticsByLine,
    required this.isLoadingDiagnostics,
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

// ===========================================================================
// _DiffTable — diff rows layout
// ===========================================================================

class _DiffTable extends StatelessWidget {
  final List<DiffHunk> hunks;
  final Map<int, List<LspDiagnostic>> diagnosticsByLine;
  final void Function(LspDiagnostic) onDiagnosticTap;
  final bool isLoadingDiagnostics;

  const _DiffTable({
    required this.hunks,
    required this.diagnosticsByLine,
    required this.onDiagnosticTap,
    required this.isLoadingDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final maxDigits = _maxLineDigits(hunks);
        final gutterWidth = maxDigits * 8.0 + 12.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final hunk in hunks)
              ...hunk.rows.map(
                (row) => _DiffRow(
                  row: row,
                  isWide: isWide,
                  gutterWidth: gutterWidth,
                  diagnostics:
                      diagnosticsByLine[row.oldLineNumber ??
                          row.newLineNumber ??
                          -1],
                  onDiagnosticTap: onDiagnosticTap,
                ),
              ),
          ],
        );
      },
    );
  }

  int _maxLineDigits(List<DiffHunk> hunks) {
    int max = 0;
    for (final hunk in hunks) {
      for (final row in hunk.rows) {
        final n = row.oldLineNumber ?? row.newLineNumber ?? 0;
        if (n > max) max = n;
      }
    }
    return max.toString().length;
  }
}

// ===========================================================================
// _DiffRow — single diff row
// ===========================================================================

class _DiffRow extends StatelessWidget {
  final DiffRow row;
  final bool isWide;
  final double gutterWidth;
  final List<LspDiagnostic>? diagnostics;
  final void Function(LspDiagnostic) onDiagnosticTap;

  const _DiffRow({
    required this.row,
    required this.isWide,
    required this.gutterWidth,
    this.diagnostics,
    required this.onDiagnosticTap,
  });

  _RowColors _computeColors(ColorScheme cs) {
    return switch (row.type) {
      DiffLineType.addition => _RowColors(
        leftBg: Colors.transparent,
        rightBg: cs.diffAddedBg,
        leftMarker: ' ',
        rightMarker: '+',
        leftText: '',
        rightText: row.right,
        leftLine: null,
        rightLine: row.newLineNumber,
      ),
      DiffLineType.removal => _RowColors(
        leftBg: cs.diffRemovedBg,
        rightBg: Colors.transparent,
        leftMarker: '-',
        rightMarker: ' ',
        leftText: row.left,
        rightText: '',
        leftLine: row.oldLineNumber,
        rightLine: null,
      ),
      DiffLineType.modified => _RowColors(
        leftBg: cs.diffRemovedBg,
        rightBg: cs.diffAddedBg,
        leftMarker: '-',
        rightMarker: '+',
        leftText: row.left,
        rightText: row.right,
        leftLine: row.oldLineNumber,
        rightLine: row.newLineNumber,
      ),
      DiffLineType.context => _RowColors(
        leftBg: Colors.transparent,
        rightBg: Colors.transparent,
        leftMarker: ' ',
        rightMarker: ' ',
        leftText: row.left,
        rightText: row.right,
        leftLine: row.oldLineNumber,
        rightLine: row.newLineNumber,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = _computeColors(cs);
    final hasDiagnostics = diagnostics != null && diagnostics!.isNotEmpty;

    final rowWidget = isWide
        ? _buildWideRow(colors, cs)
        : row.type == DiffLineType.modified
        ? _buildModifiedNarrowRow(cs)
        : _buildNarrowRow(cs);

    if (!hasDiagnostics) return rowWidget;

    return Row(
      children: [
        Expanded(child: rowWidget),
        ...diagnostics!.map(
          (d) =>
              _DiagnosticBadge(diagnostic: d, onTap: () => onDiagnosticTap(d)),
        ),
      ],
    );
  }

  Widget _buildModifiedNarrowRow(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNarrowRowWith(
          cs,
          bg: cs.diffRemovedBg,
          marker: '-',
          text: row.left,
          line: row.oldLineNumber,
        ),
        _buildNarrowRowWith(
          cs,
          bg: cs.diffAddedBg,
          marker: '+',
          text: row.right,
          line: row.newLineNumber,
        ),
      ],
    );
  }

  Widget _buildNarrowRowWith(
    ColorScheme cs, {
    required Color bg,
    required String marker,
    required String text,
    required int? line,
  }) {
    final hasBg = bg != Colors.transparent;
    return Container(
      color: bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Gutter(
            width: gutterWidth,
            lineNumber: line,
            bg: hasBg ? bg : Colors.transparent,
            fg: cs.diffLineNumberFg,
          ),
          Container(
            width: diffMarkerWidth,
            color: hasBg ? bg : Colors.transparent,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              marker,
              style: ChatoraiFontSizes.mono(
                ChatoraiFontSizes.sm,
                color: hasBg
                    ? (marker == '-' ? removalColor : additionColor)
                    : cs.dim,
                weight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      ),
    );
  }

  Widget _buildWideRow(_RowColors colors, ColorScheme cs) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Side(
              bg: colors.leftBg,
              line: colors.leftLine,
              marker: colors.leftMarker,
              text: colors.leftText,
              gutterWidth: gutterWidth,
            ),
          ),
          Expanded(
            child: _Side(
              bg: colors.rightBg,
              line: colors.rightLine,
              marker: colors.rightMarker,
              text: colors.rightText,
              gutterWidth: gutterWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowRow(ColorScheme cs) {
    return _buildNarrowRowWith(
      cs,
      bg: _bgForType(cs),
      marker: _markerForType(),
      text: _textForType(),
      line: _lineForType(),
    );
  }

  Color _bgForType(ColorScheme cs) {
    return switch (row.type) {
      DiffLineType.addition => cs.diffAddedBg,
      DiffLineType.removal => cs.diffRemovedBg,
      DiffLineType.modified => cs.diffRemovedBg,
      DiffLineType.context => Colors.transparent,
    };
  }

  String _markerForType() {
    return switch (row.type) {
      DiffLineType.addition => '+',
      DiffLineType.removal => '-',
      DiffLineType.modified => '-',
      DiffLineType.context => ' ',
    };
  }

  String _textForType() {
    return switch (row.type) {
      DiffLineType.addition => row.right,
      DiffLineType.removal => row.left,
      DiffLineType.modified => row.left,
      DiffLineType.context => row.left,
    };
  }

  int? _lineForType() {
    return switch (row.type) {
      DiffLineType.addition => row.newLineNumber,
      DiffLineType.removal => row.oldLineNumber,
      DiffLineType.modified => row.oldLineNumber,
      DiffLineType.context => row.oldLineNumber ?? row.newLineNumber,
    };
  }
}

// ===========================================================================
// _DiagnosticBadge
// ===========================================================================

class _DiagnosticBadge extends StatelessWidget {
  final LspDiagnostic diagnostic;
  final VoidCallback onTap;

  const _DiagnosticBadge({required this.diagnostic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _severityColor(diagnostic.severity, cs);
    final icon = diagnostic.severity == 1
        ? Icons.error
        : diagnostic.severity == 2
        ? Icons.warning
        : Icons.info;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 2),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Icon(icon, size: 10, color: color),
      ),
    );
  }

  Color _severityColor(int severity, ColorScheme cs) {
    switch (severity) {
      case 1:
        return cs.error;
      case 2:
        return cs.tertiary;
      case 3:
        return cs.primary;
      default:
        return cs.muted;
    }
  }
}

// ===========================================================================
// _RowColors
// ===========================================================================

class _RowColors {
  final Color leftBg;
  final Color rightBg;
  final String leftMarker;
  final String rightMarker;
  final String leftText;
  final String rightText;
  final int? leftLine;
  final int? rightLine;

  const _RowColors({
    required this.leftBg,
    required this.rightBg,
    required this.leftMarker,
    required this.rightMarker,
    required this.leftText,
    required this.rightText,
    required this.leftLine,
    required this.rightLine,
  });
}

// ===========================================================================
// _Side — wide layout side column
// ===========================================================================

class _Side extends StatelessWidget {
  final Color bg;
  final int? line;
  final String marker;
  final String text;
  final double gutterWidth;

  const _Side({
    required this.bg,
    required this.line,
    required this.marker,
    required this.text,
    required this.gutterWidth,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasBg = bg != Colors.transparent;
    return Container(
      color: bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Gutter(
            width: gutterWidth,
            lineNumber: line,
            bg: hasBg ? bg : Colors.transparent,
            fg: cs.diffLineNumberFg,
          ),
          Container(
            width: diffMarkerWidth,
            color: hasBg ? bg : Colors.transparent,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              marker,
              style: ChatoraiFontSizes.mono(
                ChatoraiFontSizes.md,
                color: hasBg
                    ? (marker == '-' ? removalColor : additionColor)
                    : cs.diffLineNumberFg,
                weight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: text.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
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
      ),
    );
  }
}

// ===========================================================================
// _Gutter — line number column
// ===========================================================================

class _Gutter extends StatelessWidget {
  final double width;
  final int? lineNumber;
  final Color bg;
  final Color fg;

  const _Gutter({
    required this.width,
    required this.lineNumber,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        lineNumber?.toString() ?? '',
        textAlign: TextAlign.right,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: ChatoraiFontSizes.mono(
          ChatoraiFontSizes.sm,
          color: fg,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}
