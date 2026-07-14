import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/permission/evaluator.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/tools/json_schema_validator.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_error.dart';
import 'package:chatorai/core/tools/truncation_service.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'package:chatorai/shared/utils/logger.dart';

// ---------------------------------------------------------------------------
// ToolExecutor — single-responsibility: execute tool calls with cache,
// doom-loop detection, and output truncation. No registration concerns.
// ---------------------------------------------------------------------------
class ToolExecutor {
  static const _doomLoopThreshold = 3;
  static const _sideEffectingTools = <String>{'bash', 'write'};

  // Session-scoped caches (pruned on session close)
  final Map<String, Map<String, dynamic>> _resultCache = {};
  final Map<String, Future<Map<String, dynamic>>> _pendingCache = {};

  // In-flight deduplication by toolCallId - prevents SDK retry from re-executing
  final Map<String, Future<Map<String, dynamic>>> _inFlightCache = {};

  // Doom-loop tracker: bounded per-session LRU
  static final _doomHistory = <String?, Map<String, List<String>>>{};
  static const _maxPerTool = 500;

  static const _maxPerSession = 2000;

  final PermissionService _permissions;
  final PermissionRuleset _defaultRules;
  void Function(String agentId, {String? messageText})? switchAgent;
  PermissionRuleset? agentRules;

  ToolExecutor(this._permissions, this._defaultRules, {this.switchAgent});

  /// Bind a ToolDef to the SDK Tool type, wiring execution through this executor.
  sdk.Tool<dynamic, dynamic> bind(
    ToolDef def,
    sdk.Tool<dynamic, dynamic> sdkTool,
  ) {
    return sdkTool;
  }

