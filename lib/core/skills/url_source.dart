import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'skill_source.dart';

/// Optional client injection for testing.
typedef HttpClientFactory = http.Client Function();

/// Configuration for a URL-based skill source.
class UrlSourceConfig {
  final String baseUrl;
  final Duration cacheTtl;
  final String? apiKey;

  const UrlSourceConfig({
    required this.baseUrl,
    this.cacheTtl = const Duration(hours: 1),
    this.apiKey,
  });

  factory UrlSourceConfig.fromJson(Map<String, dynamic> json) {
    return UrlSourceConfig(
      baseUrl: json['url'] as String,
      cacheTtl: json['cache_ttl'] != null
          ? Duration(seconds: json['cache_ttl'] as int)
          : const Duration(hours: 1),
      apiKey: json['api_key'] as String?,
    );
  }
}

/// Discovers skills from remote URLs via index.json.
///
/// Expected index format:
/// ```json
/// {
///   "skills": [
///     {
///       "name": "skill-name",
///       "description": "Short description",
///       "files": [
///         { "path": "SKILL.md", "url": "https://..." },
///         { "path": "script.py", "url": "https://..." }
///       ]
///     }
///   ]
/// }
/// ```
class UrlSource implements SkillSource {
  final UrlSourceConfig config;
  final String _key;
  final http.Client? _client; // For testing injection
  static const String _indexFileName = 'index.json';

  UrlSource({required this.config, http.Client? client})
    : _client = client,
      _key = 'url:${config.baseUrl}';

  @override
  String get key => _key;

  @override
  Future<List<SkillInfo>> discover() async {
    LogTags.skills.logInfo('UrlSource: fetching index from ${config.baseUrl}');
    try {
      final index = await _fetchIndex();
      final skills = <SkillInfo>[];

      for (final skillEntry in index['skills'] as List<dynamic>) {
        final skillMap = skillEntry as Map<String, dynamic>;
        final name = skillMap['name'] as String;
        final description = skillMap['description'] as String? ?? '';
        final files = (skillMap['files'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        if (files.isEmpty) {
          LogTags.skills.logWarning(
            'UrlSource: skill "$name" has no files, skipping',
          );
          continue;
        }

        // Verify SKILL.md exists
        final hasSkillMd = files.any(
          (f) => p.basename(f['path'] as String) == 'SKILL.md',
        );
        if (!hasSkillMd) {
          LogTags.skills.logWarning(
            'UrlSource: skill "$name" missing SKILL.md, skipping',
          );
          continue;
        }

        // Download all files for this skill into cache
        final skillDir = await _downloadSkillFiles(name, files);

        // Read SKILL.md content
        final skillMdPath = p.join(skillDir, 'SKILL.md');
        final skillContent = await File(skillMdPath).readAsString();

        // Gather auxiliary files (excluding SKILL.md)
        final auxFiles = <String>[];
        try {
          final dir = Directory(skillDir);
          final entities = await dir.list().toList();
          for (final entity in entities) {
            if (entity is File && p.basename(entity.path) != 'SKILL.md') {
              auxFiles.add(p.relative(entity.path, from: skillDir));
            }
          }
          auxFiles.sort();
        } catch (e) {
          LogTags.skills.logWarning(
            'UrlSource: failed to list files for $name: $e',
          );
        }

        final filesList = auxFiles.take(10).toList();
        final skillInfo = SkillInfo(
          name: name,
          description: description,
          directory: skillDir,
          content: skillContent,
          files: filesList,
        );
        skills.add(skillInfo);
      }

      LogTags.skills.logInfo(
        'UrlSource: discovered ${skills.length} skills from ${config.baseUrl}',
      );
      return skills;
    } catch (e, stack) {
      LogTags.skills.logError(
        'UrlSource: failed to fetch from ${config.baseUrl}',
        e,
        stack,
      );
      return const [];
    }
  }

  Future<Map<String, dynamic>> _fetchIndex() async {
    final uri = Uri.parse('${config.baseUrl}/$_indexFileName');
    final headers = <String, String>{'Accept': 'application/json'};
    if (config.apiKey != null) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    final client = _client ?? http.Client();
    final response = await client
        .get(uri, headers: headers)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Fetching $uri'),
        );

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to fetch index: HTTP ${response.statusCode}',
        uri: uri,
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<String> _downloadSkillFiles(
    String skillName,
    List<Map<String, dynamic>> files,
  ) async {
    // Create cache directory: ~/.cache/chatorai/skills/<url-hash>/<skill-name>/
    final cacheRoot = await _getCacheRoot();
    final urlHash = _hashString(config.baseUrl);
    final skillCacheDir = p.join(cacheRoot, urlHash, skillName);
    await Directory(skillCacheDir).create(recursive: true);

    for (final file in files) {
      final relativePath = file['path'] as String;
      final fileUrl = file['url'] as String;
      final targetPath = p.join(skillCacheDir, relativePath);

      // Security: ensure target path is within cache directory
      final resolvedTarget = p.normalize(targetPath);
      if (!resolvedTarget.startsWith(skillCacheDir)) {
        LogTags.skills.logWarning(
          'UrlSource: path traversal attempt in "$relativePath", skipping',
        );
        continue;
      }

      // Security: validate filename (no dangerous characters)
      final fileName = p.basename(relativePath);
      if (_containsDangerousChars(fileName)) {
        LogTags.skills.logWarning(
          'UrlSource: dangerous filename "$fileName", skipping',
        );
        continue;
      }

      try {
        await _downloadFile(fileUrl, targetPath);
      } catch (e) {
        LogTags.skills.logWarning('UrlSource: failed to download $fileUrl: $e');
      }
    }

    return skillCacheDir;
  }

  Future<void> _downloadFile(String url, String targetPath) async {
    final uri = Uri.parse(url);
    final headers = <String, String>{};
    if (config.apiKey != null) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    final client = _client ?? http.Client();
    final response = await client
        .get(uri, headers: headers)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Downloading $url'),
        );

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to download $url: HTTP ${response.statusCode}',
        uri: uri,
      );
    }

    // Ensure parent directory exists
    final targetFile = File(targetPath);
    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(response.bodyBytes);
  }

  Future<String> _getCacheRoot() async {
    final cacheDir = await XdgPaths.cacheHomeAsync;
    return p.join(cacheDir, 'skills');
  }

  String _hashString(String input) {
    // Simple hash for directory name (not cryptographic)
    var hash = 0;
    for (final codeUnit in input.codeUnits) {
      hash = ((hash << 5) - hash) + codeUnit;
      hash = hash & 0xFFFFFFFF; // Keep within 32-bit
    }
    return hash.abs().toRadixString(36);
  }

  bool _containsDangerousChars(String filename) {
    // Disallow: path separators, null bytes, control chars
    return filename.contains('/') ||
        filename.contains('\\') ||
        filename.contains('\x00') ||
        filename.contains('\n') ||
        filename.contains('\r');
  }
}
