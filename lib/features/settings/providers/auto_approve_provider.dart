import 'dart:io';

import 'package:chatorai/core/config/config_manager.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/config_writer.dart';
import 'package:chatorai/core/config/models/permission_section.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Auto-Approve categories exposed to the UI.
///
/// Mirrors the built-in defaults from [PermissionRuleset.defaults()] minus the
/// hidden internal categories (`question`, `plan_enter`, `plan_exit`).
class AutoApproveCategory {
  final String id;
  final String label;
  final String description;
  final String? defaultAction;
  final Map<String, String> exceptions;
  final bool isFileCategory;
  final bool isShellCategory;

  const AutoApproveCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.defaultAction,
    required this.exceptions,
    this.isFileCategory = false,
    this.isShellCategory = false,
  });

  AutoApproveCategory copyWith({
    String? defaultAction,
    Map<String, String>? exceptions,
    bool clearDefaultAction = false,
  }) {
    return AutoApproveCategory(
      id: id,
      label: label,
      description: description,
      defaultAction: clearDefaultAction
          ? null
          : (defaultAction ?? this.defaultAction),
      exceptions: exceptions ?? this.exceptions,
      isFileCategory: isFileCategory,
      isShellCategory: isShellCategory,
    );
  }
}

class AutoApproveState {
  final List<AutoApproveCategory> categories;
  final bool supportsProjectScope;
  final AutoApproveScope scope;

  const AutoApproveState({
    required this.categories,
    required this.supportsProjectScope,
    this.scope = AutoApproveScope.global,
  });

  AutoApproveState copyWith({
    List<AutoApproveCategory>? categories,
    bool? supportsProjectScope,
    AutoApproveScope? scope,
  }) {
    return AutoApproveState(
      categories: categories ?? this.categories,
      supportsProjectScope: supportsProjectScope ?? this.supportsProjectScope,
      scope: scope ?? this.scope,
    );
  }
}

enum AutoApproveScope { global, project }

/// UI-facing labels for scope selection.
extension AutoApproveScopeX on AutoApproveScope {
  String get label {
    switch (this) {
      case AutoApproveScope.global:
        return 'Global';
      case AutoApproveScope.project:
        return 'Project';
    }
  }
}

class AutoApproveNotifier extends AsyncNotifier<AutoApproveState> {
  static const _categories = <String>[
    'read',
    'glob',
    'grep',
    'shell',
    'edit',
    'write',
    'webfetch',
    'websearch',
    'doom_loop',
    'skill',
    'lsp',
    'task',
    'external_directory',
    'todowrite',
  ];

  static const _fileCategories = <String>{
    'external_directory',
    'read',
    'edit',
    'write',
    'glob',
    'grep',
  };

  static const _shellCategories = <String>{'shell'};

  String? _overridePath;

  /// Test hook: point the notifier at an isolated config file.
  ///
  /// Invalidates the provider so the next read rebuilds from [path] (the
  /// notifier may already have built from the default global config before
  /// this hook is called).
  void setConfigPathForTest(String path) {
    _overridePath = path;
    ref.invalidateSelf();
  }

  @override
  Future<AutoApproveState> build() => _load();

  /// Resolves the concrete config file for the active scope.
  ///
  /// [_overridePath] (test hook) always wins. Otherwise the global file is
  /// resolved via [ConfigWriter], and the project file via the workspace root
  /// (matching [ConfigLoader._projectConfigPath]) so it is absolute and
  /// independent of the process working directory.
  Future<String> _scopeConfigPath(bool global) async {
    if (_overridePath != null) return _overridePath!;
    if (global) return await ConfigWriter.resolveConfigPath(global: true);
    return p.join(workspaceRuntimeCurrent.path, '.chatorai', 'chatorai.json');
  }

  Future<AutoApproveState> _load() async {
    final scope = state.value?.scope ?? AutoApproveScope.global;
    final path = await _scopeConfigPath(scope == AutoApproveScope.global);
    final config = await ConfigManager.loadConfig(path: path);
    final permissionConfig = config.permission as Map<String, dynamic>? ?? {};
    final builtinDefaults = PermissionRuleset.defaults();

    final categories = _categories.map((id) {
      final builtinRule = builtinDefaults.rules.firstWhere(
        (r) => r.permission == id && r.pattern == '*',
        orElse: () => PermissionRule(
          permission: id,
          pattern: '*',
          action: PermissionAction.ask,
        ),
      );

      final effectiveDefault = _resolveDefault(
        permissionConfig[id],
        builtinRule.action,
      );
      final exceptions = _resolveExceptions(permissionConfig[id]);

      return AutoApproveCategory(
        id: id,
        label: _labelFor(id),
        description: '',
        defaultAction: effectiveDefault,
        exceptions: exceptions,
        isFileCategory: _fileCategories.contains(id),
        isShellCategory: _shellCategories.contains(id),
      );
    }).toList();

    final supportsProjectScope = _supportsProjectScope();

    return AutoApproveState(
      categories: categories,
      supportsProjectScope: supportsProjectScope,
      scope: scope,
    );
  }

