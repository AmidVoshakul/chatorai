import 'dart:async';
import 'dart:io';

import 'package:chatorai/core/config/agents_file_service.dart';
import 'package:chatorai/core/config/config_loader.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/core/config/instructions_resolver.dart';
import 'package:chatorai/gui/shared/workspace/workspace_provider.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final _logger = LogTags.config;

/// Directory (relative to a scope root) where inline / uploaded instruction
/// files are stored.
const String kInstructionsSubdir = '.chatorai/instructions';

/// Which config scope a mutation targets.
///
/// - [global]: the user-level config (`~/.config/chatorai/`), applied
///   everywhere.
/// - [project]: the current working directory (`Directory.current`), the same
///   root the config loader and the built-in tools use. Desktop only.
enum InstructionsScope { global, project }

/// A single scope's view: its auto-detected files and its `instructions[]`.
class ScopeInstructions {
  const ScopeInstructions({
    this.discovered = const [],
    this.entries = const [],
  });

  /// Auto-detected instruction files for this scope, in injection order.
  final List<DiscoveredInstructionFile> discovered;

  /// The `instructions[]` entries from this scope's `chatorai.json`.
  final List<String> entries;
}

/// UI-facing state for the Agents Instructions management screen.
///
/// Both scopes are loaded at once so the screen can render a Global and a
/// Project tab without switching an "active" scope.
class InstructionsManagementState {
  const InstructionsManagementState({
    this.global = const ScopeInstructions(),
    this.project = const ScopeInstructions(),
    this.supportsProjectScope = false,
    this.projectRootPath,
  });

  /// Global (user-level) scope.
  final ScopeInstructions global;

  /// Project (working-directory) scope. Empty on platforms without a project
  /// scope.
  final ScopeInstructions project;

  /// Whether this platform exposes a project scope (desktop only).
  final bool supportsProjectScope;

  /// Absolute path of the project root (`Directory.current`) on desktop, or
  /// `null` on mobile.
  final String? projectRootPath;
}

