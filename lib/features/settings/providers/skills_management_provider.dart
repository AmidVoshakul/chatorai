import 'dart:io';

import 'package:chatorai/core/skills/directory_source.dart';
import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_marketplace_catalog.dart';
import 'package:chatorai/core/skills/skill_parser.dart';
import 'package:chatorai/core/skills/skill_providers.dart';
import 'package:chatorai/core/skills/skill_writer.dart';
import 'package:chatorai/core/skills/url_source.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

final _logger = LogTags.skills;

/// Which scope a skill mutation targets.
///
/// - [global]: user-level skills in `<XDG_CONFIG_HOME>/skills`, available
///   everywhere (including mobile).
/// - [project]: skills under the current working directory's project skill
///   paths (`.chatorai/skills`, `.agents/skills`, `.claude/skills`). Managed
///   writes always go to `<projectRoot>/.chatorai/skills`. Desktop only.
enum SkillsScope { global, project }

/// A single scope's discovered skills, split into managed and read-only.
class ScopeSkills {
  const ScopeSkills({this.skills = const []});

  /// Every skill discovered for this scope (from all of its paths).
  final List<SkillInfo> skills;

  /// Skills that live inside this scope's canonical managed root and can be
  /// edited or deleted from the UI.
  List<SkillInfo> get managed =>
      skills.where((s) => s._managed == true).toList(growable: false);

  /// Skills discovered outside the managed root (read-only in the UI).
  List<SkillInfo> get readOnly =>
      skills.where((s) => s._managed != true).toList(growable: false);
}

/// UI-facing state for the Skills management screen. Both scopes are loaded at
/// once so the screen can render a Global and a Project tab without switching
/// an "active" scope.
class SkillsManagementState {
  const SkillsManagementState({
    this.global = const ScopeSkills(),
    this.project = const ScopeSkills(),
    this.supportsProjectScope = false,
    this.projectRootPath,
  });

  final ScopeSkills global;
  final ScopeSkills project;

  /// Whether this platform exposes a project scope (desktop only).
  final bool supportsProjectScope;

  /// Absolute project root path on desktop, or `null` on mobile.
  final String? projectRootPath;
}

/// Loads, mutates and persists filesystem skills for the global and project
/// scopes.
///
/// Unlike [SkillService.listAll], which flattens every source into a single
/// deduplicated list without scope information, this notifier walks each
/// scope's paths *separately* so skills can be attributed to a tab and
/// classified as managed (editable/deletable) vs read-only.
///
/// Every mutation re-runs [_reload] then invalidates [skillServiceProvider] so
/// a running chat picks up the change without a restart.
class SkillsManagementNotifier extends AsyncNotifier<SkillsManagementState> {
  SkillWriter _writer = SkillWriter();

  /// Test overrides.
  Directory? _projectRootOverride;
  String? _globalRootOverride;
  bool? _supportsProjectScopeOverride;
  http.Client Function()? _httpClientFactory;

  /// Loads a bundled skill asset's text. Defaults to [rootBundle]; overridable
  /// in tests so the core writer stays Flutter-free and no real asset bundle is
  /// required under `flutter test`.
  Future<String> Function(String assetPath) _assetLoader = (assetPath) =>
      rootBundle.loadString(assetPath);

  /// Cache of parsed marketplace descriptions (keyed by entry id) so revisiting
  /// the Marketplace tab does not re-read and re-parse every bundled asset.
  final Map<String, String?> _descriptionCache = {};

