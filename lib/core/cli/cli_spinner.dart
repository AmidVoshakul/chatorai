// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:chatorai/core/cli/cli_style.dart';

/// A minimal terminal spinner that animates in place on a TTY and degrades to
/// static lines when output is piped (CI / non-interactive).
class CliSpinner {
  CliSpinner(this.label);

  final String label;
  final List<String> _frames = const [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏',
  ];

  Timer? _timer;
  int _index = 0;

  /// Begin animating. Writes nothing visible on a non-TTY.
  void start() {
    if (!CliStyle.isTerminal) {
      stderr.writeln('${CliStyle.gray_('│')} $label...');
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final frame = _frames[_index % _frames.length];
      stderr.write(
        '\r\x1b[K${CliStyle.gray_('│')} $frame ${CliStyle.dim_(label)}',
      );
      _index++;
    });
  }

  /// Stop the animation, replacing the line with a final [done] marker or a
  /// default green check.
  void stop([String? done]) {
    _timer?.cancel();
    _timer = null;
    final result = done ?? '${CliStyle.green_('✓')} ${CliStyle.dim_(label)}';
    if (CliStyle.isTerminal) {
      stderr.write('\r\x1b[K${CliStyle.gray_('│')} $result\n');
    } else {
      stderr.writeln('${CliStyle.gray_('│')} $result');
    }
  }

  /// Stop with a failure marker (red ✗).
  void fail(String message) {
    stop('${CliStyle.red_('✗')} ${CliStyle.dim_(message)}');
  }
}
