import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:chatorai/shared/utils/hard_denied_paths.dart';

/// Directories the model is permitted to read even though they live outside the
/// project root. Mirrors `readonlyExternalDirectory` allow-rule for
/// its managed `tool-output` directory: the model may read back truncated tool
/// output, but no other external location is reachable.
///
/// **Legacy global shim** — prefer `managedReadRootsProvider` in new code.
/// This fallback exists for backward compatibility with direct getter usages.
Set<String>? _cachedManagedReadRoots;

void clearManagedReadRootsCache() => _cachedManagedReadRoots = null;

/// Computed lazily and cached so we don't create the directory (a side effect
/// of [XdgPaths.dataSubdirSync]) on every [resolveSafePath] / [isWithinAnyRoot]
/// call.
Set<String> get managedReadRoots => _cachedManagedReadRoots ??= {
  workspaceRuntimeCurrent.path,
  XdgPaths.dataSubdirSync('tool-output').path,
  XdgPaths.dataSubdirSync('attachments').path,
};

/// Pure helper: true when [parent] equals [child] or sits inside it.
///
/// Purely string-based containment: does NOT resolve symlinks. Callers needing
/// symlink-safe checks must pass canonical paths (e.g. [FilesystemBoundary.resolve]'s `resolution.path`, which is
/// already symlink-resolved via `resolveSymbolicLinksSync`).
bool pathContains(String parent, String child) {
  if (parent == child) return true;
  final rel = p.relative(child, from: parent);
  if (rel.startsWith('..')) return false;
  if (p.isAbsolute(rel)) return false;
  return true;
}

/// True when [path] equals any [root] or sits inside it.
///
/// Delegates to [contains] for the per-root check.
bool isWithinAnyRoot(String path, Iterable<String> roots) =>
    roots.any((root) => pathContains(root, path));

/// True when [a] and [b] overlap (one is within the other, in either direction).
bool overlaps(String a, String b) => pathContains(a, b) || pathContains(b, a);

/// Builds the `external_directory` permission patterns for a [directory].
///
/// Returns `[directory/*]` so a single "Always" grant covers the directory
/// recursively — the wildcard engine ([match], `dotAll: true`) treats `*` as
/// recursive, so `/parent/dir/*` matches both `/parent/dir/file` and
/// `/parent/dir/sub/file`.
///
/// SAFETY (over-broad guard): if [directory] is the filesystem root (`/`) or an
/// ancestor of (or equal to) [workspacePath], returning `[directory/*]` would
/// grant access to the entire disk or to the workspace. In that case we return
/// `[fallback]` (the exact, narrow path) instead, preventing a `/*` grant.
List<String> externalDirectoryGlobPatterns(
  String directory, {
  required String workspacePath,
  required String fallback,
}) {
  final isFsRoot = p.dirname(directory) == directory;
  final coversWorkspace = pathContains(directory, workspacePath);
  if (isFsRoot || coversWorkspace) {
    return [fallback];
  }
  return ['$directory/*'];
}

class PathDeniedException implements Exception {
  final String path;
  final String reason;
  final String hint;
  const PathDeniedException(this.path, this.reason, this.hint);
  @override
  String toString() => 'Path denied: $path ($reason). $hint';
}

String resolveSafePath(String userPath, {Set<String> allowedRoots = const {}}) {
  final normalized = p.normalize(
    userPath.startsWith('~')
        ? p.join(
            workspaceRuntimeCurrent.path,
            userPath.length > 2 ? userPath.substring(2) : '.',
          )
        : userPath,
  );
  final absolute = p.isAbsolute(normalized)
      ? normalized
      : p.join(workspaceRuntimeCurrent.path, normalized);
  final normalizedAbsolute = p.normalize(absolute);
  final projectRoot = workspaceRuntimeCurrent.path;

  if (isHardDeniedPath(normalizedAbsolute, workspaceRuntimeCurrent.path)) {
    throw PathDeniedException(
      normalizedAbsolute,
      'protected system path',
      'Grant access via settings (Auto-Approve) or use a path inside the workspace',
    );
  }

  if (normalizedAbsolute != projectRoot &&
      !p.isWithin(projectRoot, normalizedAbsolute)) {
    if (isWithinAnyRoot(normalizedAbsolute, allowedRoots)) {
      return normalizedAbsolute;
    }
    throw PathDeniedException(
      normalizedAbsolute,
      'path outside workspace',
      'Grant access via settings (Auto-Approve) or use a path inside the workspace',
    );
  }
  return normalizedAbsolute;
}

bool isPathAllowed(String userPath, {Set<String> allowedRoots = const {}}) {
  try {
    resolveSafePath(userPath, allowedRoots: allowedRoots);
    return true;
  } on PathDeniedException {
    return false;
  }
}
