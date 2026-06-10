import 'dart:io';

import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/skills/domain/services/directory_source.dart';
import 'package:chatorai/features/skills/domain/services/skill_service.dart';
import 'package:chatorai/features/skills/domain/services/skill_source.dart';
import 'package:chatorai/features/skills/domain/services/url_source.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Default skill directories (relative to project root).
List<String> defaultSkillPaths() {
  return [
    '.chatorai/skills',
    // '.opencode/skills',
    '.agents/skills',
    '.claude/skills',
  ];
}

/// Global user config directory.
String? globalSkillPath() {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null) {
    return p.join(home, '.config', 'chatorai', 'skills');
  }
  return null;
}

/// Build list of skill sources from config.
List<SkillSource> buildSkillSources(ChatOrAIConfig config) {
  final sources = <SkillSource>[];

  // 1. Default paths + global path
  final paths = <String>[...defaultSkillPaths()];
  final global = globalSkillPath();
  if (global != null) {
    paths.add(global);
  }

  // 2. Add configured paths
  if (config.skills?.paths != null) {
    paths.addAll(config.skills!.paths);
  }

  // Create DirectorySource for each path
  for (final path in paths) {
    sources.add(DirectorySource(path));
  }

  // 3. Create UrlSource for configured URLs
  if (config.skills?.urls != null) {
    for (final urlConfig in config.skills!.urls) {
      try {
        final cfg = UrlSourceConfig.fromJson(urlConfig);
        sources.add(UrlSource(config: cfg));
      } catch (e) {
        LogTags.skills.logWarning('Failed to create UrlSource from config: $e');
      }
    }
  }

  return sources;
}

/// Skill service provider (async, depends on config).
final skillServiceProvider = FutureProvider<SkillService>((ref) async {
  final config = await ref.watch(configProvider.future);
  final sources = buildSkillSources(config);
  final permissionService = ref.read(permissionServiceProvider);
  // Seed permission service with config rules before any permission checks
  final rulesList = PermissionRuleset.fromConfig(config.permission);
  permissionService.seedRules(PermissionRuleset(rules: rulesList));
  return SkillService(sources: sources, permissionService: permissionService);
});
