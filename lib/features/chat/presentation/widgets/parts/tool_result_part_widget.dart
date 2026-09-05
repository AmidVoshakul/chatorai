import 'package:chatorai/features/chat/presentation/widgets/chat_shimmer_text.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/session_db_provider.dart';
import 'package:chatorai/core/tools/lsp_diagnostics_format.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/edit_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/generic_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/grep_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/lsp_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/read_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/shell_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_icon.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_title.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/webfetch_body.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/write_body.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';
import 'package:chatorai/shared/utils/format_utils.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// ==================================================================
// ToolResultPartWidget — collapsible tool result widget
// ==================================================================

class ToolResultPartWidget extends ConsumerStatefulWidget {
  final ToolResultPart part;

  const ToolResultPartWidget({super.key, required this.part});

  @override
  ConsumerState<ToolResultPartWidget> createState() =>
      _ToolResultPartWidgetState();
}

// ==================================================================
// State
// ==================================================================

class _ToolResultPartWidgetState extends ConsumerState<ToolResultPartWidget> {
  static const _noBodyTools = {'websearch', 'webfetch', 'read', 'glob', 'grep'};

  static const _builtInCompoundNames = {
    'apply_patch',
    'document_extract',
    'external-directory',
    'json_schema',
    'plan_enter',
    'plan_exit',
  };

  // ================================================================
  // Fields
  // ================================================================

  bool _isExpanded = false;
  bool _isCopied = false;
  bool _isRestoring = false;
  final Map<int, List<LspDiagnostic>> _diagnosticsByLine = {};

  // ================================================================
  // Lifecycle
  // ================================================================

  @override
  void initState() {
    super.initState();
    final toolName = widget.part.toolName.toLowerCase();
    if (toolName == 'edit' ||
        toolName == 'apply_patch' ||
        toolName == 'write') {
      _isExpanded = true;
      _parseDiagnosticsFromResult();
    }
  }

  @override
  void didUpdateWidget(covariant ToolResultPartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final result = widget.part.result;
    final oldResult = oldWidget.part.result;
    if (result != null &&
        result != oldResult &&
        widget.part.toolName.toLowerCase() == 'edit' &&
        _isExpanded) {
      _parseDiagnosticsFromResult();
    }
  }

  // ================================================================
  // LSP Diagnostics — parse from tool output text
  // ================================================================

