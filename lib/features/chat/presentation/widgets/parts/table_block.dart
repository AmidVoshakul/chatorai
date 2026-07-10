import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/markdown_styles.dart';
import 'package:chatorai/shared/utils/message_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';

// ===========================================================================
// DATA MODEL
// ===========================================================================

class TableRowData {
  final List<String> cells;
  final bool isHeader;

  const TableRowData({required this.cells, this.isHeader = false});
}

// ===========================================================================
// WIDGET CLASS
// ===========================================================================

class TableBlock extends StatefulWidget {
  final List<TableRowData> rows;

  const TableBlock({super.key, required this.rows});

  @override
  State<TableBlock> createState() => _TableBlockState();
}

// ===========================================================================
// STATE CLASS
// ===========================================================================

class _TableBlockState extends State<TableBlock> {
  bool _isCollapsed = false;

  // =======================================================================
  // BUILD METHOD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    // Colors matching CodeBlock header
    final headerColor = isDark
        ? ChatoraiColors.white70
        : ChatoraiColors.pureBlack;
    final headerBgColor = isDark
        ? ChatoraiColors.darkGray
        : ChatoraiColors.lightGray;

    final tsvContent = _buildTsv();

    // No outer decoration — the table blends with the chat bubble
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ChatoraiSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (identical layout to CodeBlock) ──
          GestureDetector(
            onTap: () => setState(() => _isCollapsed = !_isCollapsed),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatoraiSpacing.sm,
                vertical: ChatoraiSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(ChatoraiBorderRadius.sm),
                  bottom: _isCollapsed
                      ? const Radius.circular(ChatoraiBorderRadius.sm)
                      : Radius.zero,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isCollapsed ? Icons.chevron_right : Icons.expand_more,
                        color: headerColor,
                        size: ChatoraiIconSizes.lg,
                      ),
                      const SizedBox(width: ChatoraiSpacing.xs),
                      Text(
                        'Table',
                        style: TextStyle(
                          color: headerColor,
                          fontWeight: FontWeight.bold,
                          fontSize: ChatoraiFontSizes.md,
                        ),
                      ),
                    ],
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      icon: Icon(
                        Icons.copy_all,
                        color: headerColor,
                        size: ChatoraiIconSizes.lg,
                      ),
                      onPressed: () => MessageUtils.copyMessage(
                        content: tsvContent,
                        context: context,
                      ),
                      tooltip: localizations.copyCodeTooltip,
                      splashRadius: ChatoraiIconSizes.md,
                      hoverColor: isDark
                          ? ChatoraiColors.black10
                          : ChatoraiColors.black12,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: ChatoraiSpacing.lg,
                        minHeight: ChatoraiSpacing.lg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Table body ──
          if (!_isCollapsed) SelectionArea(child: _buildTable(context, isDark)),
        ],
      ),
    );
  }

  // =======================================================================
  // TABLE BUILDER
  // =======================================================================

  Widget _buildTable(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final textColor = isDark
        ? ChatoraiColors.darkTextColor
        : ChatoraiColors.lightTextColor;
    final dividerColor = theme.dividerColor.withValues(alpha: 0.3);

    final evenRowColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);

    if (widget.rows.isEmpty) return const SizedBox.shrink();

    final colCount = widget.rows
        .map((r) => r.cells.length)
        .reduce((a, b) => a > b ? a : b);

    final normalizedRows = widget.rows.map((row) {
      if (row.cells.length < colCount) {
        return TableRowData(
          cells: [
            ...row.cells,
            ...List.filled(colCount - row.cells.length, ''),
          ],
          isHeader: row.isHeader,
        );
      }
      return row;
    }).toList();

    // Compute pixel-based column widths from content length
    const minColWidth = 80.0;
    const maxColWidth = 350.0;
    const charWidth = 8.0;
    const cellPadding = 36.0;

    final colPixelWidths = List.filled(colCount, minColWidth);
    for (final row in normalizedRows) {
      for (int i = 0; i < row.cells.length; i++) {
        final textWidth = row.cells[i].length * charWidth + cellPadding;
        if (textWidth > colPixelWidths[i]) {
          colPixelWidths[i] = textWidth.clamp(minColWidth, maxColWidth);
        }
      }
    }

    final mdStyleSheet = ChatoraiMarkdownStyles.getMarkdownStyles(context);

    final border = TableBorder(
      horizontalInside: BorderSide(
        color: dividerColor,
        width: ChatoraiBorderWidth.thin,
      ),
    );

    final tableRows = List.generate(normalizedRows.length, (rowIndex) {
      final row = normalizedRows[rowIndex];
      final isHeaderRow = row.isHeader;
      final isEvenRow = rowIndex > 0 && rowIndex % 2 == 0;

      return TableRow(
        decoration: BoxDecoration(
          color: isEvenRow ? evenRowColor : Colors.transparent,
        ),
        children: List.generate(colCount, (colIndex) {
          final cellText = colIndex < row.cells.length
              ? row.cells[colIndex]
              : '';
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChatoraiSpacing.sm,
              vertical: ChatoraiSpacing.xs,
            ),
            child: isHeaderRow
                ? Text(
                    cellText,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: ChatoraiFontSizes.base,
                    ),
                  )
                : MarkdownBody(
                    data: cellText,
                    styleSheet: mdStyleSheet,
                    selectable: true,
                    softLineBreak: true,
                    fitContent: true,
                  ),
          );
        }),
      );
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final naturalWidth = colPixelWidths.fold(0.0, (a, b) => a + b);

        if (naturalWidth <= availableWidth) {
          final ratio = availableWidth / naturalWidth;
          final stretched = <int, TableColumnWidth>{
            for (int i = 0; i < colCount; i++)
              i: FixedColumnWidth(colPixelWidths[i] * ratio),
          };
          return Table(
            columnWidths: stretched,
            border: border,
            children: tableRows,
          );
        }

        final fixed = <int, TableColumnWidth>{
          for (int i = 0; i < colCount; i++)
            i: FixedColumnWidth(colPixelWidths[i]),
        };
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            columnWidths: fixed,
            border: border,
            children: tableRows,
          ),
        );
      },
    );
  }

  // =======================================================================
  // TSV FORMATTER
  // =======================================================================

  String _buildTsv() {
    final buffer = StringBuffer();
    for (final row in widget.rows) {
      buffer.writeln(row.cells.join('\t'));
    }
    return buffer.toString().trim();
  }
}

