import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

PermissionRule rule(String p, String pattern, PermissionAction a) =>
    PermissionRule(permission: p, pattern: pattern, action: a);

void main() {
  group('PermissionService — ask() flow', () {
    late PermissionService service;
    late MockSharedPreferences prefs;

    setUp(() {
      service = PermissionService();
      prefs = MockSharedPreferences();
      when(() => prefs.getStringList(any())).thenReturn(null);
      when(() => prefs.setStringList(any(), any())).thenAnswer((_) async => true);
      service.attachPreferences(prefs);
    });

    test('emits PermissionRequest on onAsked when ask rule matches', () async {
      service.seedRules(PermissionRuleset(rules: [
        rule('write', 'lib/**', PermissionAction.ask),
      ]));

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
      service.seedRules(PermissionRuleset(rules: [
        rule('read', 'lib/**', PermissionAction.ask),
      ]));

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
      service.seedRules(PermissionRuleset(rules: [
        rule('edit', 'lib/**', PermissionAction.ask),
      ]));

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
      service.seedRules(PermissionRuleset(rules: [
        rule('bash', '*', PermissionAction.ask),
      ]));

      final req = PermissionRequest(
        id: 'r4',
        toolName: 'bash',
        permission: 'bash',
        patterns: ['*'],
      );

      final f = service.ask(req, PermissionRuleset());
      await Future<void>.delayed(Duration.zero);
      service.reply(req.id, PermissionReply.reject);

      expect(f, throwsA(isA<PermissionRejectedError>()));
    });

    test('reply(reject) rejects same-session siblings', () async {
      service.seedRules(PermissionRuleset(rules: [
        rule('read', 'lib/**', PermissionAction.ask),
        rule('write', 'lib/**', PermissionAction.ask),
      ]));

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
        options: ['Yes', 'No'],
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

  group('PermissionService — preferences persistence', () {
    test('loads approved rules from pipe-delimited prefs', () async {
      final prefs = MockSharedPreferences();
      when(() => prefs.getStringList(any())).thenReturn([
        'read|lib/**|allow',
        'write|src/**|deny',
      ]);
      when(() => prefs.setStringList(any(), any())).thenAnswer((_) async => true);

      final s = PermissionService();
      s.attachPreferences(prefs);

      expect(s.approvedRules.length, 2);
      expect(s.approvedRules[0].permission, 'read');
      expect(s.approvedRules[0].action, PermissionAction.allow);
    });

    test('ignores malformed prefs entries', () async {
      final prefs = MockSharedPreferences();
      when(() => prefs.getStringList(any())).thenReturn([
        'read|lib/**|allow',
        'corrupt',
        'write|src/**',
      ]);
      when(() => prefs.setStringList(any(), any())).thenAnswer((_) async => true);

      final s = PermissionService();
      s.attachPreferences(prefs);

      expect(s.approvedRules.length, 1);
    });

    test('persists approved rules on reply(always)', () async {
      final prefs = MockSharedPreferences();
      final captured = <List<String>>[];
      when(() => prefs.getStringList(any())).thenReturn(null);
      when(() => prefs.setStringList(any(), any()))
          .thenAnswer((i) {
        captured.add(i.positionalArguments[1] as List<String>);
        return Future<bool>.value(true);
      });

      final s = PermissionService();
      s.attachPreferences(prefs);

      s.seedRules(PermissionRuleset(rules: [
        rule('delete', 'tmp/**', PermissionAction.ask),
      ]));

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

      expect(captured, isNotEmpty);
      expect(captured.last.first, 'delete|tmp/old|allow');
    });
  });

  group('PermissionService — cancel/clear', () {
    late PermissionService service;

    setUp(() {
      service = PermissionService();
      service.seedRules(PermissionRuleset(rules: [
        rule('read', '*', PermissionAction.ask),
      ]));
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
