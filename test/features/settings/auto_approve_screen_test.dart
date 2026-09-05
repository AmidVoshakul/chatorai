import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/gui/features/settings/providers/auto_approve_provider.dart';
import 'package:chatorai/gui/features/settings/screens/auto_approve_screen.dart';
import 'package:chatorai/l10n/app_localizations.dart';

class _FakeAutoApproveNotifier extends AutoApproveNotifier {
  final AutoApproveState fakeState;

  _FakeAutoApproveNotifier(this.fakeState);

  @override
  Future<AutoApproveState> build() async => fakeState;
}

AutoApproveState _buildFullState() {
  return AutoApproveState(
    categories: const [
      AutoApproveCategory(
        id: 'external_directory',
        label: 'External Directory',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: true,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'read',
        label: 'Read',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: true,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'edit',
        label: 'Edit',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: true,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'write',
        label: 'Write',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: true,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'glob',
        label: 'Glob',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: true,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'grep',
        label: 'Grep',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: true,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'shell',
        label: 'Shell',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: false,
        isShellCategory: true,
      ),
      AutoApproveCategory(
        id: 'webfetch',
        label: 'Web Fetch',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: false,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'websearch',
        label: 'Web Search',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: false,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'skill',
        label: 'Skill',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: false,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'lsp',
        label: 'LSP',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: false,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'task',
        label: 'Task',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: false,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'todowrite',
        label: 'Todo Write',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: false,
        isShellCategory: false,
      ),
      AutoApproveCategory(
        id: 'doom_loop',
        label: 'Doom Loop',
        description: '',
        defaultAction: null,
        exceptions: const {},
        isFileCategory: false,
        isShellCategory: false,
      ),
    ],
    supportsProjectScope: false,
    scope: AutoApproveScope.global,
  );
}

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    overrides: [
      autoApproveProvider.overrideWith(
        () => _FakeAutoApproveNotifier(_buildFullState()),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(textDirection: TextDirection.ltr, child: child),
    ),
  );
}

