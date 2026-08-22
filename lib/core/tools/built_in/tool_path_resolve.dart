import 'package:path/path.dart' as p;
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';
import 'package:chatorai/shared/utils/hard_denied_paths.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';
import 'package:chatorai/core/tools/filesystem_boundary.dart';
import 'package:chatorai/core/permission/permission_service.dart';

class ResolvedPath {
  final String? path;
  final ToolOutput? error;
  const ResolvedPath(this.path) : error = null;
  const ResolvedPath.error(this.error) : path = null;
  bool get isError => error != null;
}

Future<ResolvedPath> resolveToolPath({
  required ToolContext ctx,
  required String userPath,
  required String toolName,
}) async {
  final boundary = FilesystemBoundary(workspace: workspaceRuntimeCurrent);
  final resolution = boundary.resolve(userPath);

  try {
    if (isHardDeniedPath(resolution.path, workspaceRuntimeCurrent.path)) {
      throw PathDeniedException(
        resolution.path,
        'hard denied path',
        'This path is protected and cannot be accessed',
      );
    }

    final isExternalAndNotManaged =
        resolution.isExternal &&
        !isWithinAnyRoot(resolution.path, managedReadRoots);
    if (isExternalAndNotManaged) {
      final patterns = externalDirectoryGlobPatterns(
        p.dirname(resolution.path),
        workspacePath: workspaceRuntimeCurrent.path,
        fallback: resolution.path,
      );
      await ctx.ask(
        permission: 'external_directory',
        patterns: patterns,
        always: patterns,
        metadata: {
          'filepath': resolution.path,
          'parentDir': p.dirname(resolution.path),
          'tool': toolName,
        },
      );
      return ResolvedPath(resolution.path);
    }
    final safePath = resolveSafePath(
      resolution.path,
      allowedRoots: managedReadRoots,
    );
    return ResolvedPath(safePath);
  } on PathDeniedException catch (e) {
    return ResolvedPath.error(
      ToolOutput(
        'Error: ${e.toString()}',
        metadata: {'error': true, 'path': userPath, 'hardDenied': true},
      ),
    );
  } on PermissionDeniedError catch (e) {
    return ResolvedPath.error(
      ToolOutput(
        'Error: permission denied: $e',
        metadata: {'error': true, 'hardDenied': false},
      ),
    );
  } on PermissionRejectedError catch (e) {
    return ResolvedPath.error(
      ToolOutput(
        'Error: permission rejected: $e',
        metadata: {'error': true, 'hardDenied': false},
      ),
    );
  }
}
