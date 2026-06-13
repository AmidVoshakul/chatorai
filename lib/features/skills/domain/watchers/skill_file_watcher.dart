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

  /// Starts watching a directory for SKILL.md changes.
  ///
  /// [directory] - absolute path to watch.
  /// [onChange] - callback invoked after a debounced change.
  void watch(String directory, void Function() onChange) {
    final dir = Directory(directory);
    if (!dir.existsSync()) return;

    _callbacks[directory] = onChange;

    // Use existing debounce timer or create new
    _debounceTimers.putIfAbsent(
      directory,
      () => Timer(const Duration(milliseconds: 250), () {}),
    );

    final subscription = dir.watch(recursive: false).listen((event) {
      final fileName = p.basename(event.path);
      if (fileName != 'SKILL.md') return; // Ignore other files

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
