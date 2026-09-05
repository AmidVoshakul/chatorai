import 'dart:io';

import 'package:chatorai/gui/shared/workspace/workspace_provider.dart';
import 'package:chatorai/core/workspace/workspace_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coordinates atomic workspace switch with all dependent provider invalidation.
class WorkspaceSwitcher {
  final Ref _ref;

  WorkspaceSwitcher(this._ref);

  Future<void> switchTo(String path) async {
    final newDir = Directory(path);
    if (!await newDir.exists()) {
      throw ArgumentError('Workspace does not exist: $path');
    }

    // 1. Atomic workspace switch via existing Notifier (single source of truth
    //    for CWD sync, cache invalidation, and permission service re-attach).
    await _ref.read(workspaceProvider.notifier).switchWorkspace(path);

    // 2. Guard: ensure runtime CWD was synced correctly.
    if (Directory.current.path != workspaceRuntimeCurrent.path) {
      throw StateError(
        'Failed to sync Directory.current with workspaceRuntimeCurrent: '
        '${Directory.current.path} != ${workspaceRuntimeCurrent.path}',
      );
    }
  }
}

final workspaceSwitcherProvider = Provider<WorkspaceSwitcher>(
  (ref) => WorkspaceSwitcher(ref),
);