  /// Core execution: cache → pending → doom-loop → permission → truncate.
  Future<Map<String, dynamic>> execute(
    ToolDef def,
    dynamic rawInput,
    dynamic options,
  ) async {
    final inputMap = rawInput is Map<String, dynamic>
        ? rawInput
        : <String, dynamic>{'raw': rawInput};
    if (!def.skipValidation) {
      LogTags.permission.logDebug(
        'ToolExecutor: validate ${def.id} '
        'inputMap=$inputMap '
        'inputSchema=${def.inputSchema}',
      );
      final validation = JsonSchemaValidator.validate(
        inputMap,
        def.inputSchema,
      );
      if (!validation.isValid) {
        final message = validation.errors.map((e) => e.toString()).join('; ');
        throw ToolInvalidArgsError(def.id, message);
      }
    } else {
      LogTags.permission.logDebug(
        'ToolExecutor: skip validation ${def.id} '
        'inputMap=$inputMap',
      );
    }
    final ctx = options.experimentalContext;
    final rawSessionId = ctx != null ? ctx['sessionId'] as String? : null;
    final sessionId = (rawSessionId == null || rawSessionId.isEmpty)
        ? null
        : rawSessionId;
    final requestId = ctx != null ? ctx['requestId'] as String? : null;
    final agentId = ctx != null ? ctx['agentId'] as String? : null;
    // Use toolCallId from SDK's ToolExecutionOptions as additional cache key source.
    // The ai_sdk_dart library may call executeDynamic multiple times for the same
    // toolCallId (preliminary + final dispatch). Using toolCallId ensures the
    // second invocation hits the cache instead of re-executing the tool.
    String? toolCallId;
    try {
      final opts = options as sdk.ToolExecutionOptions?;
      toolCallId = opts?.toolCallId;
    } catch (_) {}
    final cacheKeySuffix =
        sessionId ??
        toolCallId ??
        requestId ??
        'invocation_${DateTime.now().microsecondsSinceEpoch}';
    final cacheKey = '${def.id}:$cacheKeySuffix:${_normalizeInput(inputMap)}';

    // Deduplicate in-flight requests by toolCallId (preliminary + final dispatch)
    // This works for ALL tools including side-effecting (bash/write)
    // Register immediately to prevent race condition with concurrent calls
    if (toolCallId != null) {
      final inFlight = _inFlightCache[toolCallId];
      if (inFlight != null) {
        LogTags.permission.logInfo(
          'ToolExecutor: Reusing in-flight ${def.id} by toolCallId',
        );
        return inFlight;
      }
    }

    // Side-effecting tools bypass cache — always re-execute
    if (!_sideEffectingTools.contains(def.id)) {
      final cached = _resultCache[cacheKey];
      if (cached != null) {
        LogTags.permission.logInfo(
          'ToolExecutor: Cache HIT ${def.id}, session=$sessionId',
        );
        return cached;
      }
    }

    // Deduplicate in-flight requests
    final pending = _pendingCache[cacheKey];
    if (pending != null) {
      LogTags.permission.logInfo('ToolExecutor: Reusing in-flight ${def.id}');
      return pending;
    }

    final completer = Completer<Map<String, dynamic>>();
    _pendingCache[cacheKey] = completer.future;
    // Register in-flight by toolCallId for SDK retry deduplication
    if (toolCallId != null) {
      _inFlightCache[toolCallId] = completer.future;
    }

    try {
      LogTags.permission.logInfo(
        'ToolExecutor: START ${def.id}, session=$sessionId',
      );

      // Doom-loop guard
      if (_doomLoopCheck(sessionId, def.id, inputMap)) {
        final doomRule = _evaluate('doom_loop', def.id);
        if (doomRule.action == PermissionAction.deny) {
          LogTags.permission.logInfo(
            'ToolExecutor: Doom loop DENIED ${def.id}',
          );
          return {'output': ''};
        }
        if (doomRule.action == PermissionAction.ask) {
          LogTags.permission.logInfo('ToolExecutor: Doom loop ASK ${def.id}');
          try {
            await _permissions.ask(
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
                sessionApproved: _permissions.approvedRules,
              ),
            );
          } on PermissionDeniedError {
            LogTags.permission.logInfo(
              'ToolExecutor: Doom loop denied by user ${def.id}',
            );
            return {'output': ''};
          } on PermissionRejectedError {
            LogTags.permission.logInfo(
              'ToolExecutor: Doom loop rejected by user ${def.id}',
            );
            return {'output': ''};
          }
        }
      }

      // Build execution context
      final abortSignal = _extractAbortSignal(options);
      final askCtx = _AskContext(
        def: def,
        inputMap: inputMap,
        sessionId: sessionId,
        agentId: agentId,
        toolCallId: toolCallId,
        permissions: _permissions,
        defaultRules: _defaultRules,
        agentRules: agentRules,
        abortSignal: abortSignal,
        switchAgent: switchAgent,
      );

      final result = await def.execute(inputMap, askCtx.toToolContext());
      LogTags.permission.logInfo(
        'ToolExecutor: DONE ${def.id} outputLen=${result.output.length}',
      );

      // Handle overflow and truncation 
      final truncResult = await TruncationService.instance.output(
        result.output,
        hasTaskTool: true,
      );

      LogTags.permission.logDebug(
        'ToolExecutor: RESULT ${def.id} truncated=${truncResult.truncated} '
        'finalLen=${truncResult.content.length}',
      );

      final meta = result.metadata is Map<String, dynamic>
          ? Map<String, dynamic>.from(result.metadata as Map)
          : <String, dynamic>{};
      if (truncResult.truncated) {
        meta['truncated'] = true;
        meta['outputPath'] = truncResult.outputPath;
      }

      final json = <String, dynamic>{
        'output': truncResult.content,
        if (meta.isNotEmpty) 'metadata': meta,
      };

      _resultCache[cacheKey] = json;
      completer.complete(json);
      _pendingCache.remove(cacheKey);
      if (toolCallId != null) {
        _inFlightCache.remove(toolCallId);
      }
      return json;
    } on ToolInvalidArgsError catch (e) {
      _pendingCache.remove(cacheKey);
      if (toolCallId != null) _inFlightCache.remove(toolCallId);
      LogTags.permission.logWarning(
        'ToolExecutor: invalid args ${def.id}: ${e.message}',
      );
      final errorJson = <String, dynamic>{
        'error': 'invalid_args',
        'message': e.message,
        'toolName': def.id,
      };
      completer.complete(errorJson);
      return errorJson;
    } on ToolOverflowError catch (e) {
      _pendingCache.remove(cacheKey);
      if (toolCallId != null) _inFlightCache.remove(toolCallId);
      LogTags.permission.logWarning(
        'ToolExecutor: overflow ${def.id}: ${e.message}',
      );
      final errorJson = <String, dynamic>{
        'error': 'overflow',
        'message': e.message,
        'toolName': def.id,
      };
      completer.complete(errorJson);
      return errorJson;
    } catch (e, st) {
      _pendingCache.remove(cacheKey);
      if (toolCallId != null) _inFlightCache.remove(toolCallId);
      LogTags.permission.logError(
        'ToolExecutor: EXEC ERROR ${def.id}: $e',
        e,
        st,
      );
      if (!completer.isCompleted) completer.completeError(e, st);
      rethrow;
    }
  }

  /// Purge all cache and history for a closed session.
  void pruneSession(String sessionId) {
    final prefix = ':$sessionId:';
    _resultCache.removeWhere((k, _) => k.contains(prefix));
    _pendingCache.removeWhere((k, _) => k.contains(prefix));
    _doomHistory.remove(sessionId);
  }

  // --- Private helpers ---

  /// Extract abort signal from SDK tool options (if available).
  static sdk.CancellationToken? _extractAbortSignal(dynamic options) {
    if (options == null) return null;
    try {
      final signal = (options as dynamic).abortSignal;
      if (signal is sdk.CancellationToken) return signal;
    } catch (_) {}
    try {
      final ctx = (options as dynamic).experimentalContext;
      if (ctx is Map) {
        final signal = ctx['abortSignal'];
        if (signal is sdk.CancellationToken) return signal;
      }
    } catch (_) {}
    return null;
  }

  /// Evaluate a permission rule for a tool call.
  PermissionRule _evaluate(String permission, String toolId) {
    final rulesets = <PermissionRuleset>[
      PermissionRuleset(
        rules: [..._defaultRules.rules],
        sessionApproved: _permissions.approvedRules,
      ),
    ];
    if (agentRules != null) {
      rulesets.add(agentRules!);
    }
    return evaluate(permission, toolId, rulesets);
  }

  bool _doomLoopCheck(
    String? sessionId,
    String toolName,
    Map<String, dynamic> input,
  ) {
    _doomHistory.putIfAbsent(sessionId, () => {});
    final perTool = _doomHistory[sessionId]!;
    perTool.putIfAbsent(toolName, () => []);
    final jsonInput = input.toString();
    final count = perTool[toolName]!.where((c) => c == jsonInput).length;
    if (count >= _doomLoopThreshold) return true;
    perTool[toolName]!.add(jsonInput);

    // LRU prune per-tool
    if (perTool[toolName]!.length > _maxPerTool) {
      perTool[toolName]!.removeRange(
        0,
        perTool[toolName]!.length - _maxPerTool,
      );
    }
    // LRU prune per-session
    var total = perTool.values.fold<int>(0, (s, e) => s + e.length);
    if (total > _maxPerSession) {
      final excess = total - _maxPerSession;
      for (final key in perTool.keys.toList()) {
        if (excess <= 0) break;
        final entries = perTool[key]!;
        final drop = entries.length < excess ? entries.length : excess;
        entries.removeRange(0, drop);
        if (entries.isEmpty) perTool.remove(key);
      }
    }
    return false;
  }

  String _normalizeInput(Map<String, dynamic> input) {
    final entries = input.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => '$e').join(',');
  }
}

