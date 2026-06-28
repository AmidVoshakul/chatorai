import 'dart:io';
import 'package:path/path.dart' as p;
import '../permission/rule.dart';

class PathResolution {
  final String path;
  final bool isExternal;
  final PermissionAction? externalRule;

  const PathResolution({
    required this.path,
    required this.isExternal,
    this.externalRule,
  });
}

class FilesystemBoundary {
  final Directory workspace;
  final Map<String, PermissionAction> externalDirectoryRules;

  const FilesystemBoundary({
    required this.workspace,
    this.externalDirectoryRules = const {},
  });

  PathResolution resolve(String userPath) {
    final canonicalWorkspace = _canonicalize(workspace.path);
    final resolved = _resolveSymlinkSync(userPath) ?? _canonicalize(userPath);
    final isExternal = !_isWithin(canonicalWorkspace, resolved);

    PermissionAction? externalRule;
    if (isExternal) {
      externalRule = _matchExternalRule(resolved);
    }

    return PathResolution(
      path: resolved,
      isExternal: isExternal,
      externalRule: externalRule,
    );
  }

  String? _resolveSymlinkSync(String path) {
    final normalized = p.normalize(path);
    if (_linkExistsSync(normalized)) {
      try {
        return Link(normalized).resolveSymbolicLinksSync();
      } on FileSystemException catch (_) {}
    }
    var candidate = normalized;
    while (candidate != p.dirname(candidate)) {
      final parent = p.dirname(candidate);
      if (_linkExistsSync(parent)) {
        try {
          final symTarget = Link(parent).resolveSymbolicLinksSync();
          return p.join(symTarget, p.basename(candidate));
        } on FileSystemException catch (_) {}
      }
      candidate = parent;
    }
    return null;
  }

  bool _linkExistsSync(String path) {
    try {
      return Link(path).existsSync();
    } on FileSystemException catch (_) {
      return false;
    }
  }

  String _canonicalize(String path) {
    final expanded = _expandTilde(path);
    final absolute = p.isAbsolute(expanded)
        ? expanded
        : p.join(Directory.current.path, expanded);
    return p.normalize(absolute);
  }

  String _expandTilde(String path) {
    if (!path.startsWith('~')) return path;
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return path;
    if (path.startsWith('~/') || path.startsWith('~\\')) {
      return p.join(home, path.substring(2));
    }
    return home;
  }

  bool _isWithin(String parent, String child) {
    if (parent == child) return true;
    final rel = p.relative(child, from: parent);
    if (rel.startsWith('..')) return false;
    if (p.isAbsolute(rel)) return false;
    return true;
  }

  PermissionAction _matchExternalRule(String resolvedPath) {
    var result = PermissionAction.ask;
    for (final entry in externalDirectoryRules.entries) {
      if (_matchesPattern(resolvedPath, entry.key)) {
        result = entry.value;
      }
    }
    return result;
  }

  bool _matchesPattern(String path, String pattern) {
    final np = p.normalize(pattern);
    final npath = p.normalize(path);
    if (npath == np) return true;
    if (np.endsWith('${p.separator}*')) {
      final prefix = np.substring(0, np.length - p.separator.length - 1);
      return npath.startsWith('$prefix${p.separator}') || npath == prefix;
    }
    if (np.endsWith('*')) {
      return npath.startsWith(np.substring(0, np.length - 1));
    }
    if (np.endsWith(p.separator)) {
      return npath.startsWith(np) || npath == np.substring(0, np.length - 1);
    }
    if (npath.startsWith('$np${p.separator}') || npath == np) return true;
    return false;
  }
}
