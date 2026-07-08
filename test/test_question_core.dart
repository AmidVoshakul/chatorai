import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/tools/built_in/question.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_execution.dart';
import 'package:chatorai/features/chat/data/models/chat/question_part.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Create a minimal [ToolContext] that records ask/askQuestion calls.
class RecordingToolContext {
  final List<PermissionRequest> askCalls = [];
  final questionCalls = <QuestionCall>[];
  String answerToReturn = '';
  Exception? askToThrow;

  ToolContext create() {
    return ToolContext(
      toolCallId: 'test-call',
      sessionId: 'test-session',
      ask:
          ({
            required String permission,
            required List<String> patterns,
            Map<String, dynamic>? metadata,
            List<String>? always,
          }) async {
            askCalls.add(
              PermissionRequest(
                id: 'ask_${askCalls.length}',
                toolName: 'question',
                permission: permission,
                patterns: patterns,
                metadata: metadata ?? {},
                always: always ?? [],
              ),
            );
            if (askToThrow != null) throw askToThrow!;
          },
      askQuestion:
          ({
            required String question,
            List<QuestionOption> options = const [],
            bool multiple = false,
          }) async {
            questionCalls.add(
              QuestionCall(
                question: question,
                options: options,
                multiple: multiple,
              ),
            );
            return answerToReturn;
          },
    );
  }
}

class QuestionCall {
  final String question;
  final List<QuestionOption> options;
  final bool multiple;

  const QuestionCall({
    required this.question,
    required this.options,
    required this.multiple,
  });
}

/// Fake tool options for testing ToolExecutor without SDK dependencies.
class _FakeToolOptions {
  final String? sessionId;
  final Map<String, dynamic>? experimentalContext;

  _FakeToolOptions({this.sessionId, this.experimentalContext});
}

// ---------------------------------------------------------------------------
// PermissionService — askQuestion / answerQuestion / cancelPendingQuestion
// ---------------------------------------------------------------------------

