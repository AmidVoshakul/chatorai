import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:path/path.dart' as p;

enum ToolResultStatus { success, error }

class ToolOutputPersistence {
  static ToolOutputPersistence? _instance;

  Directory? _outputDir;
  Timer? _cleanupTimer;

  static const Duration _defaultMaxAge = Duration(days: 7);
  static const Duration _cleanupInterval = Duration(hours: 1);

  static ToolOutputPersistence get instance {
    _instance ??= ToolOutputPersistence();
    return _instance!;
  }

  Future<Directory> get outputDir async {
    if (_outputDir != null) return _outputDir!;
    final dir = await XdgPaths.dataSubdirAsync('tool-output');
    _outputDir = dir;
    return dir;
  }

  void initialize() {
    if (_cleanupTimer != null) return;
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      unawaited(_runCleanup());
    });
    unawaited(_runCleanup());
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _outputDir = null;
  }

  Future<void> saveResult({
    required String toolCallId,
    required String toolName,
    required Map<String, dynamic>? input,
    required String output,
    required String? sessionId,
    required int durationMs,
    required ToolResultStatus status,
  }) async {
    final dir = await outputDir;
    final tempPath = p.join(dir.path, '.$toolCallId.tmp');
    final finalPath = p.join(dir.path, '$toolCallId.json');

    final data = jsonEncode({
      'toolCallId': toolCallId,
      'toolName': toolName,
      'input': input,
      'output': output,
      'sessionId': sessionId,
      'durationMs': durationMs,
      'status': status.name,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final tempFile = File(tempPath);
    await tempFile.writeAsString(data);

    try {
      await tempFile.rename(finalPath);
    } catch (_) {
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> _runCleanup({Duration maxAge = _defaultMaxAge}) async {
    try {
      final dir = await outputDir;
      final entries = dir.listSync();
      final cutoff = DateTime.now().subtract(maxAge);
      for (final entry in entries) {
        if (entry is File &&
            (entry.path.endsWith('.json') || entry.path.endsWith('.tmp'))) {
          try {
            final isTmp = entry.path.endsWith('.tmp');
            if (isTmp) {
              await entry.delete();
            } else {
              final stat = entry.statSync();
              if (stat.modified.isBefore(cutoff)) {
                await entry.delete();
              }
            }
          } catch (e) {
            LogTags.storage.logWarning(
              'ToolOutputPersistence cleanup failed for ${entry.path}: $e',
            );
          }
        }
      }
    } catch (e) {
      LogTags.storage.logWarning('ToolOutputPersistence cleanup error: $e');
    }
  }
}
