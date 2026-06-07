import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/models/chat_message.dart';
import 'package:chatorai/widgets/chat/code_block.dart';

class TextPartWidget extends StatelessWidget {
  final TextPart part;

  const TextPartWidget({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    if (part.content.isEmpty && part.isStreaming) {
      return const _StreamingCursor();
    }

    if (part.content.isEmpty) {
      return const SizedBox(height: 16);
    }

    return _buildCustomMarkdownContent(context);
  }

  Widget _buildCustomMarkdownContent(BuildContext context) {
    final lines = part.content.split('\n');
    final styleSheet = ChatoraiMarkdownStyles.getMarkdownStyles(context);

    final List<Widget> contentWidgets = [];
    String currentTextBlock = '';
    bool inCodeBlock = false;
    String currentLanguage = 'text';
    String currentCodeBlock = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('```')) {
        if (inCodeBlock) {
          if (currentTextBlock.isNotEmpty) {
            contentWidgets.add(
              _buildMarkdownBlock(currentTextBlock, styleSheet),
            );
            currentTextBlock = '';
          }
          if (currentCodeBlock.isNotEmpty) {
            contentWidgets.add(
              CodeBlock(code: currentCodeBlock, language: currentLanguage),
            );
            currentCodeBlock = '';
          }
          inCodeBlock = false;
        } else {
          if (currentTextBlock.isNotEmpty) {
            contentWidgets.add(
              _buildMarkdownBlock(currentTextBlock, styleSheet),
            );
            currentTextBlock = '';
          }
          inCodeBlock = true;
          currentLanguage = line.substring(3).trim();
          if (currentLanguage.isEmpty) currentLanguage = 'text';
        }
      } else if (inCodeBlock) {
        currentCodeBlock += '$line\n';
      } else {
        currentTextBlock += '$line\n';
      }
    }

    if (currentTextBlock.isNotEmpty) {
      contentWidgets.add(_buildMarkdownBlock(currentTextBlock, styleSheet));
    }
    if (currentCodeBlock.isNotEmpty) {
      contentWidgets.add(
        CodeBlock(code: currentCodeBlock.trim(), language: currentLanguage),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }

  Widget _buildMarkdownBlock(String data, MarkdownStyleSheet styleSheet) {
    return MarkdownBody(data: data, styleSheet: styleSheet, selectable: true);
  }
}

class _StreamingCursor extends StatefulWidget {
  const _StreamingCursor();

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 16,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}
