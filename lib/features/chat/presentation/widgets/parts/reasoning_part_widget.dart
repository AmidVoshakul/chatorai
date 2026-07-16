import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_shimmer_text.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/markdown_styles.dart';
import 'package:chatorai/shared/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ReasoningPartWidget extends StatefulWidget {
  final ReasoningPart part;
  final String? partKey;
  final bool expandByDefault;

  const ReasoningPartWidget({
    super.key,
    required this.part,
    this.partKey,
    this.expandByDefault = true,
  });

  @override
  State<ReasoningPartWidget> createState() => _ReasoningPartWidgetState();
}

class _ReasoningPartWidgetState extends State<ReasoningPartWidget> {
  late bool _isExpanded;

  Duration? _thoughtDuration;

  String? _lastContent;
  Widget? _cachedContent;
  String? _lastThemeKey;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expandByDefault;
  }

  @override
  void didUpdateWidget(ReasoningPartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.part.isStreaming &&
        oldWidget.part.isStreaming &&
        widget.part.startedAt != null &&
        _thoughtDuration == null) {
      _thoughtDuration = DateTime.now().difference(widget.part.startedAt!);
    }

    if (oldWidget.expandByDefault != widget.expandByDefault) {
      setState(() => _isExpanded = widget.expandByDefault);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Markdown styling is derived from the theme; invalidate the memoized
    // content when the brightness changes so it re-parses with fresh styles.
    final themeKey = Theme.of(context).brightness.toString();
    if (_lastThemeKey != themeKey) {
      _lastThemeKey = themeKey;
      _cachedContent = null;
      _lastContent = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    final isStreaming = widget.part.isStreaming;
    final card = isStreaming
        ? Container(
            padding: const EdgeInsets.all(ChatoraiSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
            ),
            child: _cardContent(theme, localizations),
          )
        : AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(ChatoraiSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
            ),
            child: _cardContent(theme, localizations),
          );
    return Align(alignment: Alignment.centerLeft, child: card);
  }

  Widget _cardContent(ThemeData theme, AppLocalizations? localizations) {
    return Opacity(
      opacity: ChatoraiOpacity.low,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(localizations, theme),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: ChatoraiSpacing.sm),
              child: _buildContent(),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Memoize the parsed markdown so unrelated rebuilds (scroll, theme,
    // parent state changes) don't re-parse the full reasoning text. Only a
    // content change rebuilds it.
    if (_lastContent == widget.part.content && _cachedContent != null) {
      return _cachedContent!;
    }
    final theme = Theme.of(context);
    final content = DefaultTextStyle(
      style: theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
      child: MarkdownBody(
        data: widget.part.content,
        styleSheet: ChatoraiMarkdownStyles.getMarkdownStyles(context),
        selectable: true,
      ),
    );
    _lastContent = widget.part.content;
    _cachedContent = content;
    return content;
  }

  String? get _displayDuration {
    if (widget.part.durationMs != null) {
      return formatDurationMs(widget.part.durationMs!);
    }
    if (_thoughtDuration != null) return formatDuration(_thoughtDuration!);
    return null;
  }

  Widget _buildHeader(AppLocalizations? localizations, ThemeData theme) {
    final isStreaming = widget.part.isStreaming;
    final orange = theme.colorScheme.primary;

    if (isStreaming) {
      return GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            SpinKitCircle(color: orange, size: 16),
            const SizedBox(width: 8),
            ChatShimmerText(
              text: 'Thinking',
              color: orange,
              textSize: ChatoraiFontSizes.sm,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      );
    }

    final durationStr = _displayDuration;
    final thoughtLabel = durationStr != null
        ? 'Thought: $durationStr'
        : 'Thought:';

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          AnimatedRotation(
            turns: _isExpanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.chevron_right, size: 14, color: orange),
          ),
          const SizedBox(width: 8),
          Text(
            thoughtLabel,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.sm,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: orange,
            ),
          ),
        ],
      ),
    );
  }
}
