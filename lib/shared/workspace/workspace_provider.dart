import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workspace_runtime.dart';
import 'package:chatorai/core/config/config_provider.dart';

class WorkspaceState {
  final String currentPath;
  final List<String> knownDirectories;
  final bool initialized;

  const WorkspaceState({
    required this.currentPath,
    this.knownDirectories = const [],
    this.initialized = false,
  });

  WorkspaceState copyWith({
    String? currentPath,
    List<String>? knownDirectories,
    bool? initialized,
  }) {
    return WorkspaceState(
      currentPath: currentPath ?? this.currentPath,
      knownDirectories: knownDirectories ?? this.knownDirectories,
      initialized: initialized ?? this.initialized,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceState &&
          runtimeType == other.runtimeType &&
          currentPath == other.currentPath &&
          const ListEquality().equals(
            knownDirectories,
            other.knownDirectories,
          ) &&
          initialized == other.initialized;

  @override
  int get hashCode =>
      Object.hash(currentPath, Object.hashAll(knownDirectories), initialized);

  @override
  String toString() =>
      'WorkspaceState(currentPath: $currentPath, knownDirectories: $knownDirectories, initialized: $initialized)';
}

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  static const _knownKey = knownWorkspacesPrefsKey;

  @override
  WorkspaceState build() =>
      WorkspaceState(currentPath: workspaceRuntimeCurrent.path);

  Future<void> init() async {
    if (state.initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final known = await _loadKnown(prefs);
    final pruned = known.where((p) => Directory(p).existsSync()).toList();

    final current = workspaceRuntimeCurrent.path;
    if (!pruned.contains(current)) {
      pruned.insert(0, current);
    } else {
      pruned.remove(current);
      pruned.insert(0, current);
    }

    await _persistKnown(prefs, pruned);
    state = WorkspaceState(
      currentPath: current,
      knownDirectories: List.unmodifiable(pruned),
      initialized: true,
    );
  }

  Future<void> addDirectory(String path) async {
    final normalized = Directory(path).path;
    if (!Directory(normalized).existsSync()) {
      throw ArgumentError('Directory does not exist: $normalized');
    }

    final prefs = await SharedPreferences.getInstance();
    final known = await _loadKnown(prefs);
    final knownSet = known.toSet().toList();
    if (!knownSet.contains(normalized)) {
      knownSet.add(normalized);
    }

    final current = workspaceRuntimeCurrent.path;
    knownSet.remove(current);
    knownSet.insert(0, current);

    await _persistKnown(prefs, knownSet);
    state = state.copyWith(knownDirectories: List.unmodifiable(knownSet));
  }

  Future<void> removeDirectory(String path) async {
    final normalized = Directory(path).path;
    if (normalized == state.currentPath) {
      throw StateError('Cannot remove current workspace directory');
    }

    final prefs = await SharedPreferences.getInstance();
    final known = await _loadKnown(prefs);
    known.remove(normalized);

    await _persistKnown(prefs, known);
    state = state.copyWith(knownDirectories: List.unmodifiable(known));
  }

  Future<void> switchWorkspace(String path) async {
    final normalized = Directory(path).path;
    if (!Directory(normalized).existsSync()) {
      throw ArgumentError('Directory does not exist: $normalized');
    }

    setRuntimeCwd(normalized);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastWorkspacePrefsKey, normalized);

    final known = await _loadKnown(prefs);
    final knownSet = known.toSet().toList();
    knownSet.remove(normalized);
    knownSet.insert(0, normalized);

    await _persistKnown(prefs, knownSet);

    state = WorkspaceState(
      currentPath: normalized,
      knownDirectories: List.unmodifiable(knownSet),
      initialized: true,
    );

    ref.invalidate(configProvider);
  }

  /// Removes known directories that no longer exist on disk.
  /// Keeps currentPath pinned at index 0. Persists the pruned list.
  Future<void> pruneMissing() async {
    final prefs = await SharedPreferences.getInstance();
    final known = await _loadKnown(prefs);
    final pruned = known.where((p) => Directory(p).existsSync()).toList();

    final current = workspaceRuntimeCurrent.path;
    if (!pruned.contains(current)) {
      pruned.insert(0, current);
    } else {
      pruned.remove(current);
      pruned.insert(0, current);
    }

    await _persistKnown(prefs, pruned);
    state = WorkspaceState(
      currentPath: current,
      knownDirectories: List.unmodifiable(pruned),
      initialized: true,
    );
  }

  Future<List<String>> _loadKnown(SharedPreferences prefs) {
    return Future.value(prefs.getStringList(_knownKey) ?? []);
  }

  Future<void> _persistKnown(SharedPreferences prefs, List<String> known) {
    return prefs.setStringList(_knownKey, List.unmodifiable(known));
  }
}

final workspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceState>(
  WorkspaceNotifier.new,
);
