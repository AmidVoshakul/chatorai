import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ToolOutputBoundingResult {
  final String content;
  final bool truncated;
  final String? outputPath;

  const ToolOutputBoundingResult({
    required this.content,
    required this.truncated,
    this.outputPath,
  });
}

class ToolOutputBoundingService {
  static const _defaultMaxLines = 2000;
  static const _defaultMaxBytes = 50 * 1024;
  static const _retentionDays = 7;
  static const _cleanupIntervalHours = 1;

  static ToolOutputBoundingService? _instance;
  static ToolOutputBoundingService get instance =>
      _instance ??= ToolOutputBoundingService._();

  Directory? _dataDir;
  Timer? _cleanupTimer;

  ToolOutputBoundingService._() {
    startCleanupTimer();
  }

  Future<Directory> get _ensureDir async {
    if (_dataDir != null) return _dataDir!;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/chatorai/tool-output');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dataDir = dir;
    return dir;
  }

  ToolOutputBoundingResult compute(
    String text, {
    int? maxLines,
    int? maxBytes,
    bool hasTaskTool = false,
  }) {
    final resolvedMaxLines = maxLines ?? _defaultMaxLines;
    final resolvedMaxBytes = maxBytes ?? _defaultMaxBytes;

    final lines = text.split('\n');
    final totalBytes = utf8.encode(text).length;

    if (lines.length <= resolvedMaxLines && totalBytes <= resolvedMaxBytes) {
      return ToolOutputBoundingResult(content: text, truncated: false);
    }

    final out = <String>[];
    var bytes = 0;
    var hitBytes = false;

    for (var i = 0; i < lines.length && i < resolvedMaxLines; i++) {
      final lineBytes = utf8.encode(lines[i]).length;
      final size = lineBytes + (i > 0 ? 1 : 0);
      if (bytes + size > resolvedMaxBytes) {
        hitBytes = true;
        break;
      }
      out.add(lines[i]);
      bytes += size;
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

    final content = '$preview\n\n...$removed $unit truncated...\n\n$hint';

    return ToolOutputBoundingResult(content: content, truncated: true);
  }

  Future<ToolOutputBoundingResult> bound(
    String text, {
    int? maxLines,
    int? maxBytes,
    bool hasTaskTool = false,
  }) async {
    final result = compute(
      text,
      maxLines: maxLines,
      maxBytes: maxBytes,
      hasTaskTool: hasTaskTool,
    );
    if (result.truncated) {
      final filePath = await write(text);
      final contentWithPath = result.content.replaceFirst(
        'saved to disk',
        'saved to: $filePath',
      );
      return ToolOutputBoundingResult(
        content: contentWithPath,
        truncated: true,
        outputPath: filePath,
      );
    }
    return result;
  }

  Future<String> write(String fullOutput) async {
    final dir = await _ensureDir;
    final file = File(
      '${dir.path}/tool_${DateTime.now().microsecondsSinceEpoch}.txt',
    );
    await file.writeAsString(fullOutput);
    return file.path;
  }

  Future<void> cleanup() async {
    try {
      final dir = await _ensureDir;
      final cutoff = DateTime.now().subtract(
        const Duration(days: _retentionDays),
      );
      await for (final entity in dir.list()) {
        if (entity is File && entity.lastModifiedSync().isBefore(cutoff)) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Non-fatal: cleanup failures should never break tool execution.
    }
  }

  void startCleanupTimer() {
    _cleanupTimer ??= Timer.periodic(
      const Duration(hours: _cleanupIntervalHours),
      (_) => cleanup(),
    );
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _dataDir = null;
  }
}
