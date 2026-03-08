import 'package:flutter/material.dart';
import 'package:chatorai/widgets/chat/markdown_navigator_sidebar.dart';
import 'package:chatorai/utils/markdown_parser_with_keys.dart';

/// Пример виджета чата с интегрированным навигатором по Markdown
/// Устаревший файл, используется для тестирования. Основная логика в ChatMessages.
class ChatWithNavigator extends StatefulWidget {
  final String chatContent;

  const ChatWithNavigator({super.key, required this.chatContent});

  @override
  State<ChatWithNavigator> createState() => _ChatWithNavigatorState();
}

class _ChatWithNavigatorState extends State<ChatWithNavigator> {
  bool _isNavigatorOpen = false;
  List<MarkdownHeadingInfoWithKey> _headings = [];

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

  void _parseHeadings() {
    setState(() {
      _headings = MarkdownParserWithKeys.parseHeadingsWithKeys(
        widget.chatContent,
        messageId: 'standalone',
      );
    });
  }

  void _toggleNavigator() {
    setState(() {
      _isNavigatorOpen = !_isNavigatorOpen;
    });
  }

  void _onHeadingTap(String headingText, String messageId, int level) {
    // Находим заголовок в списке
    final heading = _headings.firstWhere(
      (h) =>
          h.text == headingText && h.messageId == messageId && h.level == level,
      orElse: () => throw Exception('Heading not found: $headingText'),
    );

    // Используем Scrollable.ensureVisible (правильный подход)
    final context = heading.context;
    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
    }

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
                  child: SingleChildScrollView(child: Text(widget.chatContent)),
                ),
              ),
            ],
          ),
        ),

        // Сайдбар навигации
        MarkdownNavigatorSidebar(
          headings: _headings,
          isOpen: _isNavigatorOpen,
          onClose: _toggleNavigator,
          onHeadingTap: _onHeadingTap,
        ),
      ],
    );
  }
}
