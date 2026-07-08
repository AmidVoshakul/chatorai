import 'dart:convert';

import 'package:chatorai/core/lsp/lsp_provider.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/_tool_icon.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/_tool_title.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

enum _DiffLineType { context, addition, removal }

class _DiffLineData {
  final int? oldLineNumber;
  final int? newLineNumber;
  final String text;
  final _DiffLineType type;
  final List<LspDiagnostic>? diagnostics;

  const _DiffLineData({
    this.oldLineNumber,
    this.newLineNumber,
    required this.text,
    required this.type,
    this.diagnostics,
  });
}

List<_DiffLineData> _computeDiff(String oldText, String newText) {
  final oldLines = oldText.split('\n');
  final newLines = newText.split('\n');

  if (oldLines.isEmpty && newLines.isEmpty) {
    return const [];
  }

  int prefixLen = 0;
  while (prefixLen < oldLines.length && prefixLen < newLines.length) {
    if (oldLines[prefixLen] == newLines[prefixLen]) {
      prefixLen++;
    } else {
      break;
    }
  }

  int suffixLen = 0;
  while (suffixLen < (oldLines.length - prefixLen) &&
      suffixLen < (newLines.length - prefixLen)) {
    final oldIdx = oldLines.length - 1 - suffixLen;
    final newIdx = newLines.length - 1 - suffixLen;
    if (oldLines[oldIdx] == newLines[newIdx]) {
      suffixLen++;
    } else {
      break;
    }
  }

  final result = <_DiffLineData>[];

  for (var i = 0; i < prefixLen; i++) {
    result.add(
      _DiffLineData(
        oldLineNumber: i + 1,
        newLineNumber: i + 1,
        text: oldLines[i],
        type: _DiffLineType.context,
      ),
    );
  }

  for (var i = prefixLen; i < oldLines.length - suffixLen; i++) {
    result.add(
      _DiffLineData(
        oldLineNumber: i + 1,
        newLineNumber: null,
        text: oldLines[i],
        type: _DiffLineType.removal,
      ),
    );
  }

  for (var i = prefixLen; i < newLines.length - suffixLen; i++) {
    result.add(
      _DiffLineData(
        oldLineNumber: null,
        newLineNumber: i + 1,
        text: newLines[i],
        type: _DiffLineType.addition,
      ),
    );
  }

  for (var i = 0; i < suffixLen; i++) {
    final oldIdx = oldLines.length - suffixLen + i;
    final newIdx = newLines.length - suffixLen + i;
    result.add(
      _DiffLineData(
        oldLineNumber: oldIdx + 1,
        newLineNumber: newIdx + 1,
        text: newLines[newIdx],
        type: _DiffLineType.context,
      ),
    );
  }

  return result;
}

class _DiffLine extends StatelessWidget {
  final _DiffLineData data;
  final void Function(LspDiagnostic)? onDiagnosticTap;

  const _DiffLine({required this.data, this.onDiagnosticTap});

  Color _severityColor(int severity, ThemeData theme) {
    switch (severity) {
      case 1:
        return theme.colorScheme.error;
      case 2:
        return theme.colorScheme.tertiary;
      case 3:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurface.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final prefix = switch (data.type) {
      _DiffLineType.addition => '+',
      _DiffLineType.removal => '-',
      _DiffLineType.context => ' ',
    };

    final lineColor = switch (data.type) {
      _DiffLineType.addition => const Color(0xFF22C55E),
      _DiffLineType.removal => const Color(0xFFEF4444),
      _DiffLineType.context => theme.colorScheme.onSurface.withValues(
        alpha: 0.4,
      ),
    };

    final lineNumber = data.newLineNumber ?? data.oldLineNumber;
    final diagnostics = data.diagnostics;
    final hasDiagnostics = diagnostics != null && diagnostics.isNotEmpty;

    final diagnosticBadges = hasDiagnostics
        ? diagnostics.map((d) {
            final color = _severityColor(d.severity, theme);
            final icon = d.severity == 1
                ? Icons.error
                : d.severity == 2
                ? Icons.warning
                : Icons.info;
            return GestureDetector(
              onTap: () => onDiagnosticTap?.call(d),
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Icon(icon, size: 10, color: color),
              ),
            );
          }).toList()
        : null;

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              data.type == _DiffLineType.context &&
                      data.oldLineNumber != data.newLineNumber
                  ? '${data.oldLineNumber}-${data.newLineNumber}'
                  : '$lineNumber',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: ChatoraiFontSizes.sm,
                color:
                    hasDiagnostics == true &&
                        diagnostics!.any((d) => d.severity == 1)
                    ? theme.colorScheme.error
                    : lineColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            prefix,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ChatoraiFontSizes.sm,
              color: lineColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SelectableText(
              data.text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: ChatoraiFontSizes.sm,
                color:
                    hasDiagnostics == true &&
                        diagnostics!.any((d) => d.severity == 1)
                    ? theme.colorScheme.error.withValues(alpha: 0.5)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (diagnosticBadges != null) ...[
            const SizedBox(width: 2),
            ...diagnosticBadges,
          ],
        ],
      ),
    );
  }
}

