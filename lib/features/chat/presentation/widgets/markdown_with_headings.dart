import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:chatorai/shared/utils/markdown_parser.dart';
import 'package:chatorai/shared/theme/markdown_styles.dart';

// ===========================================================================
// PUBLIC WIDGET
// ===========================================================================

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

  // =======================================================================
  // BUILD METHOD
  // =======================================================================

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
      builders: HeadingBuilder.headingBuilders(
        headings: filteredHeadings,
        messageId: effectiveMessageId,
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          // Link handling reserved for future
        }
      },
    );
  }
}

// ===========================================================================
// PRIVATE: HEADING BUILDER
// ===========================================================================

class HeadingBuilder extends MarkdownElementBuilder {
  final List<MarkdownHeadingInfoWithKey> headings;
  final int level;
  final String messageId;

  HeadingBuilder({
    this.headings = const [],
    required this.level,
    this.messageId = '',
  });

  static Map<String, MarkdownElementBuilder> headingBuilders({
    List<MarkdownHeadingInfoWithKey> headings = const [],
    String messageId = '',
  }) => {
    for (final level in [1, 2, 3, 4, 5, 6])
      'h$level': HeadingBuilder(
        headings: headings,
        level: level,
        messageId: messageId,
      ),
  };

  static EdgeInsets paddingForLevel(int level) {
    return switch (level) {
      1 => EdgeInsets.fromLTRB(0, 24, 0, 12),
      2 => EdgeInsets.fromLTRB(0, 20, 0, 10),
      3 => EdgeInsets.fromLTRB(0, 16, 0, 8),
      4 => EdgeInsets.fromLTRB(0, 12, 0, 8),
      5 => EdgeInsets.fromLTRB(0, 10, 0, 6),
      _ => EdgeInsets.fromLTRB(0, 8, 0, 6),
    };
  }

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent.trim();

    headings.firstWhere(
      (h) => h.text == text && h.level == level && h.messageId == messageId,
      orElse: () {
        return MarkdownHeadingInfoWithKey(
          text: text,
          level: level,
          lineIndex: 0,
          rawLine: '',
          messageId: messageId,
        );
      },
    );

    return Container(
      key: ValueKey('heading_${messageId}_${level}_$text'),
      padding: paddingForLevel(level),
      child: Text(text, style: preferredStyle),
    );
  }
}
