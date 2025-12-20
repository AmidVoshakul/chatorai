import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';
import 'package:gen_ui_chat_ai/widgets/chat/welcome_questions_data.dart';

/// Widget that displays welcome suggestions when chat is empty
/// 
/// This widget appears as a message-like element in the chat stream,
/// positioned at the start of a new chat. It has a "floating" appearance
/// with subtle glass-morphism effect and sequential pulse animations.
class WelcomeSuggestions extends StatefulWidget {
  /// List of suggestion strings to display
  final List<String> suggestions;
  
  /// Callback when a suggestion is tapped
  final Function(String) onSuggestionTap;
  
  /// Callback when the widget is closed
  final VoidCallback? onClose;
  
  /// Optional context for showing snackbars
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

class _WelcomeSuggestionsState extends State<WelcomeSuggestions> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<AnimationController> _suggestionPulseControllers = [];
  List<Animation<double>> _suggestionPulseAnimations = [];
  
  // Auto-rotation variables
  Timer? _rotationTimer;
  List<String> _currentSuggestions = [];
  
  // Question transition animation
  late AnimationController _questionsTransitionController;
  late Animation<double> _questionsFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize with first set of suggestions
    _currentSuggestions = widget.suggestions;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Questions transition animation (for smooth rotation)
    _questionsTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Start fully visible
    );
    
    _questionsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionsTransitionController,
      curve: Curves.easeInOut,
    ));
    
    // Create individual pulse controllers for each suggestion
    _suggestionPulseControllers = [];
    _suggestionPulseAnimations = [];
    
    // Start animations with delay for better UX
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _animationController.forward();
          
          // Start individual pulse animations after main animation
          Future.delayed(const Duration(milliseconds: 200), () {
            _startSequentialPulseAnimations();
          });
        });
      }
    });
    
    // Start auto-rotation timer
    _startAutoRotation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _questionsTransitionController.dispose();
    // Dispose all suggestion pulse controllers
    for (var controller in _suggestionPulseControllers) {
      controller.dispose();
    }
    // Cancel rotation timer
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startAutoRotation() {
    // Cancel any existing timer
    _rotationTimer?.cancel();
    
    // Start new timer for 10 seconds
    _rotationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _rotateQuestions();
      }
    });
  }

  void _rotateQuestions() {
    // Fade out current questions
    _questionsTransitionController.reverse().then((_) {
      if (!mounted) return;
      
      // Generate new questions (different from current)
      final newQuestions = WelcomeQuestionsData.getRandomQuestions(
        context,
        count: 4,
      );
      
      // Update state
      setState(() {
        _currentSuggestions = newQuestions;
      });
      
      // Fade in new questions
      _questionsTransitionController.forward();
      
      // Restart pulse animations for new questions
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _startSequentialPulseAnimations();
        }
      });
    });
  }

  void _startSequentialPulseAnimations() {
    // Clear previous controllers if any
    for (var controller in _suggestionPulseControllers) {
      controller.dispose();
    }
    _suggestionPulseControllers.clear();
    _suggestionPulseAnimations.clear();

    // Create controllers for each suggestion
    for (int i = 0; i < _currentSuggestions.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );

      final animation = Tween<double>(
        begin: 1.0,
        end: 0.97,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );

      _suggestionPulseControllers.add(controller);
      _suggestionPulseAnimations.add(animation);
    }

    // Start sequential pulse animation
    _startNextPulse(0);
  }

  void _startNextPulse(int index) {
    if (index >= _suggestionPulseControllers.length) {
      // Reset to first suggestion after completing all
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _startNextPulse(0);
        }
      });
      return;
    }

    final controller = _suggestionPulseControllers[index];
    
    // Start pulse animation
    controller.forward();

    // When pulse completes (forward + reverse), move to next
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Start reverse
        controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // Pulse cycle complete, move to next suggestion
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _startNextPulse(index + 1);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // Use chat background color for floating effect
                  color: AppTheme.getTheme(theme.brightness).scaffoldBackgroundColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Welcome message centered
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.waving_hand,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Welcome text centered and larger
                    Text(
                      AppLocalizations.of(context)?.welcomeMessage ?? 'Welcome! How can I help you today?',
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
                    _buildSuggestionsList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    return FadeTransition(
      opacity: _questionsFadeAnimation,
      child: Column(
        children: _currentSuggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;
          
          return Container(
            margin: EdgeInsets.only(top: index == 0 ? 0 : 8.0),
            child: AnimatedBuilder(
              animation: _suggestionPulseControllers.length > index 
                  ? _suggestionPulseControllers[index] 
                  : const AlwaysStoppedAnimation(0),
              builder: (context, child) {
                final scale = _suggestionPulseControllers.length > index
                    ? _suggestionPulseAnimations[index].value
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: _buildSuggestionItem(suggestion, index),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion, int index) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onSuggestionTap(suggestion);
          
          // Show feedback if context is available
          if (widget.context != null) {
            SnackbarUtils.showSuccessSnackBar(
              context: widget.context!,
              message: 'Sending suggestion...',
              icon: Icons.send,
              duration: const Duration(milliseconds: 800),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.brightness == Brightness.dark 
                    ? Colors.grey[800]!.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.6),
                theme.brightness == Brightness.dark 
                    ? Colors.grey[850]!.withValues(alpha: 0.2)
                    : Colors.grey[50]!.withValues(alpha: 0.4),
              ],
            ),
          ),
          child: Text(
            suggestion,
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
