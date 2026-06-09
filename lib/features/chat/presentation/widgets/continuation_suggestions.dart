import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

// ===========================================================================
// WIDGET CLASS
// ===========================================================================

class ContinuationSuggestions extends StatefulWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;
  final VoidCallback? onClose;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final BuildContext? context;

  const ContinuationSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    this.onClose,
    this.onRefresh,
    this.isLoading = false,
    this.context,
  });

  @override
  State<ContinuationSuggestions> createState() =>
      _ContinuationSuggestionsState();
}

// ===========================================================================
// STATE CLASS
// ===========================================================================

class _ContinuationSuggestionsState extends State<ContinuationSuggestions>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final List<AnimationController> _pulseControllers = [];
  int _currentIndex = 0;
  Timer? _cycleTimer;
  bool _isCycleActive = false;

  // =======================================================================
  // LIFECYCLE
  // =======================================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: ChatoraiDurations.normal,
    );

    final limitedSuggestions = widget.suggestions.take(4).toList();

    for (int i = 0; i < limitedSuggestions.length; i++) {
      _pulseControllers.add(
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _animationController.forward().then((_) {
        if (limitedSuggestions.isNotEmpty) {
          _startCycle();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var c in _pulseControllers) {
      c.dispose();
    }
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(ContinuationSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suggestions != oldWidget.suggestions) {
      _stopCycle();
      final limitedSuggestions = widget.suggestions.take(4).toList();

      for (var c in _pulseControllers) {
        c.dispose();
      }
      _pulseControllers.clear();
      for (int i = 0; i < limitedSuggestions.length; i++) {
        _pulseControllers.add(
          AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startCycle();
      });
    }
  }

  // =======================================================================
  // PUBLIC API
  // =======================================================================

  // =======================================================================
  // PRIVATE METHODS
  // =======================================================================

  void _startCycle() {
    final limitedSuggestions = widget.suggestions.take(4).toList();
    if (!mounted || limitedSuggestions.isEmpty) return;
    _isCycleActive = true;
    _pulseNext(0);
  }

  void _pulseNext(int index) {
    if (!mounted || !_isCycleActive) return;

    final limitedSuggestions = widget.suggestions.take(4).toList();
    if (index >= limitedSuggestions.length) {
      _cycleTimer = Timer(const Duration(seconds: 12), () {
        if (!mounted || !_isCycleActive) return;
        _pulseNext(0);
      });
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    final controller = _pulseControllers[index];

    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        controller.removeStatusListener(listener);
        _cycleTimer = Timer(const Duration(milliseconds: 600), () {
          if (!mounted || !_isCycleActive) return;
          _pulseNext(index + 1);
        });
      }
    }

    controller.addStatusListener(listener);
    controller.forward();
  }

  void _stopCycle() {
    _isCycleActive = false;
    _cycleTimer?.cancel();
    for (var c in _pulseControllers) {
      c.stop();
      c.reset();
    }
    setState(() {
      _currentIndex = 0;
    });
  }

  // =======================================================================
  // BUILD METHOD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animationController,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  ),
                ),
            child: Container(
              margin: const EdgeInsets.symmetric(
                vertical: ChatoraiSpacing.sm,
                horizontal: ChatoraiSpacing.md,
              ),
              padding: const EdgeInsets.all(ChatoraiSpacing.lg),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: ChatoraiColors.black15,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ChatoraiSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(
                            ChatoraiBorderRadius.sm,
                          ),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          size: ChatoraiIconSizes.md,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: ChatoraiSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.continueConversation,
                          style: TextStyle(
                            fontSize: ChatoraiFontSizes.base,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (widget.onRefresh != null)
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            size: ChatoraiIconSizes.md,
                            color: theme.colorScheme.primary.withValues(
                              alpha: ChatoraiIconOpacity.medium,
                            ),
                          ),
                          onPressed: () {
                            _stopCycle();
                            widget.onRefresh!();
                          },
                          tooltip: l10n.refreshQuestions,
                          splashRadius: ChatoraiSizes.iconButtonSplashRadius,
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: ChatoraiIconSizes.md,
                          color: theme.colorScheme.primary.withValues(
                            alpha: ChatoraiIconOpacity.medium,
                          ),
                        ),
                        onPressed: widget.onClose,
                        tooltip: l10n.close,
                        splashRadius: ChatoraiSizes.iconButtonSplashRadius,
                      ),
                    ],
                  ),
                  const SizedBox(height: ChatoraiSpacing.md),
                  if (widget.isLoading)
                    _buildLoading()
                  else if (widget.suggestions.isNotEmpty)
                    _buildSuggestions()
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =======================================================================
  // HELPER WIDGETS
  // =======================================================================

  Widget _buildLoading() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: ChatoraiBorderWidth.thinBold,
          ),
        ),
        const SizedBox(width: ChatoraiSpacing.sm),
        Text(
          l10n.generatingSuggestions,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.sm,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(
              alpha: ChatoraiIconOpacity.medium,
            ),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    final theme = Theme.of(context);
    final limitedSuggestions = widget.suggestions.take(4).toList();

    return Column(
      children: limitedSuggestions.asMap().entries.map<Widget>((entry) {
        final index = entry.key;
        final suggestion = entry.value;
        final isActive = index == _currentIndex;

        return Container(
          margin: EdgeInsets.only(top: index == 0 ? 0 : ChatoraiSpacing.sm),
          child: _buildSuggestionItem(suggestion, isActive, theme),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionItem(
    String suggestion,
    bool isActive,
    ThemeData theme,
  ) {
    Animation<double>? animation;
    final limitedSuggestions = widget.suggestions.take(4).toList();
    if (isActive &&
        _currentIndex < _pulseControllers.length &&
        _currentIndex < limitedSuggestions.length) {
      animation = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(
          parent: _pulseControllers[_currentIndex],
          curve: Curves.easeInOutCubic,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _stopCycle();
          widget.onSuggestionTap(suggestion);
        },
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        child: animation != null
            ? AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final scale = animation!.value;
                  final progress = 1.0 - scale;

                  final bgColor = theme.brightness == Brightness.dark
                      ? Color.lerp(
                          theme.cardColor,
                          Colors.white,
                          progress * 3.5,
                        )!.withValues(alpha: 0.8)
                      : Color.lerp(
                          theme.scaffoldBackgroundColor,
                          Colors.black,
                          progress * 2.5,
                        )!.withValues(alpha: 0.95);

                  final shadowOpacity = progress * 0.25;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ChatoraiSpacing.md,
                        vertical: ChatoraiSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          ChatoraiBorderRadius.md,
                        ),
                        color: bgColor,
                        boxShadow: [
                          if (shadowOpacity > 0.001)
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: shadowOpacity,
                              ),
                              blurRadius: 6 + progress * 6,
                              offset: Offset(0, 1 + progress * 2),
                            ),
                        ],
                      ),
                      child: MarkdownBody(
                        data: suggestion,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme)
                            .copyWith(
                              p: const TextStyle(
                                fontSize: ChatoraiFontSizes.sm,
                                height: 1.4,
                              ),
                            ),
                      ),
                    ),
                  );
                },
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatoraiSpacing.md,
                  vertical: ChatoraiSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
                  color: theme.brightness == Brightness.dark
                      ? theme.cardColor.withValues(alpha: 0.8)
                      : theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                ),
                child: MarkdownBody(
                  data: suggestion,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: const TextStyle(
                      fontSize: ChatoraiFontSizes.sm,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
