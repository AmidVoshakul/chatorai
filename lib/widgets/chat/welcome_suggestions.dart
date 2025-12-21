import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';
import 'package:gen_ui_chat_ai/widgets/chat/welcome_questions_data.dart';

class WelcomeSuggestions extends StatefulWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;
  final VoidCallback? onClose;
  final BuildContext? context;

  const WelcomeSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    this.onClose,
    this.context,
  });

  @override
  State<WelcomeSuggestions> createState() => _WelcomeSuggestionsState();
}

class _WelcomeSuggestionsState extends State<WelcomeSuggestions>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rotationController;
  late Animation<double> _rotationFadeAnimation;
  late Animation<Offset> _rotationSlideAnimation;
  final List<AnimationController> _pulseControllers = [];
  int _currentIndex = 0;
  Timer? _cycleTimer;
  bool _isCycleActive = false;
  List<String> _currentSuggestions = [];

  @override
  void initState() {
    super.initState();

    _currentSuggestions = widget.suggestions;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Rotation animation for smooth question transitions
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0, // Start fully visible
    );

    _rotationFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize pulse controllers
    for (int i = 0; i < _currentSuggestions.length; i++) {
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
        if (_currentSuggestions.isNotEmpty) {
          _startCycle();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    for (var c in _pulseControllers) {
      c.dispose();
    }
    _cycleTimer?.cancel();
    super.dispose();
  }

  void _startCycle() {
    if (!mounted || _currentSuggestions.isEmpty) return;
    _isCycleActive = true;
    _pulseNext(0);
  }

  void _pulseNext(int index) {
    if (!mounted || !_isCycleActive) return;

    if (index >= _currentSuggestions.length) {
      // All questions pulsed, wait 6 seconds then rotate to new questions
      _cycleTimer = Timer(const Duration(seconds: 6), () {
        if (!mounted || !_isCycleActive) return;
        _rotateQuestions();
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

  void _rotateQuestions() {
    // Fade out current questions
    _rotationController.reverse().then((_) {
      if (!mounted) return;

      // Generate new questions
      final newQuestions = WelcomeQuestionsData.getRandomQuestions(
        context,
        count: 4,
      );

      // Dispose old controllers
      for (var c in _pulseControllers) {
        c.dispose();
      }
      _pulseControllers.clear();

      // Update state
      setState(() {
        _currentSuggestions = newQuestions;
        _currentIndex = 0;
      });

      // Create new controllers
      for (int i = 0; i < _currentSuggestions.length; i++) {
        _pulseControllers.add(
          AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }

      // Fade in new questions
      _rotationController.forward();

      // Restart cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isCycleActive) return;
        _pulseNext(0);
      });
    });
  }

  void _stopCycle() {
    _isCycleActive = false;
    _cycleTimer?.cancel();
    _cycleTimer = null;
    
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
    final l10n = AppLocalizations.of(context);

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
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                padding: const EdgeInsets.all(20),
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Welcome icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.waving_hand,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Welcome text
                    Text(
                      l10n?.welcomeMessage ?? 'Welcome! How can I help you today?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        height: 1.3,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Suggestions list
                    _buildSuggestions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    final theme = Theme.of(context);
    
    return FadeTransition(
      opacity: _rotationFadeAnimation,
      child: SlideTransition(
        position: _rotationSlideAnimation,
        child: Column(
          children: _currentSuggestions.asMap().entries.map((entry) {
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
        ),
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            suggestion,
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
              height: 1.4,
            ),
            // Allow long questions to wrap naturally without truncation
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}
