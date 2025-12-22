import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/widgets/chat/markdown_navigator_sidebar.dart';
import 'package:gen_ui_chat_ai/utils/markdown_parser.dart';

/// Пример виджета чата с интегрированным навигатором по Markdown
class ChatWithNavigator extends StatefulWidget {
  final String chatContent;

  const ChatWithNavigator({
    super.key,
    required this.chatContent,
  });

  @override
  State<ChatWithNavigator> createState() => _ChatWithNavigatorState();
}

class _ChatWithNavigatorState extends State<ChatWithNavigator> {
  bool _isNavigatorOpen = false;
  List<MarkdownHeadingInfo> _headings = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _parseHeadings();
  }

  @override
  void didUpdateWidget(ChatWithNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatContent != oldWidget.chatContent) {
      _parseHeadings();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _parseHeadings() {
    setState(() {
      _headings = MarkdownParser.parseHeadings(widget.chatContent);
    });
  }

  void _toggleNavigator() {
    setState(() {
      _isNavigatorOpen = !_isNavigatorOpen;
    });
  }

  void _onHeadingTap(String headingText) {
    // Находим заголовок в списке
    final heading = _headings.firstWhere(
      (h) => h.text == headingText,
      orElse: () => throw Exception('Heading not found: $headingText'),
    );

    // Рассчитываем позицию для прокрутки
    // Учитываем только отступы
    final linesBeforeHeading = heading.lineIndex;
    
    // Примерная высота строки (может потребоваться калибровка)
    const double lineHeight = 20.0;
    const double padding = 16.0;
    
    double scrollOffset = padding + (linesBeforeHeading * lineHeight);
    
    // Ограничиваем максимальное значение
    scrollOffset = scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
    
    // Прокручиваем к заголовку
    _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    
    // Закрываем навигатор
    setState(() {
      _isNavigatorOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Основное содержимое чата
        Positioned.fill(
          child: Column(
            children: [
              // Содержимое чата
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Text(widget.chatContent),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Сайдбар навигации
        MarkdownNavigatorSidebar(
          content: widget.chatContent,
          isOpen: _isNavigatorOpen,
          onClose: _toggleNavigator,
          onHeadingTap: _onHeadingTap,
        ),
      ],
    );
  }
}
