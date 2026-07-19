// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:io';

/// ANSI styling helpers shared by all ChatORAI CLI commands for a premium,
/// consistent render (matching the `chatorai mcp list` aesthetic).
class CliStyle {
  CliStyle._();

  static const String reset = '\x1b[0m';
  static const String dim = '\x1b[2m';
  static const String bold = '\x1b[1m';
  static const String green = '\x1b[38;2;120;200;120m';
  static const String red = '\x1b[38;2;240;120;120m';
  static const String yellow = '\x1b[38;2;230;190;110m';
  static const String cyan = '\x1b[38;2;120;200;230m';
  static const String gray = '\x1b[38;2;130;140;155m';

  /// True when stdout is a real interactive terminal (enables animation).
  static bool get isTerminal => stdout.hasTerminal;

  static String dim_(String s) => '$dim$s$reset';
  static String bold_(String s) => '$bold$s$reset';
  static String green_(String s) => '$green$s$reset';
  static String red_(String s) => '$red$s$reset';
  static String yellow_(String s) => '$yellow$s$reset';
  static String cyan_(String s) => '$cyan$s$reset';
  static String gray_(String s) => '$gray$s$reset';

  /// Print a line using the block-frame indent (`│ `) used by all panels.
  static void line(String content) {
    print('$gray│$reset $content');
  }

  /// The top of a panel: `┌ <header>`.
  static void panelStart(String header) {
    print('$gray┌$reset ${bold_(cyan_(header))}');
    line('');
  }

  /// The bottom of a panel: `└ <footer>`.
  static void panelEnd(String footer) {
    print('$gray└$reset ${gray_(footer)}');
  }
}
