import 'package:chatorai/core/context/completion_provider.dart';
import 'package:chatorai/core/context/compaction_service.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';

/// Orchestrates context compaction for a session.
///
/// Reads the current session state, applies [CompactionService] to produce
/// a summarized head + preserved tail, then persists the result as
/// [CompactionStarted] / [CompactionEnded] events via [SessionRepository].
///
/// This is the production wiring of the planned compaction subagent
/// (hidden ChatORAI agent with low temperature, limited output tokens).
class CompactionOrchestrator {
  final SessionRepository _repository;
  final CompactionService _compactionService;
  final CompletionProvider _completionProvider;

  CompactionOrchestrator(
    this._repository, {
    CompactionService? compactionService,
    required CompletionProvider completionProvider,
  }) : _compactionService = compactionService ?? const CompactionService(),
       _completionProvider = completionProvider;

  /// Run compaction for [sessionId] and persist the result.
  ///
  /// Returns the updated [SessionState] after compaction, or `null` if
  /// the session could not be loaded or compaction produced no change.
  Future<SessionState?> compactSession(SessionID sessionId) async {
    final state = await _repository.loadSession(sessionId);
    if (state == null) {
      return null;
    }

    final now = DateTime.now();

    await _repository.appendEvent(
      CompactionStarted(sessionId: sessionId, timestamp: now),
    );

    final messages = state.messages
        .map((m) => {'role': m.role.name, 'content': m.content})
        .toList();

    try {
      final compacted = await _compactionService.compact(
        messages: messages,
        aiService: _completionProvider,
        model: state.modelRef ?? 'default',
      );

      final summary = compacted.isNotEmpty
          ? (compacted.first['content'] as String? ?? '')
          : '';

      await _repository.appendEvent(
        CompactionEnded(
          sessionId: sessionId,
          summary: summary,
          timestamp: DateTime.now(),
        ),
      );

      final updated = await _repository.loadSession(sessionId);
      return updated;
    } catch (e) {
      await _repository.appendEvent(
        CompactionEnded(sessionId: sessionId, summary: '', timestamp: now),
      );
      rethrow;
    }
  }
}
