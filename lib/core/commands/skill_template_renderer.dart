/// Pure-Dart rendering of skill content templates.
///
/// Shared by GUI and TUI so both substitute arguments identically.
/// Supports `$1`, `$2`, ..., last `$N` consumes remaining args, `$ARGUMENTS`,
/// quoted arguments and `[Image N]` placeholders.
class SkillTemplateRenderer {
  const SkillTemplateRenderer._();

  /// Renders [content] with [arguments] substituted.
  ///
  /// - `$N` (1-based) maps to Nth whitespace-separated argument; highest N
  ///   consumes all remaining args.
  /// - `$ARGUMENTS` expands to raw, unsplit [arguments].
  /// - Template without placeholders appends trimmed [arguments] as paragraph.
  static String render(String content, String arguments) {
    final argsRegex = RegExp(
      r'''(?:\[Image\s+\d+\]|"[^"]*"|'[^']*'|[^\s"']+)''',
    );
    final rawArgs = argsRegex
        .allMatches(arguments)
        .map((m) => m.group(0)!)
        .toList();
    final quoteTrim = RegExp(r"""^["']|["']$""");
    final args = rawArgs.map((a) => a.replaceAll(quoteTrim, '')).toList();

    final placeholderRegex = RegExp(r'''\$(\d+)''');
    final matches = placeholderRegex.allMatches(content).toList();
    final placeholders = matches.map((m) => int.parse(m.group(1)!)).toList();
    final last = placeholders.isEmpty
        ? 0
        : placeholders.reduce((a, b) => a > b ? a : b);

    var result = content.replaceAllMapped(placeholderRegex, (match) {
      final position = int.parse(match.group(1)!);
      if (position < 1) return '';
      final argIndex = position - 1;
      if (argIndex >= args.length) return '';
      if (position == last) {
        return args.sublist(argIndex).join(' ');
      }
      return args[argIndex];
    });

    final usesArguments = content.contains(r'$ARGUMENTS');
    result = result.replaceAll(r'$ARGUMENTS', arguments);
    if (placeholders.isEmpty && !usesArguments && arguments.trim().isNotEmpty) {
      result = '$result\n\n${arguments.trim()}';
    }
    return result.trim();
  }
}