  void _parseDiagnosticsFromResult() {
    final result = widget.part.result;
    if (result == null || result.isEmpty) {
      setState(() => _diagnosticsByLine.clear());
      return;
    }
    final parsed = parseLspFromToolOutput(result);
    if (mounted) {
      setState(() {
        _diagnosticsByLine
          ..clear()
          ..addAll(parsed);
      });
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

  // ================================================================
  // Restore
  // ================================================================

  Future<void> _onRestore() async {
    final metadata = widget.part.metadata;
    final sessionId = metadata?['session_id'] as String?;
    if (sessionId == null || sessionId.isEmpty || !mounted) return;
    setState(() => _isRestoring = true);
    try {
      final service = await ref.read(fileSnapshotServiceProvider.future);
      await service.restoreByStep(sessionId, widget.part.toolCallId);
      if (mounted) {
        final loc = AppLocalizations.of(context);
        SnackbarUtils.showSuccessSnackBar(
          context: context,
          message:
              loc?.toolResultRestoredSnackbar ??
              'Files restored to before-edit state',
        );
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: loc?.restoreFailed(e.toString()) ?? 'Restore failed: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _showOriginal() async {
    final metadata = widget.part.metadata;
    final sessionId = metadata?['session_id'] as String?;
    if (sessionId == null || sessionId.isEmpty) return;
    try {
      final service = await ref.read(fileSnapshotServiceProvider.future);
      final snapshots = await service.listByStep(
        sessionId,
        widget.part.toolCallId,
      );
      if (snapshots.isEmpty || !mounted) return;
      _showSnapshotDialog(snapshots);
    } catch (_) {}
  }

  void _showSnapshotDialog(List<FileSnapshot> snapshots) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final hairline = isDark
        ? ChatoraiColors.darkInputBorder
        : ChatoraiColors.inputBorder;
    final codeFill = isDark
        ? ChatoraiColors.darkInputFill
        : ChatoraiColors.inputFill;
    final contentText = isDark
        ? ChatoraiColors.darkTextColor
        : ChatoraiColors.lightTextColor;
    final subtleText = isDark
        ? ChatoraiColors.darkSecondaryTextColor
        : ChatoraiColors.secondaryTextColor;

    showDialog(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ChatoraiSpacing.lg,
                    ChatoraiSpacing.lg,
                    ChatoraiSpacing.sm,
                    ChatoraiSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(
                            alpha: isDark ? 0.18 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(
                            ChatoraiBorderRadius.sm,
                          ),
                        ),
                        child: Icon(
                          Icons.history,
                          size: ChatoraiIconSizes.md,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: ChatoraiSpacing.sm),
                      Expanded(
                        child: Text(
                          loc!.toolResultOriginalTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: ChatoraiIconSizes.md,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        color: subtleText,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(ChatoraiSpacing.xs),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: hairline),
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      ChatoraiSpacing.lg,
                      ChatoraiSpacing.md,
                      ChatoraiSpacing.lg,
                      ChatoraiSpacing.lg,
                    ),
                    itemCount: snapshots.length,
                    itemBuilder: (_, i) {
                      final snap = snapshots[i];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: ChatoraiSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snap.filePath,
                              style: ChatoraiFontSizes.mono(
                                ChatoraiFontSizes.sm,
                                color: cs.muted,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: ChatoraiSpacing.sm),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(ChatoraiSpacing.md),
                              decoration: BoxDecoration(
                                color: codeFill,
                                borderRadius: BorderRadius.circular(
                                  ChatoraiBorderRadius.sm,
                                ),
                                border: Border.all(color: hairline, width: 1),
                              ),
                              child: SelectableText(
                                snap.content,
                                style: ChatoraiFontSizes.mono(
                                  ChatoraiFontSizes.sm,
                                  color: contentText,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // Build
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final part = widget.part;
    final isError = part.error != null;
    final isRunning = part.state == ToolState.running;
    final isCompleted = part.state == ToolState.completed;
    final isPending = part.state == ToolState.pending;
    final toolNameLower = part.toolName.toLowerCase();
    final isNoBodyTool =
        _noBodyTools.contains(toolNameLower) ||
        (toolNameLower.contains('_') &&
            !_builtInCompoundNames.contains(toolNameLower));
    final isShell = toolNameLower == 'shell';
    final canExpand = (isCompleted || isError) && !isRunning && !isNoBodyTool;

    if (isPending) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitCircle(size: 14, color: theme.colorScheme.muted),
            const SizedBox(width: 8),
            ToolIcon(
              toolName: part.toolName,
              color: theme.colorScheme.muted,
              size: 13,
            ),
            const SizedBox(width: 6),
            ChatShimmerText(
              text: 'Preparing ${part.toolName}...',
              textSize: ChatoraiFontSizes.sm,
              color: theme.colorScheme.muted,
            ),
          ],
        ),
      );
    }

    if (part.toolName.toLowerCase() == 'todowrite') {
      return _buildTodoBody(theme, part);
    }

    if (isShell && !isNoBodyTool) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: _buildShellContent(theme, isError, part, canExpand),
      );
    }

    final isNonCollapsible =
        toolNameLower == 'edit' ||
        toolNameLower == 'apply_patch' ||
        toolNameLower == 'write';

    if (isNonCollapsible) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: _buildBody(theme, isError, part),
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
            if (!isNoBodyTool && _isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildBody(theme, isError, part),
              ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // Header
  // ================================================================

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
      color: isError ? theme.colorScheme.error : theme.colorScheme.muted,
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
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.muted,
              fontSize: ChatoraiFontSizes.sm,
              height: 1.4,
            ),
          ),
        ),
        if (canExpand)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 14,
              color: theme.colorScheme.muted,
            ),
          ),
      ],
    );
  }

  // ================================================================
  // Shell content
  // ================================================================

  Widget _buildShellContent(
    ThemeData theme,
    bool isError,
    ToolResultPart part,
    bool canExpand,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDark ? Colors.black26 : Colors.white38,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _buildBody(theme, isError, part, canExpand),
      ),
    );
  }

  // ================================================================
  // Body router
  // ================================================================

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

    final displayFull = _isExpanded;

    return switch (part.toolName.toLowerCase()) {
      'shell' => ShellBody(
        theme: theme,
        part: part,
        displayFull: displayFull,
        isError: isError,
        standalone: false,
        onToggle: canExpand
            ? () => setState(() => _isExpanded = !_isExpanded)
            : null,
        previewOutput: shellPreview,
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
        isLoadingDiagnostics: false,
        diagnosticsByLine: _diagnosticsByLine,
        onDiagnosticTap: _showDiagnosticDetails,
        sessionId: part.metadata?['session_id'] as String?,
        onRestore: _isRestoring ? null : _onRestore,
        onShowOriginal: _showOriginal,
      ),
      'apply_patch' => EditBody(
        theme: theme,
        part: part,
        displayFull: displayFull,
        isError: isError,
        isLoadingDiagnostics: false,
        diagnosticsByLine: _diagnosticsByLine,
        onDiagnosticTap: _showDiagnosticDetails,
        sessionId: part.metadata?['session_id'] as String?,
        onRestore: _isRestoring ? null : _onRestore,
        onShowOriginal: _showOriginal,
      ),
      'write' => WriteBody(
        theme: theme,
        part: part,
        diagnosticsByLine: _diagnosticsByLine,
        onDiagnosticTap: _showDiagnosticDetails,
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

  // ================================================================
  // Todo body
  // ================================================================

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

  // ================================================================
  // Footer
  // ================================================================

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
