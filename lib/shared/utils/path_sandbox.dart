import 'dart:io';

import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:path/path.dart' as p;

/// Directories the model is permitted to read even though they live outside the
/// project root. Mirrors opencode's `readonlyExternalDirectory` allow-rule for
/// its managed `tool-output` directory: the model may read back truncated tool
/// output, but no other external location is reachable.
List<String>? _cachedManagedReadRoots;

/// Computed lazily and cached so we don't create the directory (a side effect
/// of [XdgPaths.dataSubdirSync]) on every [resolveSafePath] / [isWithinAnyRoot]
/// call.
List<String> get managedReadRoots =>
    _cachedManagedReadRoots ??= [
      XdgPaths.dataSubdirSync('tool-output').path,
      XdgPaths.dataSubdirSync('attachments').path,
    ];

/// True when [path] equals [root] or sits inside it. This is a pure string
/// check — it does **not** resolve symlinks. Callers that need symlink-safe
/// checks (e.g. the read/grep/glob tools) must pass a canonical path such as
/// [FilesystemBoundary.resolve]'s `resolution.path`, which is already
/// symlink-resolved via `resolveSymbolicLinksSync`.
bool isWithinAnyRoot(String path, List<String> roots) =>
    roots.any((root) => path == root || p.isWithin(root, path));

String resolveSafePath(
  String userPath, {
  List<String> allowedRoots = const [],
}) {
  final normalized = p.normalize(
    userPath.startsWith('~')
        ? p.join(
            Directory.current.path,
            userPath.length > 2 ? userPath.substring(2) : '.',
          )
        : userPath,
  );
  final absolute = p.isAbsolute(normalized)
      ? normalized
      : p.join(Directory.current.path, normalized);
  final normalizedAbsolute = p.normalize(absolute);
  final projectRoot = Directory.current.path;
  if (normalizedAbsolute != projectRoot &&
      !p.isWithin(projectRoot, normalizedAbsolute)) {
    if (isWithinAnyRoot(normalizedAbsolute, allowedRoots)) {
      return normalizedAbsolute;
    }
    throw ArgumentError('Path denied: $userPath (outside project root)');
  }
  return normalizedAbsolute;
}

bool isPathAllowed(String userPath, {List<String> allowedRoots = const []}) {
  try {
    resolveSafePath(userPath, allowedRoots: allowedRoots);
    return true;
  } catch (_) {
    return false;
  }
}