class ToolResultPartWidget extends ConsumerStatefulWidget {
  final ToolResultPart part;

  const ToolResultPartWidget({super.key, required this.part});

  @override
  ConsumerState<ToolResultPartWidget> createState() =>
      _ToolResultPartWidgetState();
}

class _ToolResultPartWidgetState extends ConsumerState<ToolResultPartWidget> {
  static const _noBodyTools = {'websearch', 'webfetch', 'read', 'glob', 'grep'};

  bool _isExpanded = false;
  bool _isCopied = false;
  final Map<int, List<LspDiagnostic>> _diagnosticsByLine = {};
  bool _isLoadingDiagnostics = false;

  @override
  void didUpdateWidget(covariant ToolResultPartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final input = widget.part.input ?? {};
    final filePath =
        input['filePath'] as String? ?? input['file_path'] as String?;
    final oldFilePath =
        oldWidget.part.input?['filePath'] as String? ??
        oldWidget.part.input?['file_path'] as String?;

    if (filePath != null &&
        filePath.isNotEmpty &&
        filePath != oldFilePath &&
        widget.part.toolName.toLowerCase() == 'edit' &&
        _isExpanded) {
      _fetchDiagnostics(filePath);
    }
  }

  Future<void> _fetchDiagnostics(String filePath) async {
    if (_isLoadingDiagnostics) return;
    setState(() => _isLoadingDiagnostics = true);

    try {
      final service = await ref.read(lspServiceProvider.future);
      final diagnostics = await service.diagnostics(filePath).toList();
      final byLine = <int, List<LspDiagnostic>>{};
      for (final diag in diagnostics) {
        final line = diag.range.start.line;
        byLine.putIfAbsent(line, () => []).add(diag);
      }

      if (mounted) {
        setState(() => _diagnosticsByLine.clear());
        _diagnosticsByLine.addAll(byLine);
      }
    } catch (e) {
      if (mounted) setState(() => _diagnosticsByLine.clear());
    } finally {
      if (mounted) setState(() => _isLoadingDiagnostics = false);
    }
  }

