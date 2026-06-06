import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/permissions/evaluator.dart';
import 'package:chatorai/permissions/permission_service.dart';
import 'package:chatorai/permissions/rule.dart';
import 'package:chatorai/permissions/ruleset.dart';
import 'tool.dart';

const _doomLoopThreshold = 3;
const _maxOutputChars = 2000;

// ---------------------------------------------------------------------------
// Doom-loop tracker
// ---------------------------------------------------------------------------
class _DoomLoopTracker {
  // Map<sessionId, Map<toolName, List<jsonInput>>>
  static final _history = <String?, Map<String, List<String>>>{};

  static bool check(
    String? sessionId,
    String toolName,
    Map<String, dynamic> input,
  ) {
    _history.putIfAbsent(sessionId, () => {});
    final perTool = _history[sessionId]!;
    perTool.putIfAbsent(toolName, () => []);
    final jsonInput = input.toString();
    final currentCount = perTool[toolName]!.where((c) => c == jsonInput).length;
    if (currentCount >= _doomLoopThreshold) return true;
    perTool[toolName]!.add(jsonInput);
    return false;
  }
}

// ---------------------------------------------------------------------------
// Tool registry
// ---------------------------------------------------------------------------
class ToolRegistry {
  final List<ToolDef> _tools = [];
  final PermissionService _permissions;
  final PermissionRuleset _defaultRules;

  ToolRegistry(this._permissions, this._defaultRules);

  void register(ToolDef tool) {
    if (!_tools.any((t) => t.id == tool.id)) {
      _tools.add(tool);
    }
  }

  List<ToolDef> get all => List.unmodifiable(_tools);

  List<String> get ids => _tools.map((t) => t.id).toList();

  ToolDef? get(String id) {
    for (final t in _tools) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<ToolDef> get available {
    return _tools.where((t) {
      final rule = evaluate(t.id, '*', [_defaultRules]);
      return rule.action != PermissionAction.deny;
    }).toList();
  }

  Map<String, sdk.Tool<dynamic, dynamic>> toSDKTools() {
    final result = <String, sdk.Tool<dynamic, dynamic>>{};
    for (final def in _tools) {
      result[def.id] = _convert(def);
    }
    return result;
  }

  sdk.Tool<dynamic, dynamic> _convert(ToolDef def) {
    final permissions = _permissions;
    return sdk.Tool<dynamic, dynamic>(
      inputSchema: sdk.Schema(jsonSchema: def.inputSchema, fromJson: (j) => j),
      description: def.description,
      executeDynamic: (input, options) async {
        final inputMap = input as Map<String, dynamic>;
        final experimentalContext = options.experimentalContext;
        final rawSessionId = experimentalContext != null
            ? experimentalContext['sessionId'] as String?
            : null;
        final sessionId = (rawSessionId == null || rawSessionId.isEmpty)
            ? null
            : rawSessionId;

        Future<Map<String, dynamic>> run() async {
          final ctx = ToolContext(
            toolCallId: options.toolCallId ?? '',
            abortSignal: options.abortSignal,
            sessionId: sessionId,
            ask:
                ({
                  required String permission,
                  required List<String> patterns,
                  Map<String, dynamic>? metadata,
                  List<String>? always,
                }) async {
                  final reqMetadata = Map<String, dynamic>.from(
                    metadata ?? inputMap,
                  );
                  if (sessionId != null) {
                    reqMetadata['sessionId'] = sessionId;
                  }
                  await permissions.ask(
                    PermissionRequest(
                      id: 'req_${DateTime.now().microsecondsSinceEpoch}_${def.id}',
                      toolName: def.id,
                      permission: permission,
                      patterns: patterns,
                      metadata: reqMetadata,
                      always: always ?? [],
                    ),
                    PermissionRuleset(
                      rules: [..._defaultRules.rules],
                      sessionApproved: permissions.approvedRules,
                    ),
                  );
                },
          );
          final result = await def.execute(inputMap, ctx);

          // Output truncation
          final truncated = _truncate(result.output);
          final output = truncated.length != result.output.length
              ? result.output.substring(0, truncated.length)
              : result.output;
          return {
            'output': output,
            if (result.metadata != null) 'metadata': result.metadata,
          };
        }

        // Doom-loop guard: detect repeated identical calls
        if (_DoomLoopTracker.check(sessionId, def.id, inputMap)) {
          final doomRule = evaluate('doom_loop', def.id, [
            PermissionRuleset(
              rules: [..._defaultRules.rules],
              sessionApproved: permissions.approvedRules,
            ),
          ]);
          if (doomRule.action == PermissionAction.deny) {
            return {'output': ''};
          }
          if (doomRule.action != PermissionAction.ask) {
            return await run();
          }
          await permissions.ask(
            PermissionRequest(
              id: 'doom_${DateTime.now().microsecondsSinceEpoch}',
              toolName: def.id,
              permission: 'doom_loop',
              patterns: [def.id],
              metadata: {'sessionId': sessionId, 'input': inputMap.toString()},
            ),
            PermissionRuleset(
              rules: [..._defaultRules.rules],
              sessionApproved: permissions.approvedRules,
            ),
          );
          // User approved — proceed
        }
        return await run();
      },
    );
  }

  String _truncate(String output) {
    if (output.length <= _maxOutputChars) return output;
    return '${output.substring(0, _maxOutputChars)}\n\n[Output truncated: ${output.length} chars]';
  }
}
