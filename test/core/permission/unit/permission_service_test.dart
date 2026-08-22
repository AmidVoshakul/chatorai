import 'package:test/test.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';

void main() {
  group('PermissionService.replaceDefaultRules', () {
    test('replaces default rules and affects isAllowed', () {
      final service = PermissionService();
      // Seed initial defaults (allow shell)
      service.replaceDefaultRules(
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'shell',
              pattern: '*',
              action: PermissionAction.allow,
            ),
          ],
        ),
      );
      expect(service.isAllowed('shell', 'ls'), isTrue);

      // Replace defaults with deny-all for shell
      service.replaceDefaultRules(
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'shell',
              pattern: '*',
              action: PermissionAction.deny,
            ),
          ],
        ),
      );

      expect(service.isAllowed('shell', 'ls'), isFalse);
    });

    test('preserves session-approved rules after replace', () {
      final service = PermissionService();
      service.replaceDefaultRules(
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'read',
              pattern: '*',
              action: PermissionAction.allow,
            ),
          ],
        ),
      );

      // replaceDefaultRules must not clear session-approved grants, and a later
      // live reload must update the effective defaults (reactivity).
      service.replaceDefaultRules(
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'read',
              pattern: '*',
              action: PermissionAction.deny,
            ),
          ],
        ),
      );

      // The default is now deny, but session approvals would still apply on top.
      // A subsequent live reload (replaceDefaultRules) must update the effective
      // defaults to allow.
      service.replaceDefaultRules(
        PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'read',
              pattern: '*',
              action: PermissionAction.allow,
            ),
          ],
        ),
      );
      expect(service.isAllowed('read', 'x'), isTrue);
    });

    test('does not throw on empty ruleset', () {
      final service = PermissionService();
      service.replaceDefaultRules(PermissionRuleset.defaults());
      expect(
        () => service.replaceDefaultRules(PermissionRuleset()),
        returnsNormally,
      );
    });
  });

  group('PermissionService.ask — security: no silent rate-limit auto-allow', () {
    test(
      'rate-limited asks still require the user dialog (no silent allow)',
      () async {
        final service = PermissionService();
        // No default rules => permission defaults to "ask".
        var emissions = 0;
        final sub = service.onAsked.listen((r) async {
          emissions++;
          // Grant "once" so the dialog resolves. Distinct patterns keep each
          // ask from being auto-approved by a prior "once" grant, so every ask
          // must reach the dialog independently.
          await service.reply(r.id, PermissionReply.once);
        });

        // Exceed the old rate-limit threshold (was 10). With the silent
        // auto-allow bug present, asks beyond the 10th would `return` without
        // emitting a request (emissions == 10). After the fix every ask must go
        // through the normal dialog path.
        for (var i = 0; i < 12; i++) {
          final req = PermissionRequest(
            id: 'rate-$i',
            toolName: 'bash',
            permission: 'shell',
            patterns: ['cmd-$i'],
            metadata: {'sessionId': 'sec-session'},
          );
          await service.ask(req, PermissionRuleset());
        }
        await sub.cancel();

        // All 12 asks went through the dialog — none were silently allowed.
        expect(emissions, equals(12));
      },
    );
  });

  group('PermissionService.ask — session change must not wipe grants', () {
    test('changing sessionId preserves _approved grants', () async {
      final service = PermissionService();
      var emissions = 0;
      final sub = service.onAsked.listen((r) async {
        emissions++;
        await service.reply(r.id, PermissionReply.always);
      });

      // First session grants an "always" approval.
      final req1 = PermissionRequest(
        id: 'grant-1',
        toolName: 'bash',
        permission: 'shell',
        patterns: ['ls'],
        always: ['ls'],
        metadata: {'sessionId': 'session-A'},
      );
      await service.ask(req1, PermissionRuleset());
      expect(service.approvedRules, isNotEmpty);

      // A different session asks the same thing — grants must persist, so the
      // request is auto-allowed and does NOT open a new dialog.
      final req2 = PermissionRequest(
        id: 'grant-2',
        toolName: 'bash',
        permission: 'shell',
        patterns: ['ls'],
        metadata: {'sessionId': 'session-B'},
      );
      await service.ask(req2, PermissionRuleset());

      await sub.cancel();

      // Grant survived the session switch: only one dialog was ever shown and
      // exactly one approval rule exists (no wipe-and-re-add, no duplicate).
      expect(emissions, equals(1));
      expect(service.approvedRules.length, equals(1));
      expect(service.isAllowed('shell', 'ls'), isTrue);
    });
  });
}
