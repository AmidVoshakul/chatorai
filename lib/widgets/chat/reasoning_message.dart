import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';

final _logger = LogTags.reasoningMessage;

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
    with SingleTickerProviderStateMixin {

  // ===========================================================================
  // STATE
  // ===========================================================================

  ReasoningPhase _phase = ReasoningPhase.done;

  bool _isExpanded = false;

  // typing animation
  String _visibleReasoning = '';
  Timer? _typingTimer;

  // pulse / shimmer animation
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // ⚠️ ВАЖНО: initState — это ВСЕГДА "историческое" состояние
    if (widget.isStreaming) {
      _setPhase(ReasoningPhase.thinking);
    } else if (widget.reasoning.isNotEmpty) {
      _visibleReasoning = widget.reasoning;
      _setPhase(ReasoningPhase.done);
    }
  }

  @override
  void didUpdateWidget(covariant ReasoningMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    _logger.logDebug(
      '[ReasoningMessage] update: streaming=${widget.isStreaming}, '
      'oldLen=${oldWidget.reasoning.length}, newLen=${widget.reasoning.length}',
    );

    _syncPhase(oldWidget);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // PHASE LOGIC (КЛЮЧЕВАЯ ЧАСТЬ)
  // ===========================================================================

  void _syncPhase(ReasoningMessage oldWidget) {
    // 1. Пока идёт стрим — thinking
    if (widget.isStreaming) {
      _setPhase(ReasoningPhase.thinking);
      return;
    }

    // 2. Reasoning появился ВПЕРВЫЕ после стрима → typing
    if (!widget.isStreaming &&
        oldWidget.reasoning.isEmpty &&
        widget.reasoning.isNotEmpty) {
      _startTyping(widget.reasoning);
      return;
    }

    // 3. Историческое сообщение → сразу done
    if (widget.reasoning.isNotEmpty) {
      _typingTimer?.cancel();
      _visibleReasoning = widget.reasoning;
      _setPhase(ReasoningPhase.done);
    }
  }

  void _setPhase(ReasoningPhase next) {
    if (_phase == next) return;

    _logger.logInfo('[ReasoningMessage] phase: $_phase → $next');

    setState(() => _phase = next);

    if (next == ReasoningPhase.thinking) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
  }

  // ===========================================================================
  // TYPING ANIMATION
  // ===========================================================================

  void _startTyping(String fullText) {
    _typingTimer?.cancel();

    _visibleReasoning = '';
    _setPhase(ReasoningPhase.typing);

    int index = 0;

    _typingTimer = Timer.periodic(
      const Duration(milliseconds: 12),
      (timer) {
        if (index >= fullText.length) {
          timer.cancel();
          _visibleReasoning = fullText;
          _setPhase(ReasoningPhase.done);
        } else {
          setState(() {
            index++;
            _visibleReasoning = fullText.substring(0, index);
          });
        }
      },
    );
  }

  // ===========================================================================
  // SHIMMER
  // ===========================================================================

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Container(
          height: 12,
          width: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                UbuntuColors.neonBlue.withOpacity(0.2),
                UbuntuColors.neonBlue.withOpacity(0.6 + (_pulse.value * 0.3)),
                UbuntuColors.neonBlue.withOpacity(0.2),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    _logger.logVerbose(
      '[ReasoningMessage] build: phase=$_phase, expanded=$_isExpanded',
    );

    if (widget.reasoning.isNotEmpty) {
      _logger.logDebug(
        '[ReasoningMessage] reasoning preview: '
        '"${widget.reasoning.substring(0, min(80, widget.reasoning.length))}"',
      );
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final scale = _phase == ReasoningPhase.thinking
            ? 0.985 + (_pulse.value * 0.02)
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withOpacity(
            _phase == ReasoningPhase.thinking
                ? 0.08 + (_pulse.value * 0.05)
                : 0.1,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
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
                    _isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 16,
                  ),
                  splashRadius: 18,
                  onPressed: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // BODY
            if (_phase == ReasoningPhase.thinking)
              _buildShimmer(),

            if (_phase != ReasoningPhase.thinking && _isExpanded)
              Text(
                _phase == ReasoningPhase.typing
                    ? _visibleReasoning
                    : widget.reasoning,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
