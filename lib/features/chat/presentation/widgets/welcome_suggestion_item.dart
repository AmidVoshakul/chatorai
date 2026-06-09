import 'package:flutter/material.dart';

class WelcomeSuggestionItem extends StatelessWidget {
  final String suggestion;
  final bool isActive;
  final Animation<double>? pulseAnimation;
  final VoidCallback onTap;

  const WelcomeSuggestionItem({
    super.key,
    required this.suggestion,
    required this.isActive,
    required this.onTap,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: pulseAnimation != null
            ? AnimatedBuilder(
                animation: pulseAnimation!,
                builder: (context, child) {
                  final scale = pulseAnimation!.value;
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
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: bgColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
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
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.4,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  );
                },
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.brightness == Brightness.dark
                      ? theme.cardColor.withValues(alpha: 0.8)
                      : theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  suggestion,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
      ),
    );
  }
}
