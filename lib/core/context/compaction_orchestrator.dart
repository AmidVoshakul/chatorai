import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/context/compaction_service.dart';
import 'package:chatorai/core/context/completion_provider.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';

class CompactionOrchestrator {
  final SessionRepository _repository;
  final CompactionService _compactionService;
  final CompletionProvider _completionProvider;

  CompactionOrchestrator(
    this._repository, {
    CompactionService? compactionService,
    required CompletionProvider completionProvider,
    CompactionConfig? compactionConfig,
  }) : _compactionService =
           compactionService ??
           (compactionConfig != null
               ? CompactionService.fromConfig(compactionConfig)
               : const CompactionService()),
       _completionProvider = completionProvider;

  /// Run full compaction for [sessionId] via LLM and persist the result.
  ///
  /// Returns the updated [SessionState] after compaction, or `null` if
  /// the session could not be loaded or compaction produced no change.
  Future<SessionState?> compactSession(
    SessionID sessionId, {
    required String model,
  }) async {
    final state = await _repository.loadSession(sessionId);
    if (state == null) return null;

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
        model: model,
      );

      final summary = compacted.isNotEmpty
          ? (compacted.first['content'] as String? ?? '')
          : '';

      return _persistCompacted(
        sessionId,
        compacted,
        summary,
        tailStartId: null,
        retainedIds: null,
      );
    } catch (e) {
      await _repository.appendEvent(
        CompactionEnded(sessionId: sessionId, summary: '', timestamp: now),
      );
      rethrow;
    }
  }

  /// Persist an already-compacted message list without calling the LLM.
  ///
  /// - [tailStartId] — id of the message that starts the retained tail; it
  ///   will be marked `isCompactionTrigger=true` in the session state.
  /// - [retainedIds] — ids of messages guaranteed to appear in the tail
  ///   (used to validate the compacted context).
  ///
  /// Returns the updated [SessionState] or `null` if the session is missing.
  Future<SessionState?> compactSessionFromResult(
    SessionID sessionId,
    List<Map<String, dynamic>> compactedMessages, {
    String? model,
    String? tailStartId,
    List<String>? retainedIds,
  }) async {
    final state = await _repository.loadSession(sessionId);
    if (state == null) return null;

    final now = DateTime.now();

    await _repository.appendEvent(
      CompactionStarted(sessionId: sessionId, timestamp: now),
    );

    final summary = compactedMessages.isNotEmpty
        ? (compactedMessages.first['content'] as String? ?? '')
        : '';

    return _persistCompacted(
      sessionId,
      compactedMessages,
      summary,
      tailStartId: tailStartId,
      retainedIds: retainedIds,
    );
  }

  Future<SessionState?> _persistCompacted(
    SessionID sessionId,
    List<Map<String, dynamic>> compactedMessages,
    String summary, {
    String? tailStartId,
    List<String>? retainedIds,
  }) async {
    final state = await _repository.loadSession(sessionId);
    if (state == null) return null;

    final updated = await _repository.appendEvent(
      CompactionEnded(
        sessionId: sessionId,
        summary: summary,
        tailStartId: tailStartId,
        compactedContext: compactedMessages,
        timestamp: DateTime.now(),
      ),
    );
    // `appendEvent` already projects the event onto the cached session state
    // and returns it, so an extra `loadSession` replay is unnecessary.
    return updated;
  }
}
