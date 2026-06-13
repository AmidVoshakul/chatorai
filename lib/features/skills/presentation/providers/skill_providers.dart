import 'dart:io';

import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/skills/domain/services/skill_plugin.dart';
import 'package:chatorai/features/skills/domain/services/skill_service.dart';
import 'package:chatorai/features/skills/domain/sources/directory_source.dart';
import 'package:chatorai/features/skills/domain/sources/skill_source.dart';
import 'package:chatorai/features/skills/domain/sources/url_source.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Default skill directories (relative to project root).
List<String> defaultSkillPaths() {
  return [
    '.chatorai/skills',
    // временно закоментировано чтобы не конфликтовать с скиллами программы opencode в текущем проекте
    // '.opencode/skills',
    '.agents/skills',
    '.claude/skills',
  ];
}

/// Built-in skill plugins (currently empty).
List<SkillPlugin> defaultSkillPlugins() {
  return [
    // Example: WelcomePlugin(), HelpPlugin(), etc.
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
    sources.add(DirectorySource(rootPath: path));
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
  final plugins = defaultSkillPlugins();
  final permissionService = ref.read(permissionServiceProvider);
  // Seed permission service with config rules, or defaults if none provided
  final permissionConfig = config.permission as Map<String, dynamic>? ?? {};
  final List<PermissionRule> rulesList;
  if (permissionConfig.isEmpty) {
    // No custom permission rules, use built-in defaults (skills allowed)
    rulesList = PermissionRuleset.defaults().rules;
  } else {
    rulesList = PermissionRuleset.fromConfig(permissionConfig);
  }
  permissionService.seedRules(PermissionRuleset(rules: rulesList));
  return SkillService(
    sources: sources,
    plugins: plugins,
    permissionService: permissionService,
  );
});