  void _showDiagnosticDetails(LspDiagnostic diag) {
    final theme = Theme.of(context);
    final severityColor = switch (diag.severity) {
      1 => theme.colorScheme.error,
      2 => theme.colorScheme.tertiary,
      3 => theme.colorScheme.primary,
      _ => theme.colorScheme.onSurface,
    };

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  diag.severity == 1
                      ? Icons.error
                      : diag.severity == 2
                      ? Icons.warning
                      : Icons.info,
                  color: severityColor,
                ),
                const SizedBox(width: 8),
                Text(
                  LspDiagnosticSeverity.label(diag.severity),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              diag.message,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            if (diag.source != null) ...[
              const SizedBox(height: 8),
              Text(
                'Source: ${diag.source}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Line ${diag.range.start.line + 1}:${diag.range.start.character + 1}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final part = widget.part;
    final isError = part.error != null;
    final isRunning = part.state == ToolState.running;
    final isCompleted = part.state == ToolState.completed;
    final isNoBodyTool = _noBodyTools.contains(part.toolName.toLowerCase());
    final canExpand = (isCompleted || isError) && !isRunning && !isNoBodyTool;

    return GestureDetector(
      onTap: canExpand
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.5,
              child: _buildHeader(
                theme,
                isError,
                isRunning,
                isCompleted,
                part,
                canExpand,
              ),
            ),
            if (!isNoBodyTool)
              part.toolName.toLowerCase() == 'bash'
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _buildBody(theme, isError, part),
                    )
                  : AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _buildBody(theme, isError, part),
                      ),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                      sizeCurve: Curves.easeInOut,
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    bool isError,
    bool isRunning,
    bool isCompleted,
    ToolResultPart part,
    bool canExpand,
  ) {
    // During execution we show only a spinner; after completion the icon replaces it.
    final spinner = SizedBox(
      width: 16,
      height: 16,
      child: SpinKitCircle(
        size: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );

    final icon = ToolIcon(
      toolName: part.toolName,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      size: 14,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRunning) spinner,
        if (isRunning) const SizedBox(width: 6),
        if (!isRunning) ...[icon, const SizedBox(width: 6)],
        Expanded(
          child: Text(
            toolTitle(part.toolName, part.input ?? {}),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: ChatoraiFontSizes.sm,
              height: 1.4,
            ),
          ),
        ),
        if (canExpand)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, bool isError, ToolResultPart part) {
    if (isError) {
      return _genericBody(theme, part.error!, isError: true);
    }

    // When expanded, show full output without truncation
    final displayFull = _isExpanded;

    return switch (part.toolName.toLowerCase()) {
      'bash' => _bashBody(theme, part, displayFull: displayFull),
      'read' => _readBody(theme, part, displayFull: displayFull),
      'grep' => _grepBody(theme, part, displayFull: displayFull),
      'webfetch' => _webfetchBody(theme, part, displayFull: displayFull),
      'edit' => _editBody(theme, part, displayFull: displayFull),
      'apply_patch' => _patchBody(theme, part, displayFull: displayFull),
      'write' => _writeBody(theme, part, displayFull: displayFull),
      'lsp' => _lspBody(theme, part, displayFull: displayFull),
      _ => _defaultBody(theme, part, displayFull: displayFull),
    };
  }

  Widget _defaultBody(
    ThemeData theme,
    ToolResultPart part, {
    required bool displayFull,
  }) {
    final original = part.result ?? '';
    final displayed = displayFull ? original : _truncateOutput(original);
    return _genericBody(theme, displayed, isError: false);
  }

