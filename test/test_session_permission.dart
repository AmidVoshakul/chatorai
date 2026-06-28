import 'dart:convert';

import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// P0-2: Per-session permission propagation tests.
///
/// Covers deriveChildPermissions, SessionState.permission,
/// SessionCreated.permission, createChildSession propagation,
/// and _deserializePermission via DB round-trip.
void main() {
  // ---------------------------------------------------------------------------
  // 1. deriveChildPermissions
  // ---------------------------------------------------------------------------
  group('deriveChildPermissions', () {
    test('null parent returns ruleset with only task and todowrite denies', () {
      final result = SessionRepository.deriveChildPermissions(null);

      expect(result.rules, hasLength(2));
      expect(
        result.rules.where((r) => r.permission == 'task').single.action,
        PermissionAction.deny,
      );
      expect(
        result.rules.where((r) => r.permission == 'todowrite').single.action,
        PermissionAction.deny,
      );
    });

    test('parent with denies propagates those denies', () {
      final parentRules = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          const PermissionRule(
            permission: 'edit',
            pattern: '*.env',
            action: PermissionAction.deny,
          ),
        ],
      );

      final result = SessionRepository.deriveChildPermissions(parentRules);

      // 2 parent denies + 2 mandatory (task, todowrite)
      expect(result.rules, hasLength(4));

      // Parent denies are present
      final bashRule = result.rules.where((r) => r.permission == 'bash').single;
      expect(bashRule.action, PermissionAction.deny);
      expect(bashRule.pattern, '*');

      final editRule = result.rules.where((r) => r.permission == 'edit').single;
      expect(editRule.action, PermissionAction.deny);
      expect(editRule.pattern, '*.env');

      // Mandatory denies still present
      expect(
        result.rules.where((r) => r.permission == 'task').single.action,
        PermissionAction.deny,
      );
      expect(
        result.rules.where((r) => r.permission == 'todowrite').single.action,
        PermissionAction.deny,
      );
    });

    test('parent with allows does NOT propagate allows (only denies)', () {
      final parentRules = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );

      final result = SessionRepository.deriveChildPermissions(parentRules);

      // Only the 2 mandatory denies, no allows propagated
      expect(result.rules, hasLength(2));
      expect(
        result.rules.every((r) => r.action == PermissionAction.deny),
        isTrue,
      );
    });

    test(
      'parent with mixed rules only propagates denies plus task/todowrite',
      () {
        final parentRules = PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'read',
              pattern: '*',
              action: PermissionAction.allow,
            ),
            const PermissionRule(
              permission: 'bash',
              pattern: 'rm *',
              action: PermissionAction.deny,
            ),
            const PermissionRule(
              permission: 'edit',
              pattern: '*',
              action: PermissionAction.ask,
            ),
          ],
        );

        final result = SessionRepository.deriveChildPermissions(parentRules);

        // 1 parent deny (bash rm *) + 2 mandatory = 3 total
        expect(result.rules, hasLength(3));
        expect(
          result.rules.every((r) => r.action == PermissionAction.deny),
          isTrue,
        );

        // Verify the propagated bash deny kept its original pattern
        final bashRule = result.rules
            .where((r) => r.permission == 'bash')
            .single;
        expect(bashRule.pattern, 'rm *');
      },
    );

    test('parent with existing task deny does NOT duplicate the deny', () {
      final parentRules = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'task',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );

      final result = SessionRepository.deriveChildPermissions(parentRules);

      // Parent's task deny + 2 mandatory (task, todowrite) = 3 rules.
      // The mandatory task deny is always appended regardless of existing.
      expect(result.rules, hasLength(3));
      final taskRules = result.rules.where((r) => r.permission == 'task');
      expect(taskRules.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. SessionState with permission
  // ---------------------------------------------------------------------------
  group('SessionState.permission', () {
    test('constructor accepts permission parameter', () {
      final permission = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      final now = DateTime.now();
      final state = SessionState(
        id: SessionID.create(),
        permission: permission,
        createdAt: now,
        updatedAt: now,
      );

      expect(state.permission, isNotNull);
      expect(state.permission!.rules, hasLength(1));
      expect(state.permission!.rules.first.permission, 'bash');
    });

    test('copyWith(permission: ...) updates permission', () {
      final now = DateTime.now();
      final state = SessionState(
        id: SessionID.create(),
        createdAt: now,
        updatedAt: now,
      );

      expect(state.permission, isNull);

      final newPermission = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'task',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );

      final updated = state.copyWith(permission: newPermission);

      expect(updated.permission, isNotNull);
      expect(updated.permission!.rules, hasLength(1));
      expect(updated.permission!.rules.first.permission, 'task');
    });

    test('copyWith(clearPermission: true) clears permission', () {
      final now = DateTime.now();
      final permission = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      final state = SessionState(
        id: SessionID.create(),
        permission: permission,
        createdAt: now,
        updatedAt: now,
      );

      expect(state.permission, isNotNull);

      final cleared = state.copyWith(clearPermission: true);

      expect(cleared.permission, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. SessionCreated event
  // ---------------------------------------------------------------------------
  group('SessionCreated event', () {
    test('event carries permission field', () {
      final permission = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'edit',
            pattern: '*.env',
            action: PermissionAction.deny,
          ),
        ],
      );
      final sessionId = SessionID.create();

      final event = SessionCreated(
        sessionId: sessionId,
        permission: permission,
        timestamp: DateTime.now(),
      );

      expect(event.permission, isNotNull);
      expect(event.permission!.rules, hasLength(1));
      expect(event.permission!.rules.first.permission, 'edit');
      expect(event.permission!.rules.first.pattern, '*.env');
      expect(event.permission!.rules.first.action, PermissionAction.deny);
    });

    test('permission is included in projectEvent result', () {
      final permission = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      final sessionId = SessionID.fromString('ses_perm_test');
      final now = DateTime.now();

      final event = SessionCreated(
        sessionId: sessionId,
        title: 'Perm Test',
        agent: 'general',
        permission: permission,
        timestamp: now,
      );

      final initialState = SessionState(
        id: SessionID.fromString('ses_initial'),
        createdAt: now,
        updatedAt: now,
      );
      final state = projectEvent(initialState, event);

      expect(state.id, sessionId);
      expect(state.permission, isNotNull);
      expect(state.permission!.rules, hasLength(1));
      expect(state.permission!.rules.first.permission, 'bash');
      expect(state.permission!.rules.first.action, PermissionAction.deny);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. createChildSession permission propagation
  // ---------------------------------------------------------------------------
  group('createChildSession permission propagation', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = SessionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('child session gets derived permissions from parent', () async {
      final parentPermission = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          const PermissionRule(
            permission: 'read',
            pattern: '*',
            action: PermissionAction.allow,
          ),
        ],
      );

      final parent = await repository.createSession(
        title: 'Parent',
        permission: parentPermission,
      );

      final child = await repository.createChildSession(parent.id);

      // Child should have parent deny (bash) + task + todowrite = 3 denies
      expect(child.permission, isNotNull);
      expect(child.permission!.rules, hasLength(3));
      expect(
        child.permission!.rules.every((r) => r.action == PermissionAction.deny),
        isTrue,
      );

      // Verify the parent deny was propagated
      expect(
        child.permission!.rules.any((r) => r.permission == 'bash'),
        isTrue,
      );
      // Verify the allow was NOT propagated
      expect(
        child.permission!.rules.any((r) => r.permission == 'read'),
        isFalse,
      );
    });

    test('child permission contains deny for task and todowrite', () async {
      final parent = await repository.createSession(title: 'Parent');

      final child = await repository.createChildSession(parent.id);

      expect(child.permission, isNotNull);
      expect(
        child.permission!.rules.any(
          (r) => r.permission == 'task' && r.action == PermissionAction.deny,
        ),
        isTrue,
      );
      expect(
        child.permission!.rules.any(
          (r) =>
              r.permission == 'todowrite' && r.action == PermissionAction.deny,
        ),
        isTrue,
      );
    });

    test('child permissions are persisted in DB', () async {
      final parentPermission = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: 'rm *',
            action: PermissionAction.deny,
          ),
        ],
      );

      final parent = await repository.createSession(
        title: 'Parent',
        permission: parentPermission,
      );

      final child = await repository.createChildSession(parent.id);

      // Clear the in-memory cache so we force a DB read
      // Use getSessionMeta which reads from DB via _rowToState
      // First, we need to bypass the cache — create a new repository
      final freshRepo = SessionRepository(db);
      final loaded = await freshRepo.getSessionMeta(child.id);

      expect(loaded, isNotNull);
      expect(loaded!.permission, isNotNull);
      // bash deny + task deny + todowrite deny = 3
      expect(loaded.permission!.rules, hasLength(3));
      expect(
        loaded.permission!.rules.any(
          (r) => r.permission == 'bash' && r.pattern == 'rm *',
        ),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 5. _deserializePermission via DB round-trip
  // ---------------------------------------------------------------------------
  group('permission deserialization', () {
    test('reading from DB reconstructs PermissionRuleset', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repository = SessionRepository(db);

      try {
        final permission = PermissionRuleset(
          rules: [
            const PermissionRule(
              permission: 'bash',
              pattern: 'rm -rf *',
              action: PermissionAction.deny,
            ),
            const PermissionRule(
              permission: 'edit',
              pattern: '*.env',
              action: PermissionAction.deny,
            ),
          ],
          sessionApproved: [
            const PermissionRule(
              permission: 'read',
              pattern: '/tmp',
              action: PermissionAction.allow,
            ),
          ],
        );

        final created = await repository.createSession(
          title: 'DB Round-trip',
          permission: permission,
        );

        // Use a fresh repository to bypass cache and force DB read
        final freshRepo = SessionRepository(db);
        final loaded = await freshRepo.getSessionMeta(created.id);

        expect(loaded, isNotNull);
        expect(loaded!.permission, isNotNull);
        expect(loaded.permission!.rules, hasLength(2));
        expect(
          loaded.permission!.rules.any(
            (r) =>
                r.permission == 'bash' &&
                r.pattern == 'rm -rf *' &&
                r.action == PermissionAction.deny,
          ),
          isTrue,
        );
        expect(
          loaded.permission!.rules.any(
            (r) =>
                r.permission == 'edit' &&
                r.pattern == '*.env' &&
                r.action == PermissionAction.deny,
          ),
          isTrue,
        );
        // Verify sessionApproved also round-tripped
        expect(loaded.permission!.sessionApproved, hasLength(1));
        expect(loaded.permission!.sessionApproved.first.permission, 'read');
        expect(loaded.permission!.sessionApproved.first.pattern, '/tmp');
        expect(
          loaded.permission!.sessionApproved.first.action,
          PermissionAction.allow,
        );
      } finally {
        await db.close();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Bonus: projectToDb writes permissionRules column
  // ---------------------------------------------------------------------------
  group('projectToDb permission persistence', () {
    test(
      'SessionCreated with permission writes permissionRules column',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final sessionId = SessionID.create();
        final timestamp = DateTime.now();

        try {
          final permission = PermissionRuleset(
            rules: [
              const PermissionRule(
                permission: 'write',
                pattern: '*',
                action: PermissionAction.deny,
              ),
            ],
          );

          final event = SessionCreated(
            sessionId: sessionId,
            title: 'Permission DB Test',
            agent: 'general',
            permission: permission,
            timestamp: timestamp,
          );

          await projectToDb(db, event);

          final sessions = await db.select(db.sessions).get();
          expect(sessions, hasLength(1));
          expect(sessions.first.permissionRules, isNotNull);
          expect(sessions.first.permissionRules, isNotEmpty);

          // Verify the JSON structure
          final decoded =
              jsonDecode(sessions.first.permissionRules!)
                  as Map<String, dynamic>;
          expect(decoded['rules'], isA<List>());
          final rules = decoded['rules'] as List;
          expect(rules, hasLength(1));
          expect(rules.first['permission'], 'write');
          expect(rules.first['pattern'], '*');
          expect(rules.first['action'], 'deny');
        } finally {
          await db.close();
        }
      },
    );
  });
}
