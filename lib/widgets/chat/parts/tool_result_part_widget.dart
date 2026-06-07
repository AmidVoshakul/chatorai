import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:chatorai/models/chat_message.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/widgets/chat/parts/_tool_icon.dart';
import 'package:chatorai/widgets/chat/parts/_tool_title.dart';

class ToolResultPartWidget extends StatefulWidget {
  final ToolResultPart part;

  const ToolResultPartWidget({super.key, required this.part});

  @override
  State<ToolResultPartWidget> createState() => _ToolResultPartWidgetState();
}

class _ToolResultPartWidgetState extends State<ToolResultPartWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final part = widget.part;
    final isError = part.error != null;
    final isRunning = part.state == ToolState.running;
    final isCompleted = part.state == ToolState.completed;
    final canExpand = (isCompleted || isError) && !isRunning;

    return GestureDetector(
      onTap: canExpand
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isError
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xs),
          border: Border.all(
            color: isError
                ? theme.colorScheme.error.withValues(alpha: 0.3)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
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
    return Row(
      children: [
        if (isRunning)
          SpinKitPulse(color: theme.colorScheme.primary, size: 14)
        else if (isCompleted)
          Icon(Icons.check, size: 14, color: theme.colorScheme.primary)
        else if (isError)
          Icon(Icons.close, size: 14, color: theme.colorScheme.error),
        const SizedBox(width: 6),
        ToolIcon(toolName: part.toolName),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            toolTitle(part.toolName, part.input ?? {}),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isError
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (canExpand)
          AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, bool isError, ToolResultPart part) {
    if (isError) {
      return _genericBody(theme, part.error!, isError: true);
    }

    return switch (part.toolName.toLowerCase()) {
      'bash' => _bashBody(theme, part),
      'read' => _readBody(theme, part),
      'grep' => _grepBody(theme, part),
      'webfetch' => _webfetchBody(theme, part),
      _ => _genericBody(theme, part.result ?? ''),
    };
  }

  Widget _bashBody(ThemeData theme, ToolResultPart part) {
    final input = part.input ?? {};
    final cmd = input['command'] as String? ?? '';
    final desc = input['description'] as String?;

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (desc != null && desc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Text(
                  '# $desc',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: ChatoraiFontSizes.sm,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (cmd.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                child: Text(
                  r'$ ' + cmd,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: ChatoraiFontSizes.sm,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            if (part.result != null && part.result!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: SelectableText(
                  part.result!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: ChatoraiFontSizes.sm,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _readBody(ThemeData theme, ToolResultPart part) {
    final input = part.input ?? {};
    final offset = input['offset'];
    final limit = input['limit'];
    final result = part.result ?? '';

    if (result.isEmpty) return const SizedBox.shrink();

    String subtitle = '';
    if (offset != null || limit != null) {
      final parts = <String>[];
      if (offset != null) parts.add('offset=$offset');
      if (limit != null) parts.add('limit=$limit');
      subtitle = '[${parts.join(', ')}]';
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: ChatoraiFontSizes.sm,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SelectableText(
                result,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.sm,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grepBody(ThemeData theme, ToolResultPart part) {
    final result = part.result ?? '';
    final input = part.input ?? {};
    final pattern = input['pattern'] as String? ?? '';

    if (result.isEmpty) return const SizedBox.shrink();

    final matchCount = '\n'.allMatches(result).length;

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(
                r'✱ ' +
                    pattern +
                    (matchCount > 0 ? ' ($matchCount matches)' : ''),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.sm,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SelectableText(
                result,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.sm,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _webfetchBody(ThemeData theme, ToolResultPart part) {
    return _genericBody(theme, part.result ?? '');
  }

  Widget _genericBody(ThemeData theme, String body, {bool isError = false}) {
    if (body.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isError
              ? theme.colorScheme.error.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          body,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: ChatoraiFontSizes.sm,
            color: isError
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
