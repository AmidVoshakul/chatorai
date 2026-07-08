import 'dart:async';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _sessionId;

  // Rate-limit tracking for repeated permission requests
  final _askHistory = <String, List<DateTime>>{};
  static const _askLimitWindow = Duration(minutes: 5);
  static const _askLimitMax = 10;

  // Question tracking (interactive user questions, not permissions)
  final _questionPending = <String, _QuestionEntry>{};
  final _questionController = StreamController<QuestionRequest>.broadcast();
  final _questionAskHistory = <String, List<DateTime>>{};
  static const _questionLimitWindow = Duration(minutes: 5);
  static const _questionLimitMax = 10;

  Stream<PermissionRequest> get onAsked => _controller.stream;
  Stream<QuestionRequest> get onQuestionAsked => _questionController.stream;
  List<PermissionRule> get approvedRules => List.unmodifiable(_approved);

  void attachPreferences(SharedPreferences prefs) {
    // Session-scoped: "Always allow" rules live in memory for the current
    // session only. No persistence needed.
  }

  /// Seed the default rules from configuration.
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
    final normalized = _validatePattern(pattern);
    final rule = evaluate(permission, normalized, [
      PermissionRuleset(rules: _defaultRules),
      PermissionRuleset(sessionApproved: _approved),
    ]);
    return rule.action == PermissionAction.allow;
  }

  String _validatePattern(String pattern) {
    final trimmed = pattern.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Permission pattern must not be empty');
    }
    return trimmed;
  }

  Future<void> ask(PermissionRequest req, PermissionRuleset ruleset) async {
    LogTags.permission.logInfo(
      'PermissionService.ask: START for tool=${req.toolName}, permission=${req.permission}, patterns=${req.patterns}',
    );

    final reqSessionId = req.metadata['sessionId'] as String?;
    if (reqSessionId != null && reqSessionId != _sessionId) {
      _sessionId = reqSessionId;
      _approved.clear();
      LogTags.permission.logInfo(
        'PermissionService: session changed to $reqSessionId, cleared session-approved rules',
      );
    }

    var needsAsk = false;

    for (final pattern in req.patterns) {
      final normalized = _validatePattern(pattern);
      final rule = evaluate(req.permission, normalized, [
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

    final rateKey = '${req.toolName}:${req.permission}';

    if (_isRateLimited(rateKey)) {
      LogTags.permission.logWarning(
        'PermissionService.ask: RATE-LIMITED for $rateKey, denying',
      );
      throw PermissionDeniedError(req.toolName, req.permission);
    }
    _recordAsk(rateKey);

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

  Future<String> askQuestion({
    required String id,
    required String question,
    List<QuestionOption> options = const [],
    bool multiple = false,
  }) async {
    LogTags.permission.logInfo(
      'PermissionService.askQuestion: id=$id, question="$question", options=${options.map((o) => o.label).toList()}',
    );

    if (_isQuestionRateLimited('question')) {
      LogTags.permission.logWarning(
        'PermissionService.askQuestion: RATE-LIMITED for question, id=$id',
      );
      return '';
    }

    final completer = Completer<String>();
    _questionPending[id] = _QuestionEntry(
      question: question,
      options: options,
      multiple: multiple,
      completer: completer,
    );
    _questionController.add(
      QuestionRequest(
        id: id,
        question: question,
        options: options,
        multiple: multiple,
      ),
    );
    LogTags.permission.logInfo(
      'PermissionService.askQuestion: WAITING for user answer, id=$id',
    );
    final answer = await completer.future;
    LogTags.permission.logInfo(
      'PermissionService.askQuestion: ANSWER RECEIVED id=$id, answer="$answer"',
    );
    return answer;
  }

  void answerQuestion(String id, String answer) {
    LogTags.permission.logInfo(
      'PermissionService.answerQuestion: id=$id, answer="$answer"',
    );
    final entry = _questionPending.remove(id);
    if (entry != null) {
      entry.completer.complete(answer);
    } else {
      LogTags.permission.logWarning(
        'PermissionService.answerQuestion: No pending question for id=$id',
      );
    }
  }

  void cancelPendingQuestion(String id) {
    final entry = _questionPending.remove(id);
    if (entry != null && !entry.completer.isCompleted) {
      entry.completer.complete('');
    }
  }

  bool _isRateLimited(String key) {
    final now = DateTime.now();
    final history = _askHistory[key] ??= [];
    history.removeWhere((t) => now.difference(t) > _askLimitWindow);
    return history.length >= _askLimitMax;
  }

  bool _isQuestionRateLimited(String key) {
    final now = DateTime.now();
    final history = _questionAskHistory[key] ??= [];
    history.removeWhere((t) => now.difference(t) > _questionLimitWindow);
    if (history.length >= _questionLimitMax) return true;
    history.add(now);
    return false;
  }

  void _recordAsk(String key) {
    final now = DateTime.now();
    _askHistory.putIfAbsent(key, () => []).add(now);
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
                : entry.request.patterns) {
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
    _askHistory.clear();
    for (final entry in _questionPending.values) {
      if (!entry.completer.isCompleted) {
        entry.completer.complete('');
      }
    }
    _questionPending.clear();
    _questionAskHistory.clear();
  }

  /// Clear rate-limit history and session-approved rules.
  void clearSession() {
    _askHistory.clear();
    _questionAskHistory.clear();
    _approved.clear();
    _sessionId = null;
  }

  @Deprecated('Use clearSession() instead')
  void clearRateLimitHistory() => clearSession();
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

// ── Question Request ─────────────────────────────────────────

class QuestionRequest {
  final String id;
  final String question;
  final List<QuestionOption> options;
  final bool multiple;

  const QuestionRequest({
    required this.id,
    required this.question,
    this.options = const [],
    this.multiple = false,
  });
}

class _QuestionEntry {
  final String question;
  final List<QuestionOption> options;
  final bool multiple;
  final Completer<String> completer;

  _QuestionEntry({
    required this.question,
    required this.options,
    required this.multiple,
    required this.completer,
  });
}

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
