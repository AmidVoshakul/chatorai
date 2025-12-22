import 'package:flutter/material.dart';
import 'markdown_parser.dart';

/// Расширенная версия MarkdownHeadingInfo с GlobalKey для прокрутки
class MarkdownHeadingInfoWithKey extends MarkdownHeadingInfo {
  final GlobalKey key;

  MarkdownHeadingInfoWithKey({
    required String text,
    required int level,
    required int lineIndex,
    required String rawLine,
    required this.key,
  }) : super(
          text: text,
          level: level,
          lineIndex: lineIndex,
          rawLine: rawLine,
        );
}

/// Парсер Markdown с поддержкой GlobalKey
class MarkdownParserWithKeys {
  /// Парсит заголовки и создаёт объекты с GlobalKey
  static List<MarkdownHeadingInfoWithKey> parseHeadingsWithKeys(String content) {
    final headings = MarkdownParser.parseHeadings(content);
    return headings
        .map(
          (h) => MarkdownHeadingInfoWithKey(
            text: h.text,
            level: h.level,
            lineIndex: h.lineIndex,
            rawLine: h.rawLine,
            key: GlobalKey(),
          ),
        )
        .toList();
  }

  /// Обновляет существующие заголовки (сохраняя ключи) для нового контента
  static List<MarkdownHeadingInfoWithKey> updateHeadings(
    List<MarkdownHeadingInfoWithKey> oldHeadings,
    String newContent,
  ) {
    final newHeadings = MarkdownParser.parseHeadings(newContent);
    final result = <MarkdownHeadingInfoWithKey>[];

    for (var newHeading in newHeadings) {
      // Пытаемся найти старый заголовок с таким же текстом и уровнем
      final oldHeading = oldHeadings.firstWhere(
        (h) => h.text == newHeading.text && h.level == newHeading.level,
        orElse: () => MarkdownHeadingInfoWithKey(
          text: newHeading.text,
          level: newHeading.level,
          lineIndex: newHeading.lineIndex,
          rawLine: newHeading.rawLine,
          key: GlobalKey(),
        ),
      );
      
      // Создаём новый объект с обновлёнными данными, но старым ключом
      result.add(
        MarkdownHeadingInfoWithKey(
          text: newHeading.text,
          level: newHeading.level,
          lineIndex: newHeading.lineIndex,
          rawLine: newHeading.rawLine,
          key: oldHeading.key,
        ),
      );
    }

    return result;
  }
}
