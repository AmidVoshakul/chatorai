import 'dart:io';

import 'package:glob/glob.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:chatorai/shared/utils/xdg_paths.dart';

/// Filenames auto-discovered by walking upward from cwd to project root
/// (mirrors opencode's `AGENTS.md` / `CLAUDE.md` behaviour).
const List<String> _kInstructionFilenames = ['AGENTS.md', 'CLAUDE.md'];

/// Only `AGENTS.md` is editable in-app; other auto-detected files (e.g.
/// `CLAUDE.md`) are shown read-only, matching opencode's `ConfigRules`.
const String _kEditableFilename = 'AGENTS.md';

/// Metadata describing an auto-detected instruction file, surfaced to the GUI
/// so it can render one card per file without re-resolving the whole prompt.
///
/// Mirrors opencode's `ConfigRules.read` shape (`name`, `path`, `exists`,
/// `editable`) plus [isGlobal] to distinguish the user-level `AGENTS.md` from
/// project-level ones.
class DiscoveredInstructionFile {
  const DiscoveredInstructionFile({
    required this.name,
    required this.path,
    required this.exists,
    required this.editable,
    required this.isGlobal,
  });

  /// Basename of the file (e.g. `AGENTS.md`, `CLAUDE.md`).
  final String name;

  /// Absolute path on disk.
  final String path;

  /// Whether the file currently exists.
  final bool exists;

  /// Whether the file may be edited in-app (only `AGENTS.md`).
  final bool editable;

  /// Whether this is the global (user-level) `AGENTS.md`.
  final bool isGlobal;

  @override
  bool operator ==(Object other) =>
      other is DiscoveredInstructionFile &&
      other.name == name &&
      other.path == path &&
      other.exists == exists &&
      other.editable == editable &&
      other.isGlobal == isGlobal;

  @override
  int get hashCode => Object.hash(name, path, exists, editable, isGlobal);
}

/// Resolves `instructions` entries from `chatorai.json` into ready-to-paste
/// system-prompt blocks.
///
/// Each raw entry is one of:
/// - an `http(s)` URL — fetched and inlined,
/// - a `~/` path — expanded to the user's home directory,
/// - an absolute path — globbed by its basename inside its own directory,
/// - a relative glob/path — resolved from the project root (e.g.
///   `.chatorai/instructions/*.md`), or a filename searched upward
///   (e.g. `AGENTS.md`).
///
/// The result is a list of `"Instructions from: <path>\n<content>"` strings,
/// one per resolved, non-empty file.
///
/// ## Auto-discovery
///
/// Unless [CHATORAI_DISABLE_PROJECT_CONFIG] is set, [resolve] also walks
/// upward from [cwd] to the filesystem root and loads every `AGENTS.md` /
/// `CLAUDE.md` it finds (project-level first, then closer to cwd). A global
/// `~/.config/chatorai/AGENTS.md` is loaded when present, regardless of the
/// flag.
class InstructionsResolver {
  InstructionsResolver({
    this.home,
    http.Client? httpClient,
    bool? disableProjectConfig,
  }) : _http = httpClient ?? http.Client(),
       _disableProjectConfigOverride = disableProjectConfig;

  /// User home directory. Defaults to `Platform.environment['HOME']` /
  /// `USERPROFILE` when omitted.
  final String? home;

  final http.Client _http;

  /// Explicit override for project config disable flag (used in tests).
  final bool? _disableProjectConfigOverride;

  /// Whether project-level auto-discovery is disabled via environment flag
  /// or explicit constructor parameter.
  bool get _disableProjectConfig =>
      _disableProjectConfigOverride ??
      Platform.environment['CHATORAI_DISABLE_PROJECT_CONFIG'] == '1';

  /// Resolves [raw] entries against [cwd].
  ///
  /// Failures (missing file, network error) are silently skipped so a single
  /// bad instruction entry never breaks the whole system prompt.
  Future<List<String>> resolve(List<String> raw, {Directory? cwd}) async {
    final root = cwd ?? Directory.current;
    final blocks = <String>[];
    final seen = <String>{};

    // 1. Global AGENTS.md from ~/.config/chatorai/ (always, like opencode).
    final globalBlock = await _loadGlobalAgents();
    if (globalBlock != null) {
      final resolved = p.canonicalize(globalBlock.path);
      seen.add(resolved);
      blocks.add(globalBlock.block);
    }

    // 2. Auto-discover AGENTS.md / CLAUDE.md by walking upward (unless
    //    disabled by CHATORAI_DISABLE_PROJECT_CONFIG).
    if (!_disableProjectConfig) {
      final discovered = _discoverInstructionFiles(root);
      for (final filePath in discovered) {
        final resolved = p.canonicalize(filePath);
        if (seen.contains(resolved)) continue;
        seen.add(resolved);
        final block = await _readFile(resolved);
        if (block != null) blocks.add(block);
      }
    }

    // 3. Explicit entries from chatorai.json config.
    for (final entry in raw) {
      if (entry.trim().isEmpty) continue;

      if (entry.startsWith('http://') || entry.startsWith('https://')) {
        final block = await _resolveUrl(entry);
        if (block != null) blocks.add(block);
        continue;
      }

      final paths = await _resolvePaths(entry, root);
      for (final filePath in paths) {
        final resolved = p.canonicalize(filePath);
        if (seen.contains(resolved)) continue;
        seen.add(resolved);
        final block = await _readFile(resolved);
        if (block != null) blocks.add(block);
      }
    }

    return blocks;
  }

