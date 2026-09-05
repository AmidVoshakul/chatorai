import 'dart:io';

import 'package:path/path.dart' as p;

/// Project chatorai config directories (`<ancestor>/.chatorai`) discovered by
/// walking up from [start] (defaults to the process working directory),
/// ordered topmost ancestor first so the directory closest to [start] wins
/// name conflicts.
///
/// Only ancestors that actually contain a `.chatorai` entry are returned.
/// The walk stops after the first directory containing a `.git` entry —
/// a directory or a file (worktrees/submodules) — mirroring the worktree
/// boundary. Without such a boundary it continues to the filesystem root,
/// capped at 32 levels.
List<String> projectChatoraiRoots({String? start}) {
  var current = Directory(start ?? Directory.current.path);
  final found = <String>[];
  var depth = 0;
  while (true) {
    final configDir = p.join(current.path, '.chatorai');
    if (Directory(configDir).existsSync()) {
      found.add(configDir);
    }
    final gitType = FileSystemEntity.typeSync(p.join(current.path, '.git'));
    final atWorktreeBoundary = gitType != FileSystemEntityType.notFound;
    if (atWorktreeBoundary || depth >= 32) break;
    final parent = current.parent;
    if (parent.path == current.path) break;
    current = parent;
    depth++;
  }
  return found.reversed.toList(growable: false);
}