void main() {
  // ── PermissionService: AskQuestion ──────────────────────────────────────

  group('PermissionService.askQuestion', () {
    late PermissionService service;

    setUp(() {
      service = PermissionService();
    });

    test('returns answer when user answers immediately', () async {
      final future = service.askQuestion(
        id: 'q-1',
        question: 'What is your name?',
        options: [
          const QuestionOption(label: 'Alice', description: null),
          const QuestionOption(label: 'Bob', description: null),
        ],
      );

      // Answer from "user" on the next microtask
      scheduleMicrotask(() => service.answerQuestion('q-1', 'Alice'));

      final answer = await future;
      expect(answer, equals('Alice'));
    });

    test('does not complete when no answer is provided', () async {
      final future = service.askQuestion(
        id: 'q-timeout',
        question: 'Confused?',
      );

      // The future should not complete immediately (it's waiting for user).
      var completed = false;
      future.then((_) => completed = true);

      // Give microtasks a chance to process.
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      // Clean up: cancel the pending question
      service.cancelPendingQuestion('q-timeout');
    });

    test('answerQuestion after completer completed does not throw', () {
      // Should silently ignore and not throw
      expect(
        () => service.answerQuestion('nonexistent', 'ignored'),
        returnsNormally,
      );
    });

    test('answerQuestion resolves pending question', () async {
      final future = service.askQuestion(id: 'q-2', question: 'Pick A or B');
      service.answerQuestion('q-2', 'B');
      final answer = await future;
      expect(answer, equals('B'));
    });
  });

  // ── PermissionService: CancelPendingQuestion ──────────────────────────

  group('PermissionService.cancelPendingQuestion', () {
    test('cancels a pending question and resolves with empty string', () async {
      final service = PermissionService();
      final future = service.askQuestion(
        id: 'q-cancel',
        question: 'Should cancel?',
      );

      service.cancelPendingQuestion('q-cancel');

      final answer = await future;
      expect(answer, equals(''));

      // Completer should be removed from internal map
      // (internal state is private, but we verify no crash on double-cancel)
      expect(() => service.cancelPendingQuestion('q-cancel'), returnsNormally);
    });

    test('cancelPendingQuestion on nonexistent id does not throw', () {
      final service = PermissionService();
      expect(() => service.cancelPendingQuestion('ghost-id'), returnsNormally);
    });

    test(
      'cancelPendingQuestion future resolves with answer if answered first',
      () async {
        final service = PermissionService();
        final future = service.askQuestion(
          id: 'q-race',
          question: 'Race condition?',
        );

        // Answer first, then cancel
        service.answerQuestion('q-race', 'Yes');
        service.cancelPendingQuestion('q-race');

        final answer = await future;
        expect(answer, equals('Yes'));
      },
    );
  });

  // ── PermissionService: Rate Limiting for Questions ─────────────────────

  group('PermissionService question rate limiting', () {
    test('returns empty string when question limit exceeded', () async {
      final service = PermissionService();

      // _isQuestionRateLimited adds to history THEN checks >= 10.
      // Call 1: history=[], 0 >= 10 = false, add → [t1]
      // Call 10: history=[t1..t9], 9 >= 10 = false, add → [t1..t10]
      // Call 11: history=[t1..t10], 10 >= 10 = true → limited, returns ''
      // Call 12: history=[t1..t10], 10 >= 10 = true → limited, returns ''

      final futures = <Future<String>>[];

      for (var i = 0; i < 12; i++) {
        futures.add(
          service.askQuestion(id: 'rl-q-$i', question: 'Question $i?'),
        );
      }

      // Answer the non-limited questions (first 10) so they complete.
      for (var i = 0; i < 10; i++) {
        service.answerQuestion('rl-q-$i', 'answer-$i');
      }

      // Wait for all futures to complete.
      // Rate-limited calls (11, 12) return '' immediately.
      final results = await Future.wait(futures);

      // First 10 should have real answers
      for (var i = 0; i < 10; i++) {
        expect(results[i], equals('answer-$i'));
      }

      // 11th and 12th should be empty (rate-limited)
      expect(results[10], equals(''));
      expect(results[11], equals(''));
    });
  });

  // ── PermissionService: cancelAllPendingRequests ───────────────────────

  group('PermissionService.cancelAllPendingRequests (question cleanup)', () {
    test('cancels all pending questions when called', () async {
      final service = PermissionService();

      final q1 = service.askQuestion(id: 'cancel-q1', question: 'Q1?');
      final q2 = service.askQuestion(id: 'cancel-q2', question: 'Q2?');
      final q3 = service.askQuestion(id: 'cancel-q3', question: 'Q3?');

      service.cancelAllPendingRequests();

      expect(await q1, equals(''));
      expect(await q2, equals(''));
      expect(await q3, equals(''));
    });

    test('cancelAllPendingRequests also clears pending permissions', () async {
      final service = PermissionService();

      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );

      // Start a permission ask that will block
      final askFuture = service.ask(
        PermissionRequest(
          id: 'cancel-perm-1',
          toolName: 'bash',
          permission: 'bash',
          patterns: ['dangerous-command'],
          metadata: {'sessionId': 's1'},
        ),
        ruleset,
      );

      service.cancelAllPendingRequests();

      expect(
        () async => await askFuture,
        throwsA(isA<PermissionRejectedError>()),
      );
    });

    test('cancelAllPendingRequests clears rate-limit history', () async {
      final service = PermissionService();

      // Trigger rate limiting by making 12 question calls.
      // (History accumulates after this.)
      final futures = <Future<String>>[];
      for (var i = 0; i < 12; i++) {
        futures.add(service.askQuestion(id: 'clr-q$i', question: 'Q$i'));
      }
      await Future<void>.delayed(Duration.zero);

      // Clear rate-limit history
      service.cancelAllPendingRequests();

      // After clearing, a new question call should proceed normally
      // (not be rate-limited).
      // We use a direct answer to verify.
      final postClear = service.askQuestion(
        id: 'clr-post',
        question: 'After clear',
      );
      service.answerQuestion('clr-post', 'fresh');
      final result = await postClear;

      expect(result, equals('fresh'));

      // Also cancel the original pending questions from the loop
      // (they may have already been rate-limited, so just wait)
      await Future.wait(futures);
    });
  });

  // ── PermissionService: QuestionRequest broadcast stream ───────────────

  group('PermissionService.onQuestionAsked stream', () {
    test('emits QuestionRequest when askQuestion called', () async {
      final service = PermissionService();

      final streamFutures = <Future<QuestionRequest>>[];
      // Listen for 2 events
      streamFutures.add(service.onQuestionAsked.first);
      streamFutures.add(service.onQuestionAsked.skip(1).first);

      // Delay slightly to allow subscription to attach.
      scheduleMicrotask(() {
        service.askQuestion(
          id: 'stream-q1',
          question: 'First?',
          options: [const QuestionOption(label: 'A', description: null)],
        );
        service.askQuestion(id: 'stream-q2', question: 'Second?');
      });

      final requests = await Future.wait(streamFutures);

      expect(requests[0].question, equals('First?'));
      expect(requests[0].options.map((o) => o.label), equals(['A']));
      expect(requests[1].question, equals('Second?'));
    });
  });

  // ── QuestionPart: copyWith preserves fields ───────────────────────────

  group('QuestionPart.copyWith field preservation', () {
    test('copyWith with no arguments preserves all fields', () {
      const original = QuestionPart(
        question: 'Proceed?',
        options: [
          const QuestionOption(label: 'Yes', description: null),
          const QuestionOption(label: 'No', description: null),
          const QuestionOption(label: 'Maybe', description: null),
        ],
        answer: 'Yes',
      );
      final copy = original.copyWith();

      expect(copy.question, equals('Proceed?'));
      expect(copy.options.map((o) => o.label), equals(['Yes', 'No', 'Maybe']));
      expect(copy.answer, equals('Yes'));
    });

    test('copyWith updates only question', () {
      const original = QuestionPart(
        question: 'Original?',
        options: [const QuestionOption(label: 'A', description: null)],
        answer: 'A',
      );
      final copy = original.copyWith(question: 'Updated?');

      expect(copy.question, equals('Updated?'));
      expect(copy.options.map((o) => o.label), equals(['A']));
      expect(copy.answer, equals('A'));
    });

    test('copyWith updates only options', () {
      const original = QuestionPart(
        question: 'Q?',
        options: [const QuestionOption(label: 'old', description: null)],
        answer: 'old',
      );
      final copy = original.copyWith(
        options: const [
          QuestionOption(label: 'new1', description: null),
          QuestionOption(label: 'new2', description: null),
        ],
      );

      expect(copy.question, equals('Q?'));
      expect(
        copy.options,
        equals(const [
          QuestionOption(label: 'new1', description: null),
          QuestionOption(label: 'new2', description: null),
        ]),
      );
      expect(copy.answer, equals('old'));
    });

    test('copyWith with null answer preserves null', () {
      const original = QuestionPart(question: 'Pending?');
      final copy = original.copyWith(question: 'Still pending?');

      expect(copy.answer, isNull);
      expect(copy.question, equals('Still pending?'));
    });

    test('copyWith replaces non-null answer with new value', () {
      const original = QuestionPart(question: 'Q?', answer: 'Old');
      final copy = original.copyWith(answer: 'New');

      expect(copy.answer, equals('New'));
    });

    test('copyWith can set answer from null to a value', () {
      const original = QuestionPart(question: 'Q?');
      final copy = original.copyWith(answer: 'Resolved');

      expect(copy.answer, equals('Resolved'));
      expect(copy.question, equals('Q?'));
    });
  });

  // ── QuestionPart: toJson / fromJson roundtrip edge cases ──────────────

  group('QuestionPart serialization edge cases', () {
    test('toJson includes all fields even when answer is null', () {
      const part = QuestionPart(
        question: 'Q?',
        options: [
          const QuestionOption(label: 'A', description: null),
          const QuestionOption(label: 'B', description: null),
        ],
      );
      final json = part.toJson();

      expect(json['type'], equals('question'));
      expect(json['question'], equals('Q?'));
      expect(
        json['options'],
        equals([
          {'label': 'A'},
          {'label': 'B'},
        ]),
      );
      expect(json['answer'], isNull);
    });

    test('fromJson with explicit null options', () {
      final json = {
        'type': 'question',
        'question': 'Q',
        'options': null,
        'answer': null,
      };
      final part = QuestionPart.fromJson(json);

      expect(part.options, isEmpty);
      expect(part.answer, isNull);
    });

    test('fromJson with empty options list', () {
      final json = {
        'type': 'question',
        'question': 'Q',
        'options': <String>[],
        'answer': 'Yes',
      };
      final part = QuestionPart.fromJson(json);

      expect(part.options, isEmpty);
      expect(part.answer, equals('Yes'));
    });

    test('roundtrip with complex options', () {
      const original = QuestionPart(
        question: 'Choose color',
        options: [
          const QuestionOption(label: 'Red', description: null),
          const QuestionOption(label: 'Green', description: null),
          const QuestionOption(label: 'Blue', description: null),
          const QuestionOption(label: 'Yellow', description: null),
        ],
        answer: 'Green',
      );
      final restored = QuestionPart.fromJson(original.toJson());

      expect(restored.question, equals('Choose color'));
      expect(
        restored.options.map((o) => o.label),
        equals(['Red', 'Green', 'Blue', 'Yellow']),
      );
      expect(restored.answer, equals('Green'));
    });

    test('fromJson throws when question field is missing', () {
      final json = {
        'type': 'question',
        'options': ['A'],
      };
      expect(() => QuestionPart.fromJson(json), throwsA(isA<TypeError>()));
    });
  });

  // ── PermissionService: seedRules + isAllowed for question ─────────────

  group('PermissionService question rule evaluation', () {
    test('question is allowed by default rules', () {
      final service = PermissionService();
      final ruleset = PermissionRuleset.defaults();
      service.seedRules(ruleset);

      expect(service.isAllowed('question', '*'), isTrue);
    });

    test('question with custom deny rule is not allowed', () {
      final service = PermissionService();
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'question',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      service.seedRules(ruleset);

      expect(service.isAllowed('question', '*'), isFalse);
    });

    test('question with ask rule needs user permission', () {
      final service = PermissionService();
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'question',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );
      service.seedRules(ruleset);

      // isAllowed returns false when rule is 'ask'
      expect(service.isAllowed('question', '*'), isFalse);
    });
  });

  // ── Question Tool Def: askQuestion callback integration ───────────────

  group('QuestionTool.askQuestion integration', () {
    test('ToolDef passes question and options to ctx.askQuestion', () async {
      final tool = createQuestionTool();
      final ctx = RecordingToolContext()..answerToReturn = 'Opt-A';

      final output = await tool.execute({
        'question': 'Pick one',
        'options': ['Opt-A', 'Opt-B'],
      }, ctx.create());

      expect(output.output, equals('Opt-A'));
      expect(ctx.questionCalls, hasLength(1));
      expect(ctx.questionCalls[0].question, equals('Pick one'));
      expect(
        ctx.questionCalls[0].options.map((o) => o.label),
        equals(['Opt-A', 'Opt-B']),
      );
      expect(ctx.questionCalls[0].multiple, isFalse);
    });

    test('ToolDef passes multiple flag to ctx.askQuestion', () async {
      final tool = createQuestionTool();
      final ctx = RecordingToolContext()..answerToReturn = 'A';

      await tool.execute({
        'question': 'Select all',
        'options': ['A', 'B', 'C'],
        'multiple': true,
      }, ctx.create());

      expect(ctx.questionCalls, hasLength(1));
      expect(ctx.questionCalls[0].multiple, isTrue);
    });

    test(
      'ToolDef does not call ask() — permission check is in ToolExecutor',
      () async {
        // The ToolDef.execute() method calls ctx.askQuestion() directly.
        // The permission check (ctx.ask()) is done in _AskContext._askQuestion()
        // which is part of ToolExecutor. This test verifies that ToolDef does NOT
        // call ctx.ask() — it only calls ctx.askQuestion().
        final tool = createQuestionTool();
        final ctx = RecordingToolContext()..answerToReturn = 'Done';

        await tool.execute({'question': 'Proceed?'}, ctx.create());

        // No permission ask calls — only question calls
        expect(ctx.askCalls, isEmpty);
        expect(ctx.questionCalls, hasLength(1));
      },
    );

    test('ToolDef metadata includes question and answer', () async {
      final tool = createQuestionTool();
      final ctx = RecordingToolContext()..answerToReturn = 'Confirmed';

      final output = await tool.execute({
        'question': 'Continue?',
        'options': ['Yes', 'No'],
      }, ctx.create());

      expect(output.metadata?['question'], equals('Continue?'));
      expect(output.metadata?['options'] is List, isTrue);
      expect((output.metadata?['options'] as List).length, equals(2));
      expect(
        (output.metadata?['options'] as List).first is QuestionOption,
        isTrue,
      );
      expect(output.metadata?['answer'], equals('Confirmed'));
    });
  });

  // ── ToolExecutor: _AskContext._askQuestion permission pipeline ────────

  group('ToolExecutor._AskContext permission pipeline', () {
    test(
      '_askQuestion calls permissions.ask with correct PermissionRequest',
      () async {
        // ToolExecutor creates _AskContext which calls permissions.ask()
        // with a PermissionRequest. We verify the PermissionRequest structure
        // by using a real PermissionService with a custom ruleset that
        // records the request via the onAsked stream.
        final service = PermissionService();
        final ruleset = PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'question',
              pattern: '*',
              action: PermissionAction.ask,
            ),
          ],
        );
        service.seedRules(ruleset);

        final executor = ToolExecutor(service, ruleset);
        final tool = createQuestionTool();

        // Listen for the permission request
        final askFuture = service.onAsked.first;

        // Execute through ToolExecutor — this will block waiting for permission
        final executeFuture = executor.execute(
          tool,
          {
            'question': 'Choose direction',
            'options': ['Left', 'Right'],
          },
          _FakeToolOptions(
            sessionId: 'test-session',
            experimentalContext: {'sessionId': 'test-session'},
          ),
        );

        // Capture the permission request
        final req = await askFuture;

        // Verify the PermissionRequest structure
        expect(req.id, startsWith('question_perm_'));
        expect(req.toolName, equals('question'));
        expect(req.permission, equals('question'));
        expect(req.patterns, equals(['*']));
        expect(req.metadata['sessionId'], equals('test-session'));
        expect(req.metadata['question'], equals('Choose direction'));

        // Resolve the permission AND answer the question
        service.reply(req.id, PermissionReply.once);
        // After reply, _askQuestion calls permissions.askQuestion() which
        // creates a pending question. We need to answer it.
        // The question id is generated internally, so we use onQuestionAsked.
        final questionReqFuture = service.onQuestionAsked.first;
        final questionReq = await questionReqFuture;
        service.answerQuestion(questionReq.id, 'Left');

        // Wait for execute to finish
        final result = await executeFuture;
        expect(result['output'], equals('Left'));
      },
    );

    test('_askQuestion includes sessionId from experimentalContext', () async {
      final service = PermissionService();
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'question',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );
      service.seedRules(ruleset);

      final executor = ToolExecutor(service, ruleset);
      final tool = createQuestionTool();

      final askFuture = service.onAsked.first;

      final executeFuture = executor.execute(
        tool,
        {'question': 'Session-specific question'},
        _FakeToolOptions(
          sessionId: 'custom-session-42',
          experimentalContext: {'sessionId': 'custom-session-42'},
        ),
      );

      final req = await askFuture;
      expect(req.metadata['sessionId'], equals('custom-session-42'));

      service.reply(req.id, PermissionReply.once);
      final questionReqFuture = service.onQuestionAsked.first;
      final questionReq = await questionReqFuture;
      service.answerQuestion(questionReq.id, 'A');

      await executeFuture;
    });

    test(
      '_askQuestion omits sessionId when experimentalContext is null',
      () async {
        final service = PermissionService();
        final ruleset = PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'question',
              pattern: '*',
              action: PermissionAction.ask,
            ),
          ],
        );
        service.seedRules(ruleset);

        final executor = ToolExecutor(service, ruleset);
        final tool = createQuestionTool();

        final askFuture = service.onAsked.first;

        final executeFuture = executor.execute(tool, {
          'question': 'No session question',
        }, _FakeToolOptions(sessionId: null, experimentalContext: null));

        final req = await askFuture;
        expect(req.metadata.containsKey('sessionId'), isFalse);

        service.reply(req.id, PermissionReply.once);
        final questionReqFuture = service.onQuestionAsked.first;
        final questionReq = await questionReqFuture;
        service.answerQuestion(questionReq.id, 'B');

        await executeFuture;
      },
    );
  });

  // ── PermissionService: Multiple concurrent questions ──────────────────

  group('PermissionService multiple concurrent questions', () {
    test('handles multiple independent questions concurrently', () async {
      final service = PermissionService();

      final q1 = service.askQuestion(id: 'mq-1', question: 'First?');
      final q2 = service.askQuestion(id: 'mq-2', question: 'Second?');
      final q3 = service.askQuestion(id: 'mq-3', question: 'Third?');

      service.answerQuestion('mq-2', 'B');
      service.answerQuestion('mq-1', 'A');
      service.answerQuestion('mq-3', 'C');

      final results = await Future.wait([q1, q2, q3]);
      expect(results, equals(['A', 'B', 'C']));
    });

    test('handles out-of-order answers correctly', () async {
      final service = PermissionService();

      final q1 = service.askQuestion(id: 'ooo-1', question: 'Q1?');
      final q2 = service.askQuestion(id: 'ooo-2', question: 'Q2?');

      // Answer in reverse order
      service.answerQuestion('ooo-2', 'second');
      service.answerQuestion('ooo-1', 'first');

      final r1 = await q1;
      final r2 = await q2;

      expect(r1, equals('first'));
      expect(r2, equals('second'));
    });
  });

  // ── PermissionService: clearRateLimitHistory ──────────────────────────

  group('PermissionService.clearRateLimitHistory', () {
    test('clears rate limit history allowing new questions', () async {
      final service = PermissionService();

      // Consume some of the rate limit quota
      for (var i = 0; i < 5; i++) {
        final f = service.askQuestion(id: 'clr-hist-$i', question: 'Q$i');
        service.answerQuestion('clr-hist-$i', 'a$i');
        await f;
      }

      // Clear rate limit history
      service.clearRateLimitHistory();

      // Now questions should work without rate limit issues
      final fresh = service.askQuestion(
        id: 'clr-hist-fresh',
        question: 'Fresh',
      );
      service.answerQuestion('clr-hist-fresh', 'fresh-answer');
      final result = await fresh;

      expect(result, equals('fresh-answer'));
    });
  });
}
