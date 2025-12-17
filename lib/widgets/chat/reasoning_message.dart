import 'dart:async';

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
    with TickerProviderStateMixin {

  // ===========================================================================
  // STATE
  // ===========================================================================

  ReasoningPhase _phase = ReasoningPhase.done;
  bool _isExpanded = false;

  // typing animation
  String _visibleReasoning = '';
  String _typingTarget = ''; // Хранит цель печати
  Timer? _typingTimer;

  // pulse / shimmer animation
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  // fade-in animation for widget appearance
  late final AnimationController _fadeInController;
  late final Animation<double> _fadeIn;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    print('[DEBUG] [ReasoningMessage] initState, reasoning length: ${widget.reasoning.length}, isStreaming: ${widget.isStreaming}');

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Determine initial phase
    if (widget.isStreaming && widget.reasoning.isEmpty) {
      _phase = ReasoningPhase.thinking;
      print('[DEBUG] [ReasoningMessage] Initial phase: thinking');
    } else if (widget.reasoning.isNotEmpty) {
      _phase = ReasoningPhase.done;
      _visibleReasoning = widget.reasoning;
      print('[DEBUG] [ReasoningMessage] Initial phase: done (with content)');
    } else {
      // Historical message without streaming
      _phase = ReasoningPhase.done;
      print('[DEBUG] [ReasoningMessage] Initial phase: done (no content)');
    }

    // Fade-in: start at 0, animate to 1 if we have content
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 0.0,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeInController, curve: Curves.easeInOut),
    );

    // Start fade-in if we have content or are streaming
    if (widget.reasoning.isNotEmpty || widget.isStreaming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fadeInController.forward();
          print('[DEBUG] [ReasoningMessage] Fade-in started');
        }
      });
    }

    // Start pulse animation for thinking phase
    if (_phase == ReasoningPhase.thinking) {
      _pulseController.repeat(reverse: true);
      print('[DEBUG] [ReasoningMessage] Pulse animation started');
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
    _fadeInController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // PHASE LOGIC (КЛЮЧЕВАЯ ЧАСТЬ)
  // ===========================================================================

  void _syncPhase(ReasoningMessage oldWidget) {
    print('[DEBUG] [ReasoningMessage] _syncPhase: old streaming=${oldWidget.isStreaming}, new streaming=${widget.isStreaming}, old len=${oldWidget.reasoning.length}, new len=${widget.reasoning.length}');
    
    // 1. Пока идёт стрим, но reasoning ещё не появился — thinking
    if (widget.isStreaming && widget.reasoning.isEmpty) {
      print('[DEBUG] [ReasoningMessage] Phase 1: thinking (streaming, no reasoning yet)');
      _setPhase(ReasoningPhase.thinking);
      return;
    }

    // 2. Reasoning появился ВПЕРВЫЕ (во время или после стрима) → typing
    if (oldWidget.reasoning.isEmpty && widget.reasoning.isNotEmpty) {
      print('[DEBUG] [ReasoningMessage] Phase 2: typing (reasoning appeared for first time)');
      _startTyping(widget.reasoning);
      return;
    }

    // 3. Reasoning обновляется (дострим) — только если текст увеличился
    if (widget.reasoning.isNotEmpty &&
        widget.reasoning.length > oldWidget.reasoning.length) {
      print('[DEBUG] [ReasoningMessage] Phase 3: continuing typing (reasoning updated)');
      // Продолжаем печатать с текущей позиции
      _continueTypingTo(widget.reasoning);
      return;
    }

    // 4. Стрим закончился, reasoning есть → done
    if (!widget.isStreaming && widget.reasoning.isNotEmpty) {
      print('[DEBUG] [ReasoningMessage] Phase 4: done (stream finished, reasoning complete)');
      _typingTimer?.cancel();
      _visibleReasoning = widget.reasoning;
      _setPhase(ReasoningPhase.done);
    }
  }

  void _setPhase(ReasoningPhase next) {
    if (_phase == next) return;

    _logger.logInfo('[ReasoningMessage] phase: $_phase → $next');

    setState(() => _phase = next);

    // Pulse only for thinking phase
    if (next == ReasoningPhase.thinking) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }

    // Ensure fade-in is visible
    if (_fadeInController.value < 1.0) {
      _fadeInController.forward();
    }
  }

  // ===========================================================================
  // TYPING ANIMATION
  // ===========================================================================

  void _startTyping(String fullText) {
    _typingTimer?.cancel();

    _visibleReasoning = '';
    _typingTarget = fullText;
    _setPhase(ReasoningPhase.typing);

    int index = 0;

    _typingTimer = Timer.periodic(
      const Duration(milliseconds: 16), // 60 FPS вместо 80+
      (timer) {
        if (index >= _typingTarget.length) {
          timer.cancel();
          _visibleReasoning = _typingTarget;
          _typingTarget = '';
          _setPhase(ReasoningPhase.done);
        } else {
          setState(() {
            index++;
            _visibleReasoning = _typingTarget.substring(0, index);
          });
        }
      },
    );
  }

  void _continueTypingTo(String newTarget) {
    // Обновляем цель
    _typingTarget = newTarget;
    
    // Если таймер уже работает — просто продолжим с новой целью
    if (_typingTimer != null && _typingTimer!.isActive) {
      return;
    }

    // Если таймер не активен — запускаем новый
    int currentIndex = _visibleReasoning.length;
    
    _setPhase(ReasoningPhase.typing);

    _typingTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) {
        if (currentIndex >= _typingTarget.length) {
          timer.cancel();
          _visibleReasoning = _typingTarget;
          _typingTarget = '';
          _setPhase(ReasoningPhase.done);
        } else {
          setState(() {
            currentIndex++;
            _visibleReasoning = _typingTarget.substring(0, currentIndex);
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
      builder: (context, child) {
        return Container(
          height: 10,
          width: 120,
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

    final String sourceText =
        _visibleReasoning.isNotEmpty ? _visibleReasoning : widget.reasoning;

    final List<String> lines = sourceText.split('\n');
    final String previewText = lines.take(2).join('\n');

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
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) {
              // Pulse only for thinking phase, typing is already dynamic
              final scale = (_phase == ReasoningPhase.thinking)
                  ? 0.985 + (_pulse.value * 0.02)
                  : 1.0;

              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.65,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(
                  _phase == ReasoningPhase.thinking
                      ? 0.08 + (_pulse.value * 0.05)
                      : _phase == ReasoningPhase.typing
                          ? 0.08
                          : 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.3),
                ),
              ),
              child: _isExpanded
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Полный текст (с поддержкой typing)
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
                  : SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // BODY — показываем первые строки в свернутом состоянии
                          if (previewText.isNotEmpty)
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: 1.0,
                              child: Text(
                                previewText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          // SHIMMER — только для активных фаз
                          if (_phase == ReasoningPhase.thinking ||
                              _phase == ReasoningPhase.typing)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                _buildShimmer(),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