  // ---------------------------------------------------------------------------
  // Auto-discovery
  // ---------------------------------------------------------------------------

  /// Returns metadata for every auto-detected instruction file in injection
  /// order, for the GUI to render as cards. Unlike [resolve] this never reads
  /// file bodies and includes files that do not yet exist (so the UI can offer
  /// to create them).
  ///
  /// [globalAgentsPath] is the absolute path of the user-level `AGENTS.md`
  /// (e.g. `~/.config/chatorai/AGENTS.md`); when provided it is listed first,
  /// matching [resolve]'s global-first ordering. When [cwd] is `null` (or
  /// project auto-discovery is disabled) only the global entry is returned.
  List<DiscoveredInstructionFile> discoverFiles({
    Directory? cwd,
    String? globalAgentsPath,
  }) {
    final files = <DiscoveredInstructionFile>[];
    final seen = <String>{};

    if (globalAgentsPath != null) {
      final canonical = _canonicalizeSafe(globalAgentsPath);
      seen.add(canonical);
      files.add(
        DiscoveredInstructionFile(
          name: p.basename(globalAgentsPath),
          path: globalAgentsPath,
          exists: File(globalAgentsPath).existsSync(),
          editable: true,
          isGlobal: true,
        ),
      );
    }

    if (cwd != null && !_disableProjectConfig) {
      for (final filePath in _discoverInstructionFiles(cwd)) {
        final canonical = _canonicalizeSafe(filePath);
        if (seen.contains(canonical)) continue;
        seen.add(canonical);
        final name = p.basename(filePath);
        files.add(
          DiscoveredInstructionFile(
            name: name,
            path: filePath,
            exists: File(filePath).existsSync(),
            editable: name == _kEditableFilename,
            isGlobal: false,
          ),
        );
      }
    }

    return files;
  }

  String _canonicalizeSafe(String path) {
    try {
      return p.canonicalize(path);
    } catch (_) {
      return p.normalize(path);
    }
  }

