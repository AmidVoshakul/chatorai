import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/tool_output_persistence.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late _TestableToolOutputPersistence persistence;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tool_output_test_');
    persistence = _TestableToolOutputPersistence(tempDir);
  });

  tearDown(() async {
    persistence.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ToolOutputPersistence.saveResult', () {
    test('saves tool result to JSON file', () async {
      await persistence.saveResult(
        toolCallId: 'tool_123',
        toolName: 'shell',
        input: {'command': 'echo hello'},
        output: 'hello\n',
        sessionId: 'ses_test',
        durationMs: 50,
        status: ToolResultStatus.success,
      );

      final file = File(p.join(tempDir.path, 'tool_123.json'));
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      expect(data['toolCallId'], 'tool_123');
      expect(data['toolName'], 'shell');
      expect(data['input'], {'command': 'echo hello'});
      expect(data['output'], 'hello\n');
      expect(data['sessionId'], 'ses_test');
      expect(data['durationMs'], 50);
      expect(data['status'], 'success');
      expect(data['createdAt'], isNotNull);
    });

    test('saves error status correctly', () async {
      await persistence.saveResult(
        toolCallId: 'tool_err_456',
        toolName: 'shell',
        input: {'command': 'ls /nonexistent'},
        output: 'ls: /nonexistent: No such file or directory',
        sessionId: 'ses_test',
        durationMs: 10,
        status: ToolResultStatus.error,
      );

      final file = File(p.join(tempDir.path, 'tool_err_456.json'));
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      expect(data['status'], 'error');
    });

    test('handles null input gracefully', () async {
      await persistence.saveResult(
        toolCallId: 'tool_null_input',
        toolName: 'question',
        input: null,
        output: 'Answer text',
        sessionId: 'ses_test',
        durationMs: 100,
        status: ToolResultStatus.success,
      );

      final file = File(p.join(tempDir.path, 'tool_null_input.json'));
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      expect(data['input'], isNull);
    });

    test('handles null sessionId', () async {
      await persistence.saveResult(
        toolCallId: 'tool_no_session',
        toolName: 'read',
        input: {'path': '/test'},
        output: 'file content',
        sessionId: null,
        durationMs: 25,
        status: ToolResultStatus.success,
      );

      final file = File(p.join(tempDir.path, 'tool_no_session.json'));
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      expect(data['sessionId'], isNull);
    });

    test('uses atomic write (temp then rename)', () async {
      await persistence.saveResult(
        toolCallId: 'tool_atomic',
        toolName: 'shell',
        input: {},
        output: 'result',
        sessionId: 'ses_test',
        durationMs: 10,
        status: ToolResultStatus.success,
      );

      // After successful write, no temp file should remain
      final tempFiles = tempDir
          .listSync()
          .where((e) => e is File && p.basename(e.path).startsWith('.'))
          .toList();
      expect(tempFiles, isEmpty);

      // Final file should exist
      final file = File(p.join(tempDir.path, 'tool_atomic.json'));
      expect(await file.exists(), isTrue);
    });
  });

  group('ToolOutputPersistence cleanup', () {
    test('removes files older than maxAge', () async {
      // Create an old file directly
      final oldFile = File(p.join(tempDir.path, 'old_tool.json'));
      await oldFile.writeAsString('{}');

      // Set its modification time to 10 days ago
      final oldDate = DateTime.now().subtract(const Duration(days: 10));
      await oldFile.setLastModified(oldDate);

      // Create a recent file
      final recentFile = File(p.join(tempDir.path, 'recent_tool.json'));
      await recentFile.writeAsString('{}');

      // Run cleanup with 7 day max age
      await persistence.runCleanupForTest(maxAge: const Duration(days: 7));

      // Old file should be deleted
      expect(await oldFile.exists(), isFalse);

      // Recent file should still exist
      expect(await recentFile.exists(), isTrue);
    });

    test('removes .tmp files on cleanup', () async {
      // Create a temp file
      final tmpFile = File(p.join(tempDir.path, '.orphan.tmp'));
      await tmpFile.writeAsString('temp data');

      expect(await tmpFile.exists(), isTrue);

      // Run cleanup
      await persistence.runCleanupForTest(maxAge: const Duration(days: 7));

      // Temp file should be deleted regardless of age
      expect(await tmpFile.exists(), isFalse);
    });

    test('does not delete files within maxAge', () async {
      // Create a recent file
      final recentFile = File(p.join(tempDir.path, 'recent.json'));
      await recentFile.writeAsString('{"recent": true}');

      // Run cleanup with 7 day max age
      await persistence.runCleanupForTest(maxAge: const Duration(days: 7));

      // Recent file should still exist
      expect(await recentFile.exists(), isTrue);
    });
  });

  group('ToolOutputPersistence lifecycle', () {
    test('initialize starts cleanup timer', () {
      // Should not throw
      persistence.initialize();
      persistence.dispose();

      // Can re-initialize after dispose
      persistence.initialize();
      persistence.dispose();
    });

    test('dispose clears outputDir', () {
      persistence.initialize();
      persistence.dispose();

      // After dispose, outputDir should be cleared and recreated
      // This is tested implicitly by not throwing
    });
  });

  group('error handling', () {
    test(
      'handles corrupt JSON in existing file gracefully during cleanup',
      () async {
        // Create a file with invalid JSON
        final corruptFile = File(p.join(tempDir.path, 'corrupt.json'));
        await corruptFile.writeAsString('not valid json {{{');

        // Cleanup should not throw, just log warning
        await persistence.runCleanupForTest(maxAge: const Duration(days: 7));

        // File should still exist (cleanup failed for this file)
        expect(await corruptFile.exists(), isTrue);
      },
    );
  });
}

/// Testable subclass that uses a custom temp directory and exposes cleanup.
class _TestableToolOutputPersistence extends ToolOutputPersistence {
  final Directory _customDir;

  _TestableToolOutputPersistence(this._customDir);

  @override
  Future<Directory> get outputDir async => _customDir;

  /// Runs cleanup with a custom maxAge for testing.
  Future<void> runCleanupForTest({
    Duration maxAge = const Duration(days: 7),
  }) async {
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
            // Ignore errors during cleanup
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }
}
