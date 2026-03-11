import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:chatorai/constants/chat_constants.dart';
import 'package:chatorai/utils/markdown_parser.dart';

// ===========================================================================
// MARKDOWN NAVIGATOR SIDEBAR WIDGET
// ===========================================================================

/// Сайдбар для навигации по заголовкам Markdown в чате
/// Открывается слайдом с правого края экрана влево
/// Аналогичен основному сайдбару, но для заголовков чата
class MarkdownNavigatorSidebar extends StatefulWidget {
  final List<MarkdownHeadingInfoWithKey> headings;
  final int activeHeadingIndex;
  final Function(String headingText, String messageId, int level)? onHeadingTap;
  final bool isOpen;
  final VoidCallback? onClose;

  const MarkdownNavigatorSidebar({
    super.key,
    required this.headings,
    this.activeHeadingIndex = -1,
    this.onHeadingTap,
    required this.isOpen,
    this.onClose,
  });

  @override
  State<MarkdownNavigatorSidebar> createState() =>
      _MarkdownNavigatorSidebarState();
}

// ===========================================================================
// MARKDOWN NAVIGATOR SIDEBAR STATE
// ===========================================================================

class _MarkdownNavigatorSidebarState extends State<MarkdownNavigatorSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.isOpen) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(MarkdownNavigatorSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveHeading();
        });
      } else {
        _animationController.reverse();
      }
    }

    if (widget.activeHeadingIndex != oldWidget.activeHeadingIndex &&
        widget.activeHeadingIndex >= 0 &&
        widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveHeading();
      });
    }
  }

  void _scrollToActiveHeading() {
    if (widget.activeHeadingIndex >= 0 &&
        widget.activeHeadingIndex < widget.headings.length &&
        _scrollController.hasClients) {
      const itemHeight = 48.0;
      final targetOffset = widget.activeHeadingIndex * itemHeight;
      final maxOffset = _scrollController.position.maxScrollExtent;

      _scrollController.animateTo(
        targetOffset.clamp(0.0, maxOffset),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHeading(int index) {
    if (widget.onHeadingTap != null) {
      final heading = widget.headings[index];
      widget.onHeadingTap!(heading.text, heading.messageId, heading.level);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Overlay backdrop
            if (widget.isOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.3 * _animationController.value,
                    ),
                  ),
                ),
              ),

            // Sidebar - matches main sidebar width (280px) and style
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 280.0,
              child: Transform.translate(
                offset: Offset(280.0 * (1 - _animationController.value), 0),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    // Swipe right to close
                    if (details.primaryDelta! > 10 && widget.onClose != null) {
                      widget.onClose!();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(-2, 0),
                        ),
                      ],
                      border: Border(
                        left: BorderSide(color: theme.dividerColor, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header with close button - always visible
                        Container(
                          height: 55,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            border: Border(
                              bottom: BorderSide(
                                color: theme.dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: widget.onClose,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ),

                        // Content
                        Expanded(
                          child: widget.headings.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.format_underlined,
                                        size: 48,
                                        color: theme.iconTheme.color
                                            ?.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Заголовки не найдены',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Используйте #, ##, ### в Markdown',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  controller: _scrollController,
                                  padding: EdgeInsets.only(
                                    top: _isDesktop() ? 12 : 8,
                                    bottom: _isDesktop() ? 12 : 8,
                                    left: 0,
                                    right: 0,
                                  ),
                                  itemCount: widget.headings.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                  itemBuilder: (context, index) {
                                    final heading = widget.headings[index];
                                    final isActive =
                                        index == widget.activeHeadingIndex;

                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _scrollToHeading(index),
                                        hoverColor: theme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? theme.colorScheme.primary
                                                      .withValues(alpha: 0.1)
                                                : Colors.transparent,
                                            border: Border(
                                              left: BorderSide(
                                                color: isActive
                                                    ? theme.colorScheme.primary
                                                    : Colors.transparent,
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: MarkdownBody(
                                                  data: heading.text,
                                                  shrinkWrap: true,
                                                  styleSheet: MarkdownStyleSheet(
                                                    p: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight: isActive
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                          color: isActive
                                                              ? theme
                                                                    .colorScheme
                                                                    .primary
                                                              : theme
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.color,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isDesktop() {
    final width = MediaQuery.of(context).size.width;
    return width >= ChatScreenConstants.mobileBreakpoint;
  }
}
