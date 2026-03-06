import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:chatorai/utils/markdown_parser_with_keys.dart';
import 'package:chatorai/themes/app_theme.dart';

class MarkdownWithHeadings extends StatelessWidget {
  final String data;
  final List<MarkdownHeadingInfoWithKey> headings;
  final String? messageId;

  const MarkdownWithHeadings({
    super.key,
    required this.data,
    required this.headings,
    this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMessageId = messageId ?? '';
    final filteredHeadings = messageId != null
        ? headings.where((h) => h.messageId == messageId).toList()
        : headings;

    return MarkdownBody(
      data: data,
      styleSheet: ChatoraiMarkdownStyles.getMarkdownStyles(context),
      selectable: true,
      builders: {
        'h1': _HeadingBuilder(
          filteredHeadings,
          level: 1,
          messageId: effectiveMessageId,
        ),
        'h2': _HeadingBuilder(
          filteredHeadings,
          level: 2,
          messageId: effectiveMessageId,
        ),
        'h3': _HeadingBuilder(
          filteredHeadings,
          level: 3,
          messageId: effectiveMessageId,
        ),
        'h4': _HeadingBuilder(
          filteredHeadings,
          level: 4,
          messageId: effectiveMessageId,
        ),
        'h5': _HeadingBuilder(
          filteredHeadings,
          level: 5,
          messageId: effectiveMessageId,
        ),
        'h6': _HeadingBuilder(
          filteredHeadings,
          level: 6,
          messageId: effectiveMessageId,
        ),
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
  final String messageId;

  _HeadingBuilder(
    this.headings, {
    required this.level,
    required this.messageId,
  });

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent.trim();

    final heading = headings.firstWhere(
      (h) => h.text == text && h.level == level && h.messageId == messageId,
      orElse: () {
        return MarkdownHeadingInfoWithKey(
          text: text,
          level: level,
          lineIndex: 0,
          rawLine: '',
          key: GlobalKey(debugLabel: 'heading_fallback_${messageId}_$level'),
          messageId: messageId,
        );
      },
    );

    return Container(
      key: heading.key,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: preferredStyle),
    );
  }
}
