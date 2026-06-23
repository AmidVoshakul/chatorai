import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/permission/evaluator.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_execution.dart';
import 'package:chatorai/shared/utils/logger.dart';

// ---------------------------------------------------------------------------
// ToolRegistry — thin facade: registration + SDK conversion.
// Execution logic is delegated to ToolExecutor (single responsibility).
// ---------------------------------------------------------------------------
class ToolRegistry {
  // Registration layer
  final List<ToolDef> _tools = [];
  final PermissionRuleset _defaultRules;

  // Execution layer (composed, not inherited)
  final ToolExecutor _executor;

  ToolRegistry(PermissionService permissions, this._defaultRules)
    : _executor = ToolExecutor(permissions, _defaultRules);

  // ---- Registration API ----

  void register(ToolDef tool) {
    if (!_tools.any((t) => t.id == tool.id)) _tools.add(tool);
  }

  List<ToolDef> get all => List.unmodifiable(_tools);
  List<String> get ids => _tools.map((t) => t.id).toList();

  ToolDef? get(String id) {
    for (final t in _tools) {
      if (t.id == id) return t;
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

  // ---- Session cleanup ----

  void pruneSession(String sessionId) => _executor.pruneSession(sessionId);
}
