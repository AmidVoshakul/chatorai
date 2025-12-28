import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';

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

class _ContinuationSuggestionsState extends State<ContinuationSuggestions>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final List<AnimationController> _pulseControllers = [];
  int _currentIndex = 0;
  Timer? _cycleTimer;
  bool _isCycleActive = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Limit to 4 suggestions
    final limitedSuggestions = widget.suggestions.take(4).toList();

    // Initialize pulse controllers
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
      // Limit to 4 suggestions
      final limitedSuggestions = widget.suggestions.take(4).toList();
      
      // Reinitialize controllers
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

    // Update current index
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animationController,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.continueConversation,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      // Refresh button
                      if (widget.onRefresh != null)
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            size: 16,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          onPressed: () {
                            _stopCycle();
                            widget.onRefresh!();
                          },
                          tooltip: 'Refresh questions',
                          splashRadius: 16,
                        ),
                      // Close button
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        ),
                        onPressed: widget.onClose,
                        tooltip: l10n.close,
                        splashRadius: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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

  Widget _buildLoading() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          l10n.generatingSuggestions,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
      children: limitedSuggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final suggestion = entry.value;
        final isActive = index == _currentIndex;

        return Container(
          margin: EdgeInsets.only(top: index == 0 ? 0 : 8.0),
          child: _buildSuggestionItem(suggestion, isActive, theme),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionItem(String suggestion, bool isActive, ThemeData theme) {
    // Get animation for this suggestion
    Animation<double>? animation;
    final limitedSuggestions = widget.suggestions.take(4).toList();
    if (isActive && _currentIndex < _pulseControllers.length && _currentIndex < limitedSuggestions.length) {
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
        borderRadius: BorderRadius.circular(12),
        child: animation != null
            ? AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  // Use scale directly for perfectly synchronized transition
                  final scale = animation!.value;
                  final progress = 1.0 - scale; // 0.0 to 0.04
                  
                  // Smooth color transition - perfectly synced with scale
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
                  
                  // Smooth shadow - synced with scale
                  final shadowOpacity = progress * 0.25;
                  
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: bgColor,
                        boxShadow: [
                          if (shadowOpacity > 0.001)
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: shadowOpacity),
                              blurRadius: 6 + progress * 6,
                              offset: Offset(0, 1 + progress * 2),
                            ),
                        ],
                      ),
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  );
                },
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.brightness == Brightness.dark
                      ? theme.cardColor.withValues(alpha: 0.8)
                      : theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                ),
                child: Text(
                  suggestion,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
      ),
    );
  }
}