  Future<void> save({
    required String categoryId,
    required String? defaultAction,
    required Map<String, String> exceptions,
  }) async {
    final currentState = state.value;
    if (currentState == null) {
      throw StateError('AutoApproveState is not loaded');
    }

    final builtinDefaults = PermissionRuleset.defaults();
    final global = currentState.scope == AutoApproveScope.global;
    final path = await _scopeConfigPath(global);

    // Read the EXISTING permission section so keys not managed by the UI
    // (e.g. custom/hand-edited permission entries) are preserved on save.
    final config = await ConfigWriter.readRawConfig(path);
    final permission = Map<String, dynamic>.from(
      config['permission'] as Map? ?? {},
    );

    for (final cat in currentState.categories) {
      final targetDefault = cat.id == categoryId
          ? defaultAction
          : cat.defaultAction;
      final targetExceptions = cat.id == categoryId
          ? exceptions
          : cat.exceptions;

      // Inherit: drop the key so built-in defaults apply.
      if (targetDefault == null && targetExceptions.isEmpty) {
        permission.remove(cat.id);
        continue;
      }

      final builtinRule = builtinDefaults.rules.firstWhere(
        (r) => r.permission == cat.id && r.pattern == '*',
        orElse: () => PermissionRule(
          permission: cat.id,
          pattern: '*',
          action: PermissionAction.ask,
        ),
      );
      final effectiveDefault = targetDefault ?? builtinRule.action.name;

      if (targetExceptions.isEmpty) {
        permission[cat.id] = effectiveDefault;
      } else {
        final map = <String, String>{'*': effectiveDefault};
        map.addAll(targetExceptions);
        permission[cat.id] = map;
      }
    }

    await ConfigWriter.upsertPermissionSection(
      permission,
      global: global,
      configPath: path,
    );

    // Invalidate cascading providers so the new rules take effect immediately.
    ref.invalidate(configProvider);
    // Refresh our own state from disk.
    state = AsyncValue.data(await _load());
  }

  Future<void> setScope(AutoApproveScope scope) async {
    final currentState = state.value;
    if (currentState == null) return;
    state = AsyncValue.data(currentState.copyWith(scope: scope));
    // Reload from the newly selected scope's file.
    state = AsyncValue.data(await _load());
  }

  String? _resolveDefault(dynamic configValue, PermissionAction builtin) {
    if (configValue == null) return null;
    if (configValue is PermissionRuleConfig) {
      return configValue.defaultAction;
    }
    if (configValue is String) return configValue;
    if (configValue is Map) {
      final wildcard = configValue['*'];
      if (wildcard is String) return wildcard;
    }
    return null;
  }

  Map<String, String> _resolveExceptions(dynamic configValue) {
    if (configValue is PermissionRuleConfig) {
      return Map<String, String>.from(configValue.patternActions ?? {});
    }
    if (configValue is! Map) return const {};
    final result = <String, String>{};
    for (final entry in configValue.entries) {
      if (entry.key == '*') continue;
      if (entry.value is String) {
        result[entry.key] = entry.value as String;
      }
    }
    return result;
  }

  bool _supportsProjectScope() {
    // Project-scoped config is only available on desktop platforms.
    if (Platform.isAndroid || Platform.isIOS) return false;
    return true;
  }

  static String _labelFor(String id) {
    switch (id) {
      case 'read':
        return 'Read';
      case 'glob':
        return 'Glob';
      case 'grep':
        return 'Grep';
      case 'shell':
        return 'Shell';
      case 'edit':
        return 'Edit';
      case 'write':
        return 'Write';
      case 'webfetch':
        return 'Web Fetch';
      case 'websearch':
        return 'Web Search';
      case 'doom_loop':
        return 'Doom Loop';
      case 'skill':
        return 'Skill';
      case 'lsp':
        return 'LSP';
      case 'task':
        return 'Task';
      case 'external_directory':
        return 'External Directory';
      case 'todowrite':
        return 'Todo Write';
      default:
        return id;
    }
  }
}

/// Provider for the Auto-Approve settings screen.
final autoApproveProvider =
    AsyncNotifierProvider<AutoApproveNotifier, AutoApproveState>(() {
      return AutoApproveNotifier();
    });
