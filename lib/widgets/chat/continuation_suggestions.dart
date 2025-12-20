import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';

/// Widget that displays continuation suggestions as part of chat flow
/// 
/// This widget appears as a message-like element in the chat stream,
/// positioned under the last AI response. It has a "floating" appearance
/// with subtle glass-morphism effect.
class ContinuationSuggestions extends StatefulWidget {
  /// List of suggestion strings to display
  final List<String> suggestions;
  
  /// Callback when a suggestion is tapped
  final Function(String) onSuggestionTap;
  
  /// Callback when the widget is closed
  final VoidCallback? onClose;
  
  /// Whether to show loading state
  final bool isLoading;
  
  /// Optional context for showing snackbars
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
  State<ContinuationSuggestions> createState() => _ContinuationSuggestionsState();
}

class _ContinuationSuggestionsState extends State<ContinuationSuggestions> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  List<AnimationController> _suggestionPulseControllers = [];
  List<Animation<double>> _suggestionPulseAnimations = [];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
    
    // Pulse animation for inviting interaction
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _pulseController.forward();
          }
        });
      }
    });
    
    // Create individual pulse controllers for each suggestion
    _suggestionPulseControllers = [];
    _suggestionPulseAnimations = [];
    
    // Start animations with delay for better UX
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _animationController.forward();
          
          // Start pulse animation after main animation
          Future.delayed(const Duration(milliseconds: 300), () {
            _pulseController.forward();
            
            // Start individual pulse animations for each suggestion with delays
            _startSequentialPulseAnimations();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    // Dispose all suggestion pulse controllers
    for (var controller in _suggestionPulseControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startSequentialPulseAnimations() {
    // Clear previous controllers if any
    for (var controller in _suggestionPulseControllers) {
      controller.dispose();
    }
    _suggestionPulseControllers.clear();
    _suggestionPulseAnimations.clear();

    // Create controllers for each suggestion with smooth timing
    for (int i = 0; i < widget.suggestions.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800), // Faster pulse
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

    // Start sequential pulse animation with smooth timing
    _startNextPulse(0);
  }

  void _startNextPulse(int index) {
    if (index >= _suggestionPulseControllers.length) {
      // Reset to first suggestion after completing all with shorter delay
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _startNextPulse(0);
        }
      });
      return;
    }

    final controller = _suggestionPulseControllers[index];
    
    // Start pulse animation with smooth easing
    controller.forward();

    // When pulse completes (forward + reverse), move to next
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Start reverse
        controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // Pulse cycle complete, move to next suggestion with optimized timing
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
    final l10n = AppLocalizations.of(context)!;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.5,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
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
                            Icons.lightbulb_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
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
                      // Close icon
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
                  
                  // Loading state
                  if (widget.isLoading)
                    _buildLoadingState()
                  else if (widget.suggestions.isNotEmpty)
                    _buildSuggestionsList()
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

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
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

  Widget _buildSuggestionsList() {
    return Column(
      children: widget.suggestions.asMap().entries.map((entry) {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          child: Row(
            children: [
              Expanded(
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
              Icon(
                Icons.arrow_upward,
                size: 14,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Constants for continuation suggestions
class ContinuationSuggestionsConstants {
  static const String systemPrompt = 
      'You are a helpful assistant. Based on the previous conversation, '
      'suggest 3-4 different ways the user might want to continue the conversation. '
      'Each suggestion should be a short question or prompt (1-2 sentences max). '
      'Return only the suggestions separated by newlines, no additional text.';
  
  static const String userPrompt = 
      'Please suggest different ways I could continue this conversation.';
  
  static const int maxSuggestions = 4;
  static const int minSuggestionLength = 5;
  static const int maxSuggestionTextLength = 100;
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeOut;
}
