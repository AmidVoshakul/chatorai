import 'package:chatorai/features/chat/presentation/widgets/link_confirm_sheet.dart';
import 'package:chatorai/shared/theme/markdown_styles.dart';
import 'package:chatorai/shared/utils/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

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
      builders: HeadingBuilder.headingBuilders(
        headings: filteredHeadings,
        messageId: effectiveMessageId,
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          showLinkConfirmSheet(context, href: href);
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

  // Tracks how many times a (messageId, text) heading has been rendered at
  // this level, so that identical headings (e.g. two "## Introduction" in one
  // message) bind to distinct anchors instead of sharing one GlobalKey.
  final Map<String, int> _occurrences = {};

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
      1 => EdgeInsets.fromLTRB(0, 10, 0, 12),
      2 => EdgeInsets.fromLTRB(0, 10, 0, 10),
      3 => EdgeInsets.fromLTRB(0, 16, 0, 8),
      4 => EdgeInsets.fromLTRB(0, 12, 0, 8),
      5 => EdgeInsets.fromLTRB(0, 10, 0, 6),
      _ => EdgeInsets.fromLTRB(0, 8, 0, 6),
    };
  }

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent.trim();

    // Match against the parsed heading anchors, disambiguating identical
    // headings by their occurrence order at this level. No fallback that
    // allocates a fresh GlobalKey: doing so would (a) change on every rebuild
    // causing remount thrashing, and (b) collide with a real anchor's id if a
    // heading with the same text/level exists. When there is no match the
    // rendered heading simply has no key — it cannot be scroll-targeted, which
    // is acceptable because a mismatch should not happen in practice.
    final matches = headings
        .where(
          (h) => h.text == text && h.level == level && h.messageId == messageId,
        )
        .toList();

    MarkdownHeadingInfoWithKey? match;
    if (matches.isNotEmpty) {
      final occKey = '$messageId:$text';
      final index = _occurrences.putIfAbsent(occKey, () => 0);
      _occurrences[occKey] = index + 1;
      // Rendered occurrences may exceed parsed headings (setext headings or
      // headings inside blockquotes are rendered but not parsed). Extra
      // occurrences get no key instead of colliding with an earlier
      // occurrence's GlobalKey — a duplicate key crashes the widget tree.
      if (index < matches.length) match = matches[index];
    }

    return Container(
      key: match?.anchorKey,
      padding: paddingForLevel(level),
      child: Text(text, style: preferredStyle),
    );
  }
}
