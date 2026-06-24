import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Centralized truncation service for tool output.
///
/// Behaviour matches opencode/opencode-ai:
///  - Midpoint cut: head + tail are kept, middle is replaced with
///    "... [N lines truncated] ..." sentinel so the LLM understands
///    what was lost.
///  - Disk persistence: the full original text is written to a temp file
///    when truncation happens, so it can be inspected later with Read.
class TruncationService {
  static const _maxOutputChars = 50000;
  static const _retentionDays = 7;
  static const _cleanupIntervalHours = 1;

  static TruncationService? _instance;
  static TruncationService get instance => _instance ??= TruncationService._();

  TruncationService._() {
    _scheduleCleanup();
  }

  Future<Directory> _ensureDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/chatorai_truncation');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Midpoint cut with line-count sentinel.
  ///
  /// Returns original text unchanged when it fits within [_maxOutputChars].
  String truncate(String output) {
    if (output.length <= _maxOutputChars) return output;
    final half = _maxOutputChars ~/ 2;
    final skipped = output.substring(half, output.length - half);
    final linesSkipped = '\n'.allMatches(skipped).length;
    final sentinel = '\n... [$linesSkipped lines truncated] ...\n';
    final tailStart = output.length - half;
    return '${output.substring(0, half)}'
        '$sentinel'
        '${output.substring(tailStart)}';
  }

  /// Write full output to disk and return the file path.
  ///
  /// Caller is responsible for deleting the file when no longer needed,
  /// or rely on periodic cleanup.
  Future<String> write(String fullOutput) async {
    final dir = await _ensureDir();
    final file = File(
      '${dir.path}/tool_${DateTime.now().microsecondsSinceEpoch}.txt',
    );
    await file.writeAsString(fullOutput);
    return file.path;
  }

  /// Delete files older than [_retentionDays].
  Future<void> cleanup() async {
    try {
      final dir = await _ensureDir();
      final cutoff = DateTime.now().subtract(Duration(days: _retentionDays));
      await for (final entity in dir.list()) {
        if (entity is File && entity.lastModifiedSync().isBefore(cutoff)) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Non-fatal: cleanup failures should never break tool execution.
    }
  }

  void _scheduleCleanup() {
    Timer.periodic(Duration(hours: _cleanupIntervalHours), (_) => cleanup());
  }
}