  bool get _supportsProjectScope =>
      _supportsProjectScopeOverride ??
      (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  Directory get _projectRoot => _projectRootOverride ?? Directory.current;

  /// Test hooks — inject isolated writer / roots / project detection.
  void configureForTest({
    SkillWriter? writer,
    Directory? projectRoot,
    String? globalRoot,
    bool? supportsProjectScope,
    http.Client Function()? httpClientFactory,
    Future<String> Function(String assetPath)? assetLoader,
  }) {
    if (writer != null) _writer = writer;
    _projectRootOverride = projectRoot;
    _globalRootOverride = globalRoot;
    _supportsProjectScopeOverride = supportsProjectScope;
    _httpClientFactory = httpClientFactory;
    if (assetLoader != null) _assetLoader = assetLoader;
  }

  @override
  Future<SkillsManagementState> build() => _reload();

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<SkillsManagementState> _reload() async {
    try {
      final supportsProject = _supportsProjectScope;
      final globalRoot = await _globalRoot();

      final globalSkills = await _discoverScope(
        roots: [globalRoot],
        managedRoot: globalRoot,
      );

      var projectSkills = const ScopeSkills();
      if (supportsProject) {
        final projectRoots = _projectRoots();
        projectSkills = await _discoverScope(
          roots: projectRoots,
          managedRoot: _projectManagedRoot(),
        );
      }

      return SkillsManagementState(
        global: globalSkills,
        project: projectSkills,
        supportsProjectScope: supportsProject,
        projectRootPath: supportsProject ? _projectRoot.path : null,
      );
    } catch (e, st) {
      _logger.logError('SkillsManagement: failed to load', e, st);
      rethrow;
    }
  }

  /// Scans every [roots] path for skills, deduplicating by directory, and tags
  /// each one as managed when it lives inside [managedRoot].
  Future<ScopeSkills> _discoverScope({
    required List<String> roots,
    required String managedRoot,
  }) async {
    final byDir = <String, SkillInfo>{};
    for (final root in roots) {
      final source = DirectorySource(rootPath: root);
      final found = await source.discover();
      for (final skill in found) {
        final managed = _isWithin(managedRoot, skill.directory);
        byDir[p.normalize(skill.directory)] = skill._withManaged(managed);
      }
    }
    final list = byDir.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return ScopeSkills(skills: list);
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Creates a managed skill in [scope]'s canonical root.
  Future<void> createSkill({
    required SkillsScope scope,
    required String name,
    required String description,
    String? content,
  }) async {
    await _persistAndSync(() async {
      await _writer.createSkill(
        scopeRoot: await _managedRootFor(scope),
        name: name,
        description: description,
        content: content,
      );
    });
  }

  /// Deletes a managed skill. The [skill] must live inside the scope's managed
  /// root; the writer rejects anything else.
  Future<void> deleteSkill({
    required SkillsScope scope,
    required SkillInfo skill,
  }) async {
    await _persistAndSync(() async {
      await _writer.deleteSkill(
        scopeRoot: await _managedRootFor(scope),
        skillDirectory: skill.directory,
      );
    });
  }

  /// Downloads skills from a remote `index.json` [url] and installs them into
  /// [scope]'s managed root. The URL is *not* written to `chatorai.json`.
  /// Returns the names of the installed skills.
  Future<List<String>> installFromUrl({
    required SkillsScope scope,
    required String url,
    String? apiKey,
  }) async {
    late List<String> installed;
    await _persistAndSync(() async {
      final source = UrlSource(
        config: UrlSourceConfig(baseUrl: url.trim(), apiKey: apiKey),
        client: _httpClientFactory?.call(),
      );
      installed = await _writer.installFromSource(
        source: source,
        destRoot: await _managedRootFor(scope),
      );
    });
    return installed;
  }

  // ---------------------------------------------------------------------------
  // Marketplace
  // ---------------------------------------------------------------------------

  /// Installs a bundled marketplace [entry] into [scope]'s managed root.
  ///
  /// The `SKILL.md` asset is loaded here (Flutter layer) and handed to the
  /// writer as plain text, keeping the core writer free of asset APIs.
  Future<void> installBundled({
    required SkillsScope scope,
    required SkillMarketplaceEntry entry,
  }) async {
    if (!entry.isBundled) {
      throw ArgumentError('Entry "${entry.id}" is not a bundled skill');
    }
    final content = await _assetLoader(entry.assetPath);
    await _persistAndSync(() async {
      await _writer.installBundledSkill(
        scopeRoot: await _managedRootFor(scope),
        slug: entry.id,
        content: content,
      );
    });
  }

  /// Installs a URL-delivered marketplace [entry] via its remote `index.json`.
  /// Returns the names of the installed skills.
  Future<List<String>> installUrlEntry({
    required SkillsScope scope,
    required SkillMarketplaceEntry entry,
    String? apiKey,
  }) {
    final url = entry.url;
    if (url == null) {
      throw ArgumentError('Entry "${entry.id}" is not a URL skill');
    }
    return installFromUrl(scope: scope, url: url, apiKey: apiKey);
  }

  /// Loads the raw `SKILL.md` content for a bundled marketplace [entry] so it
  /// can be previewed before installing. URL entries have no offline body.
  Future<String> loadEntryContent(SkillMarketplaceEntry entry) {
    if (!entry.isBundled) {
      throw ArgumentError('Entry "${entry.id}" has no previewable content');
    }
    return _assetLoader(entry.assetPath);
  }

  /// Parses the `description` field from a bundled [entry]'s `SKILL.md`
  /// frontmatter for display on marketplace cards. Returns `null` when the
  /// asset can't be loaded or parsed, letting callers fall back gracefully.
  Future<String?> loadEntryDescription(SkillMarketplaceEntry entry) async {
    if (!entry.isBundled) return null;
    if (_descriptionCache.containsKey(entry.id)) {
      return _descriptionCache[entry.id];
    }
    String? description;
    try {
      final content = await _assetLoader(entry.assetPath);
      description = SkillParser.parse(entry.assetPath, content).description;
    } catch (_) {
      description = null;
    }
    _descriptionCache[entry.id] = description;
    return description;
  }

  /// Loads descriptions for every bundled [entries] in parallel, using the
  /// cache. Returns a map of entry id → description (non-null only).
  Future<Map<String, String>> loadDescriptions(
    Iterable<SkillMarketplaceEntry> entries,
  ) async {
    final bundled = entries.where((e) => e.isBundled).toList();
    final results = await Future.wait(bundled.map(loadEntryDescription));
    final map = <String, String>{};
    for (var i = 0; i < bundled.length; i++) {
      final desc = results[i];
      if (desc != null && desc.isNotEmpty) map[bundled[i].id] = desc;
    }
    return map;
  }

  /// Whether a marketplace [entry] is already installed in [scope] (matched by
  /// managed directory slug).
  bool isInstalled({
    required SkillsScope scope,
    required SkillMarketplaceEntry entry,
  }) {
    final data = state.value;
    if (data == null) return false;
    final scopeSkills = scope == SkillsScope.project
        ? data.project
        : data.global;
    final expectedSlug = SkillWriter.slugify(entry.id);
    return scopeSkills.managed.any(
      (s) => p.basename(p.normalize(s.directory)) == expectedSlug,
    );
  }

  /// Reads the `SKILL.md` for a skill (for the view/edit dialog).
  Future<String> readSkillFile(SkillInfo skill) =>
      _writer.readSkillFile(skill.directory);

  /// Overwrites the `SKILL.md` of a managed skill and syncs.
  Future<void> saveSkillFile(SkillInfo skill, String content) async {
    await _persistAndSync(() async {
      await _writer.writeSkillFile(skill.directory, content);
    });
  }

  Future<void> refresh() async {
    state = AsyncValue.data(await _reload());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _persistAndSync(Future<void> Function() mutation) async {
    await mutation();
    state = AsyncValue.data(await _reload());
    ref.invalidate(skillServiceProvider);
  }

  Future<String> _globalRoot() async =>
      _globalRootOverride ?? await _writer.globalSkillsRoot();

  String _projectManagedRoot() => _writer.projectSkillsRoot(_projectRoot);

  List<String> _projectRoots() => [
    for (final rel in defaultSkillPaths()) p.join(_projectRoot.path, rel),
  ];

  Future<String> _managedRootFor(SkillsScope scope) async =>
      scope == SkillsScope.project
      ? _projectManagedRoot()
      : await _globalRoot();

  bool _isWithin(String root, String candidate) {
    final normRoot = p.normalize(p.absolute(root));
    final normCandidate = p.normalize(p.absolute(candidate));
    return normCandidate == normRoot || p.isWithin(normRoot, normCandidate);
  }
}

/// Lightweight managed-flag carrier attached to discovered [SkillInfo]s.
///
/// Kept as an [Expando] so [SkillInfo] stays a pure model without a UI concern.
final Expando<bool> _managedFlag = Expando<bool>('skillManaged');

extension _SkillManaged on SkillInfo {
  bool? get _managed => _managedFlag[this];

  SkillInfo _withManaged(bool managed) {
    final copy = SkillInfo(
      name: name,
      description: description,
      directory: directory,
      content: content,
      files: files,
    );
    _managedFlag[copy] = managed;
    return copy;
  }
}

final skillsManagementProvider =
    AsyncNotifierProvider<SkillsManagementNotifier, SkillsManagementState>(
      SkillsManagementNotifier.new,
    );
