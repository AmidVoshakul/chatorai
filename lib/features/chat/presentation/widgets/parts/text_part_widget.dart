import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/markdown_with_headings.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/code_block.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/table_block.dart';
import 'package:chatorai/shared/theme/markdown_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class TextPartWidget extends StatefulWidget {
  final TextPart part;

  const TextPartWidget({super.key, required this.part});

  @override
  State<TextPartWidget> createState() => _TextPartWidgetState();
}

class _TextPartWidgetState extends State<TextPartWidget> {
  String? _lastContent;
  List<Widget>? _cachedContentWidgets;
  String? _lastThemeKey;

  @override
  void didUpdateWidget(covariant TextPartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.part.content != widget.part.content) {
      _lastContent = null;
      _cachedContentWidgets = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeKey = Theme.of(context).brightness.toString();
    if (_lastThemeKey != themeKey) {
      _lastThemeKey = themeKey;
      _lastContent = null;
      _cachedContentWidgets = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final part = widget.part;

    if (part.content.isEmpty && part.isStreaming) {
      return const _StreamingCursor();
    }

    if (part.content.isEmpty) {
      return const SizedBox(height: 16);
    }

    if (_lastContent != part.content) {
      final previousContent = _lastContent;
      _lastContent = part.content;
      if (previousContent != null &&
          part.content.startsWith(previousContent) &&
          part.content.length > previousContent.length) {
        final tail = part.content.substring(previousContent.length);
        if (_isSimpleTextTail(tail)) {
          final fullText = part.content;
          final appended = _buildMarkdownBlock(
            fullText,
            ChatoraiMarkdownStyles.getMarkdownStyles(context),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [appended],
          );
        }
      }
      _cachedContentWidgets = _buildCustomMarkdownContent(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _cachedContentWidgets!,
    );
  }

  bool _isSimpleTextTail(String tail) {
    for (final char in tail.characters) {
      if (char == '\n' || char == '`' || char == '#' || char == '|') {
        return false;
      }
    }
    return true;
  }

  List<Widget> _buildCustomMarkdownContent(BuildContext context) {
    final lines = widget.part.content.split('\n');
    final styleSheet = ChatoraiMarkdownStyles.getMarkdownStyles(context);

    final List<Widget> contentWidgets = [];
    String currentTextBlock = '';
    bool inCodeBlock = false;
    String currentLanguage = 'text';
    String currentCodeBlock = '';
    int i = 0;

    while (i < lines.length) {
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
        final tableResult = TableParser.extractTableAt(lines, i);
        if (tableResult != null) {
          if (currentTextBlock.isNotEmpty) {
            contentWidgets.add(
              _buildMarkdownBlock(currentTextBlock, styleSheet),
            );
            currentTextBlock = '';
          }

          final tableRows = TableParser.parseTableLines(tableResult.lines);
          if (tableRows != null && tableRows.isNotEmpty) {
            contentWidgets.add(TableBlock(rows: tableRows));
          }

          i = tableResult.endIndex;
          continue;
        } else {
          currentTextBlock += '$line\n';
        }
      }
      i++;
    }

    if (currentTextBlock.isNotEmpty) {
      contentWidgets.add(_buildMarkdownBlock(currentTextBlock, styleSheet));
    }
    if (currentCodeBlock.isNotEmpty) {
      contentWidgets.add(
        CodeBlock(code: currentCodeBlock.trim(), language: currentLanguage),
      );
    }

    return contentWidgets;
  }

  Widget _buildMarkdownBlock(String data, MarkdownStyleSheet styleSheet) {
    return RepaintBoundary(
      child: MarkdownBody(
        data: data,
        styleSheet: styleSheet,
        selectable: true,
        builders: HeadingBuilder.headingBuilders(),
      ),
    );
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
