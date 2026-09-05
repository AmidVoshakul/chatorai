import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Watches skill directories for changes to SKILL.md files.
///
/// Uses file system events and debounces rapid changes.
class SkillFileWatcher {
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, void Function()> _callbacks = {};
  final Map<String, StreamSubscription<FileSystemEvent>> _subscriptions = {};
  final Map<String, String?> _filters = {};

  /// Starts watching a directory for file changes.
  ///
  /// [directory] - absolute path to watch.
  /// [onChange] - callback invoked after a debounced change.
  /// [fileName] - optional filter. When null, defaults to `SKILL.md`.
  ///   Pass `'*.md'` to react to any file ending in `.md`.
  /// [recursive] - also watch subdirectories; needed for nested command and
  ///   agent directory trees.
  void watch(
    String directory,
    void Function() onChange, {
    String? fileName,
    bool recursive = false,
  }) {
    final dir = Directory(directory);
    // Silently no-ops for missing paths: directories created AFTER startup
    // are picked up only when discovery runs again (e.g. a config reload).
    if (!dir.existsSync()) return;

    // Re-watching the same path must not orphan the old subscription/timer.
    _subscriptions.remove(directory)?.cancel();
    _debounceTimers.remove(directory)?.cancel();

    _callbacks[directory] = onChange;
    _filters[directory] = fileName;

    // Use existing debounce timer or create new
    _debounceTimers.putIfAbsent(
      directory,
      () => Timer(const Duration(milliseconds: 250), () {}),
    );

    final subscription = dir.watch(recursive: recursive).listen((event) {
      final filter = _filters[directory];
      final eventBasename = p.basename(event.path);
      if (filter == '*.md') {
        if (!event.path.endsWith('.md')) return;
      } else if (eventBasename != (filter ?? 'SKILL.md')) {
        return;
      }

      // Reset debounce timer
      final existing = _debounceTimers[directory];
      existing?.cancel();
      _debounceTimers[directory] = Timer(const Duration(milliseconds: 250), () {
        onChange();
      });
    });

    _subscriptions[directory] = subscription;
  }

  /// Stops watching a specific directory.
  void stopWatching(String directory) {
    _debounceTimers[directory]?.cancel();
    _debounceTimers.remove(directory);
    _subscriptions[directory]?.cancel();
    _subscriptions.remove(directory);
    _callbacks.remove(directory);
  }

  /// Stops all watchers.
  void stopAll() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _callbacks.clear();
  }

  /// Triggers change manually (useful for invalidations).
  void trigger(String directory) {
    final cb = _callbacks[directory];
    if (cb != null) {
      cb();
    }
  }
}