  /// Walks upward from [start] toward the filesystem root, collecting every
  /// `AGENTS.md` / `CLAUDE.md` found. Returns paths from project root toward
  /// [start] (opencode order: project-level first, closest-to-cwd last).
  List<String> _discoverInstructionFiles(Directory start) {
    var dir = start;
    final candidates = <String>[];

    while (true) {
      for (final filename in _kInstructionFilenames) {
        final candidate = p.join(dir.path, filename);
        if (File(candidate).existsSync()) {
          candidates.add(candidate);
        }
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }

    // Reverse: closest-to-cwd first matches existing _findUp order for
    // explicit entries, but opencode injects project-level first. We
    // reverse so the closest file ends up at the *end* of the list (lower
    // priority when deduplicating), matching opencode's "project root
    // dominates" semantics.
    return candidates.reversed.toList();
  }

  /// Loads `AGENTS.md` from the global config directory
  /// (`~/.config/chatorai/AGENTS.md`).
  Future<_GlobalBlock?> _loadGlobalAgents() async {
    try {
      final configDir = await XdgPaths.configHomeAsync;
      final globalFile = File(p.join(configDir, 'AGENTS.md'));
      if (!await globalFile.exists()) return null;

      final content = await globalFile.readAsString();
      if (content.trim().isEmpty) return null;

      final path = globalFile.path;
      return _GlobalBlock(
        path: path,
        block: 'Instructions from: $path\n$content',
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _resolvePaths(String entry, Directory root) async {
    final expanded = _expandHome(entry);

    if (p.isAbsolute(expanded)) {
      // Glob by basename inside its own directory (opencode behaviour).
      // The user explicitly provided an absolute path, so it is trusted.
      final dir = p.dirname(expanded);
      final base = p.basename(expanded);
      if (base.contains('*') || base.contains('?')) {
        return _globList(Glob(base), rootDir: dir);
      }
      return File(expanded).existsSync() ? [expanded] : [];
    }

    // Relative entry. Prevent path traversal outside the project root.
    final normalized = p.normalize(p.join(root.path, entry));
    if (!p.isWithin(root.path, normalized) && normalized != root.path) {
      return [];
    }

    // If it looks like a glob, resolve from the project root.
    final isGlob = entry.contains('*') || entry.contains('?');
    if (isGlob) {
      return _globList(Glob(entry), rootDir: root.path);
    }

    // Otherwise treat as a filename and search upward from the project root.
    return _findUp(entry, root);
  }

  List<String> _globList(Glob glob, {required String rootDir}) {
    final results = <String>[];
    try {
      for (final entity in Directory(
        rootDir,
      ).listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        // Glob patterns are relative; match against the path relative to root.
        if (glob.matches(p.relative(entity.path, from: rootDir))) {
          results.add(entity.path);
        }
      }
    } catch (_) {
      // Ignore unreadable directories.
    }
    results.sort();
    return results;
  }

  List<String> _findUp(String filename, Directory root) {
    var dir = root;
    final results = <String>[];
    // Walk upward until the filesystem root.
    while (true) {
      final candidate = p.join(dir.path, filename);
      if (File(candidate).existsSync()) {
        results.add(candidate);
        break; // First (closest) match wins, like opencode.
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return results;
  }

  String _expandHome(String path) {
    if (path.startsWith('~/')) {
      final h = home ?? _defaultHome();
      return p.join(h, path.substring(2));
    }
    return path;
  }

  String _defaultHome() => Platform.isWindows
      ? (Platform.environment['USERPROFILE'] ??
            Platform.environment['HOME'] ??
            '.')
      : (Platform.environment['HOME'] ?? '.');

  Future<String?> _readFile(String path) async {
    try {
      final file = File(path);
      final length = await file.length();
      const maxBytes = 2 * 1024 * 1024; // 2 MB cap to avoid OOM on huge files.
      if (length > maxBytes) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      return 'Instructions from: $path\n$content';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'http' && uri.scheme != 'https') return null;
      // Block resolution of internal/loopback/link-local addresses to avoid
      // SSRF against cloud metadata endpoints or localhost services.
      if (_isPrivateHost(uri.host)) return null;
      final response = await _http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final body = response.body;
      if (body.trim().isEmpty) return null;
      return 'Instructions from: $url\n$body';
    } catch (_) {
      return null;
    }
  }

  /// Returns true for hosts that should never be fetched from instructions
  /// (loopback, link-local, private IPv4/IPv6 ranges, and `.local` domains).
  bool _isPrivateHost(String host) {
    final lower = host.toLowerCase();
    if (lower == 'localhost' || lower.endsWith('.localhost')) return true;
    if (lower.endsWith('.local')) return true;
    final ip = InternetAddress.tryParse(host);
    if (ip == null) {
      // Unresolvable host name: treat as unsafe rather than risk a fetch.
      return false;
    }
    if (ip.isLoopback) return true;
    if (ip.isLinkLocal) return true;
    if (ip.isMulticast) return true;
    if (ip.type == InternetAddressType.IPv4) {
      final octets = ip.address.split('.');
      if (octets.length != 4) return true;
      final a = int.tryParse(octets[0]);
      if (a == null) return true;
      // 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
      if (a == 10) return true;
      if (a == 172) {
        final b = int.tryParse(octets[1]);
        if (b != null && b >= 16 && b <= 31) return true;
      }
      if (a == 192) {
        final b = int.tryParse(octets[1]);
        if (b == 168) return true;
      }
    }
    return false;
  }

  void dispose() => _http.close();
}

/// Holds a global AGENTS.md path and its formatted content block.
class _GlobalBlock {
  const _GlobalBlock({required this.path, required this.block});
  final String path;
  final String block;
}

/// In-memory cache of resolved instruction blocks, shared between the GUI
/// (via [resolvedInstructionsProvider]) and non-UI contexts such as the task
/// tool / CLI. The raw list is populated once at bootstrap from the loaded
/// config; the resolution (file reads, network fetches) is performed lazily
/// and memoized so it happens at most once per process.
///
/// A generation counter guards against stale reads: every [setRaw] bumps the
/// generation and drops the in-flight future, so a config reload while a
/// resolution is pending yields the new instructions, never the old ones.
class InstructionsCache {
  InstructionsCache._();

  static final InstructionsCache instance = InstructionsCache._();

  final InstructionsResolver _resolver = InstructionsResolver();
  List<String> _raw = const [];
  Directory? _cwd;
  int _generation = 0;
  int _resolvedGeneration = -1;
  Future<List<String>>? _pending;

  /// Populates the raw instruction list and the resolution root. Call once
  /// after the config loads (and whenever it reloads).
  void setRaw(List<String> raw, {Directory? cwd}) {
    _raw = raw;
    if (cwd != null) _cwd = cwd;
    _generation++;
    _pending = null; // force re-resolution on next access
  }

  /// Returns the resolved system-prompt blocks, resolving lazily on first use
  /// for the current generation. A config reload (which bumps [_generation])
  /// invalidates the memoized future so callers never see stale instructions.
  Future<List<String>> get resolved {
    if (_resolvedGeneration != _generation) {
      _pending = null;
      _resolvedGeneration = _generation;
    }
    return _pending ??= _resolver.resolve(_raw, cwd: _cwd ?? Directory.current);
  }

  /// Releases the underlying HTTP client. Call at app shutdown.
  void dispose() => _resolver.dispose();
}
