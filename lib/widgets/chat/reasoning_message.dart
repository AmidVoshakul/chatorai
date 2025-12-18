import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';

/// Фазы отображения reasoning
enum ReasoningPhase {
  thinking, // модель думает (streaming)
  typing,   // reasoning печатается
  done,     // reasoning готов
}

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
    with TickerProviderStateMixin {
  
  bool _isExpanded = false;
  late final AnimationController _fadeInController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    
    // Simple fade-in animation
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 0.0,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeInController, curve: Curves.easeInOut),
    );

    // Start fade-in immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeInController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    // Directly use widget.reasoning - no local state, no typing animation
    final String sourceText = widget.reasoning;
    final List<String> lines = sourceText.split('\n');
    final String previewText = lines.take(2).join('\n');

    // Show shimmer/spinner only during streaming with no content yet
    final bool showShimmer = widget.isStreaming && sourceText.isEmpty;

    return AnimatedBuilder(
      animation: _fadeIn,
      builder: (_, child) {
        return Opacity(
          opacity: _fadeIn.value,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: _isExpanded ? null : 140,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.65,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: _isExpanded
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(localizations, theme),
                      const SizedBox(height: 8),
                      Text(
                        sourceText,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(localizations, theme),
                    const SizedBox(height: 8),
                    if (sourceText.isNotEmpty)
                      Text(
                        previewText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    if (showShimmer)
                      Container(
                        height: 10,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? localizations, ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.psychology, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            localizations?.reasoning ?? 'Reasoning',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 16,
          ),
          splashRadius: 18,
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
      ],
    );
  }
}