/// Loads, mutates, and persists `AGENTS.md` files and the `instructions[]`
/// array of `chatorai.json` for both the global and project scopes.
///
/// The project scope is always the process working directory
/// ([Directory.current]) — the same root the config loader and built-in tools
/// use — so there is a single source of truth for "the project".
///
/// Every mutation re-runs [_reload] then invalidates [configProvider] +
/// [resolvedInstructionsProvider] so a running chat picks up the change without
/// an app restart.
class InstructionsManagementNotifier
    extends AsyncNotifier<InstructionsManagementState> {
  AgentsFileService _agentsFiles = AgentsFileService();
  final InstructionsResolver _resolver = InstructionsResolver(
    disableProjectConfig: false,
  );

  /// Global `chatorai.json` path override (tests only).
  String? _globalConfigPathOverride;

  /// Project root override (tests only). Defaults to [Directory.current].
  Directory? _projectRootOverride;

  /// Whether the project scope is exposed. Defaults to desktop detection;
  /// overridable in tests.
  bool? _supportsProjectScopeOverride;

  bool get _supportsProjectScope =>
      _supportsProjectScopeOverride ??
      (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  Directory get _projectRoot => _projectRootOverride ?? Directory.current;

  /// Test hooks — inject isolated services / paths / project root.
  void configureForTest({
    AgentsFileService? agentsFiles,
    String? globalConfigPath,
    Directory? projectRoot,
    bool? supportsProjectScope,
  }) {
    if (agentsFiles != null) _agentsFiles = agentsFiles;
    _globalConfigPathOverride = globalConfigPath;
    _projectRootOverride = projectRoot;
    _supportsProjectScopeOverride = supportsProjectScope;
  }

  @override
  Future<InstructionsManagementState> build() {
    // Re-read whenever the active workspace changes so the Project tab always
    // reflects the current workspace root (both the config path and the
    // auto-discovered AGENTS.md walk-up move with it).
    ref.listen(workspaceProvider, (previous, next) {
      if (previous?.currentPath != next.currentPath) {
        unawaited(refresh());
      }
    });
    return _reload();
  }

  Future<InstructionsManagementState> _reload() async {
    try {
      final supportsProject = _supportsProjectScope;
      final projectRoot = _projectRoot;
      final globalAgentsPath = await _agentsFiles.resolvePath();

      // Global scope: always show the single global AGENTS.md card (created on
      // save), plus the global chatorai.json instructions[].
      final globalDiscovered = _resolver.discoverFiles(
        globalAgentsPath: globalAgentsPath,
      );
      final globalEntries = await _readEntries(await _globalConfigPath());

      // Project scope (desktop only): only files that actually exist on disk,
      // discovered by walking up from the working directory.
      var projectDiscovered = const <DiscoveredInstructionFile>[];
      var projectEntries = const <String>[];
      if (supportsProject) {
        projectDiscovered = _resolver
            .discoverFiles(cwd: projectRoot)
            .where((f) => f.exists)
            .toList();
        projectEntries = await _readEntries(
          await _projectConfigPath(projectRoot),
        );
      }

      return InstructionsManagementState(
        global: ScopeInstructions(
          discovered: globalDiscovered,
          entries: globalEntries,
        ),
        project: ScopeInstructions(
          discovered: projectDiscovered,
          entries: projectEntries,
        ),
        supportsProjectScope: supportsProject,
        projectRootPath: supportsProject ? projectRoot.path : null,
      );
    } catch (e, st) {
      _logger.logError('InstructionsManagement: failed to load', e, st);
      rethrow;
    }
  }

  Future<List<String>> _readEntries(String configPath) async {
    final raw = await ConfigWriter.readRawConfig(configPath);
    if (raw['instructions'] is! List) return const [];
    return List<String>.of((raw['instructions'] as List).whereType<String>());
  }

  Future<String> _globalConfigPath() async =>
      _globalConfigPathOverride ??
      await ConfigLoader.resolveConfigPath(global: true);

  Future<String> _projectConfigPath(Directory root) async =>
      ConfigLoader.resolveConfigPath(global: false, projectRoot: root);

  Future<String> _configPathFor(InstructionsScope scope) async =>
      scope == InstructionsScope.project
      ? await _projectConfigPath(_projectRoot)
      : await _globalConfigPath();

  /// Absolute root for a scope: the project root for [InstructionsScope.project]
  /// and the global config dir for global. [relPath] already carries the
  /// `.chatorai/instructions/` prefix, so the root must NOT include it.
  Future<Directory?> _rootFor(InstructionsScope scope) async =>
      scope == InstructionsScope.project ? _projectRoot : await _globalRoot();

  /// Absolute directory the global scope's managed instruction files live
  /// under: `<configHome>/`. Independent of the process working directory, so
  /// global instructions never leak into the project folder.
  Future<Directory> _globalRoot() async {
    final configPath = await _globalConfigPath();
    return Directory(p.dirname(configPath));
  }

  Future<void> _persistAndSync(Future<void> Function() mutation) async {
    await mutation();
    state = AsyncValue.data(await _reload());
    ref.invalidate(configProvider);
    ref.invalidate(resolvedInstructionsProvider);
  }

  // ---------------------------------------------------------------------------
  // AGENTS.md
  // ---------------------------------------------------------------------------

  /// Reads the current contents of an auto-detected file at [path] (for the
  /// view / edit dialog). Returns an empty string when the file is absent.
  Future<String> readDiscoveredFile(String path) => _agentsFiles.readAt(path);

  /// Writes [content] to an auto-detected `AGENTS.md` at an absolute [path]
  /// (any scope) and syncs so a running chat picks it up without a restart.
  Future<void> saveDiscoveredAgents(String path, String content) async {
    await _persistAndSync(() async {
      await _agentsFiles.writeAt(path, content);
    });
  }

  /// Creates (or overwrites) the project `AGENTS.md` at `<projectRoot>/AGENTS.md`.
  Future<void> createProjectAgents(String content) =>
      saveDiscoveredAgents(p.join(_projectRoot.path, 'AGENTS.md'), content);

  // ---------------------------------------------------------------------------
  // instructions[] entries
  // ---------------------------------------------------------------------------

  /// Reads the current contents of an inline instruction [entry] under [scope].
  Future<String> readInstructionEntry(
    String entry, {
    required InstructionsScope scope,
  }) async {
    final absPath = await _absoluteForScope(scope, entry);
    return File(absPath).readAsString();
  }

  /// Writes [content] to an inline instruction [entry] under [scope] and syncs
  /// so a running chat picks it up without a restart.
  Future<void> saveInstructionEntry(
    String entry,
    String content, {
    required InstructionsScope scope,
  }) async {
    await _persistAndSync(() async {
      final absPath = await _absoluteForScope(scope, entry);
      await File(absPath).writeAsString(content);
    });
  }

  /// Creates an inline instruction in [scope]: writes `[name].md` under
  /// `<scope>/.chatorai/instructions/` and registers its relative path in
  /// `instructions[]`.
  Future<void> addInlineInstruction(
    String name,
    String content, {
    InstructionsScope scope = InstructionsScope.project,
  }) async {
    await _persistAndSync(() async {
      final relPath = p.join(kInstructionsSubdir, _slugFile(name));
      final absPath = await _absoluteForScope(scope, relPath);
      final file = File(absPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);

      await ConfigWriter.addInstruction(
        relPath,
        configPath: await _configPathFor(scope),
      );
    });
  }

  /// Copies an uploaded `.md` file into `<scope>/.chatorai/instructions/` and
  /// registers its relative path in `instructions[]`.
  Future<void> addFileInstruction(
    String sourcePath, {
    InstructionsScope scope = InstructionsScope.project,
  }) async {
    await _persistAndSync(() async {
      final baseName = p.basename(sourcePath);
      final relPath = p.join(kInstructionsSubdir, baseName);
      final absPath = await _absoluteForScope(scope, relPath);
      final dest = File(absPath);
      await dest.parent.create(recursive: true);
      await File(sourcePath).copy(absPath);

      await ConfigWriter.addInstruction(
        relPath,
        configPath: await _configPathFor(scope),
      );
    });
  }

  /// Removes an instruction entry from [scope]'s `instructions[]`. When the
  /// referenced file lives inside `<scope>/.chatorai/instructions/` it is
  /// deleted from disk too; externally-referenced files are left untouched.
  Future<void> removeInstruction(
    String entry, {
    InstructionsScope scope = InstructionsScope.project,
  }) async {
    await _persistAndSync(() async {
      await ConfigWriter.removeInstruction(
        entry,
        configPath: await _configPathFor(scope),
      );
      await _deleteIfManaged(scope, entry);
    });
  }

  /// Updates an existing instruction entry (path) in place within [scope].
  Future<void> updateInstruction(
    String oldEntry,
    String newEntry, {
    InstructionsScope scope = InstructionsScope.project,
  }) async {
    await _persistAndSync(() async {
      await ConfigWriter.updateInstruction(
        oldEntry,
        newEntry,
        configPath: await _configPathFor(scope),
      );
    });
  }

  Future<void> refresh() async {
    state = AsyncValue.data(await _reload());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Resolves a scope-relative path to an absolute one. For the global scope
  /// the instructions dir is relative to the global config dir; for project
  /// it is relative to the project root.
  Future<String> _absoluteForScope(
    InstructionsScope scope,
    String relPath,
  ) async {
    final root = await _rootFor(scope);
    if (root != null) return p.join(root.path, relPath);
    return relPath;
  }

  /// Deletes the on-disk file for [entry] only when it is a managed file inside
  /// `<scope>/.chatorai/instructions/`.
  Future<void> _deleteIfManaged(InstructionsScope scope, String entry) async {
    final normalized = p.normalize(entry);
    if (!p.isWithin(kInstructionsSubdir, normalized) &&
        !normalized.startsWith(kInstructionsSubdir)) {
      return;
    }
    final absPath = await _absoluteForScope(scope, normalized);
    final file = File(absPath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e, st) {
        _logger.logError('InstructionsManagement: delete failed', e, st);
      }
    }
  }

  /// Turns a display name into a safe `<slug>.md` filename.
  String _slugFile(String name) {
    final base = name.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]+'),
      '-',
    );
    final cleaned = base.replaceAll(RegExp(r'^-+|-+$'), '');
    final stem = cleaned.isEmpty ? 'instruction' : cleaned;
    return stem.endsWith('.md') ? stem : '$stem.md';
  }
}

final instructionsManagementProvider =
    AsyncNotifierProvider<
      InstructionsManagementNotifier,
      InstructionsManagementState
    >(InstructionsManagementNotifier.new);
