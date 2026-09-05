import 'package:flutter/material.dart';

/// Утилита для парсинга Markdown заголовков
class MarkdownParser {
  static List<MarkdownHeadingInfo> parseHeadings(String content) {
    final lines = content.split('\n');
    final headings = <MarkdownHeadingInfo>[];
    bool inCodeBlock = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (inCodeBlock) continue;

      final trimmedLine = line.trim();

      if (trimmedLine.startsWith('# ')) {
        headings.add(
          MarkdownHeadingInfo(
            text: stripMarkdownFormatting(trimmedLine.substring(2)),
            level: 1,
            lineIndex: i,
            rawLine: trimmedLine,
          ),
        );
      } else if (trimmedLine.startsWith('## ')) {
        headings.add(
          MarkdownHeadingInfo(
            text: stripMarkdownFormatting(trimmedLine.substring(3)),
            level: 2,
            lineIndex: i,
            rawLine: trimmedLine,
          ),
        );
      } else if (trimmedLine.startsWith('### ')) {
        headings.add(
          MarkdownHeadingInfo(
            text: stripMarkdownFormatting(trimmedLine.substring(4)),
            level: 3,
            lineIndex: i,
            rawLine: trimmedLine,
          ),
        );
      }
    }

    return headings;
  }

  static bool hasHeadings(String content) {
    return parseHeadings(content).isNotEmpty;
  }

  static Map<int, int> getHeadingCounts(List<MarkdownHeadingInfo> headings) {
    final counts = <int, int>{};
    for (var heading in headings) {
      counts[heading.level] = (counts[heading.level] ?? 0) + 1;
    }
    return counts;
  }

  static String getDisplayText(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

class MarkdownHeadingInfo {
  final String text;
  final int level;
  final int lineIndex;
  final String rawLine;

  MarkdownHeadingInfo({
    required this.text,
    required this.level,
    required this.lineIndex,
    required this.rawLine,
  });

  @override
  String toString() => 'H$level: $text (line $lineIndex)';
}

// ===========================================================================
// HEADING ANCHOR (Stable GlobalKey for Scrollable.ensureVisible)
// ===========================================================================

class HeadingAnchor {
  final String id;
  final String text;
  final int level;
  final int lineIndex;
  final String rawLine;
  final String messageId;
  final GlobalKey anchorKey;

  HeadingAnchor({
    required this.id,
    required this.text,
    required this.level,
    required this.lineIndex,
    required this.rawLine,
    required this.messageId,
    GlobalKey? anchorKey,
  }) : anchorKey = anchorKey ?? GlobalKey();

  String get uniqueKey => '${messageId}_${level}_${lineIndex}_$text';
}

// ===========================================================================
// ANCHOR REGISTRY (Manages anchors - per-chat instance)
// ===========================================================================

class HeadingAnchorRegistry {
  HeadingAnchorRegistry();

  final Map<String, HeadingAnchor> _anchors = {};

  void registerAnchor(HeadingAnchor anchor) {
    _anchors[anchor.id] = anchor;
  }

  void unregisterAnchor(String id) {
    _anchors.remove(id);
  }

  HeadingAnchor? getAnchor(String id) => _anchors[id];

  List<HeadingAnchor> get allAnchors => _anchors.values.toList();

  void prune(Set<String> keepIds) {
    _anchors.removeWhere((id, _) => !keepIds.contains(id));
  }

  void clear() {
    _anchors.clear();
  }
}

// ===========================================================================
// MARKDOWN HEADING INFO WITH ANCHOR
// ===========================================================================

class MarkdownHeadingInfoWithKey extends MarkdownHeadingInfo {
  final HeadingAnchor anchor;
  final String messageId;

  MarkdownHeadingInfoWithKey({
    required super.text,
    required super.level,
    required super.lineIndex,
    required super.rawLine,
    required this.messageId,
    HeadingAnchor? anchor,
  }) : anchor =
           anchor ??
           HeadingAnchor(
             id: '${messageId}_${level}_${lineIndex}_$text',
             text: text,
             level: level,
             lineIndex: lineIndex,
             rawLine: rawLine,
             messageId: messageId,
           );

  String get uniqueKey => '${messageId}_${level}_${lineIndex}_$text';

  GlobalKey get anchorKey => anchor.anchorKey;
}

// ===========================================================================
// MARKDOWN PARSER WITH KEYS
// ===========================================================================

class MarkdownParserWithKeys {
  static List<MarkdownHeadingInfoWithKey> parseHeadingsWithKeys(
    String content, {
    required String messageId,
  }) {
    final headings = MarkdownParser.parseHeadings(content);
    return headings
        .map(
          (h) => MarkdownHeadingInfoWithKey(
            text: h.text,
            level: h.level,
            lineIndex: h.lineIndex,
            rawLine: h.rawLine,
            messageId: messageId,
          ),
        )
        .toList();
  }

  static List<MarkdownHeadingInfoWithKey> parseAllMessagesHeadings(
    List<dynamic> messages, {
    List<MarkdownHeadingInfoWithKey>? existingHeadings,
    required HeadingAnchorRegistry registry,
  }) {
    final allHeadings = <MarkdownHeadingInfoWithKey>[];

    for (final message in messages) {
      final messageRole = message.role?.toString().split('.').last;
      if (messageRole == 'assistant' && message.content.isNotEmpty) {
        final newHeadings = MarkdownParser.parseHeadings(message.content);

        for (final newHeading in newHeadings) {
          // Try to get existing anchor from registry. The id includes the
          // line index so two identical headings in the same message
          // (e.g. two "## Introduction") never share a GlobalKey.
          final anchorId =
              '${message.id}_${newHeading.level}_${newHeading.lineIndex}_${newHeading.text}';
          HeadingAnchor? existingAnchor = registry.getAnchor(anchorId);

          // Also try to find in existingHeadings if not found in registry
          if (existingAnchor == null && existingHeadings != null) {
            try {
              final existing = existingHeadings.firstWhere(
                (h) =>
                    h.messageId == message.id &&
                    h.level == newHeading.level &&
                    h.text == newHeading.text,
              );
              existingAnchor = existing.anchor;
            } catch (e) {
              // Not found
            }
          }

          final heading = MarkdownHeadingInfoWithKey(
            text: newHeading.text,
            level: newHeading.level,
            lineIndex: newHeading.lineIndex,
            rawLine: newHeading.rawLine,
            anchor: existingAnchor,
            messageId: message.id,
          );

          // Register anchor in per-chat registry
          registry.registerAnchor(heading.anchor);
          allHeadings.add(heading);
        }
      }
    }

    return allHeadings;
  }
}

String stripMarkdownFormatting(String text) {
  String result = text;
  result = result.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'\*([^*]+)\*'),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'__([^_]+)__'),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'_([^_]+)_'),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'\`([^`]+)\`'),
    (m) => m.group(1) ?? '',
  );
  return result.trim();
}
