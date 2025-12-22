import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/utils/markdown_parser.dart';

/// Сайдбар для навигации по заголовкам Markdown в чате
/// Открывается слайдом с правого края экрана влево
/// Аналогичен основному сайдбару, но для заголовков чата
class MarkdownNavigatorSidebar extends StatefulWidget {
  final String content;
  final Function(String)? onHeadingTap;
  final bool isOpen;
  final VoidCallback? onClose;

  const MarkdownNavigatorSidebar({
    super.key,
    required this.content,
    this.onHeadingTap,
    required this.isOpen,
    this.onClose,
  });

  @override
  State<MarkdownNavigatorSidebar> createState() => _MarkdownNavigatorSidebarState();
}

class _MarkdownNavigatorSidebarState extends State<MarkdownNavigatorSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<MarkdownHeadingInfo> _headings = [];
  int _activeIndex = -1;

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
    
    _parseHeadings();
  }

  @override
  void didUpdateWidget(MarkdownNavigatorSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.content != oldWidget.content) {
      _parseHeadings();
    }
    
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _parseHeadings() {
    final headings = MarkdownParser.parseHeadings(widget.content);
    setState(() {
      _headings = headings;
    });
  }

  void _scrollToHeading(int index) {
    setState(() {
      _activeIndex = index;
    });
    
    if (widget.onHeadingTap != null) {
      widget.onHeadingTap!(_headings[index].text);
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
                    color: Colors.black.withValues(alpha: 0.3 * _animationController.value),
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
                offset: Offset(
                  280.0 * (1 - _animationController.value),
                  0,
                ),
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
                      left: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header - only show close button on mobile
                      if (!_isDesktop())
                        Container(
                          height: 35,
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
                        child: _headings.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.format_underlined,
                                      size: 48,
                                      color: theme.iconTheme.color?.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Заголовки не найдены',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.textTheme.bodyMedium?.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Используйте #, ##, ### в Markdown',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.only(
                                  top: _isDesktop() ? 12 : 8,
                                  bottom: _isDesktop() ? 12 : 8,
                                  left: 0,
                                  right: 0,
                                ),
                                itemCount: _headings.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: theme.dividerColor.withValues(alpha: 0.1),
                                ),
                                itemBuilder: (context, index) {
                                  final heading = _headings[index];
                                  final isActive = index == _activeIndex;
                                  
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _scrollToHeading(index),
                                      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      child: Container(
                                        padding: EdgeInsets.only(
                                          left: 16 + (heading.level - 1) * 12.0,
                                          right: 16,
                                          top: 12,
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
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
                                              child: Text(
                                                heading.text,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                                  color: isActive
                                                      ? theme.colorScheme.primary
                                                      : theme.textTheme.bodyMedium?.color,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
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
          ],
        );
      },
    );
  }

  bool _isDesktop() {
    final width = MediaQuery.of(context).size.width;
    return width >= 800;
  }
}
