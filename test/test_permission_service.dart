import 'dart:async';
import 'package:test/test.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';

void main() {
  group('PermissionService', () {
    late PermissionService service;
    late PermissionRuleset ruleset;

    setUp(() {
      service = PermissionService();
      ruleset = PermissionRuleset.defaults();
    });

    test('allow auto-passes', () async {
      final req = PermissionRequest(
        id: 'req-1',
        toolName: 'read',
        permission: 'read',
        patterns: ['*.dart'],
        metadata: {'sessionId': 's1'},
      );
      // read is allow by default
      await service.ask(req, ruleset);
    });

    test('ask blocks until reply', () async {
      final req = PermissionRequest(
        id: 'req-2',
        toolName: 'bash',
        permission: 'bash',
        patterns: ['git *'],
        metadata: {'sessionId': 's1'},
      );

      // Start ask in background (it will block)
      final future = service.ask(req, ruleset);

      // Give it a tick to ensure it's blocking on the completer
      await Future.delayed(Duration.zero);

      // Reply once
      service.reply('req-2', PermissionReply.once);

      await future;
    });

    test(
      'once grant is not blocked by rate-limit on a different pattern',
      () async {
        // Regression: after replying "once", a follow-up ask for the same
        // permission but a DIFFERENT pattern (e.g. two distinct bash commands)
        // must not be rate-limited into a PermissionDeniedError, and must not
        // require a second reply. See logs: "RATE-LIMITED for bash:bash".
        final req1 = PermissionRequest(
          id: 'req-once-1',
          toolName: 'bash',
          permission: 'bash',
          patterns: ['git status'],
          metadata: {'sessionId': 's1'},
        );
        final f1 = service.ask(req1, ruleset);
        await Future.delayed(Duration.zero);
        service.reply('req-once-1', PermissionReply.once);
        await f1;

        final req2 = PermissionRequest(
          id: 'req-once-2',
          toolName: 'bash',
          permission: 'bash',
          patterns: ['ls -la'],
          metadata: {'sessionId': 's1'},
        );
        // Must complete without throwing and without requiring another reply.
        await service.ask(req2, ruleset);
      },
    );

    test('deny throws immediately', () async {
      final denyRuleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: 'rm -rf *',
            action: PermissionAction.deny,
          ),
        ],
      );
      final req = PermissionRequest(
        id: 'req-3',
        toolName: 'bash',
        permission: 'bash',
        patterns: ['rm -rf /'],
        metadata: {'sessionId': 's1'},
      );

      expect(
        () => service.ask(req, denyRuleset),
        throwsA(isA<PermissionDeniedError>()),
      );
    });

    test('always promotes to sessionApproved', () async {
      final req = PermissionRequest(
        id: 'req-4',
        toolName: 'edit',
        permission: 'edit',
        patterns: ['lib/*.dart'],
        metadata: {'sessionId': 's1'},
      );

      // Start ask in background (it will block because edit is ask by default)
      final future = service.ask(req, ruleset);

      // Give it a tick to ensure it's blocking
      await Future.delayed(Duration.zero);

      // Reply with always
      service.reply('req-4', PermissionReply.always);

      await future;

      // After "always", subsequent requests for same pattern should auto-approve
      final req2 = PermissionRequest(
        id: 'req-5',
        toolName: 'edit',
        permission: 'edit',
        patterns: ['lib/*.dart'],
        metadata: {'sessionId': 's1'},
      );
      await service.ask(req2, ruleset);
    });

    test('reject throws PermissionRejectedError', () async {
      final req = PermissionRequest(
        id: 'req-6',
        toolName: 'bash',
        permission: 'bash',
        patterns: ['npm run *'],
        metadata: {'sessionId': 's1'},
      );

      final future = service.ask(req, ruleset);
      service.reply('req-6', PermissionReply.reject);

      expect(future, throwsA(isA<PermissionRejectedError>()));
    });

    test('reject cascades to session siblings', () async {
      final req1 = PermissionRequest(
        id: 'req-7',
        toolName: 'bash',
        permission: 'bash',
        patterns: ['git *'],
        metadata: {'sessionId': 's1'},
      );
      final req2 = PermissionRequest(
        id: 'req-8',
        toolName: 'bash',
        permission: 'bash',
        patterns: ['npm *'],
        metadata: {'sessionId': 's1'},
      );

      final future1 = service.ask(req1, ruleset);
      final future2 = service.ask(req2, ruleset);

      // Reject one — both should be rejected
      service.reply('req-7', PermissionReply.reject);

      expect(future1, throwsA(isA<PermissionRejectedError>()));
      expect(future2, throwsA(isA<PermissionRejectedError>()));
    });

    test(
      'always cascades to session siblings when always covers all',
      () async {
        final req1 = PermissionRequest(
          id: 'req-11',
          toolName: 'bash',
          permission: 'bash',
          patterns: ['git *'],
          always: ['*'],
          metadata: {'sessionId': 's2'},
        );
        final req2 = PermissionRequest(
          id: 'req-12',
          toolName: 'bash',
          permission: 'bash',
          patterns: ['npm *'],
          metadata: {'sessionId': 's2'},
        );

        final future1 = service.ask(req1, ruleset);
        final future2 = service.ask(req2, ruleset);

        await Future.delayed(Duration.zero);

        // Reply with always using wildcard — should resolve both
        service.reply('req-11', PermissionReply.always);

        await expectLater(future1, completes);
        await expectLater(future2, completes);
      },
    );

    test(
      'always with wildcard cascade resolves all pending in session',
      () async {
        final req1 = PermissionRequest(
          id: 'req-15',
          toolName: 'bash',
          permission: 'bash',
          patterns: ['ls'],
          always: ['*'],
          metadata: {'sessionId': 's4'},
        );
        final req2 = PermissionRequest(
          id: 'req-16',
          toolName: 'bash',
          permission: 'bash',
          patterns: ['cat *'],
          metadata: {'sessionId': 's4'},
        );
        final req3 = PermissionRequest(
          id: 'req-17',
          toolName: 'bash',
          permission: 'bash',
          patterns: ['echo *'],
          metadata: {'sessionId': 's4'},
        );

        final f1 = service.ask(req1, ruleset);
        final f2 = service.ask(req2, ruleset);
        final f3 = service.ask(req3, ruleset);

        await Future.delayed(Duration.zero);

        service.reply('req-15', PermissionReply.always);

        await expectLater(f1, completes);
        await expectLater(f2, completes);
        await expectLater(f3, completes);
      },
    );

    test('cancelAllPendingRequests clears all', () async {
      final req1 = PermissionRequest(
        id: 'req-9',
        toolName: 'bash',
        permission: 'bash',
        patterns: ['cmd1'],
        metadata: {'sessionId': 's1'},
      );
      final req2 = PermissionRequest(
        id: 'req-10',
        toolName: 'bash',
        permission: 'bash',
        patterns: ['cmd2'],
        metadata: {'sessionId': 's1'},
      );

      final future1 = service.ask(req1, ruleset);
      final future2 = service.ask(req2, ruleset);

      service.cancelAllPendingRequests();

      expect(future1, throwsA(isA<PermissionRejectedError>()));
      expect(future2, throwsA(isA<PermissionRejectedError>()));
    });

    test('session gate blocks execute until reply', () async {
      // No gate open initially → returns immediately.
      await expectLater(service.waitWhilePaused('gate-session'), completes);

      final req = PermissionRequest(
        id: 'gate-req',
        toolName: 'custom_tool',
        permission: 'custom_tool',
        patterns: ['cmd-gate'],
        metadata: {'sessionId': 'gate-session'},
      );

      final askFuture = service.ask(req, ruleset);
      // Let the dialog be emitted and the session paused.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // A concurrent execute for the same session must be blocked by the gate.
      var gateReleased = false;
      final blocked = service.waitWhilePaused('gate-session').then((_) {
        gateReleased = true;
      });

      // Gate is still held (dialog open) — not yet released.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(gateReleased, isFalse);

      // User answers → gate resumes, blocked execute proceeds, ask resolves.
      service.reply('gate-req', PermissionReply.once);
      await expectLater(blocked, completes);
      await expectLater(askFuture, completes);
      expect(gateReleased, isTrue);
    });

    test('session gate is isolated per session', () async {
      final req = PermissionRequest(
        id: 'gate-req-2',
        toolName: 'custom_tool',
        permission: 'custom_tool',
        patterns: ['cmd-gate-2'],
        metadata: {'sessionId': 'session-A'},
      );
      final askFuture = service.ask(req, ruleset);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // A different session is NOT blocked while session-A dialog is open.
      await expectLater(service.waitWhilePaused('session-B'), completes);

      service.reply('gate-req-2', PermissionReply.once);
      await expectLater(askFuture, completes);
    });
  });
}
