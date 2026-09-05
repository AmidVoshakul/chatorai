import 'package:chatorai/core/workspace/workspace_port.dart';
import 'package:chatorai/gui/shared/workspace/workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Папка проекта для приложения: берётся с экрана списка папок.
class RiverpodWorkspacePort extends WorkspacePort {
  final Ref ref;

  RiverpodWorkspacePort(this.ref);

  @override
  String get currentPath => ref.read(workspaceProvider).currentPath;
}
