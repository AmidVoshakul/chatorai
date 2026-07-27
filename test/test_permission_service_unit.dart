import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';

/// Unit tests for PermissionService.
///
/// Uses in-memory SharedPreferences (no real I/O).
/// Tests cover: seedRules, isAllowed, ask flow, cancelPending, rate limiting.
void main() {
  late PermissionService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = PermissionService();
  });

  group('PermissionService.seedRules', () {
    test('seeds rules from ruleset on first call', () {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );

      service.seedRules(ruleset);

      // After seeding, isAllowed should reflect the seeded rule
      expect(service.isAllowed('shell', 'any-command'), isFalse);
    });

    test('does not re-seed on subsequent calls', () {
      final ruleset1 = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      final ruleset2 = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );

      service.seedRules(ruleset1);
      service.seedRules(ruleset2);

      // First seed wins
      expect(service.isAllowed('shell', 'any-command'), isFalse);
    });

    test('does not seed empty ruleset', () {
      final ruleset = PermissionRuleset(rules: []);
      service.seedRules(ruleset);

      // No rules seeded, isAllowed should use defaults (ask → not allowed)
      expect(service.isAllowed('shell', 'any-command'), isFalse);
    });
  });

  group('PermissionService.isAllowed', () {
    test('returns true when rule allows', () {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );
      service.seedRules(ruleset);

      expect(service.isAllowed('read', '/some/file.txt'), isTrue);
    });

    test('returns false when rule denies', () {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      service.seedRules(ruleset);

      expect(service.isAllowed('shell', 'rm -rf /'), isFalse);
    });

    test('returns false when rule asks (ask is not allow)', () {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'edit',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );
      service.seedRules(ruleset);

      expect(service.isAllowed('edit', '/some/file.txt'), isFalse);
    });

    test('throws ArgumentError for empty pattern', () {
      expect(
        () => service.isAllowed('read', ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for whitespace-only pattern', () {
      expect(
        () => service.isAllowed('read', '   '),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('PermissionService.ask', () {
    test('completes immediately when rule allows', () async {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );

      final req = const PermissionRequest(
        id: 'test-1',
        toolName: 'read',
        permission: 'read',
        patterns: ['/some/file.txt'],
      );

      // Should complete without throwing
      await service.ask(req, ruleset);
    });

    test('throws PermissionDeniedError when rule denies', () async {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );

      final req = const PermissionRequest(
        id: 'test-deny',
        toolName: 'shell',
        permission: 'shell',
        patterns: ['rm -rf /'],
      );

      expect(
        () => service.ask(req, ruleset),
        throwsA(isA<PermissionDeniedError>()),
      );
    });

    test('emits request on stream when rule asks', () async {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'edit',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );

      final req = const PermissionRequest(
        id: 'test-ask',
        toolName: 'edit',
        permission: 'edit',
        patterns: ['/some/file.txt'],
      );

      // Listen for the emitted request
      final emitted = <PermissionRequest>[];
      service.onAsked.listen(emitted.add);

      // Start ask (will block waiting for user response)
      final askFuture = service.ask(req, ruleset);

      // Give the stream time to emit
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted, hasLength(1));
      expect(emitted.first.id, equals('test-ask'));
      expect(emitted.first.toolName, equals('edit'));

      // Resolve the pending request
      service.reply('test-ask', PermissionReply.once);

      await askFuture;
    });

    test('reject throws PermissionRejectedError', () async {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'write',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );

      final req = const PermissionRequest(
        id: 'test-reject',
        toolName: 'write',
        permission: 'write',
        patterns: ['/some/file.txt'],
      );

      final askFuture = service.ask(req, ruleset);

      // Give the stream time to register
      await Future<void>.delayed(const Duration(milliseconds: 10));

      service.reply('test-reject', PermissionReply.reject);

      expect(() => askFuture, throwsA(isA<PermissionRejectedError>()));
    });

    test('always reply adds approved rules', () async {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'write',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );

      final req = const PermissionRequest(
        id: 'test-always',
        toolName: 'write',
        permission: 'write',
        patterns: ['/some/file.txt'],
        always: ['/some/file.txt'],
      );

      final askFuture = service.ask(req, ruleset);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      service.reply('test-always', PermissionReply.always);

      await askFuture;

      // After "always", the approved rules should contain the pattern
      expect(
        service.approvedRules.any(
          (r) =>
              r.permission == 'write' &&
              r.pattern == '/some/file.txt' &&
              r.action == PermissionAction.allow,
        ),
        isTrue,
      );
    });
  });

  group('PermissionService rate limiting', () {
    test('rate limits after 10 asks within 5 minutes', () async {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );

      // Make 10 asks (each will be pending)
      final futures = <Future<void>>[];
      for (var i = 0; i < 10; i++) {
        final req = PermissionRequest(
          id: 'rate-$i',
          toolName: 'shell',
          permission: 'shell',
          patterns: ['cmd-$i'],
        );
        futures.add(service.ask(req, ruleset));
      }

      // Give time for all to register
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // The 11th ask should be rate-limited (throws PermissionDeniedError)
      final req11 = const PermissionRequest(
        id: 'rate-10',
        toolName: 'shell',
        permission: 'shell',
        patterns: ['cmd-10'],
      );

      expect(
        () => service.ask(req11, ruleset),
        throwsA(isA<PermissionDeniedError>()),
      );

      // Clean up pending requests
      for (var i = 0; i < 10; i++) {
        service.reply('rate-$i', PermissionReply.once);
      }
      await Future.wait(futures);
    });

    test('clearRateLimitHistory resets rate limit', () async {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );

      // Make 10 asks
      final futures = <Future<void>>[];
      for (var i = 0; i < 10; i++) {
        final req = PermissionRequest(
          id: 'reset-$i',
          toolName: 'shell',
          permission: 'shell',
          patterns: ['cmd-$i'],
        );
        futures.add(service.ask(req, ruleset));
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Clear rate limit
      service.clearRateLimitHistory();

      // Now a new ask should work (not rate limited)
      final reqNew = const PermissionRequest(
        id: 'reset-new',
        toolName: 'shell',
        permission: 'shell',
        patterns: ['cmd-new'],
      );

      // This should NOT throw PermissionDeniedError
      // (it will be pending, which is fine)
      final newFuture = service.ask(reqNew, ruleset);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Resolve all
      for (var i = 0; i < 10; i++) {
        service.reply('reset-$i', PermissionReply.once);
      }
      service.reply('reset-new', PermissionReply.once);

      await Future.wait([...futures, newFuture]);
    });
  });

  group('PermissionService.cancelAllPendingRequests', () {
    test('cancels all pending requests', () async {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'edit',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );

      final futures = <Future<void>>[];
      for (var i = 0; i < 3; i++) {
        final req = PermissionRequest(
          id: 'cancel-$i',
          toolName: 'edit',
          permission: 'edit',
          patterns: ['file-$i'],
        );
        futures.add(service.ask(req, ruleset));
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));

      service.cancelAllPendingRequests();

      // All futures should complete with error
      for (final f in futures) {
        expect(() => f, throwsA(isA<PermissionRejectedError>()));
      }
    });

    test('clears rate-limit history on cancel', () async {
      final ruleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'shell',
            pattern: '*',
            action: PermissionAction.ask,
          ),
        ],
      );

      // Make some asks to populate rate limit
      final futures = <Future<void>>[];
      for (var i = 0; i < 5; i++) {
        final req = PermissionRequest(
          id: 'clear-$i',
          toolName: 'shell',
          permission: 'shell',
          patterns: ['cmd-$i'],
        );
        futures.add(service.ask(req, ruleset));
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));

      service.cancelAllPendingRequests();

      // Wait for pending futures to complete with errors
      for (final f in futures) {
        try {
          await f;
        } on PermissionRejectedError {
          // Expected
        }
      }

      // Rate limit history should be cleared
      // (we can't directly verify, but we can check that new asks work)
      final reqNew = const PermissionRequest(
        id: 'clear-new',
        toolName: 'shell',
        permission: 'shell',
        patterns: ['cmd-new'],
      );

      // This should not be rate limited (it will be pending)
      final newFuture = service.ask(reqNew, ruleset);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      service.reply('clear-new', PermissionReply.once);
      await newFuture;
    });
  });

  group('PermissionService.attachPreferences', () {
    test('session-scoped: does not load any rules', () async {
      SharedPreferences.setMockInitialValues({
        'permission_approved_rules': ['read|*.txt|allow', 'shell|git *|allow'],
      });

      final prefs = await SharedPreferences.getInstance();
      service.attachPreferences(prefs);

      expect(service.approvedRules, isEmpty);
    });
  });
}
