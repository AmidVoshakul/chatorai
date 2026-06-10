import 'dart:async';

import 'package:chatorai/shared/utils/logger.dart';
import 'evaluator.dart';
import 'rule.dart';
import 'ruleset.dart';

class PermissionRequest {
  final String id;
  final String toolName;
  final String permission;
  final List<String> patterns;
  final Map<String, dynamic> metadata;
  final List<String> always;

  const PermissionRequest({
    required this.id,
    required this.toolName,
    required this.permission,
    required this.patterns,
    this.metadata = const {},
    this.always = const [],
  });
}

class PermissionService {
  final _pending = <String, _PendingEntry>{};
  final _approved = <PermissionRule>[];
  final _defaultRules = <PermissionRule>[];
  final _controller = StreamController<PermissionRequest>.broadcast();
  bool _rulesSeeded = false;

  Stream<PermissionRequest> get onAsked => _controller.stream;
  List<PermissionRule> get approvedRules => List.unmodifiable(_approved);

  /// Seed the default rules from configuration.
  /// This is called once at startup to load the permission rules from chatorai.json.
  void seedRules(PermissionRuleset ruleset) {
    if (!_rulesSeeded && ruleset.rules.isNotEmpty) {
      _defaultRules.addAll(ruleset.rules);
      _rulesSeeded = true;
      LogTags.permission.logInfo(
        'PermissionService seeded with ${ruleset.rules.length} rules',
      );
    }
  }

  bool isAllowed(String permission, String pattern) {
    final rule = evaluate(permission, pattern, [
      PermissionRuleset(rules: _defaultRules),
      PermissionRuleset(sessionApproved: _approved),
    ]);
    return rule.action == PermissionAction.allow;
  }

  Future<void> ask(PermissionRequest req, PermissionRuleset ruleset) async {
    LogTags.permission.logInfo(
      'PermissionService.ask: START for tool=${req.toolName}, permission=${req.permission}, patterns=${req.patterns}',
    );
    var needsAsk = false;

    for (final pattern in req.patterns) {
      final rule = evaluate(req.permission, pattern, [
        ruleset,
        PermissionRuleset(sessionApproved: _approved),
      ]);

      if (rule.action == PermissionAction.deny) {
        LogTags.permission.logWarning(
          'PermissionService.ask: DENY for tool=${req.toolName}, pattern=$pattern',
        );
        throw PermissionDeniedError(req.toolName, pattern);
      }

      if (rule.action == PermissionAction.ask) {
        LogTags.permission.logInfo(
          'PermissionService.ask: ASK needed for tool=${req.toolName}, pattern=$pattern',
        );
        needsAsk = true;
      }
    }

    if (!needsAsk) {
      LogTags.permission.logInfo(
        'PermissionService.ask: ALLOW (no ask needed) for tool=${req.toolName}',
      );
      return;
    }

    if (!_rulesSeeded && ruleset.rules.isNotEmpty) {
      _rulesSeeded = true;
      _defaultRules.addAll(ruleset.rules);
    }

    final completer = Completer<void>();
    _pending[req.id] = _PendingEntry(
      request: req,
      completer: completer,
      patterns: req.patterns,
    );
    LogTags.permission.logInfo(
      'PermissionService.ask: Emitting request on stream, pending count=${_pending.length}',
    );
    _controller.add(req);

    LogTags.permission.logInfo(
      'PermissionService.ask: WAITING for user response for tool=${req.toolName}, requestId=${req.id}',
    );
    await completer.future;

    LogTags.permission.logInfo(
      'PermissionService.ask: RESPONSE RECEIVED for tool=${req.toolName}, requestId=${req.id}',
    );

    if (_pending.containsKey(req.id) && _pending[req.id]!.rejected) {
      throw PermissionRejectedError(req.toolName);
    }
  }

  void reply(String requestId, PermissionReply reply, {String? message}) {
    final entry = _pending[requestId];
    if (entry == null) return;

    if (reply == PermissionReply.reject) {
      entry.rejected = true;
      for (final pending in _pending.values) {
        if (pending.request.metadata['sessionId'] ==
                entry.request.metadata['sessionId'] &&
            pending != entry) {
          pending.rejected = true;
          pending.completer.completeError(
            PermissionRejectedError(pending.request.toolName),
          );
        }
      }
      entry.completer.completeError(
        PermissionRejectedError(entry.request.toolName),
      );
      _pending.remove(requestId);
    } else {
      if (reply == PermissionReply.always) {
        final newRules = <PermissionRule>[];
        for (final pattern
            in entry.request.always.isNotEmpty
                ? entry.request.always
                : entry.patterns) {
          newRules.add(
            PermissionRule(
              permission: entry.request.permission,
              pattern: pattern,
              action: PermissionAction.allow,
            ),
          );
        }
        _approved.addAll(newRules);
        _resolveSiblings(entry, newRules);
      }
      entry.completer.complete();
      _pending.remove(requestId);
    }
  }

  void _resolveSiblings(_PendingEntry entry, List<PermissionRule> newRules) {
    final sessionId = entry.request.metadata['sessionId'];
    if (sessionId == null) return;

    final mergedRuleset = PermissionRuleset(
      rules: [..._defaultRules, ..._approved],
      sessionApproved: const [],
    );

    final siblingsToResolve = <_PendingEntry>[];
    for (final pending in _pending.values) {
      if (pending == entry) continue;
      if (pending.request.metadata['sessionId'] != sessionId) continue;
      if (pending.rejected) continue;

      final allAllowed = pending.request.patterns.every((pattern) {
        final rule = evaluate(pending.request.permission, pattern, [
          mergedRuleset,
        ]);
        return rule.action == PermissionAction.allow;
      });

      if (allAllowed) {
        siblingsToResolve.add(pending);
      }
    }

    for (final pending in siblingsToResolve) {
      pending.completer.complete();
      _pending.remove(pending.request.id);
    }
  }

  void cancelAllPendingRequests() {
    for (final entry in _pending.values) {
      entry.completer.completeError(
        PermissionRejectedError(entry.request.toolName),
      );
    }
    _pending.clear();
  }
}

class _PendingEntry {
  final PermissionRequest request;
  final Completer<void> completer;
  final List<String> patterns;
  bool rejected = false;

  _PendingEntry({
    required this.request,
    required this.completer,
    required this.patterns,
  });
}

enum PermissionReply { once, always, reject }

class PermissionDeniedError implements Exception {
  final String toolName;
  final String pattern;

  PermissionDeniedError(this.toolName, this.pattern);

  @override
  String toString() => 'Permission denied: $toolName cannot access "$pattern"';
}

class PermissionRejectedError implements Exception {
  final String toolName;

  PermissionRejectedError(this.toolName);

  @override
  String toString() => 'Permission rejected by user: $toolName';
}
