import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/permission/evaluator.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_execution.dart';

// ---------------------------------------------------------------------------
// ToolRegistry —  registry with lazy init, tagging, and
// named access. Thin facade; execution logic delegated to ToolExecutor.
// ---------------------------------------------------------------------------
class ToolRegistry {
  // Registration layer
  final List<ToolDef> _tools = [];
  final PermissionRuleset _defaultRules;
  final PermissionService _permissions;

  // Execution layer (composed, not inherited)
  final ToolExecutor _executor;

  void Function(String agentId, {String? messageText})? switchAgent;

  ToolRegistry(this._permissions, this._defaultRules)
    : _executor = ToolExecutor(_permissions, _defaultRules);

  set agentRules(PermissionRuleset? rules) {
    _executor.agentRules = rules;
  }

  PermissionRuleset? get agentRules => _executor.agentRules;

  set switchAgentCallback(
    void Function(String agentId, {String? messageText})? callback,
  ) {
    switchAgent = callback;
    _executor.switchAgent = callback;
  }

  // ---- Registration API ----

  void register(ToolDef tool) {
    if (!contains(tool.id)) _tools.add(tool);
  }

  List<ToolDef> get all => List.unmodifiable(_tools);
  List<String> get ids => _tools.map((t) => t.id).toList();

  bool contains(String id) => _tools.any((t) => t.id == id);

  bool remove(String id) {
    final idx = _tools.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tools.removeAt(idx);
      return true;
    }
    return false;
  }

  ToolDef? get(String id) {
    for (final t in _tools) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<ToolDef> get available {
    final rulesets = <PermissionRuleset>[
      PermissionRuleset(rules: [..._defaultRules.rules]),
      if (_executor.agentRules != null) _executor.agentRules!,
      PermissionRuleset(rules: [], sessionApproved: _permissions.approvedRules),
      PermissionRuleset(
        rules: [],
        sessionApproved: _permissions.onceApprovedRules,
      ),
    ];

    return _tools
        .where(
          (t) => evaluate(t.id, '*', rulesets).action != PermissionAction.deny,
        )
        .toList();
  }

  // ---- Named access  ----

  ToolDef? get task {
    try {
      return _tools.firstWhere((t) => t.id == 'task');
    } catch (_) {
      return null;
    }
  }

  ToolDef? get read {
    try {
      return _tools.firstWhere((t) => t.id == 'read');
    } catch (_) {
      return null;
    }
  }

  // ---- SDK conversion ----

  Map<String, sdk.Tool<dynamic, dynamic>> toSDKTools() {
    final result = <String, sdk.Tool<dynamic, dynamic>>{};
    for (final def in available) {
      result[def.id] = sdk.Tool<dynamic, dynamic>(
        inputSchema: sdk.Schema(
          jsonSchema: def.inputSchema,
          fromJson: (j) => j,
        ),
        description: def.description,
        executeDynamic: (input, options) async {
          final result = await _executor.execute(def, input, options);
          // Preserve structured content blocks (e.g. files, outputPath) when
          // the tool explicitly provides them via metadata['structured'].
          final meta = result['metadata'] as Map<String, dynamic>?;
          if (meta != null && meta['structured'] != null) {
            return meta['structured'];
          }
          if (result.containsKey('output')) return result['output'] as String;
          if (result.containsKey('message')) return result['message'] as String;
          return result.toString();
        },
      );
    }
    return result;
  }

  ToolExecutor get executor => _executor;
  void pruneSession(String sessionId) => _executor.pruneSession(sessionId);
}
