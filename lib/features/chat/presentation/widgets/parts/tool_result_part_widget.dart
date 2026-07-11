import 'package:chatorai/core/lsp/lsp_provider.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/bash_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/edit_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/generic_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/grep_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/lsp_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/patch_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/read_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_icon.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_title.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/webfetch_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/write_body.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';
import 'package:chatorai/shared/utils/format_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ToolResultPartWidget extends ConsumerStatefulWidget {
  final ToolResultPart part;

  const ToolResultPartWidget({super.key, required this.part});

  @override
  ConsumerState<ToolResultPartWidget> createState() =>
      _ToolResultPartWidgetState();
}

class _ToolResultPartWidgetState extends ConsumerState<ToolResultPartWidget> {
  static const _noBodyTools = {'websearch', 'webfetch', 'read', 'glob', 'grep'};

  /// Built-in tools with underscores/dashes that are NOT MCP.
  static const _builtInCompoundNames = {
    'apply_patch',
    'external-directory',
    'json_schema',
    'plan_enter',
    'plan_exit',
  };

  bool _isExpanded = false;
  bool _isCopied = false;
  final Map<int, List<LspDiagnostic>> _diagnosticsByLine = {};
  bool _isLoadingDiagnostics = false;

  @override
  void didUpdateWidget(covariant ToolResultPartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final input = widget.part.input ?? {};
    final filePath =
        (input['filePath'] as String?) ?? (input['file_path'] as String?);
    final oldFilePath =
        (oldWidget.part.input?['filePath'] as String?) ??
        (oldWidget.part.input?['file_path'] as String?);

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
            Text(diag.message, style: ChatoraiFontSizes.mono(13)),
            if (diag.source != null) ...[
              const SizedBox(height: 8),
              Text(
                'Source: ${diag.source}',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.muted),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Line ${diag.range.start.line + 1}:${diag.range.start.character + 1}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.muted),
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
    final toolNameLower = part.toolName.toLowerCase();
    final isNoBodyTool =
        _noBodyTools.contains(toolNameLower) ||
        (toolNameLower.contains('_') &&
            !_builtInCompoundNames.contains(toolNameLower));
    final isBash = toolNameLower == 'bash';
    final canExpand = (isCompleted || isError) && !isRunning && !isNoBodyTool;

    if (part.toolName.toLowerCase() == 'todowrite') {
      return _buildTodoBody(theme, part);
    }

    if (isBash && !isNoBodyTool) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: _buildBashContent(theme, isError, isRunning, part, canExpand),
      );
    }

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
            _buildHeader(
              theme,
              isError,
              isRunning,
              isCompleted,
              part,
              canExpand,
            ),
            if (!isNoBodyTool)
              AnimatedCrossFade(
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
      width: 15,
      height: 15,
      child: SpinKitCircle(size: 15, color: theme.colorScheme.muted),
    );

    final icon = ToolIcon(
      toolName: part.toolName,
      color: theme.colorScheme.muted,
      size: 13,
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
              color: theme.colorScheme.muted,
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
                color: theme.colorScheme.muted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBashContent(
    ThemeData theme,
    bool isError,
    bool isRunning,
    ToolResultPart part,
    bool canExpand,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDark ? Colors.black26 : Colors.white38,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _buildHeader(theme, isError, isRunning, false, part, false),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: _buildBody(theme, isError, part, canExpand),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    bool isError,
    ToolResultPart part, [
    bool canExpand = false,
  ]) {
    if (isError) {
      return GenericBody(
        theme: theme,
        displayedBody: part.error!,
        isError: true,
        buildResultFooter: (String displayedBody, bool error) =>
            _buildResultFooter(theme, displayedBody, error),
      );
    }

    // When expanded, show full output without truncation
    final displayFull = _isExpanded;
    final input = part.input ?? {};
    final filePath =
        (input['filePath'] as String?) ?? (input['file_path'] as String?);

    return switch (part.toolName.toLowerCase()) {
      'bash' => BashBody(
        theme: theme,
        part: part,
        displayFull: displayFull,
        isError: isError,
        standalone: false,
        onToggle: canExpand
            ? () => setState(() => _isExpanded = !_isExpanded)
            : null,
        previewOutput: bashPreview,
      ),
      'read' => ReadBody(
        theme: theme,
        part: part,
        displayFull: displayFull,
        isError: isError,
        previewOutput: truncateOutput,
        buildResultFooter: (String displayedBody, bool error) =>
            _buildResultFooter(theme, displayedBody, error),
      ),
      'grep' => GrepBody(
        theme: theme,
        part: part,
        displayFull: displayFull,
        isError: isError,
        previewOutput: truncateOutput,
        buildResultFooter: (String displayedBody, bool error) =>
            _buildResultFooter(theme, displayedBody, error),
      ),
      'webfetch' => WebfetchBody(
        theme: theme,
        part: part,
        displayFull: displayFull,
        isError: isError,
        previewOutput: truncateOutput,
        buildResultFooter: (String displayedBody, bool error) =>
            _buildResultFooter(theme, displayedBody, error),
      ),
      'edit' => EditBody(
        theme: theme,
        part: part,
        displayFull: displayFull,
        isError: isError,
        isLoadingDiagnostics: _isLoadingDiagnostics,
        diagnosticsByLine: _diagnosticsByLine,
        onFetchDiagnostics:
            (displayFull &&
                filePath != null &&
                filePath.isNotEmpty &&
                _diagnosticsByLine.isEmpty &&
                !_isLoadingDiagnostics)
            ? () => _fetchDiagnostics(filePath)
            : null,
        onDiagnosticTap: _showDiagnosticDetails,
        previewOutput: truncateOutput,
        buildResultFooter: (String displayedBody, bool error) =>
            _buildResultFooter(theme, displayedBody, error),
      ),
      'apply_patch' => PatchBody(
        theme: theme,
        part: part,
        displayFull: displayFull,
        isError: isError,
        buildResultFooter: (String displayedBody, bool error) =>
            _buildResultFooter(theme, displayedBody, error),
      ),
      'write' => WriteBody(
        theme: theme,
        part: part,
        displayFull: displayFull,
        isError: isError,
        buildResultFooter: (String displayedBody, bool error) =>
            _buildResultFooter(theme, displayedBody, error),
      ),
      'lsp' => LspBody(theme: theme, part: part, displayFull: displayFull),
      _ => GenericBody(
        theme: theme,
        displayedBody: part.result ?? '',
        isError: isError,
        buildResultFooter: (String displayedBody, bool error) =>
            _buildResultFooter(theme, displayedBody, error),
      ),
    };
  }

  Widget _buildTodoBody(ThemeData theme, ToolResultPart part) {
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white60 : Colors.black54;
    final accentColor = theme.colorScheme.primary.withValues(alpha: 0.6);
    final text = part.result ?? '';

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    List<Widget> items = [];
    for (final line in lines) {
      final parsed = _parseTodoLine(line);
      if (parsed == null) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              line,
              style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
          ),
        );
        continue;
      }

      final (status, _, description) = parsed;
      final isCompleted = status == 'completed' || status == 'cancelled';
      final isInProgress = status == 'in_progress';

      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Transform.translate(
                offset: const Offset(0, 2),
                child: isCompleted
                    ? Text(
                        '✓',
                        style: TextStyle(fontSize: 18, color: accentColor),
                      )
                    : isInProgress
                    ? Text(
                        '●',
                        style: TextStyle(fontSize: 18, color: accentColor),
                      )
                    : Text(
                        '○',
                        style: TextStyle(fontSize: 18, color: mutedColor),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(ChatoraiSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white38,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '# Todos',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.white24 : Colors.black26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  (String, String, String)? _parseTodoLine(String line) {
    final regex = RegExp(r'^\[(\w+)\]\s+(\w+)\s+(.+)$');
    final match = regex.firstMatch(line.trim());
    if (match == null) return null;
    return (match.group(1)!, match.group(2)!, match.group(3)!);
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
            style: TextStyle(fontSize: 10, color: theme.colorScheme.muted),
          ),
          if (_isCopied)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '✅',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.muted,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'Copied',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.muted,
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
                    Icon(Icons.copy, size: 12, color: theme.colorScheme.muted),
                    const SizedBox(width: 2),
                    Text(
                      'Copy',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.muted,
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

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      if (kDebugMode) debugPrint('[ToolResultPart] copy failed: $e');
    }
    if (!mounted) return;
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }
}
