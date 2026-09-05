/// Pattern cache to avoid re-compiling RegExp on every match call.
final _patternCache = <String, RegExp>{};
const _maxCacheSize = 256;

bool match(String input, String pattern) {
  final normalized = input.replaceAll(r'\', '/');
  final escaped = pattern
      .replaceAll(r'\', '/')
      .replaceAllMapped(RegExp(r'[.+^${}()|[\]\\]'), (m) => '\\${m[0]}')
      .replaceAll('*', '.*')
      .replaceAll('?', '.');

  final regexStr = escaped.endsWith(' .*')
      ? '^${escaped.substring(0, escaped.length - 3)}( .*)?\$'
      : '^$escaped\$';

  final regex = _patternCache.putIfAbsent(regexStr, () {
    if (_patternCache.length >= _maxCacheSize) {
      _patternCache.clear();
    }
    return RegExp(
      regexStr,
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );
  });

  return regex.hasMatch(normalized);
}
