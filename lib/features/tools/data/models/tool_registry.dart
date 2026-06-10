import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/permission/evaluator.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/shared/utils/logger.dart';

import 'tool.dart';
import 'dart:async';

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

  final Map<String, Map<String, dynamic>> _resultCache = {};
  final Map<String, Future<Map<String, dynamic>>> _pendingCache = {};

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
    LogTags.permission.logInfo(
      'ToolRegistry._convert: Converting tool ${def.id}',
    );
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

        final cacheKey =
            '${def.id}:${sessionId ?? "null"}:${_normalizeInput(inputMap)}';

        // Check result cache
        if (_resultCache.containsKey(cacheKey)) {
          LogTags.permission.logInfo(
            'ToolRegistry.execute: Cache HIT for ${def.id}, sessionId=$sessionId',
          );
          return _resultCache[cacheKey]!;
        }

        // Check pending cache (in-flight)
        if (_pendingCache.containsKey(cacheKey)) {
          LogTags.permission.logInfo(
            'ToolRegistry.execute: Reusing in-flight ${def.id}, sessionId=$sessionId',
          );
          return _pendingCache[cacheKey]!;
        }

        LogTags.permission.logInfo(
          'ToolRegistry.execute: Cache MISS for ${def.id}, sessionId=$sessionId, creating future',
        );

        final completer = Completer<Map<String, dynamic>>();
        _pendingCache[cacheKey] = completer.future;

        try {
          LogTags.permission.logInfo(
            'ToolRegistry.execute: START tool=${def.id}, sessionId=$sessionId',
          );

          Future<Map<String, dynamic>> run() async {
            // Doom-loop guard: detect repeated identical calls
            if (_DoomLoopTracker.check(sessionId, def.id, inputMap)) {
              LogTags.permission.logInfo(
                'ToolRegistry.execute: Doom loop detected for tool=${def.id}',
              );
              final doomRule = evaluate('doom_loop', def.id, [
                PermissionRuleset(
                  rules: [..._defaultRules.rules],
                  sessionApproved: permissions.approvedRules,
                ),
              ]);
              if (doomRule.action == PermissionAction.deny) {
                LogTags.permission.logInfo(
                  'ToolRegistry.execute: Doom loop denied, returning empty',
                );
                return {'output': ''};
              }
              if (doomRule.action != PermissionAction.ask) {
                LogTags.permission.logInfo(
                  'ToolRegistry.execute: Doom loop not asking, proceeding',
                );
                // proceed to actual tool call below
              } else {
                LogTags.permission.logInfo(
                  'ToolRegistry.execute: Asking for doom loop permission',
                );
                await permissions.ask(
                  PermissionRequest(
                    id: 'doom_${DateTime.now().microsecondsSinceEpoch}',
                    toolName: def.id,
                    permission: 'doom_loop',
                    patterns: [def.id],
                    metadata: {
                      'sessionId': sessionId,
                      'input': inputMap.toString(),
                    },
                  ),
                  PermissionRuleset(
                    rules: [..._defaultRules.rules],
                    sessionApproved: permissions.approvedRules,
                  ),
                );
                // User approved — proceed
              }
            }

            LogTags.permission.logInfo(
              'ToolRegistry.execute: About to run() for tool=${def.id}',
            );
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
                    LogTags.permission.logInfo(
                      'ToolRegistry.ask: CALLED tool=${def.id}, permission=$permission, patterns=$patterns',
                    );
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
                    LogTags.permission.logInfo(
                      'ToolRegistry.ask: RETURNED tool=${def.id}',
                    );
                  },
            );

            LogTags.permission.logInfo(
              'ToolRegistry.execute: Calling tool ${def.id}.execute()',
            );
            final result = await def.execute(inputMap, ctx);
            LogTags.permission.logInfo(
              'ToolRegistry.execute: Tool ${def.id}.execute() returned',
            );

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

          final result = await run();

          // Store in result cache
          _resultCache[cacheKey] = result;

          // Complete the completer
          completer.complete(result);

          // Remove from pending
          _pendingCache.remove(cacheKey);
          return result;
        } catch (e, st) {
          // On error, remove from pending so retry can re-execute
          _pendingCache.remove(cacheKey);
          if (!completer.isCompleted) {
            completer.completeError(e, st);
          }
          rethrow;
        }
      },
    );
  }

  String _truncate(String output) {
    if (output.length <= _maxOutputChars) return output;
    return '${output.substring(0, _maxOutputChars)}\n\n[Output truncated: ${output.length} chars]';
  }

  String _normalizeInput(Map<String, dynamic> input) {
    final entries = input.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final parts = <String>[];
    for (final e in entries) {
      if (e.value is Map<String, dynamic>) {
        parts.add(
          '${e.key}:${_normalizeInput(Map<String, dynamic>.from(e.value))}',
        );
      } else if (e.value is List) {
        parts.add('${e.key}:${e.value}');
      } else {
        parts.add('${e.key}:${e.value}');
      }
    }
    return parts.join(',');
  }
}
