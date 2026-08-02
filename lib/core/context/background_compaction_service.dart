import 'dart:async';

import 'package:chatorai/core/context/compaction_orchestrator.dart';
import 'package:chatorai/core/context/completion_provider.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/shared/utils/logger.dart';

/// Background compaction thresholds.
class BackgroundCompactionThresholds {
  final double warningRatio;
  final double hardRatio;

  const BackgroundCompactionThresholds({
    this.warningRatio = 0.8,
    this.hardRatio = 0.95,
  });

  bool shouldCompact(int totalTokens, int usableTokens) {
    if (usableTokens <= 0) return false;
    final ratio = totalTokens / usableTokens;
    return ratio >= warningRatio;
  }

  bool isHardOverflow(int totalTokens, int usableTokens) {
    if (usableTokens <= 0) return false;
    final ratio = totalTokens / usableTokens;
    return ratio >= hardRatio;
  }
}

/// State for background compaction of a single session.
class BackgroundCompactionState {
  final bool isRunning;
  final int lastCheckTokens;
  final double lastThreshold;
  final bool? isHardOverflow;
  final String? lastCompactionResult;
  final DateTime? lastCompactedAt;
  final String? lastError;

  const BackgroundCompactionState({
    required this.isRunning,
    required this.lastCheckTokens,
    required this.lastThreshold,
    this.isHardOverflow,
    this.lastCompactionResult,
    this.lastCompactedAt,
    this.lastError,
  });

  BackgroundCompactionState copyWith({
    bool? isRunning,
    int? lastCheckTokens,
    double? lastThreshold,
    bool? isHardOverflow,
    String? lastCompactionResult,
    DateTime? lastCompactedAt,
    String? lastError,
  }) {
    return BackgroundCompactionState(
      isRunning: isRunning ?? this.isRunning,
      lastCheckTokens: lastCheckTokens ?? this.lastCheckTokens,
      lastThreshold: lastThreshold ?? this.lastThreshold,
      isHardOverflow: isHardOverflow ?? this.isHardOverflow,
      lastCompactionResult: lastCompactionResult ?? this.lastCompactionResult,
      lastCompactedAt: lastCompactedAt ?? this.lastCompactedAt,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Manages automatic background compaction based on token usage.
///
/// Monitors token usage after each response and triggers compaction
/// when the context window approaches its limit.
class BackgroundCompactionService {
  final Map<String, BackgroundCompactionState> _sessionStates = {};
  BackgroundCompactionThresholds _thresholds =
      const BackgroundCompactionThresholds();

  BackgroundCompactionState stateFor(String sessionId) {
    return _sessionStates[sessionId] ??
        const BackgroundCompactionState(
          isRunning: false,
          lastCheckTokens: 0,
          lastThreshold: 0,
        );
  }

  void _updateState(String sessionId, BackgroundCompactionState state) {
    _sessionStates[sessionId] = state;
  }

  void updateThresholds(BackgroundCompactionThresholds thresholds) {
    _thresholds = thresholds;
  }

  /// Whether any compaction is currently running for [sessionId].
  bool isCompacting(String sessionId) => stateFor(sessionId).isRunning;

  /// Checks if background compaction is needed based on current token usage.
  ///
  /// Returns true if compaction should be triggered.
  bool shouldCompact(int totalTokens, int usableTokens) {
    return _thresholds.shouldCompact(totalTokens, usableTokens);
  }

  /// Triggers background compaction for the given session.
  ///
  /// Returns the updated session state after compaction, or null if compaction
  /// failed or was not needed.
  Future<String?> compactInBackground({
    required SessionID sessionId,
    required SessionRepository repository,
    required CompletionProvider completionProvider,
    required String modelId,
    required int totalTokens,
    required int usableTokens,
  }) async {
    final key = sessionId.value;
    final currentState = stateFor(key);
    if (currentState.isRunning) {
      LogTags.chatScreen.logInfo(
        'Background compaction already running for $sessionId, skipping',
      );
      return null;
    }

    if (!shouldCompact(totalTokens, usableTokens)) {
      return null;
    }

    final isHard = _thresholds.isHardOverflow(totalTokens, usableTokens);
    final threshold = isHard ? _thresholds.hardRatio : _thresholds.warningRatio;
    LogTags.chatScreen.logInfo(
      'Background compaction triggered for $sessionId: '
      'tokens=$totalTokens, usable=$usableTokens, ratio=${(totalTokens / usableTokens).toStringAsFixed(2)}, hard=$isHard',
    );

    _updateState(
      key,
      BackgroundCompactionState(
        isRunning: true,
        lastCheckTokens: totalTokens,
        lastThreshold: threshold,
        isHardOverflow: isHard,
      ),
    );

    try {
      final orchestrator = CompactionOrchestrator(
        repository,
        completionProvider: completionProvider,
      );

      final updatedState = await orchestrator.compactSession(sessionId);

      if (updatedState != null) {
        final result = updatedState.messages.isNotEmpty
            ? updatedState.messages.first.content
            : '';
        LogTags.chatScreen.logInfo(
          'Background compaction completed for $sessionId: ${result.length} chars',
        );
        _updateState(
          key,
          BackgroundCompactionState(
            isRunning: false,
            lastCheckTokens: totalTokens,
            lastThreshold: threshold,
            isHardOverflow: isHard,
            lastCompactionResult: result,
            lastCompactedAt: DateTime.now(),
          ),
        );
        return result;
      } else {
        LogTags.chatScreen.logInfo(
          'Background compaction returned null for $sessionId (no compaction needed or failed)',
        );
        _updateState(
          key,
          BackgroundCompactionState(
            isRunning: false,
            lastCheckTokens: totalTokens,
            lastThreshold: threshold,
            isHardOverflow: isHard,
          ),
        );
        return null;
      }
    } catch (e, stack) {
      LogTags.chatScreen.logError(
        'Background compaction failed for $sessionId: $e',
        e,
        stack,
      );
      _updateState(
        key,
        BackgroundCompactionState(
          isRunning: false,
          lastCheckTokens: totalTokens,
          lastThreshold: threshold,
          isHardOverflow: isHard,
          lastError: e.toString(),
        ),
      );
      return null;
    }
  }

  /// Resets the background compaction state for a session.
  void reset(String sessionId) {
    _sessionStates.remove(sessionId);
  }
}