void main() {
  group('AutoApproveScreen', () {
    testWidgets('renders categories and dropdowns', (tester) async {
      final fakeState = AutoApproveState(
        categories: [
          AutoApproveCategory(
            id: 'shell',
            label: 'Shell',
            description: 'Allow shell command execution',
            defaultAction: null,
            exceptions: const {},
            isShellCategory: true,
          ),
          AutoApproveCategory(
            id: 'read',
            label: 'Read',
            description: 'Allow reading files',
            defaultAction: 'allow',
            exceptions: const {},
            isFileCategory: true,
          ),
        ],
        supportsProjectScope: false,
        scope: AutoApproveScope.global,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autoApproveProvider.overrideWith(
              () => _FakeAutoApproveNotifier(fakeState),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: AutoApproveScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Auto-Approve'), findsOneWidget);
      expect(find.text('Shell'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets(
      'scope toggle shows Global tab when project scope unsupported',
      (tester) async {
        final fakeState = AutoApproveState(
          categories: [
            AutoApproveCategory(
              id: 'shell',
              label: 'Shell',
              description: 'Allow shell command execution',
              defaultAction: null,
              exceptions: const {},
              isShellCategory: true,
            ),
          ],
          supportsProjectScope: false,
          scope: AutoApproveScope.global,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              autoApproveProvider.overrideWith(
                () => _FakeAutoApproveNotifier(fakeState),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                AppLocalizations.delegate,
              ],
              supportedLocales: [Locale('en')],
              home: AutoApproveScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Auto-Approve'), findsOneWidget);
        // Global tab should still be visible.
        expect(find.text('Global'), findsOneWidget);
        // Project tab should be present but disabled.
        expect(find.text('Project'), findsOneWidget);
      },
    );

    testWidgets(
      'project tab is disabled with tooltip when project scope unsupported',
      (tester) async {
        final fakeState = AutoApproveState(
          categories: const [
            AutoApproveCategory(
              id: 'read',
              label: 'Read',
              description: '',
              defaultAction: null,
              exceptions: const {},
              isFileCategory: true,
              isShellCategory: false,
            ),
          ],
          supportsProjectScope: false,
          scope: AutoApproveScope.global,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              autoApproveProvider.overrideWith(
                () => _FakeAutoApproveNotifier(fakeState),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                AppLocalizations.delegate,
              ],
              supportedLocales: [Locale('en')],
              home: AutoApproveScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // When project scope is unsupported, Global tab should be present and
        // Project tab should be present but disabled (with tooltip).
        expect(find.text('Global'), findsOneWidget);
        expect(find.text('Project'), findsOneWidget);
      },
    );

    testWidgets('scope toggle renders TabBar when project scope is supported', (
      tester,
    ) async {
      final fakeState = AutoApproveState(
        categories: const [
          AutoApproveCategory(
            id: 'read',
            label: 'Read',
            description: '',
            defaultAction: null,
            exceptions: const {},
            isFileCategory: true,
            isShellCategory: false,
          ),
        ],
        supportsProjectScope: true,
        scope: AutoApproveScope.global,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autoApproveProvider.overrideWith(
              () => _FakeAutoApproveNotifier(fakeState),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: AutoApproveScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Project'), findsOneWidget);
    });

    testWidgets('embedded mode renders without AppBar', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const AutoApproveScreen(embedded: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Auto-Approve'), findsNothing);
      expect(find.text('File Access'), findsOneWidget);
      expect(find.text('Shell & Commands'), findsOneWidget);
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Agents & Automation'), findsOneWidget);
    });

    testWidgets('categories are grouped into correct sections', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const AutoApproveScreen(embedded: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('File Access'), findsOneWidget);
      expect(find.text('Shell & Commands'), findsOneWidget);
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Agents & Automation'), findsOneWidget);

      // Verify shell category label is present (under Shell & Commands).
      expect(find.text('Shell'), findsOneWidget);
      // Verify read category label is present (under File Access).
      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('shell inherit dropdown shows Default (Ask)', (tester) async {
      final fakeState = AutoApproveState(
        categories: const [
          AutoApproveCategory(
            id: 'shell',
            label: 'Shell',
            description: '',
            defaultAction: null,
            exceptions: const {},
            isShellCategory: true,
            isFileCategory: false,
          ),
        ],
        supportsProjectScope: false,
        scope: AutoApproveScope.global,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autoApproveProvider.overrideWith(
              () => _FakeAutoApproveNotifier(fakeState),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: AutoApproveScreen(embedded: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The dropdown hint for shell (builtin ask) should show the dynamic inherit label.
      expect(find.text('Default (Ask)'), findsOneWidget);
    });

    testWidgets(
      'exceptions header is visible without expanding for file categories',
      (tester) async {
        final fakeState = AutoApproveState(
          categories: const [
            AutoApproveCategory(
              id: 'read',
              label: 'Read',
              description: 'Allow reading files',
              defaultAction: null,
              exceptions: const {},
              isFileCategory: true,
              isShellCategory: false,
            ),
          ],
          supportsProjectScope: false,
          scope: AutoApproveScope.global,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              autoApproveProvider.overrideWith(
                () => _FakeAutoApproveNotifier(fakeState),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                AppLocalizations.delegate,
              ],
              supportedLocales: [Locale('en')],
              home: AutoApproveScreen(embedded: true),
            ),
          ),
        );

        await tester.pumpAndSettle();
        // Exceptions section should be visible immediately without tapping.
        expect(find.text('Exceptions'), findsOneWidget);
      },
    );

    testWidgets(
      'exceptions header is visible without expanding for shell category',
      (tester) async {
        final fakeState = AutoApproveState(
          categories: const [
            AutoApproveCategory(
              id: 'shell',
              label: 'Shell',
              description: 'Allow shell command execution',
              defaultAction: null,
              exceptions: const {},
              isFileCategory: false,
              isShellCategory: true,
            ),
          ],
          supportsProjectScope: false,
          scope: AutoApproveScope.global,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              autoApproveProvider.overrideWith(
                () => _FakeAutoApproveNotifier(fakeState),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                AppLocalizations.delegate,
              ],
              supportedLocales: [Locale('en')],
              home: AutoApproveScreen(embedded: true),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Exceptions'), findsOneWidget);
      },
    );

    testWidgets('scope toggle renders TabBar when project scope is supported', (
      tester,
    ) async {
      final fakeState = AutoApproveState(
        categories: const [
          AutoApproveCategory(
            id: 'read',
            label: 'Read',
            description: '',
            defaultAction: null,
            exceptions: const {},
            isFileCategory: true,
            isShellCategory: false,
          ),
        ],
        supportsProjectScope: true,
        scope: AutoApproveScope.global,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autoApproveProvider.overrideWith(
              () => _FakeAutoApproveNotifier(fakeState),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: AutoApproveScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Project'), findsOneWidget);
    });

    testWidgets('file category add dialog shows browse directory button', (
      tester,
    ) async {
      final fakeState = AutoApproveState(
        categories: const [
          AutoApproveCategory(
            id: 'read',
            label: 'Read',
            description: '',
            defaultAction: null,
            exceptions: const {},
            isFileCategory: true,
            isShellCategory: false,
          ),
        ],
        supportsProjectScope: false,
        scope: AutoApproveScope.global,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autoApproveProvider.overrideWith(
              () => _FakeAutoApproveNotifier(fakeState),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: AutoApproveScreen(embedded: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the Add path button to open the dialog.
      await tester.tap(find.text('Add path'));
      await tester.pumpAndSettle();

      // Browse is now a suffix icon (no duplicate text button).
      expect(find.byIcon(Icons.folder_open_rounded), findsOneWidget);
    });

    testWidgets(
      'shell category add dialog does not show browse directory button',
      (tester) async {
        final fakeState = AutoApproveState(
          categories: const [
            AutoApproveCategory(
              id: 'shell',
              label: 'Shell',
              description: '',
              defaultAction: null,
              exceptions: const {},
              isShellCategory: true,
              isFileCategory: false,
            ),
          ],
          supportsProjectScope: false,
          scope: AutoApproveScope.global,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              autoApproveProvider.overrideWith(
                () => _FakeAutoApproveNotifier(fakeState),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                AppLocalizations.delegate,
              ],
              supportedLocales: [Locale('en')],
              home: AutoApproveScreen(embedded: true),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap the Add command button to open the dialog.
        await tester.tap(find.text('Add command'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.folder_open_rounded), findsNothing);
      },
    );

    testWidgets('add exception dialog uses custom Dialog not AlertDialog', (
      tester,
    ) async {
      final fakeState = AutoApproveState(
        categories: const [
          AutoApproveCategory(
            id: 'read',
            label: 'Read',
            description: '',
            defaultAction: null,
            exceptions: const {},
            isFileCategory: true,
            isShellCategory: false,
          ),
        ],
        supportsProjectScope: false,
        scope: AutoApproveScope.global,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autoApproveProvider.overrideWith(
              () => _FakeAutoApproveNotifier(fakeState),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: AutoApproveScreen(embedded: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the Add path button to open the dialog.
      await tester.tap(find.text('Add path'));
      await tester.pumpAndSettle();

      // Should use custom Dialog, not AlertDialog.
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('category card has premium dark background in dark theme', (
      tester,
    ) async {
      final fakeState = AutoApproveState(
        categories: const [
          AutoApproveCategory(
            id: 'read',
            label: 'Read',
            description: 'Allow reading files',
            defaultAction: null,
            exceptions: const {},
            isFileCategory: true,
            isShellCategory: false,
          ),
        ],
        supportsProjectScope: false,
        scope: AutoApproveScope.global,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autoApproveProvider.overrideWith(
              () => _FakeAutoApproveNotifier(fakeState),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: const AutoApproveScreen(embedded: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Category card should use gradient like Usage Statistics _StatCard.
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .toList();
      final card = containers.firstWhere(
        (c) => (c.decoration as BoxDecoration?)?.gradient is LinearGradient,
      );
      final decoration = card.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors, const [Color(0xFF1E1E1E), Color(0xFF262626)]);
    });
  });
}
