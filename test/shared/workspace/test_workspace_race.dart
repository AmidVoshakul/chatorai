import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/config/models/permission_section.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/shared/utils/path_sandbox_provider.dart';
import 'package:chatorai/shared/workspace/workspace_provider.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  final WorkspaceState fakeState;

  _FakeWorkspaceNotifier(this.fakeState);

  @override
  WorkspaceState build() => fakeState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Workspace race conditions', () {
    test(
      'workspaceProvider switchWorkspace invalidates dependent providers',
      () async {
        final container = ProviderContainer(
          overrides: [
            workspaceProvider.overrideWith(
              () => _FakeWorkspaceNotifier(
                WorkspaceState(
                  currentPath: '/tmp/ws1',
                  knownDirectories: ['/tmp/ws1'],
                  initialized: true,
                ),
              ),
            ),
          ],
        );

        expect(container.read(workspaceProvider).currentPath, '/tmp/ws1');

        await Directory('/tmp/ws2').create(recursive: true);
        await container
            .read(workspaceProvider.notifier)
            .switchWorkspace('/tmp/ws2');
        expect(container.read(workspaceProvider).currentPath, '/tmp/ws2');
      },
    );

    test(
      'switchWorkspace does not throw CircularDependencyError for resolvedInstructionsProvider',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});

        // Use the REAL workspaceProvider (no override) so the cycle between
        // switchWorkspace's manual invalidate and resolvedInstructionsProvider
        // (which watches workspaceProvider) is reproduced.
        final container = ProviderContainer(
          overrides: [
            // configProvider does real disk I/O (loads chatorai.json); fake it.
            configProvider.overrideWith(
              (ref) async => ChatOrAIConfig(
                version: 0,
                permission: const <String, PermissionRuleConfig>{},
              ),
            ),
            // permissionServiceProvider builds a real storage; use the no-op one.
            permissionServiceProvider.overrideWith(
              (ref) => PermissionService(),
            ),
          ],
        );

        // Keep resolvedInstructionsProvider alive so it is rebuilt when the
        // workspace changes (it watches workspaceProvider). This is what makes
        // the manual invalidate inside switchWorkspace form a self-cycle.
        final sub = container.listen(
          resolvedInstructionsProvider,
          (prev, next) {},
        );

        final wsA = await Directory('/tmp/ws_a').create(recursive: true);
        final wsB = await Directory('/tmp/ws_b').create(recursive: true);

        // Switch to a real directory first so currentPath is valid.
        await container
            .read(workspaceProvider.notifier)
            .switchWorkspace(wsA.path);
        expect(container.read(workspaceProvider).currentPath, wsA.path);

        // This previously threw CircularDependencyError.
        await container
            .read(workspaceProvider.notifier)
            .switchWorkspace(wsB.path);
        expect(container.read(workspaceProvider).currentPath, wsB.path);

        sub.close();
      },
    );

    test('managedReadRootsProvider is available', () {
      final container = ProviderContainer(
        overrides: [
          workspaceProvider.overrideWith(
            () => _FakeWorkspaceNotifier(
              WorkspaceState(
                currentPath: '/tmp/ws1',
                knownDirectories: ['/tmp/ws1'],
                initialized: true,
              ),
            ),
          ),
        ],
      );

      final roots = container.read(managedReadRootsProvider);
      expect(roots, isA<Set<String>>());
      expect(roots, isNotEmpty);
    });

    test('PermissionService clears caches on workspace change', () async {
      final container = ProviderContainer(
        overrides: [
          workspaceProvider.overrideWith(
            () => _FakeWorkspaceNotifier(
              WorkspaceState(
                currentPath: '/tmp/ws1',
                knownDirectories: ['/tmp/ws1'],
                initialized: true,
              ),
            ),
          ),
        ],
      );

      final permService = container.read(permissionServiceProvider);

      final req = PermissionRequest(
        id: 'req-1',
        toolName: 'read',
        permission: 'read',
        patterns: ['/tmp/ws1/*'],
        always: ['/tmp/ws1/*'],
        metadata: {'sessionId': 'sess-1'},
      );

      final askFuture = permService.ask(req, PermissionRuleset());
      await permService.reply('req-1', PermissionReply.always);
      await askFuture;

      expect(permService.approvedRules, isNotEmpty);

      permService.onWorkspaceChanged();
      expect(permService.approvedRules, isEmpty);
    });
  });
}
