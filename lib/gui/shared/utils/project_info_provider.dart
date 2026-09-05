import 'dart:io';

import 'package:chatorai/gui/shared/workspace/workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shortens an absolute path against the user's home directory, mirroring
///  `abbreviateHome`: home becomes `~`, paths inside home become
/// `~/relative`, everything else is returned unchanged.
String shortenPath(String path, [String? home]) {
  home ??= Platform.isWindows
      ? Platform.environment['USERPROFILE']
      : Platform.environment['HOME'];
  if (home == null || home.isEmpty) return path;
  final separator = Platform.pathSeparator;
  final normalizedHome = home.endsWith(separator) ? home : '$home$separator';
  if (path == home) return '~';
  if (path.startsWith(normalizedHome)) {
    return '~$separator${path.substring(normalizedHome.length)}';
  }
  return path;
}

/// The current working directory, shortened for display.
final workingDirProvider = Provider<String>((ref) {
  return shortenPath(ref.watch(workspaceProvider).currentPath);
});

/// The raw absolute path of the current working directory.
final absoluteWorkingDirProvider = Provider<String>((ref) {
  return ref.watch(workspaceProvider).currentPath;
});

/// The current git branch of the working directory, or `null` when not in a
/// git repository or git is unavailable.
final gitBranchProvider = FutureProvider<String?>((ref) {
  final cwd = ref.watch(workspaceProvider).currentPath;
  return resolveGitBranch(cwd);
});

Future<String?> resolveGitBranch(String workingDirectory) async {
  try {
    final result = await Process.run(
      'git',
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      runInShell: true,
      workingDirectory: workingDirectory,
    );
    if (result.exitCode == 0) {
      final branch = (result.stdout as String? ?? '').trim();
      return branch.isNotEmpty ? branch : null;
    }
  } catch (_) {
    // Not a git repository or git is unavailable.
  }
  return null;
}
