/// Утилита для парсинга Markdown заголовков
class MarkdownParser {
  /// Парсит заголовки из Markdown текста
  /// Поддерживает уровни: #, ##, ###
  static List<MarkdownHeadingInfo> parseHeadings(String content) {
    final lines = content.split('\n');
    final headings = <MarkdownHeadingInfo>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Парсим заголовки #, ##, ###
      if (line.startsWith('# ')) {
        headings.add(
          MarkdownHeadingInfo(
            text: line.substring(2).trim(),
            level: 1,
            lineIndex: i,
            rawLine: line,
          ),
        );
      } else if (line.startsWith('## ')) {
        headings.add(
          MarkdownHeadingInfo(
            text: line.substring(3).trim(),
            level: 2,
            lineIndex: i,
            rawLine: line,
          ),
        );
      } else if (line.startsWith('### ')) {
        headings.add(
          MarkdownHeadingInfo(
            text: line.substring(4).trim(),
            level: 3,
            lineIndex: i,
            rawLine: line,
          ),
        );
      }
    }

    return headings;
  }

  /// Проверяет, есть ли заголовки в тексте
  static bool hasHeadings(String content) {
    return parseHeadings(content).isNotEmpty;
  }

  /// Получает количество заголовков каждого уровня
  static Map<int, int> getHeadingCounts(List<MarkdownHeadingInfo> headings) {
    final counts = <int, int>{};
    for (var heading in headings) {
      counts[heading.level] = (counts[heading.level] ?? 0) + 1;
    }
    return counts;
  }

  /// Получает текст для отображения в навигаторе (сокращенный)
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
