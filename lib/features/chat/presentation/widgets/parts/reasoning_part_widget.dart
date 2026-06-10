import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_call_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_result_part_widget.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ReasoningPartWidget extends StatefulWidget {
  final ReasoningPart part;
  final List<MessagePart>? toolParts;

  const ReasoningPartWidget({super.key, required this.part, this.toolParts});

  @override
  State<ReasoningPartWidget> createState() => _ReasoningPartWidgetState();
}

class _ReasoningPartWidgetState extends State<ReasoningPartWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shimmerAnimation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (widget.part.isStreaming) {
      _shimmerController.repeat();
      _dotsController.repeat();
    }
  }

  @override
  void didUpdateWidget(ReasoningPartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.part.isStreaming) {
      if (!_shimmerController.isAnimating) _shimmerController.repeat();
      if (!_dotsController.isAnimating) _dotsController.repeat();
    } else {
      _shimmerController.stop();
      _shimmerController.value = 0;
      _dotsController.stop();
      _dotsController.value = 0;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(ChatoraiSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Opacity(
          // Уменьшаем заметность всего reasoning (и мыслей, и инструментов)
          opacity: 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(localizations, theme),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: ChatoraiSpacing.sm),
                  child: _buildContent(),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 350),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: DefaultTextStyle(
          style: theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: widget.part.content,
                styleSheet: ChatoraiMarkdownStyles.getMarkdownStyles(context),
                selectable: true,
              ),
              if (widget.toolParts != null && widget.toolParts!.isNotEmpty)
                const SizedBox(height: ChatoraiSpacing.md),
              if (widget.toolParts != null)
                ...widget.toolParts!.map(_buildToolWidget),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolWidget(MessagePart part) {
    if (part is ToolCallPart) {
      return ToolCallPartWidget(part: part);
    } else if (part is ToolResultPart) {
      return ToolResultPartWidget(part: part);
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeader(AppLocalizations? localizations, ThemeData theme) {
    final textColor = theme.colorScheme.onSurface;
    final headerText = localizations?.reasoning ?? 'Reasoning';

    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerAnimation, _dotsController]),
      builder: (context, child) {
        final isStreaming = widget.part.isStreaming;

        return GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: ChatoraiIconSizes.md,
                  color: textColor,
                ),
              ),
              const SizedBox(width: ChatoraiSpacing.xs),
              if (isStreaming)
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment(-1 + _shimmerAnimation.value, 0),
                      end: Alignment(1 + _shimmerAnimation.value, 0),
                      colors: [
                        textColor.withValues(alpha: 0.35),
                        textColor,
                        textColor.withValues(alpha: 0.35),
                      ],
                      stops: const [0.25, 0.5, 0.75],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    headerText,
                    style: TextStyle(
                      fontSize: ChatoraiFontSizes.sm,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: textColor,
                    ),
                  ),
                )
              else
                Text(
                  headerText,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.sm,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: textColor,
                  ),
                ),
              // Dots (without shimmer)
              AnimatedBuilder(
                animation: _dotsController,
                builder: (context, child) {
                  final dotIndex = isStreaming
                      ? (_dotsController.value * 3).floor() % 4
                      : 0;
                  final dots = '.' * dotIndex;
                  return Text(
                    dots,
                    style: TextStyle(
                      fontSize: ChatoraiFontSizes.sm,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: textColor,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
