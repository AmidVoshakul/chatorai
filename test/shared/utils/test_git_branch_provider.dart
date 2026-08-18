import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/shared/utils/project_info_provider.dart';
import 'package:chatorai/shared/workspace/workspace_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveGitBranch', () {
    test('returns branch name for a git repo', () async {
      final tempDir = Directory.systemTemp.createTempSync('git_branch_test_');
      final initResult = await Process.run('git', [
        'init',
        '-q',
        '-b',
        'main',
      ], workingDirectory: tempDir.path);
      if (initResult.exitCode != 0) {
        tempDir.deleteSync(recursive: true);
        return; // skip silently if git unavailable
      }

      // Create an initial commit so HEAD points to a valid branch.
      final configFile = File('${tempDir.path}/.gitignore');
      await configFile.writeAsString('');
      final addResult = await Process.run('git', [
        'add',
        '.gitignore',
      ], workingDirectory: tempDir.path);
      if (addResult.exitCode != 0) {
        tempDir.deleteSync(recursive: true);
        return;
      }
      final commitResult = await Process.run('git', [
        'commit',
        '-q',
        '-m',
        'init',
      ], workingDirectory: tempDir.path);
      if (commitResult.exitCode != 0) {
        tempDir.deleteSync(recursive: true);
        return;
      }

      final branch = await resolveGitBranch(tempDir.path);
      expect(branch, 'main');

      tempDir.deleteSync(recursive: true);
    });

    test('returns null for non-git directory', () async {
      final tempDir = Directory.systemTemp.createTempSync('non_git_test_');
      final branch = await resolveGitBranch(tempDir.path);
      expect(branch, isNull);
      tempDir.deleteSync(recursive: true);
    });
  });

  group('gitBranchProvider integration', () {
    test('picks up workspace from workspaceProvider', () async {
      SharedPreferences.setMockInitialValues({});
      final tempDir = Directory.systemTemp.createTempSync(
        'git_branch_provider_test_',
      );
      final initResult = await Process.run('git', [
        'init',
        '-q',
        '-b',
        'main',
      ], workingDirectory: tempDir.path);
      if (initResult.exitCode != 0) {
        tempDir.deleteSync(recursive: true);
        return; // skip silently if git unavailable
      }

      // Create an initial commit so HEAD points to a valid branch.
      final configFile = File('${tempDir.path}/.gitignore');
      await configFile.writeAsString('');
      final addResult = await Process.run('git', [
        'add',
        '.gitignore',
      ], workingDirectory: tempDir.path);
      if (addResult.exitCode != 0) {
        tempDir.deleteSync(recursive: true);
        return;
      }
      final commitResult = await Process.run('git', [
        'commit',
        '-q',
        '-m',
        'init',
      ], workingDirectory: tempDir.path);
      if (commitResult.exitCode != 0) {
        tempDir.deleteSync(recursive: true);
        return;
      }

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(workspaceProvider.notifier);
      await notifier.init();
      await notifier.switchWorkspace(tempDir.path);

      final branch = await container.read(gitBranchProvider.future);
      expect(branch, 'main');

      tempDir.deleteSync(recursive: true);
    });
  });
}
