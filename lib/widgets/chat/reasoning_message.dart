import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';

class ReasoningMessage extends StatefulWidget {
  final String reasoning;
  final bool isStreaming;

  const ReasoningMessage({
    super.key,
    required this.reasoning,
    this.isStreaming = false,
  });

  @override
  State<ReasoningMessage> createState() => _ReasoningMessageState();
}

class _ReasoningMessageState extends State<ReasoningMessage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const _shimmerDuration = Duration(milliseconds: 1500);
  static const _chunkTimeout = Duration(milliseconds: 300);
  static const _bubbleWidthRatio = 0.65;
  static const _bubblePadding = 12.0;
  static const _textFontSize = 13.0;
  static const _headerFontSize = 12.0;

  bool _isExpanded = false;
  bool _isShimmering = false;
  Timer? _shimmerStopTimer;
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _initShimmer();
  }

  void _initShimmer() {
    _shimmerController = AnimationController(
      vsync: this,
      duration: _shimmerDuration,
    );
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    if (widget.isStreaming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startShimmer();
      });
    }
  }

  @override
  void didUpdateWidget(ReasoningMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only start shimmer if reasoning content changed
    if (widget.reasoning != oldWidget.reasoning) {
      _startShimmer();
    }

    // Only stop shimmer when streaming ends
    if (widget.isStreaming != oldWidget.isStreaming && !widget.isStreaming) {
      _stopShimmer();
    }
  }

  void _startShimmer() {
    _shimmerStopTimer?.cancel();

    if (!_isShimmering) {
      _isShimmering = true;
      _shimmerController.repeat();
    }

    _shimmerStopTimer = Timer(_chunkTimeout, () {
      if (mounted) _stopShimmer();
    });
  }

  void _stopShimmer() {
    _shimmerStopTimer?.cancel();
    _shimmerStopTimer = null;

    if (_isShimmering) {
      _isShimmering = false;
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerStopTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: _bubbleWidthRatio,
        child: Stack(
          children: [
            _buildContent(theme, localizations),
            if (_isShimmering) _buildShimmerOverlay(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(_bubblePadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: _isExpanded
          ? _buildExpandedContent(theme, localizations)
          : _buildCollapsedContent(theme, localizations),
    );
  }

  Widget _buildShimmerOverlay(ThemeData theme) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (_, __) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _buildShimmerGradient(theme),
              ),
            );
          },
        ),
      ),
    );
  }

  Gradient _buildShimmerGradient(ThemeData theme) {
    final shimmerPosition = _shimmerAnimation.value;
    
    return LinearGradient(
      begin: Alignment(-1.0 + shimmerPosition, 0),
      end: Alignment(shimmerPosition, 0),
      colors: [
        Colors.transparent,
        theme.colorScheme.secondary.withOpacity(0.1),
        theme.colorScheme.secondary.withOpacity(0.25),
        theme.colorScheme.secondary.withOpacity(0.4),
        theme.colorScheme.secondary.withOpacity(0.5),
        theme.colorScheme.secondary.withOpacity(0.4),
        theme.colorScheme.secondary.withOpacity(0.25),
        theme.colorScheme.secondary.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.1, 0.25, 0.4, 0.5, 0.6, 0.75, 0.9, 1.0],
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    AppLocalizations? localizations,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(localizations, theme),
          const SizedBox(height: 8),
          Text(
            widget.reasoning,
            style: const TextStyle(fontSize: _textFontSize, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedContent(
    ThemeData theme,
    AppLocalizations? localizations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(localizations, theme),
        const SizedBox(height: 8),
        if (widget.reasoning.isNotEmpty)
          Text(
            widget.reasoning,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: _textFontSize, height: 1.4),
          ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations? localizations, ThemeData theme) {
    final iconColor = theme.textTheme.bodyMedium?.color ?? Colors.grey.shade700;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.lightbulb_outline, size: 12, color: iconColor),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            localizations?.reasoning ?? 'Reasoning',
            style: const TextStyle(
              fontSize: _headerFontSize,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 16,
            color: iconColor,
          ),
        ),
      ],
    );
  }
}
