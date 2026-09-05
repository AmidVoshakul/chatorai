import 'dart:io';

/// Single shared rule for "which project folder is current".
///
/// Both sides implement it: the app (via the folder list screen)
/// and the terminal (via the launch folder). Settings and tools
/// take the path only from here — there are no separate paths.
abstract class WorkspacePort {
  String get currentPath;

  Directory get directory => Directory(currentPath);
}
