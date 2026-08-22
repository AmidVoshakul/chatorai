import 'dart:async';
import 'dart:io';

import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Watches `chatorai.json` files for changes and triggers [invalidateConfig]
/// (wired to `ref.invalidate(configProvider)` in the app) so the app picks up
/// live edits without a restart.
///
/// The parent DIRECTORY of each config file is watched (not the file itself),
/// so the watcher survives the atomic rename-based writes used by [ConfigWriter]
/// and by most external editors (which rewrite via a temp file + rename). A
/// plain file watch would silently die on such a rename.
///
/// Watched:
/// - Global: `<XDG_CONFIG_HOME>/chatorai.json` on every platform.
/// - Project: `<cwd>/.chatorai/chatorai.json` on desktop only.
///
/// Missing directories are tolerated (no watch is installed). Events are
/// debounced by ~300ms to coalesce the modify + rename event pairs.
class ConfigWatcher {
  ConfigWatcher(
    this.invalidateConfig, {
    String? globalConfigPath,
    String? projectConfigPath,
  }) : _globalConfigPath = globalConfigPath,
       _projectConfigPath = projectConfigPath;

  /// Called (debounced) whenever a watched config file changes.
  final void Function() invalidateConfig;

  final String? _globalConfigPath;
  final String? _projectConfigPath;

  StreamSubscription<FileSystemEvent>? _globalSubscription;
  StreamSubscription<FileSystemEvent>? _projectSubscription;
  Timer? _globalDebounce;
  Timer? _projectDebounce;
  bool _active = false;
  bool _disposed = false;
  static const _debounceMs = 300;

  bool get isDisposed => _disposed;

  Future<void> start() async {
    if (_active || _disposed) return;
    _active = true;
    await _watchGlobal();
    await _watchProject();
  }

  Future<void> stop() async {
    _disposed = true;
    _active = false;
    await _globalSubscription?.cancel();
    await _projectSubscription?.cancel();
    _globalDebounce?.cancel();
    _projectDebounce?.cancel();
    _globalSubscription = null;
    _projectSubscription = null;
    _globalDebounce = null;
    _projectDebounce = null;
  }

  Future<void> _watchGlobal() async {
    final path =
        _globalConfigPath ?? await ConfigWriter.resolveConfigPath(global: true);
    await _watchDirOf(path, _onGlobalChanged, (s) => _globalSubscription = s);
  }

  Future<void> _watchProject() async {
    // Project-scoped config is only available on desktop platforms.
    if (Platform.isAndroid || Platform.isIOS) return;

    final path =
        _projectConfigPath ??
        p.join(workspaceRuntimeCurrent.path, '.chatorai', 'chatorai.json');
    await _watchDirOf(path, _onProjectChanged, (s) => _projectSubscription = s);
  }

  Future<void> _watchDirOf(
    String path,
    void Function() onChanged,
    void Function(StreamSubscription<FileSystemEvent>) setSub,
  ) async {
    final dir = Directory(p.dirname(path));
    if (!await dir.exists()) {
      // Directory will be created by ConfigWriter.ensureDir on next write.
      return;
    }

    final name = p.basename(path);
    try {
      setSub(
        dir.watch().listen(
          (event) {
            if (p.basename(event.path) == name) onChanged();
          },
          onError: (e) {
            LogTags.config.logWarning(
              'ConfigWatcher: watch error for $path: $e',
            );
          },
        ),
      );
    } on Object catch (e) {
      LogTags.config.logWarning('ConfigWatcher: failed to watch $path: $e');
    }
  }

  void _onGlobalChanged() {
    _globalDebounce?.cancel();
    _globalDebounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!_active) return;
      LogTags.config.logInfo(
        'ConfigWatcher: global chatorai.json changed, invalidating configProvider',
      );
      invalidateConfig();
    });
  }

  void _onProjectChanged() {
    _projectDebounce?.cancel();
    _projectDebounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!_active) return;
      LogTags.config.logInfo(
        'ConfigWatcher: project chatorai.json changed, invalidating configProvider',
      );
      invalidateConfig();
    });
  }
}

/// Provider that starts a [ConfigWatcher] for the lifetime of the app.
///
/// Place a `ref.watch(configWatcherProvider)` in the app root or bootstrap to
/// activate it. The watcher is disposed automatically when no longer listened to.
final configWatcherProvider = Provider<ConfigWatcher>((ref) {
  final watcher = ConfigWatcher(() => ref.invalidate(configProvider));
  ref.onDispose(() {
    unawaited(watcher.stop());
  });
  // Start watching after the first frame so we don't block startup I/O.
  Future.microtask(() {
    if (!watcher.isDisposed) {
      watcher.start();
    }
  });
  return watcher;
});
