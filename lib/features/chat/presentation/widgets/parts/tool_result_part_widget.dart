import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/_tool_icon.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/_tool_title.dart';

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
    final toolColor = isError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRunning)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(toolColor),
            ),
          ),
        if (isRunning) const SizedBox(width: 4),
        ToolIcon(toolName: part.toolName, color: toolColor, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            toolTitle(part.toolName, part.input ?? {}),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: toolColor,
              fontSize: ChatoraiFontSizes.sm,
              height: 1.4,
            ),
          ),
        ),
        if (part.duration != null && isCompleted)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${part.duration!.inMilliseconds}ms',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: toolColor.withValues(alpha: 0.5),
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
                color: toolColor.withValues(alpha: 0.5),
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
    final result = part.result ?? '';

    final truncatedResult = _truncateOutput(
      result,
      _maxShellLines,
      _maxShellChars,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (desc != null && desc.isNotEmpty)
            Text(
              '# $desc',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: ChatoraiFontSizes.sm,
                color: theme.colorScheme.onSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (cmd.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
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
          if (truncatedResult.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: SelectableText(
                truncatedResult,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.sm,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
        ],
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
                color: theme.colorScheme.onSurface,
              ),
            ),
          if (result.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
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
    );
  }

  Widget _grepBody(ThemeData theme, ToolResultPart part) {
    final result = part.result ?? '';
    final input = part.input ?? {};
    final pattern = input['pattern'] as String? ?? '';

    if (result.isEmpty) return const SizedBox.shrink();

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
              color: theme.colorScheme.onSurface,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
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
    );
  }

  Widget _webfetchBody(ThemeData theme, ToolResultPart part) {
    return _genericBody(theme, part.result ?? '');
  }

  static const int _maxGenericLines = 3;
  static const int _maxShellLines = 10;
  static const int _maxGenericChars = 2000;
  static const int _maxShellChars = 10000;

  Widget _genericBody(
    ThemeData theme,
    String body, {
    bool isError = false,
    bool isShell = false,
  }) {
    if (body.isEmpty) return const SizedBox.shrink();

    final maxLines = isShell ? _maxShellLines : _maxGenericLines;
    final maxChars = isShell ? _maxShellChars : _maxGenericChars;
    final truncated = _truncateOutput(body, maxLines, maxChars);
    final wasTruncated = truncated != body;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: SelectableText(
            truncated,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ChatoraiFontSizes.sm,
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (wasTruncated || true)
          _buildResultFooter(theme, body, wasTruncated, isError),
      ],
    );
  }

  Widget _buildResultFooter(
    ThemeData theme,
    String fullBody,
    bool wasTruncated,
    bool isError,
  ) {
    final lineCount = '\n'.allMatches(fullBody).length + 1;
    final charCount = fullBody.length;
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
          InkWell(
            onTap: () => _copyToClipboard(fullBody),
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
  }

  String _truncateOutput(String output, int maxLines, int maxChars) {
    var result = output;
    final lines = result.split('\n');
    if (lines.length > maxLines) {
      result = lines.take(maxLines).join('\n');
    }
    if (result.length > maxChars) {
      result = result.substring(0, maxChars - 1);
    }
    if (result != output) {
      result = '$result…';
    }
    return result;
  }
}