// ===========================================================================
// TABLE PARSER
// ===========================================================================

class TableParser {
  static final _pipeTableLineRegex = RegExp(r'^\s*\|.+\|\s*$');
  static final _separatorLineRegex = RegExp(r'^\|[\s\-:]+\|[\s\-:]*\|');

  /// Parses a list of lines into a list of TableRowData.
  /// Returns null if the lines don't form a valid table.
  static List<TableRowData>? parseTableLines(List<String> lines) {
    if (lines.isEmpty) return null;

    final pipeLines = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (_pipeTableLineRegex.hasMatch(trimmed)) {
        pipeLines.add(trimmed);
      } else {
        return null;
      }
    }

    if (pipeLines.length < 2) return null;

    final rows = <TableRowData>[];
    bool hasHeader = false;

    // Check if second line is a separator
    if (_separatorLineRegex.hasMatch(pipeLines[1])) {
      hasHeader = true;
    }

    for (int i = 0; i < pipeLines.length; i++) {
      if (hasHeader && i == 1) continue; // Skip separator line

      final cells = _parseRow(pipeLines[i]);
      rows.add(TableRowData(cells: cells, isHeader: hasHeader && i == 0));
    }

    return rows;
  }

  static List<String> _parseRow(String line) {
    // Remove leading and trailing pipes, then split by pipe
    final trimmed = line.replaceFirst(RegExp(r'^\|'), '');
    final withoutTrailing = trimmed.replaceFirst(RegExp(r'\|$'), '');
    return withoutTrailing.split('|').map((cell) => cell.trim()).toList();
  }

  /// Extracts consecutive table lines from a list of lines starting at index.
  /// Returns the table lines and the index after the table.
  static ({List<String> lines, int endIndex})? extractTableAt(
    List<String> allLines,
    int startIndex,
  ) {
    if (startIndex >= allLines.length) return null;

    final tableLines = <String>[];
    int i = startIndex;

    while (i < allLines.length) {
      final line = allLines[i].trim();
      if (_pipeTableLineRegex.hasMatch(line)) {
        tableLines.add(line);
        i++;
      } else {
        break;
      }
    }

    if (tableLines.length < 2) return null;

    return (lines: tableLines, endIndex: i);
  }
}
