import 'dart:io';

import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_source.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:path/path.dart' as p;

final _logger = LogTags.skills;

/// Filename that identifies a skill inside its directory.
const String kSkillFileName = 'SKILL.md';

/// Directory (relative to a scope root) that holds managed skills for the
/// project scope. Global skills live in `<XDG_CONFIG_HOME>/skills`.
const String kProjectSkillsSubdir = '.chatorai/skills';

/// Creates, deletes, reads and installs *managed* skills on disk.
///
/// A managed skill is a directory `<scopeRoot>/<slug>/` containing a
/// `SKILL.md`. The writer never mutates `chatorai.json`; skills are discovered
/// straight from the filesystem, so writing a `SKILL.md` is enough for a
/// running chat to pick it up (after the skill service is invalidated).
///
/// All destructive operations validate that the target path is safely
/// contained within a scope root, rejecting path traversal.
class SkillWriter {
  SkillWriter({Future<String> Function()? globalConfigDir})
    : _globalConfigDir = globalConfigDir ?? (() => XdgPaths.configHomeAsync);

  final Future<String> Function() _globalConfigDir;

  /// Canonical root for managed *global* skills: `<XDG_CONFIG_HOME>/skills`.
  Future<String> globalSkillsRoot() async {
    final dir = await _globalConfigDir();
    return p.join(dir, 'skills');
  }

  /// Canonical root for managed *project* skills:
  /// `<projectRoot>/.chatorai/skills`.
  String projectSkillsRoot(Directory projectRoot) =>
      p.join(projectRoot.path, kProjectSkillsSubdir);

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Reads the `SKILL.md` file inside [skillDirectory]. Returns an empty string
  /// when it is absent.
  Future<String> readSkillFile(String skillDirectory) async {
    final file = File(p.join(skillDirectory, kSkillFileName));
    if (!await file.exists()) return '';
    return file.readAsString();
  }

