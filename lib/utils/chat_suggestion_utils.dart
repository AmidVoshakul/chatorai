List<String> parseSuggestions(String responseText) {
  final suggestions = responseText
      .split('\n')
      .map((s) => s.trim())
      .where(
        (s) =>
            s.isNotEmpty &&
            (s.startsWith('-') ||
                s.startsWith('1.') ||
                s.startsWith('2.') ||
                s.startsWith('3.') ||
                s.startsWith('•') ||
                s.length > 10),
      )
      .map(
        (s) => s
            .replaceFirst(RegExp(r'^[-•]\s*'), '')
            .replaceFirst(RegExp(r'^\d+\.\s*'), ''),
      )
      .where((s) => s.length > 5)
      .take(4)
      .toList();

  return suggestions;
}
