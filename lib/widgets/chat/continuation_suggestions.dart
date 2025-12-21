import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';

class ContinuationSuggestions extends StatefulWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;
  final VoidCallback? onClose;
  final bool isLoading;
  final BuildContext? context;

  const ContinuationSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    this.onClose,
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

    // Initialize pulse controllers
    for (int i = 0; i < widget.suggestions.length; i++) {
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
        if (widget.suggestions.isNotEmpty) {
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
      // Reinitialize controllers
      for (var c in _pulseControllers) {
        c.dispose();
      }
      _pulseControllers.clear();
      for (int i = 0; i < widget.suggestions.length; i++) {
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
    if (!mounted || widget.suggestions.isEmpty) return;
    _isCycleActive = true;
    _pulseNext(0);
  }

  void _pulseNext(int index) {
    if (!mounted || !_isCycleActive) return;

    if (index >= widget.suggestions.length) {
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
    
    return Column(
      children: widget.suggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final suggestion = entry.value;
        final isActive = index == _currentIndex;

        // Get animation for this suggestion
        Animation<double>? animation;
        if (index < _pulseControllers.length && isActive) {
          animation = Tween<double>(begin: 1.0, end: 0.97).animate(
            CurvedAnimation(
              parent: _pulseControllers[index],
              curve: Curves.easeInOut,
            ),
          );
        }

        return Container(
          margin: EdgeInsets.only(top: index == 0 ? 0 : 8.0),
          child: animation != null
              ? AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: animation!.value,
                      child: child,
                    );
                  },
                  child: _buildSuggestionItem(suggestion, isActive, theme),
                )
              : _buildSuggestionItem(suggestion, isActive, theme),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionItem(String suggestion, bool isActive, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _stopCycle();
          widget.onSuggestionTap(suggestion);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  suggestion,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_upward,
                size: 14,
                color: theme.colorScheme.primary.withValues(
                  alpha: isActive ? 1.0 : 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
