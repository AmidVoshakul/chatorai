import 'dart:io';

import 'package:chatorai/core/workspace/workspace_port.dart';

/// Default workspace: the process working folder.
///
/// Used by the terminal and as the fallback before the app
/// replaces it with the folder list screen value.
class ProcessWorkspacePort extends WorkspacePort {
  @override
  String get currentPath => Directory.current.path;
}
