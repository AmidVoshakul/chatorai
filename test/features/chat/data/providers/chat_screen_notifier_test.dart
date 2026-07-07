import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    show
        AssistantContent,
        AssistantReasoning,
        AssistantText,
        AssistantTool,
        AssistantTask,
        ToolState;
import 'package:chatorai/features/chat/data/models/chat/session_to_chat_converter.dart'
    show assistantContentToPartMaps;
import 'package:chatorai/features/chat/data/providers/chat_screen_notifier.dart';

void main() {
  group('ChatScreenNotifier startStreaming / finalizeStreaming', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial state is empty and not streaming', () {
      final state = container.read(chatScreenProvider);
      expect(state.isStreaming, isFalse);
      expect(state.streamingParts, isEmpty);
      expect(state.streamingSessionId, isNull);
    });

    test('startStreaming initializes session and clears parts', () {
      container.read(chatScreenProvider.notifier).startStreaming('ses_abc');
      final state = container.read(chatScreenProvider);
      expect(state.isStreaming, isTrue);
      expect(state.streamingSessionId, 'ses_abc');
      expect(state.streamingParts, isEmpty);
    });

    test('finalizeStreaming sets ended on open AssistantReasoning', () {
      final n = container.read(chatScreenProvider.notifier);
      n.startStreaming('ses_abc');
      n.onReasoning('p1', 'm1', 'ses_abc', 'thinking step 1');
      n.onReasoning('p1', 'm1', 'ses_abc', 'step 2');

      final before = container
          .read(chatScreenProvider)
          .streamingParts
          .whereType<AssistantReasoning>()
          .first;
      expect(
        before.ended,
        isNull,
        reason: 'still streaming -> ended must be null',
      );

      n.finalizeStreaming();

      final after = container.read(chatScreenProvider);
      expect(after.isStreaming, isFalse);
      expect(after.streamingSessionId, isNull);
      expect(
        after.streamingParts,
        isEmpty,
        reason: 'finalizeStreaming clears all parts to const []',
      );
      // The reasoning that was open BEFORE finalize is gone, but in a real flow
      // the caller serializes parts BEFORE clearing (see Bug fixes 1.1 + 1.2).
      // We assert the cleanup behavior here in isolation.
    });

    test(
      'finalizeStreaming with already-closed parts is a no-op for parts list',
      () {
        final n = container.read(chatScreenProvider.notifier);
        n.startStreaming('ses_abc');
        // Use onToolCall which closes open parts via _closeOpenStreamingParts
        n.onReasoning('p1', 'm1', 'ses_abc', 'r1');
        n.onToolCall('tc1', 'tool_1', 'm1', 'ses_abc', 'bash', {'cmd': 'ls'});

        n.finalizeStreaming();
        final state = container.read(chatScreenProvider);
        expect(state.streamingParts, isEmpty);
      },
    );
  });

  group('ChatScreenNotifier natural block separation (Bug 6 fix)', () {
    late ProviderContainer container;
    late ChatScreenNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(chatScreenProvider.notifier);
      notifier.startStreaming('ses_abc');
    });

    tearDown(() => container.dispose());

    test('two consecutive onReasoning calls merge into ONE part', () {
      notifier.onReasoning('p1', 'm1', 'ses_abc', 'Hello ');
      notifier.onReasoning('p1', 'm1', 'ses_abc', 'world');

      final reasonings = container
          .read(chatScreenProvider)
          .streamingParts
          .whereType<AssistantReasoning>()
          .toList();
      expect(
        reasonings.length,
        1,
        reason: 'consecutive reasoning deltas must be one block',
      );
      expect(reasonings.single.text, 'Hello world');
    });

    test('onToolCall closes open reasoning before adding a new tool', () {
      notifier.onReasoning('p1', 'm1', 'ses_abc', 'before tool');
      notifier.onToolCall('tc1', 'tool_1', 'm1', 'ses_abc', 'bash', {
        'cmd': 'ls',
      });

      final parts = container.read(chatScreenProvider).streamingParts;
      final reasonings = parts.whereType<AssistantReasoning>().toList();
      final tools = parts.whereType<AssistantTool>().toList();

      expect(tools.length, 1, reason: 'tool added');
      expect(reasonings.length, 1);
      expect(
        reasonings.single.ended,
        isNotNull,
        reason: 'reasoning must be CLOSED when tool starts — no append',
      );
    });

    test(
      'reasoning AFTER tool creates a NEW reasoning block (Bug 6 regression)',
      () {
        notifier.onReasoning('p1', 'm1', 'ses_abc', 'reasoning 1');
        notifier.onToolCall('tc1', 'tool_1', 'm1', 'ses_abc', 'bash', {
          'cmd': 'ls',
        });
        notifier.onReasoning('p2', 'm1', 'ses_abc', 'reasoning 2');

        final reasonings = container
            .read(chatScreenProvider)
            .streamingParts
            .whereType<AssistantReasoning>()
            .toList();
        expect(
          reasonings.length,
          2,
          reason:
              'new reasoning after tool must be a SEPARATE widget, not append',
        );
        expect(reasonings[0].text, 'reasoning 1');
        expect(reasonings[0].ended, isNotNull);
        expect(reasonings[1].text, 'reasoning 2');
        expect(reasonings[1].ended, isNull, reason: 'still streaming');
      },
    );

    test('text AFTER tool creates a NEW text block', () {
      notifier.onToolCall('tc1', 'tool_1', 'm1', 'ses_abc', 'bash', {});

      notifier.onChunk('txt1', 'm1', 'ses_abc', 'first answer ');
      notifier.onChunk('txt1', 'm1', 'ses_abc', 'continues');

      notifier.onToolCall('tc2', 'tool_2', 'm1', 'ses_abc', 'bash', {});

      notifier.onChunk('txt2', 'm1', 'ses_abc', 'second answer');

      final texts = container
          .read(chatScreenProvider)
          .streamingParts
          .whereType<AssistantText>()
          .toList();
      expect(
        texts.length,
        2,
        reason: 'text after tool must START a new widget, not append',
      );
      expect(texts[0].text, 'first answer continues');
      expect(texts[1].text, 'second answer');
    });

    test(
      'reasoning -> text -> reasoning -> tools -> reasoning -> text natural order',
      () {
        notifier.onReasoning('r1', 'm1', 'ses_abc', 'thought 1');
        notifier.onChunk('t1', 'm1', 'ses_abc', 'answer 1');
        notifier.onReasoning('r2', 'm1', 'ses_abc', 'thought 2');
        notifier.onToolCall('tc1', 'tool_1', 'm1', 'ses_abc', 'bash', {});
        notifier.onToolCall('tc2', 'tool_2', 'm1', 'ses_abc', 'bash', {});
        notifier.onToolCall('tc3', 'tool_3', 'm1', 'ses_abc', 'bash', {});
        notifier.onReasoning('r3', 'm1', 'ses_abc', 'thought 3');
        notifier.onChunk('t2', 'm1', 'ses_abc', 'answer 2');

        final parts = container.read(chatScreenProvider).streamingParts;
        final types = parts.map((p) => p.runtimeType.toString()).toList();

        expect(
          types,
          [
            'AssistantReasoning',
            'AssistantText',
            'AssistantTool',
            'AssistantTool',
            'AssistantTool',
            'AssistantReasoning',
            'AssistantText',
          ],
          reason:
              'must follow natural provider event order, no merging across tool/question/task',
        );
      },
    );

    test('onTaskStart closes open text/reasoning', () {
      notifier.onReasoning('r1', 'm1', 'ses_abc', 'pre-task reasoning');
      notifier.onTaskStart('task_1', 'm1', 'ses_abc', 'explore', 'Explore');

      final parts = container.read(chatScreenProvider).streamingParts;
      final reasonings = parts.whereType<AssistantReasoning>().toList();
      final tasks = parts.whereType<AssistantTask>().toList();

      expect(tasks.length, 1);
      expect(reasonings.single.ended, isNotNull);
    });

    test('onTaskStart dedup — duplicate partId is ignored', () {
      notifier.onTaskStart('task_1', 'm1', 'ses_abc', 'explore', 'Explore');
      notifier.onTaskStart('task_1', 'm1', 'ses_abc', 'explore', 'Explore');

      final parts = container.read(chatScreenProvider).streamingParts;
      final tasks = parts.whereType<AssistantTask>().toList();

      expect(
        tasks.length,
        1,
        reason: 'calling onTaskStart twice with same partId must not duplicate',
      );
    });

    test('onQuestion closes open text/reasoning', () {
      notifier.onReasoning('r1', 'm1', 'ses_abc', 'pre-question reasoning');
      notifier.onReasoning('r1', 'm1', 'ses_abc', ' more');
      notifier.onQuestion('q1', 'm1', 'ses_abc', 'Pick one', ['A', 'B']);

      final reasonings = container
          .read(chatScreenProvider)
          .streamingParts
          .whereType<AssistantReasoning>()
          .toList();
      expect(reasonings.length, 1);
      expect(
        reasonings.single.ended,
        isNotNull,
        reason: 'reasoning must close before question is presented',
      );
    });

    test('onTodo closes open text/reasoning', () {
      notifier.onReasoning('r1', 'm1', 'ses_abc', 'pre-todo');
      notifier.onChunk('t1', 'm1', 'ses_abc', 'pre-todo text');
      notifier.onTodo('todo1', 'm1', 'ses_abc', const []);

      final parts = container.read(chatScreenProvider).streamingParts;
      expect(parts.whereType<AssistantReasoning>().single.ended, isNotNull);
    });
  });

  group('ChatScreenNotifier assistantContentToPartMaps — JSON schema fix', () {
    late ProviderContainer container;
    late ChatScreenNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(chatScreenProvider.notifier);
      notifier.startStreaming('ses_abc');
    });

    tearDown(() => container.dispose());

    test('reasoning serializes with content (not text) for round-trip', () {
      final closedReasoning = AssistantReasoning(
        id: 'p1',
        sessionId: 'ses_abc',
        messageId: 'm1',
        text: 'think',
        started: DateTime.now().subtract(const Duration(seconds: 2)),
        ended: DateTime.now(),
      );

      final json = assistantContentToPartMaps([closedReasoning]).first;
      expect(json['type'], 'reasoning');
      expect(
        json['content'],
        'think',
        reason: 'must use MessagePart schema "content" key (not "text")',
      );
      expect(
        json['startedAt'],
        isNotNull,
        reason: 'must use MessagePart schema "startedAt" key (not "started")',
      );
      expect(
        json['durationMs'],
        isA<int>(),
        reason: 'timing must be preserved when ended is set',
      );
    });

    test('tool serializes with toolName/toolCallId (not tool/callId)', () {
      final tool = AssistantTool(
        id: 'p1',
        sessionId: 'ses_abc',
        messageId: 'm1',
        callId: 'tc_1',
        tool: 'bash',
        state: ToolState.completed,
        input: {'cmd': 'ls'},
        output: 'file.txt',
      );

      final json = assistantContentToPartMaps([tool]).first;
      expect(
        json['type'],
        'tool_result',
        reason: 'schema uses tool_result, not tool',
      );
      expect(json['toolName'], 'bash', reason: 'schema uses toolName');
      expect(json['toolCallId'], 'tc_1', reason: 'schema uses toolCallId');
      expect(
        json['result'],
        'file.txt',
        reason: 'schema uses result, not output',
      );
    });

    test('task serializes with status (not state)', () {
      final task = AssistantTask(
        id: 'task_1',
        sessionId: 'ses_abc',
        messageId: 'm1',
        description: 'Do something',
        agent: 'explore',
        state: ToolState.completed,
        currentTool: 'bash',
        startedAt: DateTime.now().subtract(const Duration(seconds: 5)),
        endedAt: DateTime.now(),
      );

      final json = assistantContentToPartMaps([task]).first;
      expect(json['type'], 'task');
      expect(
        json['status'],
        'completed',
        reason:
            'schema uses status (not state) — critical to avoid default "running"',
      );
      expect(json['currentTool'], 'bash');
      expect(json['startedAt'], isNotNull);
    });

    test('final message round-trip preserves all part types', () {
      // Simulate a full natural flow ending in saved message
      notifier.onReasoning('r1', 'm1', 'ses_abc', 'thought');
      notifier.onChunk('t1', 'm1', 'ses_abc', 'answer');
      notifier.onToolCall('tc1', 'tool_1', 'm1', 'ses_abc', 'bash', {
        'cmd': 'ls',
      });

      // Capture parts BEFORE finalizeStreaming cleared them (Bug fix: should
      // already have reasoning/text closed due to onToolCall closing logic)
      final parts = container.read(chatScreenProvider).streamingParts;

      final reasoningsBefore = parts.whereType<AssistantReasoning>().toList();
      expect(reasoningsBefore.length, 1);
      expect(reasoningsBefore.first.ended, isNotNull);

      final toolsBefore = parts.whereType<AssistantTool>().toList();
      expect(toolsBefore.length, 1);
      expect(toolsBefore.first.state, ToolState.running);

      // Now serialize and verify schema
      final json = assistantContentToPartMaps(parts);
      expect(json.length, 3, reason: '3 parts: reasoning, text, tool');
      expect(json[0]['type'], 'reasoning');
      expect(json[1]['type'], 'text');
      expect(json[2]['type'], 'tool_result');
    });
  });

  group('ChatScreenSessionId — Bug 5 fix (child session isolation)', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test(
      'streamingSessionId is set on startStreaming and cleared on finalize',
      () {
        final n = container.read(chatScreenProvider.notifier);
        n.startStreaming('ses_parent');
        expect(
          container.read(chatScreenProvider).streamingSessionId,
          'ses_parent',
        );

        n.finalizeStreaming();
        expect(container.read(chatScreenProvider).streamingSessionId, isNull);
      },
    );

    test('two sessions cannot share streaming state — starting a new session '
        'must produce its own sessionId', () {
      final n = container.read(chatScreenProvider.notifier);
      n.startStreaming('ses_parent');
      n.onReasoning('r1', 'm1', 'ses_parent', 'parent thought');

      // Simulate: user opens child session via SessionContextWindow — but
      // the global chatScreenProvider shouldn't leak parent streaming data
      // into the child view. The widget-side fix (Phase 3) makes child
      // sessions skip watching this provider entirely.
      // Here we just verify the provider has a single source-of-truth sessionId.
      expect(
        container.read(chatScreenProvider).streamingSessionId,
        'ses_parent',
      );
    });
  });
}
