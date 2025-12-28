import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:chatorai/utils/markdown_parser_with_keys.dart';
import 'package:chatorai/themes/app_theme.dart';

/// Виджет Markdown с поддержкой ключей для заголовков
class MarkdownWithHeadings extends StatelessWidget {
  final String data;
  final List<MarkdownHeadingInfoWithKey> headings;

  const MarkdownWithHeadings({
    super.key,
    required this.data,
    required this.headings,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      styleSheet: UbuntuMarkdownStyles.getMarkdownStyles(context),
      selectable: true,
      builders: {
        'h1': _HeadingBuilder(headings, level: 1),
        'h2': _HeadingBuilder(headings, level: 2),
        'h3': _HeadingBuilder(headings, level: 3),
        'h4': _HeadingBuilder(headings, level: 4),
      },
      onTapLink: (text, href, title) {
        if (href != null) {
          // TODO: Handle link tapping
        }
      },
    );
  }
}

class _HeadingBuilder extends MarkdownElementBuilder {
  final List<MarkdownHeadingInfoWithKey> headings;
  final int level;

  _HeadingBuilder(this.headings, {required this.level});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent.trim();
    
    // Find the matching heading with key
    final heading = headings.firstWhere(
      (h) => h.text == text && h.level == level,
      orElse: () {
        // Fallback if no match found
        return MarkdownHeadingInfoWithKey(
          text: text,
          level: level,
          lineIndex: 0,
          rawLine: '',
          key: GlobalKey(),
        );
      },
    );

    return Container(
      key: heading.key,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: preferredStyle,
      ),
    );
  }
}