// Helper: bridges ToolDef permission callbacks to ToolExecutor fields.
class _AskContext {
  final ToolDef def;
  final Map<String, dynamic> inputMap;
  final String? sessionId;
  final String? agentId;
  final String? toolCallId;
  final PermissionService permissions;
  final PermissionRuleset defaultRules;
  final PermissionRuleset? agentRules;
  final sdk.CancellationToken? abortSignal;
  final void Function(String agentId, {String? messageText})? switchAgent;

  _AskContext({
    required this.def,
    required this.inputMap,
    required this.sessionId,
    required this.agentId,
    required this.permissions,
    required this.defaultRules,
    this.agentRules,
    this.abortSignal,
    this.switchAgent,
    this.toolCallId,
  });

  PermissionRuleset get _combinedRules {
    final rules = <PermissionRule>[...defaultRules.rules];
    if (agentRules != null) {
      rules.addAll(agentRules!.rules);
    }
    return PermissionRuleset(
      rules: rules,
      sessionApproved: permissions.approvedRules,
    );
  }

  ToolContext toToolContext() {
    return ToolContext(
      agentId: agentId,
      toolCallId: toolCallId ?? '',
      sessionId: sessionId,
      permissionRuleset: _combinedRules,
      abortSignal: abortSignal,
      ask: _ask,
      askQuestion: _askQuestion,
      switchAgent: switchAgent,
    );
  }

