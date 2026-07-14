bool match(String input, String pattern) {
  final normalized = input.replaceAll(r'\', '/');
  final escaped = pattern
      .replaceAll(r'\', '/')
      .replaceAllMapped(RegExp(r'[.+^${}()|[\]\\]'), (m) => '\\${m[0]}')
      .replaceAll('*', '.*')
      .replaceAll('?', '.');

  final patternRegex = escaped.endsWith(' .*')
      ? '^${escaped.substring(0, escaped.length - 3)}( .*)?\$'
      : '^$escaped\$';

  return RegExp(
    patternRegex,
    caseSensitive: false,
    multiLine: true,
    dotAll: true,
  ).hasMatch(normalized);
}
