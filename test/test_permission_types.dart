import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/chat/chat/question_option.dart';

/// Tests for PermissionAction enum, PermissionRule model, PermissionRequest,
/// QuestionRequest, PermissionReply, and error classes.
void main() {
  // ── PermissionAction enum ──────────────────────────────────────────────

  group('PermissionAction', () {
    test('has exactly 3 values: allow, ask, deny', () {
      expect(PermissionAction.values, hasLength(3));
      expect(PermissionAction.values, contains(PermissionAction.allow));
      expect(PermissionAction.values, contains(PermissionAction.ask));
      expect(PermissionAction.values, contains(PermissionAction.deny));
    });

    test('allow has name "allow"', () {
      expect(PermissionAction.allow.name, equals('allow'));
    });

    test('ask has name "ask"', () {
      expect(PermissionAction.ask.name, equals('ask'));
    });

    test('deny has name "deny"', () {
      expect(PermissionAction.deny.name, equals('deny'));
    });

    test('PermissionAction.values.byName works for all values', () {
      expect(PermissionAction.values.byName('allow'), PermissionAction.allow);
      expect(PermissionAction.values.byName('ask'), PermissionAction.ask);
      expect(PermissionAction.values.byName('deny'), PermissionAction.deny);
    });

    test('PermissionAction.values.byName throws for unknown name', () {
      expect(
        () => PermissionAction.values.byName('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('enum equality works', () {
      expect(PermissionAction.allow == PermissionAction.allow, isTrue);
      expect(PermissionAction.allow == PermissionAction.deny, isFalse);
      expect(PermissionAction.ask == PermissionAction.ask, isTrue);
    });
  });

  // ── PermissionRule model ───────────────────────────────────────────────

  group('PermissionRule', () {
    test('const constructor creates instance with correct fields', () {
      const rule = PermissionRule(
        permission: 'read',
        pattern: '*.dart',
        action: PermissionAction.allow,
      );

      expect(rule.permission, equals('read'));
      expect(rule.pattern, equals('*.dart'));
      expect(rule.action, equals(PermissionAction.allow));
    });

    test('const constructor with wildcard permission', () {
      const rule = PermissionRule(
        permission: '*',
        pattern: '*',
        action: PermissionAction.deny,
      );

      expect(rule.permission, equals('*'));
      expect(rule.pattern, equals('*'));
      expect(rule.action, equals(PermissionAction.deny));
    });

    test('const constructor with complex pattern', () {
      const rule = PermissionRule(
        permission: 'shell',
        pattern: 'git commit -m "*"',
        action: PermissionAction.ask,
      );

      expect(rule.permission, equals('shell'));
      expect(rule.pattern, equals('git commit -m "*"'));
      expect(rule.action, equals(PermissionAction.ask));
    });

    test('equality works for identical rules', () {
      const rule1 = PermissionRule(
        permission: 'read',
        pattern: '*.txt',
        action: PermissionAction.allow,
      );
      const rule2 = PermissionRule(
        permission: 'read',
        pattern: '*.txt',
        action: PermissionAction.allow,
      );

      expect(rule1 == rule2, isTrue);
    });

    test('inequality works for different rules', () {
      const rule1 = PermissionRule(
        permission: 'read',
        pattern: '*.txt',
        action: PermissionAction.allow,
      );
      const rule2 = PermissionRule(
        permission: 'write',
        pattern: '*.txt',
        action: PermissionAction.allow,
      );

      expect(rule1 == rule2, isFalse);
    });

    test('inequality for different patterns', () {
      const rule1 = PermissionRule(
        permission: 'read',
        pattern: '*.txt',
        action: PermissionAction.allow,
      );
      const rule2 = PermissionRule(
        permission: 'read',
        pattern: '*.dart',
        action: PermissionAction.allow,
      );

      expect(rule1 == rule2, isFalse);
    });

    test('inequality for different actions', () {
      const rule1 = PermissionRule(
        permission: 'read',
        pattern: '*.txt',
        action: PermissionAction.allow,
      );
      const rule2 = PermissionRule(
        permission: 'read',
        pattern: '*.txt',
        action: PermissionAction.deny,
      );

      expect(rule1 == rule2, isFalse);
    });

    test('hashCode is consistent for identical rules', () {
      const rule1 = PermissionRule(
        permission: 'shell',
        pattern: 'rm *',
        action: PermissionAction.deny,
      );
      const rule2 = PermissionRule(
        permission: 'shell',
        pattern: 'rm *',
        action: PermissionAction.deny,
      );

      expect(rule1.hashCode, equals(rule2.hashCode));
    });

    test('toString returns default Dart representation', () {
      const rule = PermissionRule(
        permission: 'read',
        pattern: '*.dart',
        action: PermissionAction.allow,
      );

      final str = rule.toString();
      // PermissionRule does not override toString(), so it uses default
      // Dart 'Instance of' representation
      expect(str, contains('PermissionRule'));
    });
  });

  // ── PermissionRequest model ────────────────────────────────────────────

  group('PermissionRequest', () {
    test('const constructor with required fields', () {
      const req = PermissionRequest(
        id: 'req-1',
        toolName: 'read',
        permission: 'read',
        patterns: ['/some/file.txt'],
      );

      expect(req.id, equals('req-1'));
      expect(req.toolName, equals('read'));
      expect(req.permission, equals('read'));
      expect(req.patterns, equals(['/some/file.txt']));
      expect(req.metadata, isEmpty);
      expect(req.always, isEmpty);
    });

    test('const constructor with metadata', () {
      const req = PermissionRequest(
        id: 'req-2',
        toolName: 'shell',
        permission: 'shell',
        patterns: ['git *'],
        metadata: {'sessionId': 'sess-abc', 'depth': 2},
      );

      expect(req.metadata['sessionId'], equals('sess-abc'));
      expect(req.metadata['depth'], equals(2));
    });

    test('const constructor with always field', () {
      const req = PermissionRequest(
        id: 'req-3',
        toolName: 'edit',
        permission: 'edit',
        patterns: ['lib/main.dart'],
        always: ['lib/main.dart', 'lib/*.dart'],
      );

      expect(req.always, hasLength(2));
      expect(req.always, contains('lib/main.dart'));
      expect(req.always, contains('lib/*.dart'));
    });

    test('const constructor with all fields', () {
      const req = PermissionRequest(
        id: 'req-4',
        toolName: 'write',
        permission: 'write',
        patterns: ['/tmp/file.txt'],
        metadata: {'sessionId': 's1', 'source': 'user'},
        always: ['/tmp/*'],
      );

      expect(req.id, equals('req-4'));
      expect(req.toolName, equals('write'));
      expect(req.permission, equals('write'));
      expect(req.patterns, hasLength(1));
      expect(req.metadata, hasLength(2));
      expect(req.always, hasLength(1));
    });

    test('multiple patterns', () {
      const req = PermissionRequest(
        id: 'req-5',
        toolName: 'shell',
        permission: 'shell',
        patterns: ['git status', 'git log', 'git diff'],
      );

      expect(req.patterns, hasLength(3));
    });

    test('empty patterns list', () {
      const req = PermissionRequest(
        id: 'req-6',
        toolName: 'read',
        permission: 'read',
        patterns: [],
      );

      expect(req.patterns, isEmpty);
    });
  });

  // ── QuestionRequest model ──────────────────────────────────────────────

  group('QuestionRequest', () {
    test('const constructor with required fields', () {
      const q = QuestionRequest(id: 'q-1', question: 'Continue?');

      expect(q.id, equals('q-1'));
      expect(q.question, equals('Continue?'));
      expect(q.options, isEmpty);
      expect(q.multiple, isFalse);
    });

    test('const constructor with options', () {
      const q = QuestionRequest(
        id: 'q-2',
        question: 'Pick one',
        options: [
          const QuestionOption(label: 'Yes', description: null),
          const QuestionOption(label: 'No', description: null),
          const QuestionOption(label: 'Maybe', description: null),
        ],
      );

      expect(q.options, hasLength(3));
      expect(q.options.map((o) => o.label), contains('Yes'));
      expect(q.options.map((o) => o.label), contains('No'));
      expect(q.options.map((o) => o.label), contains('Maybe'));
    });

    test('const constructor with multiple=true', () {
      const q = QuestionRequest(
        id: 'q-3',
        question: 'Select all that apply',
        options: [
          const QuestionOption(label: 'A', description: null),
          const QuestionOption(label: 'B', description: null),
          const QuestionOption(label: 'C', description: null),
        ],
        multiple: true,
      );

      expect(q.multiple, isTrue);
      expect(q.options, hasLength(3));
    });

    test('const constructor with all fields', () {
      const q = QuestionRequest(
        id: 'q-4',
        question: 'Choose model',
        options: [
          const QuestionOption(label: 'GPT-4', description: null),
          const QuestionOption(label: 'Claude', description: null),
          const QuestionOption(label: 'Gemini', description: null),
        ],
        multiple: false,
      );

      expect(q.id, equals('q-4'));
      expect(q.question, equals('Choose model'));
      expect(q.options, hasLength(3));
      expect(q.multiple, isFalse);
    });
  });

  // ── PermissionReply enum ───────────────────────────────────────────────

  group('PermissionReply', () {
    test('has exactly 3 values: once, always, reject', () {
      expect(PermissionReply.values, hasLength(3));
      expect(PermissionReply.values, contains(PermissionReply.once));
      expect(PermissionReply.values, contains(PermissionReply.always));
      expect(PermissionReply.values, contains(PermissionReply.reject));
    });

    test('once has name "once"', () {
      expect(PermissionReply.once.name, equals('once'));
    });

    test('always has name "always"', () {
      expect(PermissionReply.always.name, equals('always'));
    });

    test('reject has name "reject"', () {
      expect(PermissionReply.reject.name, equals('reject'));
    });

    test('values.byName works for all values', () {
      expect(PermissionReply.values.byName('once'), PermissionReply.once);
      expect(PermissionReply.values.byName('always'), PermissionReply.always);
      expect(PermissionReply.values.byName('reject'), PermissionReply.reject);
    });
  });

  // ── PermissionDeniedError ──────────────────────────────────────────────

  group('PermissionDeniedError', () {
    test('toString formats message correctly', () {
      final error = PermissionDeniedError('read', '/secret');
      expect(
        error.toString(),
        'Permission denied: read cannot access "/secret"',
      );
    });

    test('toString with empty pattern', () {
      final error = PermissionDeniedError('shell', '');
      expect(error.toString(), 'Permission denied: shell cannot access ""');
    });

    test('stores toolName', () {
      final error = PermissionDeniedError('edit', 'file.txt');
      expect(error.toolName, equals('edit'));
    });

    test('stores pattern', () {
      final error = PermissionDeniedError('write', 'file.txt');
      expect(error.pattern, equals('file.txt'));
    });

    test('is an Exception', () {
      final error = PermissionDeniedError('read', 'file');
      expect(error, isA<Exception>());
    });
  });

  // ── PermissionRejectedError ────────────────────────────────────────────

  group('PermissionRejectedError', () {
    test('toString formats message correctly', () {
      final error = PermissionRejectedError('shell');
      expect(error.toString(), 'Permission rejected by user: shell');
    });

    test('stores toolName', () {
      final error = PermissionRejectedError('edit');
      expect(error.toolName, equals('edit'));
    });

    test('is an Exception', () {
      final error = PermissionRejectedError('read');
      expect(error, isA<Exception>());
    });
  });

  // ── PermissionRuleset ──────────────────────────────────────────────────

  group('PermissionRuleset', () {
    test('const constructor with defaults', () {
      const ruleset = PermissionRuleset();

      expect(ruleset.rules, isEmpty);
      expect(ruleset.sessionApproved, isEmpty);
    });

    test('const constructor with rules', () {
      const ruleset = PermissionRuleset(
        rules: [
          PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );

      expect(ruleset.rules, hasLength(1));
      expect(ruleset.sessionApproved, isEmpty);
    });

    test('const constructor with sessionApproved', () {
      const ruleset = PermissionRuleset(
        sessionApproved: [
          PermissionRule(
            permission: 'shell',
            pattern: 'git *',
            action: PermissionAction.allow,
          ),
        ],
      );

      expect(ruleset.rules, isEmpty);
      expect(ruleset.sessionApproved, hasLength(1));
    });

    test('const constructor with both rules and sessionApproved', () {
      const ruleset = PermissionRuleset(
        rules: [
          PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
        sessionApproved: [
          PermissionRule(
            permission: 'shell',
            pattern: 'git *',
            action: PermissionAction.allow,
          ),
        ],
      );

      expect(ruleset.rules, hasLength(1));
      expect(ruleset.sessionApproved, hasLength(1));
    });

    test('equality for identical rulesets', () {
      const rs1 = PermissionRuleset(
        rules: [
          PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );
      const rs2 = PermissionRuleset(
        rules: [
          PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );

      expect(rs1 == rs2, isTrue);
    });

    test('inequality for different rulesets', () {
      const rs1 = PermissionRuleset(
        rules: [
          PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );
      const rs2 = PermissionRuleset(
        rules: [
          PermissionRule(
            permission: 'read',
            pattern: '*.txt',
            action: PermissionAction.allow,
          ),
        ],
      );

      expect(rs1 == rs2, isFalse);
    });
  });
}
