import 'package:chatorai/gui/shared/workspace/workspace_provider.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reactive provider for managed read roots.
/// Updates automatically when workspace changes via ref.watch(workspaceProvider).
final managedReadRootsProvider = Provider<Set<String>>((ref) {
  final workspace = ref.watch(workspaceProvider).currentPath;
  return {
    workspace,
    XdgPaths.dataSubdirSync('tool-output').path,
    XdgPaths.dataSubdirSync('attachments').path,
  };
});
