import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/permission_storage.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

PermissionRule rule(String p, String pattern, PermissionAction a) =>
    PermissionRule(permission: p, pattern: pattern, action: a);

void main() {
  group('PermissionService — ask() flow', () {
    late PermissionService service;
    late MockSharedPreferences prefs;

    setUp(() {
      prefs = MockSharedPreferences();
      when(() => prefs.getStringList(any())).thenReturn(null);
      when(
        () => prefs.setStringList(any(), any()),
      ).thenAnswer((_) async => true);
      service = PermissionService(storage: SharedPrefsPermissionStorage(prefs));
    });

    test('emits PermissionRequest on onAsked when ask rule matches', () async {
      service.seedRules(
        PermissionRuleset(
          rules: [rule('write', 'lib/**', PermissionAction.ask)],
        ),
      );

      final req = PermissionRequest(
        id: 'r1',
        toolName: 'write',
        permission: 'write',
        patterns: ['lib/main.dart'],
        metadata: {'sessionId': 's1'},
      );

      final emitted = <PermissionRequest>[];
      service.onAsked.listen(emitted.add);

      final f = service.ask(req, PermissionRuleset());
      await Future<void>.delayed(Duration.zero);
      expect(emitted, contains(req));

      service.reply(req.id, PermissionReply.once);
      await f;
    });

    test('reply(once) does not persist approved rule', () async {
      service.seedRules(
        PermissionRuleset(
          rules: [rule('read', 'lib/**', PermissionAction.ask)],
        ),
      );

      final req = PermissionRequest(
        id: 'r2',
        toolName: 'read',
        permission: 'read',
        patterns: ['lib/a.dart'],
      );

      final f = service.ask(req, PermissionRuleset());
      await Future<void>.delayed(Duration.zero);
      service.reply(req.id, PermissionReply.once);
      await f;

      expect(service.approvedRules, isEmpty);
    });

    test('reply(always) persists approved rule', () async {
      service.seedRules(
        PermissionRuleset(
          rules: [rule('edit', 'lib/**', PermissionAction.ask)],
        ),
      );

      final req = PermissionRequest(
        id: 'r3',
        toolName: 'edit',
        permission: 'edit',
        patterns: ['lib/main.dart'],
      );

      final f = service.ask(req, PermissionRuleset());
      await Future<void>.delayed(Duration.zero);
      service.reply(req.id, PermissionReply.always);
      await f;

      expect(service.isAllowed('edit', 'lib/main.dart'), isTrue);
    });

    test('reply(reject) throws PermissionRejectedError', () async {
      service.seedRules(
        PermissionRuleset(rules: [rule('shell', '*', PermissionAction.ask)]),
      );

      final req = PermissionRequest(
        id: 'r4',
        toolName: 'shell',
        permission: 'shell',
        patterns: ['*'],
      );

      final f = service.ask(req, PermissionRuleset());
      await Future<void>.delayed(Duration.zero);
      service.reply(req.id, PermissionReply.reject);

      expect(f, throwsA(isA<PermissionRejectedError>()));
    });

    test('reply(reject) rejects same-session siblings', () async {
      service.seedRules(
        PermissionRuleset(
          rules: [
            rule('read', 'lib/**', PermissionAction.ask),
            rule('write', 'lib/**', PermissionAction.ask),
          ],
        ),
      );

      final req1 = PermissionRequest(
        id: 's1',
        toolName: 'read',
        permission: 'read',
        patterns: ['lib/a.dart'],
        metadata: {'sessionId': 'sess-x'},
      );
      final req2 = PermissionRequest(
        id: 's2',
        toolName: 'write',
        permission: 'write',
        patterns: ['lib/b.dart'],
        metadata: {'sessionId': 'sess-x'},
      );
      final req3 = PermissionRequest(
        id: 's3',
        toolName: 'read',
        permission: 'read',
        patterns: ['lib/c.dart'],
        metadata: {'sessionId': 'sess-y'},
      );

      final f1 = service.ask(req1, PermissionRuleset());
      final f2 = service.ask(req2, PermissionRuleset());
      final f3 = service.ask(req3, PermissionRuleset());
      await Future<void>.delayed(Duration.zero);

      service.reply(req1.id, PermissionReply.reject);

      expect(f1, throwsA(isA<PermissionRejectedError>()));
      expect(f2, throwsA(isA<PermissionRejectedError>()));
      expect(f3, completes);
      service.reply(req3.id, PermissionReply.once);
      await f3;
    });
  });

  group('PermissionService — askQuestion', () {
    late PermissionService service;

    setUp(() => service = PermissionService());

    test('emits QuestionRequest on stream and resolves on answer', () async {
      final emitted = <QuestionRequest>[];
      service.onQuestionAsked.listen(emitted.add);

      final f = service.askQuestion(
        id: 'q1',
        question: 'Continue?',
        options: [
          const QuestionOption(label: 'Yes', description: null),
          const QuestionOption(label: 'No', description: null),
        ],
      );
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isNotEmpty);
      expect(emitted.last.id, 'q1');
      expect(emitted.last.question, 'Continue?');

      service.answerQuestion('q1', 'Yes');
      expect(await f, 'Yes');
    });

    test('cancelPendingQuestion resolves with empty string', () async {
      final f = service.askQuestion(id: 'q2', question: 'Will cancel');
      await Future<void>.delayed(Duration.zero);

      service.cancelPendingQuestion('q2');
      expect(await f, isEmpty);
    });

    test('answerQuestion for unknown id is no-op', () {
      expect(() => service.answerQuestion('nope', 'yes'), returnsNormally);
    });
  });

  group('PermissionService — session-scoped approved rules', () {
    test(
      'constructor with SharedPrefsPermissionStorage does not load any rules',
      () async {
        final prefs = MockSharedPreferences();
        when(
          () => prefs.getStringList(any()),
        ).thenReturn(['read|lib/**|allow', 'write|src/**|deny']);

        final s = PermissionService(
          storage: SharedPrefsPermissionStorage(prefs),
        );

        expect(s.approvedRules, isEmpty);
      },
    );

    test('reply(always) adds rules in memory only', () async {
      final s = PermissionService();
      s.seedRules(
        PermissionRuleset(
          rules: [rule('delete', 'tmp/**', PermissionAction.ask)],
        ),
      );

      final req = PermissionRequest(
        id: 'rp',
        toolName: 'delete',
        permission: 'delete',
        patterns: ['tmp/old'],
      );

      final f = s.ask(req, PermissionRuleset());
      await Future<void>.delayed(Duration.zero);
      s.reply(req.id, PermissionReply.always);
      await f;

      expect(s.isAllowed('delete', 'tmp/old'), isTrue);
    });

    test('new session clears previously approved rules', () async {
      final s = PermissionService();
      s.seedRules(
        PermissionRuleset(rules: [rule('write', '*', PermissionAction.ask)]),
      );

      // Session A: approve write
      var req = PermissionRequest(
        id: 's1',
        toolName: 'write',
        permission: 'write',
        patterns: ['a.txt'],
        metadata: {'sessionId': 'sess-a'},
      );
      var f = s.ask(req, PermissionRuleset());
      await Future<void>.delayed(Duration.zero);
      s.reply(req.id, PermissionReply.always);
      await f;
      expect(s.isAllowed('write', 'a.txt'), isTrue);

      // Session B: old rules should be gone
      req = PermissionRequest(
        id: 's2',
        toolName: 'write',
        permission: 'write',
        patterns: ['b.txt'],
        metadata: {'sessionId': 'sess-b'},
      );
      f = s.ask(req, PermissionRuleset());
      await Future<void>.delayed(Duration.zero);

      // Confirm: approved rules were cleared
      expect(s.approvedRules, isEmpty);
      s.reply(req.id, PermissionReply.once);
      await f;
    });
  });

  group('PermissionService — cancel/clear', () {
    late PermissionService service;

    setUp(() {
      service = PermissionService();
      service.seedRules(
        PermissionRuleset(rules: [rule('read', '*', PermissionAction.ask)]),
      );
    });

    test('cancelAllPendingRequests rejects active asks', () async {
      final req = PermissionRequest(
        id: 'ca',
        toolName: 'read',
        permission: 'read',
        patterns: ['*'],
      );

      final f = service.ask(req, PermissionRuleset());
      await Future<void>.delayed(Duration.zero);

      service.cancelAllPendingRequests();

      expect(f, throwsA(isA<PermissionRejectedError>()));
    });

    test('cancelAllPendingRequests clears question state', () async {
      final f = service.askQuestion(id: 'q2', question: 'Will cancel');
      await Future<void>.delayed(Duration.zero);

      service.cancelAllPendingRequests();

      final answer = await f;
      expect(answer, isEmpty);
    });
  });

  group('PermissionService — validation', () {
    late PermissionService service;

    setUp(() => service = PermissionService());

    test('isAllowed with empty pattern throws ArgumentError', () {
      expect(() => service.isAllowed('read', ''), throwsArgumentError);
    });

    test('isAllowed with whitespace pattern throws ArgumentError', () {
      expect(() => service.isAllowed('read', '   '), throwsArgumentError);
    });

    test('isAllowed trims pattern before evaluation', () {
      expect(() => service.isAllowed('read', '  lib/**  '), returnsNormally);
    });
  });
}