  Future<String> _askQuestion({
    required String question,
    List<QuestionOption> options = const [],
    bool multiple = false,
  }) async {
    LogTags.permission.logInfo(
      '_AskContext._askQuestion: START question="$question", options=${options.map((o) => o.label).toList()}',
    );

    final combinedRules = _combinedRules;
    final rule = evaluate('question', '*', [combinedRules]);
    if (rule.action == PermissionAction.deny) {
      throw PermissionDeniedError('question', '*');
    }

    if (rule.action == PermissionAction.ask) {
      await permissions.ask(
        PermissionRequest(
          id: 'question_perm_${DateTime.now().microsecondsSinceEpoch}',
          toolName: 'question',
          permission: 'question',
          patterns: ['*'],
          metadata: {
            if (sessionId != null) 'sessionId': sessionId,
            'question': question,
          },
        ),
        combinedRules,
      );
    }

    LogTags.permission.logInfo(
      '_AskContext._askQuestion: Permission granted, proceeding with question',
    );

    final id = 'question_${DateTime.now().microsecondsSinceEpoch}';
    LogTags.permission.logInfo(
      '_AskContext._askQuestion: id=$id, question="$question", options=${options.map((o) => o.label).toList()}',
    );
    return permissions.askQuestion(
      id: id,
      question: question,
      options: options,
      multiple: multiple,
    );
  }

  Future<void> _ask({
    required String permission,
    required List<String> patterns,
    Map<String, dynamic>? metadata,
    List<String>? always,
  }) async {
    final reqMetadata = Map<String, dynamic>.from(metadata ?? inputMap);
    if (sessionId != null) reqMetadata['sessionId'] = sessionId;

    final combinedRules = _combinedRules;

    var needsAsk = false;
    for (final pattern in patterns) {
      final normalized = pattern.trim().isEmpty ? '*' : pattern.trim();
      final rule = evaluate(permission, normalized, [combinedRules]);
      if (rule.action == PermissionAction.deny) {
        throw PermissionDeniedError(def.id, normalized);
      }
      if (rule.action == PermissionAction.ask) {
        needsAsk = true;
      }
    }

    if (!needsAsk) {
      return;
    }

    final requestId =
        toolCallId ?? 'req_${DateTime.now().microsecondsSinceEpoch}_${def.id}';
    await permissions.ask(
      PermissionRequest(
        id: requestId,
        toolName: def.id,
        permission: permission,
        patterns: patterns,
        metadata: reqMetadata,
        always: always ?? [],
      ),
      combinedRules,
    );
  }
}
