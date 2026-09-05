import 'package:chatorai/core/commands/command_parser.dart';
import 'package:chatorai/core/commands/command_registry.dart';
import 'package:chatorai/core/skills/skill_file_watcher.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:path/path.dart' as p;

/// Discovers custom slash commands from the given config roots and keeps the
/// result cached, hot-reloading whenever a watched markdown file changes.
class CommandService {
  /// Config roots to scan, ordered global-first; later roots win on name
  /// conflicts. Both `<root>/commands/` and `<root>/command/` trees are read,
  /// including nested subdirectories.
  final List<String> roots;

  /// Commands declared in chatorai.json; file definitions override them on
  /// every discovery pass.
  final Map<String, CommandInfo> fromJson;

  final SkillFileWatcher _watcher;
  final void Function()? _onChanged;
  final Map<String, CommandInfo> _cache = {};
  Future<void>? _load;
  bool _watchersInstalled = false;

  /// Increments on every discovery start; a superseded discovery must not
  /// write its (stale) results over a newer one's cache.
  int _generation = 0;

  CommandService({
    required this.roots,
    this.fromJson = const {},
    SkillFileWatcher? watcher,
    void Function()? onChanged,
  }) : _watcher = watcher ?? SkillFileWatcher(),
       _onChanged = onChanged;

  Future<List<CommandInfo>> listAll() async {
    _load ??= _discover();
    await _load;
    return _cache.values.toList(growable: false);
  }

  Future<CommandInfo?> getByName(String name) async {
    _load ??= _discover();
    await _load;
    return _cache[name];
  }

  Future<void> refresh() async {
    _load = _discover();
    await _load;
  }

  Future<void> _discover() async {
    final generation = ++_generation;
    final loaded = await CommandRegistry.load(roots, fromJson: fromJson);
    if (generation != _generation) return;
    _cache
      ..clear()
      ..addAll(loaded);
    if (!_watchersInstalled) {
      _installWatchers();
      _watchersInstalled = true;
    }
  }

  void _installWatchers() {
    for (final root in roots) {
      for (final dirName in const ['commands', 'command']) {
        final dir = p.join(root, dirName);
        _watcher.watch(
          dir,
          () {
            LogTags.chat.logDebug('[CommandService] change detected in $dir');
            _invalidate();
          },
          fileName: '*.md',
          recursive: true,
        );
      }
    }
  }

  void _invalidate() {
    _load = null;
    final callback = _onChanged;
    if (callback != null) callback();
  }

  void dispose() => _watcher.stopAll();
}
