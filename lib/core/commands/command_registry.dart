import 'dart:io';

import 'package:chatorai/core/commands/command_parser.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:path/path.dart' as p;

/// Loads custom slash-command definitions from `<root>/command(s)/**/*.md`.
///
/// Roots are scanned in the given order; entries from later roots override
/// same-named entries from earlier ones, so passing the global config root
/// first and the project root last makes project commands win.
class CommandRegistry {
  static const List<String> _dirNames = ['commands', 'command'];

  const CommandRegistry._();

  /// Scans each root (ordered global-first); entries from later roots override
  /// same-named entries from earlier ones. [fromJson] seeds the base map —
  /// file-defined commands override same-named JSON-configured ones.
  static Future<Map<String, CommandInfo>> load(
    Iterable<String> roots, {
    Map<String, CommandInfo> fromJson = const {},
  }) async {
    final loaded = Map<String, CommandInfo>.from(fromJson);
    for (final root in roots) {
      for (final dirName in _dirNames) {
        final dir = Directory(p.join(root, dirName));
        if (!dir.existsSync()) continue;
        await for (final entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is! File) continue;
          if (!entity.path.endsWith('.md')) continue;
          final entryPath = p.relative(entity.path, from: root);
          try {
            final content = await entity.readAsString();
            final command = CommandParser.parse(entryPath, content);
            loaded[command.name] = command;
          } catch (e) {
            LogTags.chat.logWarning('Skipping command ${entity.path}: $e');
          }
        }
      }
    }
    return loaded;
  }
}
