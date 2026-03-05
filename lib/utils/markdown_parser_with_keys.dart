import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_models.dart' as models;
import 'markdown_parser.dart';

class MarkdownHeadingInfoWithKey extends MarkdownHeadingInfo {
  final GlobalKey key;
  final String messageId;

  MarkdownHeadingInfoWithKey({
    required String text,
    required int level,
    required int lineIndex,
    required String rawLine,
    required this.key,
    required this.messageId,
  }) : super(text: text, level: level, lineIndex: lineIndex, rawLine: rawLine);

  String get uniqueKey => '${messageId}_${level}_$text';
}

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
            key: GlobalKey(
              debugLabel: 'heading_${messageId}_${h.level}_${h.text}',
            ),
            messageId: messageId,
          ),
        )
        .toList();
  }

  static List<MarkdownHeadingInfoWithKey> parseAllMessagesHeadings(
    List<models.Message> messages, {
    List<MarkdownHeadingInfoWithKey>? existingHeadings,
  }) {
    final allHeadings = <MarkdownHeadingInfoWithKey>[];

    for (final message in messages) {
      if (message.role == models.MessageRole.assistant &&
          message.content.isNotEmpty) {
        final newHeadings = MarkdownParser.parseHeadings(message.content);

        for (final newHeading in newHeadings) {
          // Try to find existing heading with same messageId, level, and text
          MarkdownHeadingInfoWithKey? existingHeading;
          if (existingHeadings != null) {
            try {
              existingHeading = existingHeadings.firstWhere(
                (h) =>
                    h.messageId == message.id &&
                    h.level == newHeading.level &&
                    h.text == newHeading.text,
              );
            } catch (e) {
              existingHeading = null;
            }
          }

          // Use existing key if found, otherwise create new one
          if (existingHeading != null) {
            allHeadings.add(
              MarkdownHeadingInfoWithKey(
                text: newHeading.text,
                level: newHeading.level,
                lineIndex: newHeading.lineIndex,
                rawLine: newHeading.rawLine,
                key: existingHeading.key,
                messageId: message.id,
              ),
            );
          } else {
            allHeadings.add(
              MarkdownHeadingInfoWithKey(
                text: newHeading.text,
                level: newHeading.level,
                lineIndex: newHeading.lineIndex,
                rawLine: newHeading.rawLine,
                key: GlobalKey(
                  debugLabel:
                      'heading_${message.id}_${newHeading.level}_${newHeading.text}',
                ),
                messageId: message.id,
              ),
            );
          }
        }
      }
    }

    return allHeadings;
  }

  static MarkdownHeadingInfoWithKey? findHeadingByKey(
    List<MarkdownHeadingInfoWithKey> headings,
    String messageId,
    int level,
    String text,
  ) {
    try {
      return headings.firstWhere(
        (h) => h.messageId == messageId && h.level == level && h.text == text,
      );
    } catch (e) {
      return null;
    }
  }
}
