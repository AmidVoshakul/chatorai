import 'dart:io';

import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:path/path.dart' as p;

/// Reads and writes the free-form `AGENTS.md` instruction file for a given
/// scope.
///
/// Two scopes exist:
/// - **global**: `~/.config/chatorai/AGENTS.md` (or the mobile equivalent),
///   always available. This is the first block injected into every prompt.
/// - **project**: `<projectRoot>/AGENTS.md`, only on desktop when the user has
///   selected a project folder.
///
/// The service never mutates `chatorai.json`; it only touches the `AGENTS.md`
/// file itself. Callers pass [projectRoot] to target the project scope, or
/// leave it `null` for the global scope.
class AgentsFileService {
  AgentsFileService({Future<String> Function()? globalConfigDir})
    : _globalConfigDir = globalConfigDir ?? (() => XdgPaths.configHomeAsync);

  final Future<String> Function() _globalConfigDir;

  static const String fileName = 'AGENTS.md';

  /// Resolves the absolute `AGENTS.md` path for the chosen scope.
  Future<String> resolvePath({String? projectRoot}) async {
    if (projectRoot != null) {
      return p.join(projectRoot, fileName);
    }
    final dir = await _globalConfigDir();
    return p.join(dir, fileName);
  }

  /// Reads the `AGENTS.md` contents for the scope, or an empty string when the
  /// file does not exist yet.
  Future<String> read({String? projectRoot}) async {
    final path = await resolvePath(projectRoot: projectRoot);
    final file = File(path);
    if (!await file.exists()) return '';
    return file.readAsString();
  }

  /// Writes [content] to `AGENTS.md` for the scope, creating parent
  /// directories as needed. Writing empty content removes the file so an empty
  /// scope leaves no stray file behind.
  Future<void> write(String content, {String? projectRoot}) async {
    final path = await resolvePath(projectRoot: projectRoot);
    final file = File(path);
    if (content.trim().isEmpty) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Whether an `AGENTS.md` file currently exists for the scope.
  Future<bool> exists({String? projectRoot}) async {
    final path = await resolvePath(projectRoot: projectRoot);
    return File(path).exists();
  }

  /// Reads any instruction file at an absolute [path], returning an empty
  /// string when it does not exist. Used by the GUI to view/edit auto-detected
  /// files (`AGENTS.md`, `CLAUDE.md`) regardless of scope.
  Future<String> readAt(String path) async {
    final file = File(path);
    if (!await file.exists()) return '';
    return file.readAsString();
  }

  /// Writes [content] to an absolute [path], creating parent directories as
  /// needed. Empty content deletes the file so an emptied editor leaves no
  /// stray file behind (mirrors [write]).
  Future<void> writeAt(String path, String content) async {
    final file = File(path);
    if (content.trim().isEmpty) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }
}