  /// Overwrites the `SKILL.md` inside [skillDirectory] with [content].
  Future<void> writeSkillFile(String skillDirectory, String content) async {
    final file = File(p.join(skillDirectory, kSkillFileName));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  /// Creates a managed skill at `<scopeRoot>/<slug(name)>/SKILL.md` with valid
  /// YAML frontmatter. Returns the created skill directory path.
  ///
  /// When [content] is provided it is used verbatim as the markdown body;
  /// otherwise a minimal placeholder body is written.
  Future<String> createSkill({
    required String scopeRoot,
    required String name,
    required String description,
    String? content,
  }) async {
    final slug = _slug(name);
    final skillDir = p.join(scopeRoot, slug);
    _assertWithin(scopeRoot, skillDir);

    if (await Directory(skillDir).exists()) {
      throw ArgumentError('Skill "$name" already exists at $skillDir');
    }

    final body = (content ?? '').trim();
    final md = _renderSkillMd(
      name: name.trim(),
      description: description.trim(),
      body: body,
    );
    await writeSkillFile(skillDir, md);
    _logger.logInfo('SkillWriter: created skill "$name" at $skillDir');
    return skillDir;
  }

  /// Renders a full `SKILL.md` document from frontmatter fields and a body.
  ///
  /// [name] and [description] are emitted as double-quoted, escaped YAML
  /// scalars so values containing `:`, `#`, quotes or newlines stay valid YAML
  /// and remain parseable by [SkillParser].
  String _renderSkillMd({
    required String name,
    required String description,
    required String body,
  }) {
    final buffer = StringBuffer()..writeln('---');
    _writeYamlString(buffer, 'name', name);
    _writeYamlString(buffer, 'description', description);
    buffer
      ..writeln('---')
      ..writeln();
    if (body.isNotEmpty) {
      buffer.writeln(body);
    } else {
      buffer.writeln('# $name');
    }
    return buffer.toString();
  }

  /// Writes a `key: "value"` line with the value escaped as a YAML
  /// double-quoted scalar.
  void _writeYamlString(StringBuffer buffer, String key, String value) {
    final escaped = value
        .replaceAll('\\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\r', r'\r')
        .replaceAll('\n', r'\n')
        .replaceAll('\t', r'\t');
    buffer.writeln('$key: "$escaped"');
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  /// Recursively deletes a managed skill directory. Throws [ArgumentError] when
  /// [skillDirectory] is not safely contained within [scopeRoot] (traversal /
  /// external path protection).
  Future<void> deleteSkill({
    required String scopeRoot,
    required String skillDirectory,
  }) async {
    _assertWithin(scopeRoot, skillDirectory);
    final dir = Directory(skillDirectory);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      _logger.logInfo('SkillWriter: deleted skill dir $skillDirectory');
    }
  }

  // ---------------------------------------------------------------------------
  // Install from bundled asset
  // ---------------------------------------------------------------------------

  /// Installs a bundled marketplace skill as `<scopeRoot>/<slug>/SKILL.md`.
  ///
  /// [content] is the already-loaded `SKILL.md` text (the asset read happens in
  /// the caller so this layer stays Flutter-free). [slug] comes from the
  /// catalog and is used verbatim as the directory name after a traversal
  /// check. Returns the created skill directory path.
  ///
  /// Throws [ArgumentError] when the target already exists (collision guard) or
  /// escapes [scopeRoot] (traversal guard).
  Future<String> installBundledSkill({
    required String scopeRoot,
    required String slug,
    required String content,
  }) async {
    final safeSlug = _slug(slug);
    final skillDir = p.join(scopeRoot, safeSlug);
    _assertWithin(scopeRoot, skillDir);

    if (await Directory(skillDir).exists()) {
      throw ArgumentError('Skill "$slug" already exists at $skillDir');
    }

    await writeSkillFile(skillDir, content);
    _logger.logInfo(
      'SkillWriter: installed bundled skill "$slug" at $skillDir',
    );
    return skillDir;
  }

  // ---------------------------------------------------------------------------
  // Install from URL
  // ---------------------------------------------------------------------------

  /// Installs every skill discovered by [source] into [destRoot], copying the
  /// skill directories out of the temporary download cache so they become
  /// ordinary managed skills. Returns the names of the installed skills.
  Future<List<String>> installFromSource({
    required SkillSource source,
    required String destRoot,
  }) async {
    final List<SkillInfo> discovered = await source.discover();
    final installed = <String>[];
    for (final skill in discovered) {
      final sourceDir = skill.directory.trim();
      if (sourceDir.isEmpty || !await Directory(sourceDir).exists()) {
        _logger.logWarning(
          'SkillWriter: skipping "${skill.name}" — invalid source dir '
          '"${skill.directory}"',
        );
        continue;
      }
      final slug = _slug(skill.name);
      final target = p.join(destRoot, slug);
      _assertWithin(destRoot, target);
      await _copyDirectory(Directory(sourceDir), Directory(target));
      installed.add(skill.name);
    }
    _logger.logInfo(
      'SkillWriter: installed ${installed.length} skill(s) into $destRoot',
    );
    return installed;
  }

  Future<void> _copyDirectory(Directory from, Directory to) async {
    if (!await from.exists()) {
      throw ArgumentError('Source directory does not exist: ${from.path}');
    }
    await to.create(recursive: true);
    await for (final entity in from.list(recursive: true)) {
      final rel = p.relative(entity.path, from: from.path);
      final targetPath = p.join(to.path, rel);
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await entity.copy(targetPath);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Rejects a candidate path that escapes [root] (absolute-elsewhere, `..`).
  void _assertWithin(String root, String candidate) {
    final normRoot = p.normalize(p.absolute(root));
    final normCandidate = p.normalize(p.absolute(candidate));
    final isWithin =
        normCandidate == normRoot || p.isWithin(normRoot, normCandidate);
    if (!isWithin) {
      throw ArgumentError('Path "$candidate" is not within scope root "$root"');
    }
  }

  /// Turns a display name (or catalog id) into a safe directory slug.
  ///
  /// Exposed statically so callers that must match an installed skill's
  /// directory name (e.g. marketplace "is installed" lookups) can derive the
  /// exact same slug this writer uses on disk, avoiding id/slug drift.
  static String slugify(String name) {
    final base = name.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]+'),
      '-',
    );
    final cleaned = base.replaceAll(RegExp(r'^-+|-+$'), '');
    return cleaned.isEmpty ? 'skill' : cleaned;
  }

  String _slug(String name) => slugify(name);
}
