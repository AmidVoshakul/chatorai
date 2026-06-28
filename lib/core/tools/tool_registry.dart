import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/permission/evaluator.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_definition.dart';
import 'package:chatorai/core/tools/tool_execution.dart';
import 'package:chatorai/shared/utils/logger.dart';

// ---------------------------------------------------------------------------
// ToolRegistry — OpenCode-inspired registry with lazy init, tagging, and
// named access. Thin facade; execution logic delegated to ToolExecutor.
// ---------------------------------------------------------------------------
class ToolRegistry {
  // Registration layer
  final List<ToolDef> _tools = [];
  final List<ToolDefinition> _definitions = [];
  final PermissionRuleset _defaultRules;

  // Execution layer (composed, not inherited)
  final ToolExecutor _executor;

  ToolRegistry(PermissionService permissions, this._defaultRules)
    : _executor = ToolExecutor(permissions, _defaultRules);

  // ---- Registration API ----

  void register(ToolDef tool) {
    if (!contains(tool.id)) _tools.add(tool);
  }

  void registerDefinition(ToolDefinition definition) {
    if (!contains(definition.id)) _definitions.add(definition);
  }

  Future<void> resolveAll() async {
    for (final def in _definitions) {
      final resolved = def.isResolved ? def.def : await def.resolve();
      if (!_tools.any((t) => t.id == resolved.id)) _tools.add(resolved);
    }
  }

  List<ToolDef> get all => List.unmodifiable(_tools);
  List<String> get ids => _tools.map((t) => t.id).toList();

  bool contains(String id) =>
      _tools.any((t) => t.id == id) || _definitions.any((d) => d.id == id);

  bool remove(String id) {
    final idx = _tools.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tools.removeAt(idx);
      return true;
    }
    final defIdx = _definitions.indexWhere((d) => d.id == id);
    if (defIdx != -1) {
      _definitions.removeAt(defIdx);
      _tools.removeWhere((t) => t.id == id);
      return true;
    }
    return false;
  }

  ToolDef? get(String id) {
    for (final t in _tools) {
      if (t.id == id) return t;
    }
    for (final d in _definitions) {
      if (d.id == id && d.isResolved) return d.def;
    }
    return null;
  }

  List<ToolDef> get available => _tools
      .where(
        (t) =>
            evaluate(t.id, '*', [_defaultRules]).action !=
            PermissionAction.deny,
      )
      .toList();

  // ---- Named access (OpenCode pattern) ----

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
    for (final def in _tools) {
      result[def.id] = _executor.bind(def, _convert(def));
    }
    return result;
  }

  sdk.Tool<dynamic, dynamic> _convert(ToolDef def) {
    LogTags.permission.logInfo(
      'ToolRegistry._convert: Converting tool ${def.id}',
    );
    return sdk.Tool<dynamic, dynamic>(
      inputSchema: sdk.Schema(jsonSchema: def.inputSchema, fromJson: (j) => j),
      description: def.description,
      executeDynamic: (input, options) =>
          _executor.execute(def, input, options),
    );
  }

  ToolExecutor get executor => _executor;
  void pruneSession(String sessionId) => _executor.pruneSession(sessionId);
}
