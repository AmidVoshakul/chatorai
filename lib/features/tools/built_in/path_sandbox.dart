import 'dart:io';

import 'package:path/path.dart' as p;

String resolveSafePath(String userPath) {
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
    throw ArgumentError('Path denied: $userPath (outside project root)');
  }
  return normalizedAbsolute;
}

bool isPathAllowed(String userPath) {
  try {
    resolveSafePath(userPath);
    return true;
  } catch (_) {
    return false;
  }
}