  Widget _bashBody(
    ThemeData theme,
    ToolResultPart part, {
    required bool displayFull,
  }) {
    final input = part.input ?? {};
    final cmd = input['command'] as String? ?? '';
    final originalResult = part.result ?? '';
    final displayedResult = displayFull
        ? originalResult
        : _bashPreview(originalResult);
    final isError = part.error != null;
    final isDark = theme.brightness == Brightness.dark;
    final terminal = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    const pad = 12.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDark ? Colors.black26 : Colors.white38,
      padding: const EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cmd.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    r'$ ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: ChatoraiFontSizes.md,
                      fontWeight: FontWeight.w700,
                      color: isError ? theme.colorScheme.error : terminal,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      cmd,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: ChatoraiFontSizes.md,
                        fontWeight: FontWeight.w600,
                        color: terminal,
                      ),
                      softWrap: true,
                    ),
                  ),
                  if (isError)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.error_outline,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          if (originalResult.isNotEmpty)
            SingleChildScrollView(
              child: SelectableText(
                displayedResult,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.md,
                  color: isError
                      ? (isDark ? Colors.red[200] : Colors.red[700])
                      : terminal,
                ),
              ),
            ),
          if (originalResult.isNotEmpty)
            _buildResultFooter(theme, displayedResult, isError),
        ],
      ),
    );
  }

  Widget _readBody(
    ThemeData theme,
    ToolResultPart part, {
    required bool displayFull,
  }) {
    final input = part.input ?? {};
    final offset = input['offset'];
    final limit = input['limit'];
    final originalResult = part.result ?? '';
    final displayedResult = displayFull
        ? originalResult
        : _truncateOutput(originalResult);
    final isError = part.error != null;

    if (originalResult.isEmpty) return const SizedBox.shrink();

    String subtitle = '';
    if (offset != null || limit != null) {
      final parts = <String>[];
      if (offset != null) parts.add('offset=$offset');
      if (limit != null) parts.add('limit=$limit');
      subtitle = '[${parts.join(', ')}]';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: ChatoraiFontSizes.sm,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          if (originalResult.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SelectableText(
                displayedResult,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.sm,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          if (originalResult.isNotEmpty)
            _buildResultFooter(theme, displayedResult, isError),
        ],
      ),
    );
  }

  Widget _grepBody(
    ThemeData theme,
    ToolResultPart part, {
    required bool displayFull,
  }) {
    final originalResult = part.result ?? '';
    final displayedResult = displayFull
        ? originalResult
        : _truncateOutput(originalResult);
    final input = part.input ?? {};
    final pattern = input['pattern'] as String? ?? '';
    final isError = part.error != null;

    if (originalResult.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✱ $pattern',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ChatoraiFontSizes.sm,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: SelectableText(
              displayedResult,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: ChatoraiFontSizes.sm,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          _buildResultFooter(theme, displayedResult, isError),
        ],
      ),
    );
  }

  Widget _webfetchBody(
    ThemeData theme,
    ToolResultPart part, {
    required bool displayFull,
  }) {
    final original = part.result ?? '';
    final displayed = displayFull ? original : _truncateOutput(original);
    final isError = part.error != null;
    return _genericBody(theme, displayed, isError: isError);
  }

  Widget _editBody(
    ThemeData theme,
    ToolResultPart part, {
    required bool displayFull,
  }) {
    final input = part.input ?? {};
    final filePath =
        input['filePath'] as String? ?? input['file_path'] as String? ?? '';
    final oldStr = input['old_string'] as String? ?? '';
    final newStr = input['new_string'] as String? ?? '';
    final isError = part.error != null;
    final result = part.result ?? '';

    final additions = newStr.split('\n').length;
    final deletions = oldStr.split('\n').length;

    if (displayFull &&
        filePath.isNotEmpty &&
        _diagnosticsByLine.isEmpty &&
        !_isLoadingDiagnostics) {
      _fetchDiagnostics(filePath);
    }

    final diffLines = _computeDiff(oldStr, newStr).map((d) {
      final lineNumber = d.newLineNumber ?? d.oldLineNumber;
      final diags = lineNumber != null ? _diagnosticsByLine[lineNumber] : null;
      return _DiffLineData(
        oldLineNumber: d.oldLineNumber,
        newLineNumber: d.newLineNumber,
        text: d.text,
        type: d.type,
        diagnostics: diags,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                'Edit $filePath',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.sm,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (_isLoadingDiagnostics) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (!displayFull)
            Text(
              '+$additions -$deletions',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          if (displayFull && (oldStr.isNotEmpty || newStr.isNotEmpty)) ...[
            ...diffLines.map(
              (d) =>
                  _DiffLine(data: d, onDiagnosticTap: _showDiagnosticDetails),
            ),
          ],
          _buildResultFooter(theme, result, isError),
        ],
      ),
    );
  }

  Widget _patchBody(
    ThemeData theme,
    ToolResultPart part, {
    required bool displayFull,
  }) {
    final input = part.input ?? {};
    final filePath = input['file_path'] as String? ?? '';
    final patchStr = input['patch'] as String? ?? '';
    final isError = part.error != null;
    final result = part.result ?? '';

    final patchLines = patchStr.split('\n');
    final previewLines = displayFull
        ? patchLines
        : patchLines.take(40).toList();

    final diffLines = <_DiffLineData>[];
    for (final line in previewLines) {
      if (line.startsWith('+') && !line.startsWith('+++')) {
        diffLines.add(_DiffLineData(text: line, type: _DiffLineType.addition));
      } else if (line.startsWith('-') && !line.startsWith('---')) {
        diffLines.add(_DiffLineData(text: line, type: _DiffLineType.removal));
      } else {
        diffLines.add(_DiffLineData(text: line, type: _DiffLineType.context));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patch $filePath',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ChatoraiFontSizes.sm,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          if (diffLines.isNotEmpty) ...diffLines.map((d) => _DiffLine(data: d)),
          _buildResultFooter(theme, result, isError),
        ],
      ),
    );
  }

  Widget _writeBody(
    ThemeData theme,
    ToolResultPart part, {
    required bool displayFull,
  }) {
    final input = part.input ?? {};
    final filePath = input['file_path'] as String? ?? '';
    final content = input['content'] as String? ?? '';
    final isError = part.error != null;
    final result = part.result ?? '';

    final lines = content.split('\n');
    final previewLines = displayFull ? lines : lines.take(20).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write $filePath',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ChatoraiFontSizes.sm,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          if (previewLines.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                previewLines.join('\n'),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.xs,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                maxLines: displayFull ? null : 20,
              ),
            ),
          _buildResultFooter(theme, result, isError),
        ],
      ),
    );
  }

  Widget _genericBody(
    ThemeData theme,
    String displayedBody, {
    bool isError = false,
  }) {
    if (displayedBody.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: SelectableText(
            displayedBody,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ChatoraiFontSizes.sm,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        _buildResultFooter(theme, displayedBody, isError),
      ],
    );
  }

  String _truncateOutput(String text) {
    const int maxLines = 2000;
    const int maxChars = 51200;

    if (text.isEmpty) return text;

    final lines = text.split('\n');
    bool truncated = false;
    String result = text;

    if (lines.length > maxLines) {
      result = lines.take(maxLines).join('\n');
      truncated = true;
    }
    if (result.length > maxChars) {
      result = result.substring(0, maxChars);
      truncated = true;
    }

    if (truncated) {
      result += '\n[...truncated...]';
    }

    return result;
  }

  String _bashPreview(String text) {
    const maxLines = 10;
    const maxChars = 500;
    if (text.isEmpty) return text;
    final lines = text.split('\n');
    if (lines.length <= maxLines && text.length <= maxChars) return text;
    String truncated;
    if (lines.length > maxLines) {
      truncated = lines.take(maxLines).join('\n');
    } else {
      truncated = text;
    }
    if (truncated.length > maxChars) {
      truncated = truncated.substring(0, maxChars);
    }
    return '$truncated\n[...]';
  }

  Widget _buildResultFooter(
    ThemeData theme,
    String displayedBody,
    bool isError,
  ) {
    final original = widget.part.result ?? '';
    final wasTruncated = displayedBody != original;
    final lineCount = '\n'.allMatches(displayedBody).length + 1;
    final charCount = displayedBody.length;
    final subtitle =
        '$lineCount lines, $charCount chars${wasTruncated ? ' (truncated)' : ''}';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (_isCopied)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '✅',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'Copied',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: () => _copyToClipboard(original),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy,
                      size: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Copy',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Widget _lspBody(
    ThemeData theme,
    ToolResultPart part, {
    required bool displayFull,
  }) {
    final input = part.input ?? {};
    final filePath = input['filePath'] as String? ?? 'unknown';
    final result = part.result ?? '';
    String action = input['action'] as String? ?? 'diagnostics';
    int errorCount = 0;
    int warningCount = 0;

    try {
      final json = jsonDecode(result) as Map<String, dynamic>;
      action = json['action'] as String? ?? action;
      final summary = json['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        errorCount = summary['errors'] as int? ?? 0;
        warningCount = summary['warnings'] as int? ?? 0;
      }
    } catch (_) {}

    final hasDiagnostics = errorCount > 0 || warningCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              action == 'diagnostics'
                  ? (hasDiagnostics
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle)
                  : Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              action == 'diagnostics'
                  ? '$filePath — $errorCount errors, $warningCount warnings'
                  : '$action: $filePath',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        if (result.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              result,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              maxLines: displayFull ? null : 20,
              overflow: displayFull ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
