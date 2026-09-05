import 'dart:io';

/// Legacy global runtime CWD.
///
/// This global is retained for backward compatibility with existing utilities
/// that have not yet been migrated to Riverpod. New code should read the
/// current workspace path via `ref.watch(workspaceProvider).currentPath` and
/// avoid mutating this global directly. The [WorkspaceSwitcher] keeps this
/// global in sync with [Directory.current] during workspace switches.
Directory workspaceRuntimeCurrent = Directory.current;

void setRuntimeCwd(String path) {
  workspaceRuntimeCurrent = Directory(path);
}

const String lastWorkspacePrefsKey = 'last_workspace';
const String knownWorkspacesPrefsKey = 'known_workspaces';

Future<String> resolveInitialWorkspace({
  required String? cliPath,
  required Future<String?> Function() readLastUsed,
}) async {
  if (cliPath != null && cliPath.isNotEmpty) return cliPath;
  final last = await readLastUsed();
  if (last != null && last.isNotEmpty && Directory(last).existsSync()) {
    return last;
  }
  return Directory.current.path;
}
