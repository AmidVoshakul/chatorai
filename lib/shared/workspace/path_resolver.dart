import 'dart:io';

import 'package:chatorai/core/tools/filesystem_boundary.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart' as sandbox;

/// Thin DI wrapper around [FilesystemBoundary] and [sandbox.resolveSafePath].
///
/// Legacy shim kept for callers that still construct a [PathResolver] directly.
/// New code should use [FilesystemBoundary] + [sandbox.resolveSafePath] instead.
class PathResolver {
  final Directory workspace;
  final Set<String> managedRoots;

  const PathResolver({required this.workspace, required this.managedRoots});

  /// Resolve a user-provided path to its canonical form.
  PathResolution resolve(String userPath) {
    final boundary = FilesystemBoundary(workspace: workspace);
    final resolution = boundary.resolve(userPath);
    return PathResolution(
      path: resolution.path,
      isExternal: resolution.isExternal,
      externalRule: resolution.externalRule,
    );
  }

  /// Resolve and validate a path against sandbox rules.
  /// Throws [PathDeniedException] if path is denied.
  String resolveSafePath(String path) {
    return sandbox.resolveSafePath(path, allowedRoots: managedRoots);
  }
}
