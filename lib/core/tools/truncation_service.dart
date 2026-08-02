import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/shared/utils/xdg_paths.dart';

/// Result of a truncation operation.
class TruncationResult {
  final String content;
  final bool truncated;
  final String? outputPath;

  const TruncationResult({
    required this.content,
    required this.truncated,
    this.outputPath,
  });
}

/// Options for truncation.
class TruncationOptions {
  final int? maxLines;
  final int? maxBytes;
  final String direction; // "head" or "tail"

  const TruncationOptions({
    this.maxLines,
    this.maxBytes,
    this.direction = 'head',
  });
}

/// Centralized truncation service for tool output.
///
/// Behaviour:
///  - Byte-aware line truncation with direction (head/tail).
///  - Disk persistence: full original text written to a data-dir file
///    when truncation occurs, so it can be inspected later with Read.
///  - Periodic cleanup of files older than 7 days.
class TruncationService {
  // Legacy midpoint cut limit still used by built-in tools.
  static const _maxOutputChars = 50000;

  // New structured truncation defaults (UTF-8 byte count, used by compute()).
  static const _defaultMaxLines = 2000;
  static const _defaultMaxBytes = 50 * 1024; // 50 KB

  static const _retentionDays = 7;
  static const _cleanupIntervalHours = 1;

  Directory? _dataDir;

  static TruncationService? _instance;
  static TruncationService get instance => _instance ??= TruncationService._();

  TruncationService._() {
    _scheduleCleanup();
  }

  Future<Directory> _ensureDir() async {
    if (_dataDir != null) return _dataDir!;
    final dir = await XdgPaths.dataSubdirAsync('tool-output');
    _dataDir = dir;
    return dir;
  }

  /// Resolved truncation limits — currently uses hardcoded defaults.
  TruncationOptions limits() {
    return const TruncationOptions(
      maxLines: _defaultMaxLines,
      maxBytes: _defaultMaxBytes,
    );
  }

  /// Pure truncation algorithm — no I/O, no side effects.
  ///
  /// Returns a [TruncationResult] describing the truncated preview. When
  /// [truncated] is true the caller is expected to write the original text
  /// to disk and return the file path through [output()] (or handle the
  /// full-original flow independently).
  static TruncationResult compute(
    String text, {
    TruncationOptions? options,
    bool hasTaskTool = false,
  }) {
    final resolved = options ?? const TruncationOptions();
    final maxLines = resolved.maxLines ?? _defaultMaxLines;
    final maxBytes = resolved.maxBytes ?? _defaultMaxBytes;
    final direction = resolved.direction;

    final lines = text.split('\n');
    final totalBytes = utf8.encode(text).length;

    if (lines.length <= maxLines && totalBytes <= maxBytes) {
      return TruncationResult(content: text, truncated: false);
    }

    final out = <String>[];
    var bytes = 0;
    var hitBytes = false;

    if (direction == 'head') {
      for (var i = 0; i < lines.length && i < maxLines; i++) {
        final lineBytes = utf8.encode(lines[i]).length;
        final size = lineBytes + (i > 0 ? 1 : 0);
        if (bytes + size > maxBytes) {
          hitBytes = true;
          break;
        }
        out.add(lines[i]);
        bytes += size;
      }
    } else {
      for (var i = lines.length - 1; i >= 0 && out.length < maxLines; i--) {
        final lineBytes = utf8.encode(lines[i]).length;
        final size = lineBytes + (out.isNotEmpty ? 1 : 0);
        if (bytes + size > maxBytes) {
          hitBytes = true;
          break;
        }
        out.insert(0, lines[i]);
        bytes += size;
      }
    }

    final removed = hitBytes ? totalBytes - bytes : lines.length - out.length;
    final unit = hitBytes ? 'bytes' : 'lines';
    final preview = out.join('\n');

    final hint = hasTaskTool
        ? 'The tool call succeeded but the output was truncated. '
              'Full output saved to disk.\n'
              'Use the Task tool to have explore agent process this file with '
              'Grep and Read (with offset/limit). Do NOT read the full file '
              'yourself - delegate to save context.'
        : 'The tool call succeeded but the output was truncated. '
              'Full output saved to disk.\n'
              'Use Grep to search the full content or Read with offset/limit '
              'to view specific sections.';

    final content = direction == 'head'
        ? '$preview\n\n...$removed $unit truncated...\n\n$hint'
        : '...$removed $unit truncated...\n\n$hint\n\n$preview';

    return TruncationResult(content: content, truncated: true);
  }

  /// Full truncation API matching  Truncate.output().
  ///
  /// Calls [compute] for the truncation logic and writes the original text
  /// to disk when truncation occurs.
  Future<TruncationResult> output(
    String text, {
    TruncationOptions? options,
    bool hasTaskTool = false,
  }) async {
    final resolved = options ?? limits();
    final result = TruncationService.compute(
      text,
      options: resolved,
      hasTaskTool: hasTaskTool,
    );
    if (result.truncated) {
      final filePath = await write(text);
      final contentWithPath = result.content.replaceFirst(
        'saved to disk',
        'saved to: $filePath',
      );
      return TruncationResult(
        content: contentWithPath,
        truncated: true,
        outputPath: filePath,
      );
    }
    return result;
  }

  /// Midpoint cut with line-count sentinel (legacy compatibility).
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
