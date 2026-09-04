import 'dart:io';

import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late SessionRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tool_card_order');
    db = AppDatabase.file('${tempDir.path}/db.sqlite');
    repository = SessionRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test(
    'deferred tool card is emitted only AFTER the reasoning part fully closes, '
    'never mid-reasoning — even when reasoning deltas keep trickling',
    () async {
      const sessionIdRaw = 'ses_tool_order';
      final sessionId = SessionID.fromString(sessionIdRaw);
      final session = SessionRunnerSession.forExisting(
        repository: repository,
        sessionId: sessionId,
        immediate: true,
      );

      await session.onReasoning('thinking part one. ');
      await session.onToolStart('call-1', 'websearch', {'query': 'weather'});
      // Late reasoning tail deltas keep trickling AFTER the tool call —
      // the card must stay deferred while the reasoning part is open.
      await session.onReasoning('tail continues. ');
      await session.onReasoning('more tail. ');

      final midState = await repository.loadSession(sessionId);
      expect(midState, isNotNull);
      // No tool card may exist while the reasoning part is still open.
      expect(midState!.parts.whereType<AssistantTask>(), isEmpty);
      expect(midState.parts.whereType<AssistantReasoning>(), isNotEmpty);

      // The authoritative end-of-reasoning signal: close + flush the card.
      await session.onReasoningEnd();

      final endState = await repository.loadSession(sessionId);
      final reasoning = endState!.parts.indexOf(
        endState.parts.whereType<AssistantReasoning>().first,
      );
      final tool = endState.parts.indexOf(
        endState.parts.whereType<AssistantTool>().first,
      );
      // Reasoning part comes first; the tool card only after it.
      expect(reasoning, greaterThanOrEqualTo(0));
      expect(tool, greaterThan(reasoning));
    },
  );
}
