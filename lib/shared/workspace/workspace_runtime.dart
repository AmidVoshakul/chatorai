import 'dart:io';

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
