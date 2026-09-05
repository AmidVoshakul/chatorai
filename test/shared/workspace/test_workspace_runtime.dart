import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/workspace/workspace_runtime.dart';

void main() {
  group('resolveInitialWorkspace', () {
    test('cliPath wins over valid lastUsed', () async {
      final result = await resolveInitialWorkspace(
        cliPath: '/tmp/cli_workspace',
        readLastUsed: () async => '/tmp/last_used',
      );
      expect(result, '/tmp/cli_workspace');
    });

    test('valid lastUsed used when no cliPath', () async {
      final lastUsed = '/tmp/last_used';
      Directory(lastUsed).createSync(recursive: true);
      final result = await resolveInitialWorkspace(
        cliPath: null,
        readLastUsed: () async => lastUsed,
      );
      expect(result, lastUsed);
      Directory(lastUsed).deleteSync(recursive: true);
    });

    test(
      'non-existent lastUsed falls back to Directory.current.path',
      () async {
        final result = await resolveInitialWorkspace(
          cliPath: null,
          readLastUsed: () async => '/tmp/nonexistent_workspace_12345',
        );
        expect(result, Directory.current.path);
      },
    );

    test('empty cliPath treated as absent', () async {
      final lastUsed = '/tmp/last_used';
      Directory(lastUsed).createSync(recursive: true);
      final result = await resolveInitialWorkspace(
        cliPath: '',
        readLastUsed: () async => lastUsed,
      );
      expect(result, lastUsed);
      Directory(lastUsed).deleteSync(recursive: true);
    });

    test('empty lastUsed falls back to Directory.current.path', () async {
      final result = await resolveInitialWorkspace(
        cliPath: null,
        readLastUsed: () async => '',
      );
      expect(result, Directory.current.path);
    });

    test('null lastUsed falls back to Directory.current.path', () async {
      final result = await resolveInitialWorkspace(
        cliPath: null,
        readLastUsed: () async => null,
      );
      expect(result, Directory.current.path);
    });
  });

  group('setRuntimeCwd', () {
    test('updates workspaceRuntimeCurrent', () async {
      final original = workspaceRuntimeCurrent.path;
      final newPath = Directory.systemTemp
          .createTempSync('ws_runtime_test_')
          .path;
      setRuntimeCwd(newPath);
      expect(workspaceRuntimeCurrent.path, newPath);
      setRuntimeCwd(original);
    });
  });
}
