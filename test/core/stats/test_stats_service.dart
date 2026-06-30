import 'package:drift/drift.dart';

import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/stats/stats_service.dart';
import 'package:test/test.dart';

void main() {
  group('StatsAggregator (in-memory drift)', () {
    late AppDatabase db;
    late StatsAggregator aggregator;

    setUp(() async {
      db = AppDatabase.inMemory();
      aggregator = StatsAggregator(db);
    });

    tearDown(() async => db.close());

    test('aggregate returns zeros on empty DB', () async {
      final stats = await aggregator.aggregate();
      expect(stats.totalSessions, 0);
      expect(stats.totalMessages, 0);
      expect(stats.totalCost, 0.0);
      expect(stats.totalTokens.total, 0);
      expect(stats.toolUsage, isEmpty);
      expect(stats.modelUsage, isEmpty);
    });

    test('sessions and messages count', () async {
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 's1',
              title: const Value('T1'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 's2',
              title: const Value('T2'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              id: 'm1',
              sessionId: 's1',
              seq: 0,
              role: 'user',
              createdAt: DateTime.now(),
            ),
          );
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              id: 'm2',
              sessionId: 's1',
              seq: 1,
              role: 'assistant',
              createdAt: DateTime.now(),
            ),
          );

      final stats = await aggregator.aggregate();
      expect(stats.totalSessions, 2);
      expect(stats.totalMessages, 2);
    });

    test('total tokens and cost aggregate', () async {
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 's1',
              title: const Value('T'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              tokensInput: const Value(10),
              tokensOutput: const Value(20),
              tokensReasoning: const Value(5),
              cost: const Value(1.25),
            ),
          );
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 's2',
              title: const Value('T'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              tokensInput: const Value(3),
              tokensOutput: const Value(7),
              tokensReasoning: const Value(2),
              cost: const Value(0.5),
            ),
          );

      final stats = await aggregator.aggregate();
      expect(stats.totalTokens.input, 13);
      expect(stats.totalTokens.output, 27);
      expect(stats.totalTokens.reasoning, 7);
      expect(stats.totalTokens.total, 47);
      expect(stats.totalCost, 1.75);
    });

    test('days parameter is passed through', () async {
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 's1',
              title: const Value('T'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final stats = await aggregator.aggregate(days: 14);
      expect(stats.days, 14);
    });

    test('tool usage aggregating', () async {
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 's1',
              title: const Value('T'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await db
          .into(db.toolResults)
          .insert(
            ToolResultsCompanion.insert(
              id: 'r1',
              sessionId: 's1',
              messageId: 'm1',
              toolName: 'bash',
              createdAt: DateTime.now(),
            ),
          );
      await db
          .into(db.toolResults)
          .insert(
            ToolResultsCompanion.insert(
              id: 'r2',
              sessionId: 's1',
              messageId: 'm2',
              toolName: 'bash',
              createdAt: DateTime.now(),
            ),
          );
      await db
          .into(db.toolResults)
          .insert(
            ToolResultsCompanion.insert(
              id: 'r3',
              sessionId: 's1',
              messageId: 'm3',
              toolName: 'grep',
              createdAt: DateTime.now(),
            ),
          );

      final stats = await aggregator.aggregate();
      expect(stats.toolUsage.length, 2);
      final bash = stats.toolUsage.firstWhere((t) => t.toolName == 'bash');
      expect(bash.count, 2);
      final grep = stats.toolUsage.firstWhere((t) => t.toolName == 'grep');
      expect(grep.count, 1);
    });

    test('model usage grouping', () async {
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 's1',
              title: const Value('T'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              modelRef: const Value('openai/gpt-4o'),
              tokensInput: const Value(1),
              tokensOutput: const Value(2),
              cost: const Value(0.1),
            ),
          );
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 's2',
              title: const Value('T'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              modelRef: const Value('openai/gpt-4o'),
              tokensInput: const Value(3),
              tokensOutput: const Value(4),
              cost: const Value(0.2),
            ),
          );
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 's3',
              title: const Value('T'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              modelRef: const Value('anthropic/claude-3'),
              tokensInput: const Value(5),
              tokensOutput: const Value(6),
              cost: const Value(0.3),
            ),
          );

      final stats = await aggregator.aggregate();
      expect(stats.modelUsage.length, 2);
      final gpt = stats.modelUsage.firstWhere(
        (m) => m.modelRef == 'openai/gpt-4o',
      );
      expect(gpt.tokens.input, 4);
      expect(gpt.tokens.output, 6);
      expect(gpt.cost, closeTo(0.3, 0.0001));
      expect(gpt.messages, 2);
    });
  });
}
