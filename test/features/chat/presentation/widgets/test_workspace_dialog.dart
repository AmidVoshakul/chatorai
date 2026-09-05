import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:chatorai/core/session/session_db_provider.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/gui/features/chat/data/providers/chat_screen_notifier.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/workspace_dialog.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/gui/features/sessions/providers/session_providers.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/gui/shared/workspace/workspace_provider.dart';
import 'package:chatorai/core/workspace/workspace_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StreamingChatScreenNotifier extends ChatScreenNotifier {
  @override
  ChatScreenState build() {
    final state = super.build();
    return state.copyWith(
      isStreaming: true,
      streamingSessionId: 'test-session',
    );
  }
}

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  group('showWorkspaceDialog', () {
    late Directory originalCwd;

    setUpAll(() {
      registerFallbackValue(SessionID.create());
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      originalCwd = Directory.current;
    });

    tearDown(() async {
      workspaceRuntimeCurrent = originalCwd;
    });

    Widget _buildTestApp({required Widget child}) {
      return ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () async {
                    await showWorkspaceDialog(context, ref);
                  },
                  child: child,
                );
              },
            ),
          ),
        ),
      );
    }

    Widget _buildTestAppWithSessionOverride({required Widget child}) {
      return ProviderScope(
        overrides: [
          sessionsByDirectoryProvider.overrideWith(
            (ref, directory) async => [],
          ),
        ],
        child: _buildTestApp(child: child),
      );
    }

    testWidgets(
      'renders directory title, search field, add-directory row visible',
      (tester) async {
        await tester.pumpWidget(
          _buildTestAppWithSessionOverride(child: const Text('open')),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Directory'), findsOneWidget);
        expect(find.text('Search directories'), findsOneWidget);
        expect(find.text('Add directory'), findsOneWidget);
      },
    );

    testWidgets('search filters by basename substring (case-insensitive)', (
      tester,
    ) async {
      final tempDir = Directory.systemTemp.createTempSync('ws_search_test_');

      await tester.pumpWidget(
        _buildTestAppWithSessionOverride(child: const Text('open')),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      final notifier = container.read(workspaceProvider.notifier);
      await notifier.init();
      await notifier.addDirectory(tempDir.path);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final basename = p.basename(tempDir.path);
      await tester.enterText(
        find.byType(TextField).first,
        basename.substring(0, 4),
      );
      await tester.pumpAndSettle();

      expect(find.text(basename), findsOneWidget);
      expect(find.text('No directories found'), findsNothing);

      tempDir.deleteSync(recursive: true);
    });

    testWidgets('search filters by full-path substring', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('ws_path_search_');

      await tester.pumpWidget(
        _buildTestAppWithSessionOverride(child: const Text('open')),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      final notifier = container.read(workspaceProvider.notifier);
      await notifier.init();
      await notifier.addDirectory(tempDir.path);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final pathPart = tempDir.path.substring(0, 10);
      await tester.enterText(find.byType(TextField).first, pathPart);
      await tester.pumpAndSettle();

      expect(find.text(p.basename(tempDir.path)), findsOneWidget);
      expect(find.text('No directories found'), findsNothing);

      tempDir.deleteSync(recursive: true);
    });

    testWidgets('non-matching query shows noWorkspacesFound', (tester) async {
      await tester.pumpWidget(
        _buildTestAppWithSessionOverride(child: const Text('open')),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'zzzz_not_a_real_dir',
      );
      await tester.pumpAndSettle();

      expect(find.text('No directories found'), findsOneWidget);
    });

    testWidgets('active row shows orange folder icon and NO active label', (
      tester,
    ) async {
      final tempDir = Directory.systemTemp.createTempSync('ws_active_test_');

      await tester.pumpWidget(
        _buildTestAppWithSessionOverride(child: const Text('open')),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      final notifier = container.read(workspaceProvider.notifier);
      await notifier.init();
      await notifier.switchWorkspace(tempDir.path);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Active row shows orange folder icon.
      final folderIcons = find.byIcon(Icons.folder_outlined).evaluate();
      final orangeIcon = folderIcons.firstWhere(
        (element) => (element.widget as Icon).color == ChatoraiColors.orange,
      );
      expect(orangeIcon, isNotNull);

      // No check_circle or Active label.
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.text('Active'), findsNothing);

      tempDir.deleteSync(recursive: true);
    });

    testWidgets('delete removes non-active row from list', (tester) async {
      final keepDir = Directory.systemTemp.createTempSync('ws_keep_del_');
      final deleteDir = Directory.systemTemp.createTempSync('ws_delete_del_');

      await tester.pumpWidget(
        _buildTestAppWithSessionOverride(child: const Text('open')),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      final notifier = container.read(workspaceProvider.notifier);
      await notifier.init();
      await notifier.addDirectory(keepDir.path);
      await notifier.addDirectory(deleteDir.path);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(p.basename(deleteDir.path)), findsOneWidget);

      // The first delete icon belongs to keepDir; the second belongs to deleteDir.
      await tester.tap(find.byIcon(Icons.delete_outline).at(1));
      await tester.pumpAndSettle();

      expect(find.text(p.basename(deleteDir.path)), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      final persisted = prefs.getStringList('known_workspaces') ?? [];
      expect(persisted, isNot(contains(deleteDir.path)));

      keepDir.deleteSync(recursive: true);
      deleteDir.deleteSync(recursive: true);
    });

    testWidgets('auto-prune removes deleted dirs on open', (tester) async {
      final keepDir = Directory.systemTemp.createTempSync('ws_keep_prune_');
      final deleteDir = Directory.systemTemp.createTempSync('ws_delete_prune_');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('known_workspaces', [
        keepDir.path,
        deleteDir.path,
      ]);

      // Delete one dir before opening dialog.
      deleteDir.deleteSync(recursive: true);

      await tester.pumpWidget(
        _buildTestAppWithSessionOverride(child: const Text('open')),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(p.basename(keepDir.path)), findsOneWidget);
      expect(find.text(p.basename(deleteDir.path)), findsNothing);

      keepDir.deleteSync(recursive: true);
    });

    testWidgets('switching while NOT streaming: tap row pops with path', (
      tester,
    ) async {
      final tempDir = Directory.systemTemp.createTempSync('ws_switch_test_');

      await tester.pumpWidget(
        _buildTestAppWithSessionOverride(child: const Text('open')),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      final notifier = container.read(workspaceProvider.notifier);
      await notifier.init();
      await notifier.addDirectory(tempDir.path);

      String? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionsByDirectoryProvider.overrideWith(
              (ref, directory) async => [],
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () async {
                      result = await showWorkspaceDialog(context, ref);
                    },
                    child: const Text('open'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(p.basename(tempDir.path)));
      await tester.pumpAndSettle();

      expect(result, equals(tempDir.path));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_workspace'), equals(tempDir.path));
      expect(workspaceRuntimeCurrent.path, equals(tempDir.path));

      tempDir.deleteSync(recursive: true);
    });

    testWidgets(
      'switching while streaming: confirm sheet visible, Cancel keeps dialog open',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('ws_stream_test_');

        String? result;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              chatScreenProvider.overrideWith(
                () => _StreamingChatScreenNotifier(),
              ),
              sessionsByDirectoryProvider.overrideWith(
                (ref, directory) async => [],
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        // Initialize workspace and add directory before opening dialog.
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(tempDir.path);
                        result = await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(p.basename(tempDir.path)));
        await tester.pumpAndSettle();

        expect(find.text('Switch workspace'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should still be open.
        expect(find.text('Directory'), findsOneWidget);
        expect(result, isNull);

        // Tap again and confirm.
        await tester.tap(find.text(p.basename(tempDir.path)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(result, equals(tempDir.path));

        tempDir.deleteSync(recursive: true);
      },
    );

    testWidgets('add-directory row exists but is not tapped (FilePicker)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestAppWithSessionOverride(child: const Text('open')),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Add directory'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNWidgets(2));
    });

    group('wide layout', () {
      testWidgets('two columns present, left width 300, right column exists', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildTestAppWithSessionOverride(child: const Text('open')),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpAndSettle();

        // Left column is a SizedBox with width 300.
        final leftSizedBox = tester.widget<SizedBox>(
          find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.width == 300.0,
          ),
        );
        expect(leftSizedBox.width, equals(300.0));

        // Right column has session search field and sessions header.
        expect(find.text('Sessions'), findsOneWidget);
        expect(find.text('Search sessions'), findsOneWidget);
      });
    });

    group('sessions right column', () {
      late MockSessionRepository mockRepo;
      late Directory dirA;
      late Directory dirB;

      setUp(() {
        mockRepo = MockSessionRepository();
        dirA = Directory.systemTemp.createTempSync('ws_sess_a_');
        dirB = Directory.systemTemp.createTempSync('ws_sess_b_');
      });

      tearDown(() {
        dirA.deleteSync(recursive: true);
        dirB.deleteSync(recursive: true);
      });

      testWidgets('wide surface shows right column with sessions header', (
        tester,
      ) async {
        when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'A1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.addDirectory(dirB.path);
                        await notifier.switchWorkspace(dirA.path);
                        await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Force wide layout.
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Sessions'), findsOneWidget);
        expect(find.text('(1)'), findsOneWidget);
        expect(find.text('A1'), findsOneWidget);
      });

      testWidgets('directory tap pops dialog with selected path', (
        tester,
      ) async {
        when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'A1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            ),
          ],
        );
        when(() => mockRepo.findSessionsByDirectory(dirB.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_b1'),
              title: 'B1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirB.path,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.addDirectory(dirB.path);
                        await notifier.switchWorkspace(dirA.path);
                        final result = await showWorkspaceDialog(context, ref);
                        expect(result, equals(dirB.path));
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(p.basename(dirB.path)));
        await tester.pumpAndSettle();
      });

      testWidgets('tap session row sets currentChatId and pops dialog', (
        tester,
      ) async {
        when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'A1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.switchWorkspace(dirA.path);
                        await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold)),
        );
        expect(container.read(currentChatIdProvider), equals('ses_a1'));
      });

      testWidgets('empty sessions shows noSessions text', (tester) async {
        when(
          () => mockRepo.findSessionsByDirectory(dirA.path),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.switchWorkspace(dirA.path);
                        await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('No sessions yet'), findsOneWidget);
      });

      testWidgets('narrow width shows stacked layout with sessions below', (
        tester,
      ) async {
        when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'A1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.switchWorkspace(dirA.path);
                        await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('A1'), findsOneWidget);
        expect(find.text('Sessions'), findsOneWidget);
      });

      testWidgets('directory search filters left list only', (tester) async {
        when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'A1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.addDirectory(dirB.path);
                        await notifier.switchWorkspace(dirA.path);
                        await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Type in the first TextField (directory search).
        await tester.enterText(
          find.byType(TextField).first,
          p.basename(dirB.path),
        );
        await tester.pumpAndSettle();

        // dirB should be visible in directory list (text appears in row + textfield).
        expect(find.text(p.basename(dirB.path)), findsNWidgets(2));
        // Sessions from dirA should still be visible (search doesn't affect sessions).
        expect(find.text('A1'), findsOneWidget);
      });

      testWidgets('sessions search filters right list only', (tester) async {
        when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'Alpha',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            ),
            SessionState(
              id: SessionID.fromString('ses_a2'),
              title: 'Beta',
              agent: 'general',
              createdAt: DateTime(2025, 1, 2),
              updatedAt: DateTime(2025, 1, 2),
              directory: dirA.path,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.switchWorkspace(dirA.path);
                        await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Type in the second TextField (session search).
        await tester.enterText(find.byType(TextField).at(1), 'Alpha');
        await tester.pumpAndSettle();

        // "Alpha" appears in both the TextField and the session row.
        expect(find.text('Alpha'), findsNWidgets(2));
        expect(find.text('Beta'), findsNothing);
      });

      testWidgets('delete session: confirm removes row, cancel keeps row', (
        tester,
      ) async {
        final deleted = <SessionID>[];
        when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'A1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            ),
          ].where((s) => !deleted.contains(s.id)).toList(),
        );
        when(() => mockRepo.deleteSession(any())).thenAnswer((
          invocation,
        ) async {
          deleted.add(invocation.positionalArguments[0] as SessionID);
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.switchWorkspace(dirA.path);
                        await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Tap delete icon (session row is the second delete_outline icon).
        await tester.tap(find.byIcon(Icons.delete_outline).at(1));
        await tester.pumpAndSettle();

        // Premium confirm sheet shown.
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Cancel.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Row still present.
        expect(find.text('A1'), findsOneWidget);

        // Tap delete again and confirm.
        await tester.tap(find.byIcon(Icons.delete_outline).at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Row removed.
        expect(find.text('A1'), findsNothing);
        verify(() => mockRepo.deleteSession(any())).called(1);
      });

      testWidgets('deleting current session nulls currentChatId', (
        tester,
      ) async {
        when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'A1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            ),
          ],
        );
        when(() => mockRepo.deleteSession(any())).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.switchWorkspace(dirA.path);
                        await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Set current chat id to the session we're about to delete.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold)),
        );
        container.read(currentChatIdProvider.notifier).setChatId('ses_a1');
        expect(container.read(currentChatIdProvider), equals('ses_a1'));

        // Tap delete icon (session row is the second delete_outline icon).
        await tester.tap(find.byIcon(Icons.delete_outline).at(1));
        await tester.pumpAndSettle();

        // Confirm delete.
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(container.read(currentChatIdProvider), isNull);
      });

      testWidgets(
        'new session creates via chatListProvider and pops with target',
        (tester) async {
          SessionID? createdSessionId;
          when(
            () => mockRepo.cleanupOrphanSessions(),
          ).thenAnswer((_) async => 0);
          when(
            () => mockRepo.findAll(),
          ).thenAnswer((_) async => <SessionState>[]);
          when(
            () => mockRepo.createSession(
              title: any(named: 'title'),
              agent: any(named: 'agent'),
              directory: any(named: 'directory'),
            ),
          ).thenAnswer((invocation) async {
            final directory =
                invocation.namedArguments[#directory] as String? ?? '';
            final session = SessionState(
              id: SessionID.create(),
              title: '',
              agent: 'general',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              directory: directory,
            );
            createdSessionId = session.id;
            return session;
          });

          // Switch to dirB before opening dialog so it's pre-selected.
          String? result;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sessionRepositoryProvider.overrideWith((_) async => mockRepo),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton(
                        onPressed: () async {
                          final container = ProviderScope.containerOf(context);
                          final notifier = container.read(
                            workspaceProvider.notifier,
                          );
                          await notifier.init();
                          await notifier.addDirectory(dirA.path);
                          await notifier.addDirectory(dirB.path);
                          await notifier.switchWorkspace(dirB.path);
                          result = await showWorkspaceDialog(context, ref);
                        },
                        child: const Text('open'),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          tester.view.physicalSize = const Size(1200, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();

          // Tap new session.
          await tester.tap(find.text('New session'));
          await tester.pumpAndSettle();

          // Verify createSession was called with dirB.
          verify(
            () => mockRepo.createSession(
              title: '',
              agent: 'general',
              directory: dirB.path,
            ),
          ).called(1);

          // Verify the new chat is registered in chatListProvider.state.
          final container = ProviderScope.containerOf(
            tester.element(find.byType(Scaffold)),
          );
          final chats = container.read(chatListProvider).value;
          expect(chats, isNotNull);
          expect(chats!.length, equals(1));
          expect(chats.first.id, equals(createdSessionId!.value));

          // Dialog should have popped with dirB.
          expect(result, equals(dirB.path));
        },
      );

      testWidgets(
        'new session confirm-cancel: NO session created and NO switch',
        (tester) async {
          SessionID? createdSessionId;
          when(
            () => mockRepo.cleanupOrphanSessions(),
          ).thenAnswer((_) async => 0);
          when(
            () => mockRepo.findAll(),
          ).thenAnswer((_) async => <SessionState>[]);
          when(
            () => mockRepo.createSession(
              title: any(named: 'title'),
              agent: any(named: 'agent'),
              directory: any(named: 'directory'),
            ),
          ).thenAnswer((invocation) async {
            final directory =
                invocation.namedArguments[#directory] as String? ?? '';
            final session = SessionState(
              id: SessionID.create(),
              title: '',
              agent: 'general',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              directory: directory,
            );
            createdSessionId = session.id;
            return session;
          });

          String? result;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                chatScreenProvider.overrideWith(
                  () => _StreamingChatScreenNotifier(),
                ),
                sessionRepositoryProvider.overrideWith((_) async => mockRepo),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton(
                        onPressed: () async {
                          final container = ProviderScope.containerOf(context);
                          final notifier = container.read(
                            workspaceProvider.notifier,
                          );
                          await notifier.init();
                          await notifier.addDirectory(dirA.path);
                          await notifier.addDirectory(dirB.path);
                          await notifier.switchWorkspace(dirA.path);
                          result = await showWorkspaceDialog(context, ref);
                        },
                        child: const Text('open'),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          tester.view.physicalSize = const Size(1200, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();

          // Select dirB (non-current) while streaming: confirm sheet appears.
          await tester.tap(find.text(p.basename(dirB.path)));
          await tester.pumpAndSettle();
          expect(find.text('Switch workspace'), findsOneWidget);

          // Cancel the directory switch — dialog stays open with dirB selected.
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(find.text('Directory'), findsOneWidget);

          // Tap new session.
          await tester.tap(find.text('New session'));
          await tester.pumpAndSettle();

          // Confirm sheet should be visible for the new-session switch.
          expect(find.text('Switch workspace'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);

          // Tap Cancel.
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();

          // Dialog should still be open.
          expect(find.text('Directory'), findsOneWidget);
          expect(result, isNull);

          // Verify no session was created.
          verifyNever(
            () => mockRepo.createSession(
              title: any(named: 'title'),
              agent: any(named: 'agent'),
              directory: any(named: 'directory'),
            ),
          );
        },
      );

      testWidgets(
        'new session target == current: no switch, chat created, pop',
        (tester) async {
          SessionID? createdSessionId;
          when(
            () => mockRepo.cleanupOrphanSessions(),
          ).thenAnswer((_) async => 0);
          when(
            () => mockRepo.findAll(),
          ).thenAnswer((_) async => <SessionState>[]);
          when(
            () => mockRepo.createSession(
              title: any(named: 'title'),
              agent: any(named: 'agent'),
              directory: any(named: 'directory'),
            ),
          ).thenAnswer((invocation) async {
            final directory =
                invocation.namedArguments[#directory] as String? ?? '';
            final session = SessionState(
              id: SessionID.create(),
              title: '',
              agent: 'general',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              directory: directory,
            );
            createdSessionId = session.id;
            return session;
          });

          String? result;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sessionRepositoryProvider.overrideWith((_) async => mockRepo),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton(
                        onPressed: () async {
                          final container = ProviderScope.containerOf(context);
                          final notifier = container.read(
                            workspaceProvider.notifier,
                          );
                          await notifier.init();
                          await notifier.addDirectory(dirA.path);
                          await notifier.switchWorkspace(dirA.path);
                          result = await showWorkspaceDialog(context, ref);
                        },
                        child: const Text('open'),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          tester.view.physicalSize = const Size(1200, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();

          // Tap new session (current == selected == dirA).
          await tester.tap(find.text('New session'));
          await tester.pumpAndSettle();

          // Verify createSession was called with dirA.
          verify(
            () => mockRepo.createSession(
              title: '',
              agent: 'general',
              directory: dirA.path,
            ),
          ).called(1);

          // Verify chatListProvider contains the new chat.
          final container = ProviderScope.containerOf(
            tester.element(find.byType(Scaffold)),
          );
          final chats = container.read(chatListProvider).value;
          expect(chats, isNotNull);
          expect(chats!.length, equals(1));
          expect(chats.first.id, equals(createdSessionId!.value));

          // Dialog should have popped with dirA.
          expect(result, equals(dirA.path));
        },
      );

      testWidgets('open session from non-current directory switches workspace', (
        tester,
      ) async {
        when(() => mockRepo.findSessionsByDirectory(dirB.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_b1'),
              title: 'B1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirB.path,
            ),
          ],
        );

        String? result;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              chatScreenProvider.overrideWith(
                () => _StreamingChatScreenNotifier(),
              ),
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.addDirectory(dirB.path);
                        await notifier.switchWorkspace(dirA.path);
                        result = await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Tap dirB row while streaming: confirm sheet appears, Cancel keeps dialog open
        // with _selectedDirectory = dirB but currentPath still = dirA.
        await tester.tap(find.text(p.basename(dirB.path)));
        await tester.pumpAndSettle();
        expect(find.text('Switch workspace'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Session column now shows sessions for dirB.
        await tester.pumpAndSettle();
        expect(find.text('B1'), findsOneWidget);

        // Tap session B1.
        await tester.tap(find.text('B1'));
        await tester.pumpAndSettle();

        // Streaming confirm for session switch should appear.
        expect(find.text('Switch workspace'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Verify workspace switched to dirB and chat id set.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold)),
        );
        expect(
          container.read(workspaceProvider).currentPath,
          equals(dirB.path),
        );
        expect(container.read(currentChatIdProvider), equals('ses_b1'));
        expect(result, equals(dirB.path));
      });

      testWidgets(
        'open session from current directory does not switch workspace',
        (tester) async {
          when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
            (_) async => [
              SessionState(
                id: SessionID.fromString('ses_a1'),
                title: 'A1',
                agent: 'general',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
                directory: dirA.path,
              ),
            ],
          );

          String? result;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sessionRepositoryProvider.overrideWith((_) async => mockRepo),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton(
                        onPressed: () async {
                          final container = ProviderScope.containerOf(context);
                          final notifier = container.read(
                            workspaceProvider.notifier,
                          );
                          await notifier.init();
                          await notifier.addDirectory(dirA.path);
                          await notifier.switchWorkspace(dirA.path);
                          result = await showWorkspaceDialog(context, ref);
                        },
                        child: const Text('open'),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          tester.view.physicalSize = const Size(1200, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();

          // Tap session A1 (current directory).
          await tester.tap(find.text('A1'));
          await tester.pumpAndSettle();

          // Verify workspace unchanged and chat id set.
          final container = ProviderScope.containerOf(
            tester.element(find.byType(Scaffold)),
          );
          expect(
            container.read(workspaceProvider).currentPath,
            equals(dirA.path),
          );
          expect(container.read(currentChatIdProvider), equals('ses_a1'));
          expect(result, equals(dirA.path));
        },
      );

      testWidgets(
        'delete session: confirm-cancel does not call deleteSession',
        (tester) async {
          when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
            (_) async => [
              SessionState(
                id: SessionID.fromString('ses_a1'),
                title: 'A1',
                agent: 'general',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
                directory: dirA.path,
              ),
            ],
          );
          when(() => mockRepo.deleteSession(any())).thenAnswer((_) async {});

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sessionRepositoryProvider.overrideWith((_) async => mockRepo),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton(
                        onPressed: () async {
                          final container = ProviderScope.containerOf(context);
                          final notifier = container.read(
                            workspaceProvider.notifier,
                          );
                          await notifier.init();
                          await notifier.addDirectory(dirA.path);
                          await notifier.switchWorkspace(dirA.path);
                          await showWorkspaceDialog(context, ref);
                        },
                        child: const Text('open'),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          tester.view.physicalSize = const Size(1200, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();

          // Tap delete icon.
          await tester.tap(find.byIcon(Icons.delete_outline).at(1));
          await tester.pumpAndSettle();

          // Tap Cancel.
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();

          // Verify deleteSession was NOT called.
          verifyNever(() => mockRepo.deleteSession(any()));
        },
      );

      testWidgets('no sessions empty state', (tester) async {
        when(
          () => mockRepo.findSessionsByDirectory(dirA.path),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.switchWorkspace(dirA.path);
                        await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('No sessions yet'), findsOneWidget);
      });

      testWidgets('narrow width shows stacked layout with sessions below', (
        tester,
      ) async {
        when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'A1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.switchWorkspace(dirA.path);
                        await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('A1'), findsOneWidget);
        expect(find.text('Sessions'), findsOneWidget);
      });

      testWidgets(
        'row tap switch clears foreign chat when session directory differs from target',
        (tester) async {
          when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
            (_) async => [
              SessionState(
                id: SessionID.fromString('ses_a1'),
                title: 'A1',
                agent: 'general',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
                directory: dirA.path,
              ),
            ],
          );
          when(() => mockRepo.findSessionsByDirectory(dirB.path)).thenAnswer(
            (_) async => [
              SessionState(
                id: SessionID.fromString('ses_b1'),
                title: 'B1',
                agent: 'general',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
                directory: dirB.path,
              ),
            ],
          );
          when(() => mockRepo.getSessionMetaFromId(any())).thenAnswer((
            inv,
          ) async {
            final id = inv.positionalArguments[0] as String;
            if (id == 'ses_a1') {
              return SessionState(
                id: SessionID.fromString('ses_a1'),
                title: 'A1',
                agent: 'general',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
                directory: dirA.path,
              );
            }
            if (id == 'ses_b1') {
              return SessionState(
                id: SessionID.fromString('ses_b1'),
                title: 'B1',
                agent: 'general',
                createdAt: DateTime(2025, 1, 1),
                updatedAt: DateTime(2025, 1, 1),
                directory: dirB.path,
              );
            }
            return null;
          });

          String? result;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sessionRepositoryProvider.overrideWith((_) async => mockRepo),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton(
                        onPressed: () async {
                          final container = ProviderScope.containerOf(context);
                          final notifier = container.read(
                            workspaceProvider.notifier,
                          );
                          await notifier.init();
                          await notifier.addDirectory(dirA.path);
                          await notifier.addDirectory(dirB.path);
                          await notifier.switchWorkspace(dirA.path);
                          // Set current chat to a session in dirA (foreign to dirB).
                          container
                              .read(currentChatIdProvider.notifier)
                              .setChatId('ses_a1');
                          result = await showWorkspaceDialog(context, ref);
                        },
                        child: const Text('open'),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          tester.view.physicalSize = const Size(1200, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();

          // Tap dirB row (not streaming → no confirm sheet).
          await tester.tap(find.text(p.basename(dirB.path)));
          await tester.pumpAndSettle();

          // Dialog should have popped with dirB and current chat cleared.
          final container = ProviderScope.containerOf(
            tester.element(find.byType(Scaffold)),
          );
          expect(result, equals(dirB.path));
          expect(container.read(currentChatIdProvider), isNull);
        },
      );

      testWidgets('row tap switch to same directory keeps current chat id', (
        tester,
      ) async {
        when(() => mockRepo.findSessionsByDirectory(dirA.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'A1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            ),
          ],
        );
        when(() => mockRepo.findSessionsByDirectory(dirB.path)).thenAnswer(
          (_) async => [
            SessionState(
              id: SessionID.fromString('ses_b1'),
              title: 'B1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirB.path,
            ),
          ],
        );
        when(() => mockRepo.getSessionMetaFromId(any())).thenAnswer((
          inv,
        ) async {
          final id = inv.positionalArguments[0] as String;
          if (id == 'ses_a1') {
            return SessionState(
              id: SessionID.fromString('ses_a1'),
              title: 'A1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirA.path,
            );
          }
          if (id == 'ses_b1') {
            return SessionState(
              id: SessionID.fromString('ses_b1'),
              title: 'B1',
              agent: 'general',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
              directory: dirB.path,
            );
          }
          return null;
        });

        String? result;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((_) async => mockRepo),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final notifier = container.read(
                          workspaceProvider.notifier,
                        );
                        await notifier.init();
                        await notifier.addDirectory(dirA.path);
                        await notifier.addDirectory(dirB.path);
                        await notifier.switchWorkspace(dirA.path);
                        // Set current chat to a session in dirB (same as target).
                        container
                            .read(currentChatIdProvider.notifier)
                            .setChatId('ses_b1');
                        result = await showWorkspaceDialog(context, ref);
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Tap dirB row (not streaming → no confirm sheet).
        await tester.tap(find.text(p.basename(dirB.path)));
        await tester.pumpAndSettle();

        // Dialog should have popped with dirB and current chat kept.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold)),
        );
        expect(result, equals(dirB.path));
        expect(container.read(currentChatIdProvider), equals('ses_b1'));
      });

      testWidgets(
        'barrier dismiss commits selected directory when different from current',
        (tester) async {
          final tempDir = Directory.systemTemp.createTempSync(
            'ws_barrier_test_',
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sessionsByDirectoryProvider.overrideWith(
                  (ref, directory) async => [],
                ),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton(
                        onPressed: () async {
                          final container = ProviderScope.containerOf(context);
                          final notifier = container.read(
                            workspaceProvider.notifier,
                          );
                          await notifier.init();
                          await notifier.addDirectory(tempDir.path);
                          await notifier.switchWorkspace(
                            Directory.current.path,
                          );
                          await showWorkspaceDialog(context, ref);
                        },
                        child: const Text('open'),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          tester.view.physicalSize = const Size(1200, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();

          // Tap dirB row to select it (but don't switch yet).
          await tester.tap(find.text(p.basename(tempDir.path)));
          await tester.pumpAndSettle();

          // Dismiss via barrier tap.
          await tester.tap(find.byType(ModalBarrier));
          await tester.pumpAndSettle();

          // Verify workspace switched to tempDir.
          final container = ProviderScope.containerOf(
            tester.element(find.byType(Scaffold)),
          );
          expect(
            container.read(workspaceProvider).currentPath,
            equals(tempDir.path),
          );
          expect(workspaceRuntimeCurrent.path, equals(tempDir.path));

          tempDir.deleteSync(recursive: true);
        },
      );
    });
  });
}
