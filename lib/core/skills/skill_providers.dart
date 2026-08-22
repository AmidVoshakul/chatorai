import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/skills/directory_source.dart';
import 'package:chatorai/core/skills/skill_plugin.dart';
import 'package:chatorai/core/skills/skill_source.dart';
import 'package:chatorai/core/skills/url_source.dart';
import 'package:chatorai/core/skills/skill_service.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
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

/// Global user config directory via XDG_CONFIG_HOME.
String globalSkillPath() {
  final path = p.join(XdgPaths.configHome, 'skills');
  return path;
}

/// Build list of skill sources from config.
List<SkillSource> buildSkillSources(ChatOrAIConfig config) {
  final sources = <SkillSource>[];

  // 1. Default paths + global path
  final paths = <String>[...defaultSkillPaths()];
  paths.add(globalSkillPath());

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
  // Always start with defaults, layer config rules on top (last-match-wins)
  final permissionConfig = config.permission as Map<String, dynamic>? ?? {};
  final rulesList = <PermissionRule>[
    ...PermissionRuleset.defaults().rules,
    if (permissionConfig.isNotEmpty)
      ...PermissionRuleset.fromConfig(permissionConfig),
  ];
  permissionService.replaceDefaultRules(PermissionRuleset(rules: rulesList));
  return SkillService(
    sources: sources,
    plugins: plugins,
    permissionService: permissionService,
  );
});
