import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/features/settings/providers/mcp_management_provider.dart';
import 'package:chatorai/features/settings/screens/mcp_servers_screen.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake that records installs and reflects them in its state so the
/// Marketplace "Installed" badge can be asserted.
class _FakeMarketNotifier extends McpManagementNotifier {
  final Map<String, McpServerConfig> _servers = {};
  String? lastAddedName;
  McpServerConfig? lastAddedConfig;

  @override
  Future<McpManagementState> build() async =>
      McpManagementState(servers: Map.from(_servers));

  @override
  Future<void> addServer(String name, McpServerConfig config) async {
    lastAddedName = name;
    lastAddedConfig = config;
    _servers[name] = config;
  }
}

void main() {
  group('MCP Marketplace', () {
    late _FakeMarketNotifier fake;

    Future<void> pumpMarketplace(WidgetTester tester) async {
      // Large viewport so every grid card is mounted (GridView.builder is
      // lazy and only builds visible items).
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1.0;
      fake = _FakeMarketNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mcpManagementProvider.overrideWith(() => fake)],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: McpServersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the Marketplace tab with server cards', (tester) async {
      await pumpMarketplace(tester);
      expect(find.text('Marketplace'), findsWidgets);
      expect(find.text('Exa'), findsOneWidget);
      expect(find.text('Context7'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('search filters the catalog', (tester) async {
      await pumpMarketplace(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Search servers…'),
        'github',
      );
      await tester.pumpAndSettle();
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Exa'), findsNothing);
    });

    testWidgets('category chip filters the catalog', (tester) async {
      await pumpMarketplace(tester);
      await tester.tap(find.text('Design').first);
      await tester.pumpAndSettle();
      expect(find.text('Figma'), findsOneWidget);
      expect(find.text('Exa'), findsNothing);
    });

    testWidgets('install adds the server and shows Installed badge', (
      tester,
    ) async {
      await pumpMarketplace(tester);
      final installButton = find.widgetWithText(FilledButton, 'Install').first;
      await tester.tap(installButton);
      // Allow the install + snackbar to mount; the success snackbar uses a
      // 6s timer, so flush it before the test tears down.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 7));

      expect(fake.lastAddedName, 'exa');
      expect(fake.lastAddedConfig!.isRemote, isTrue);
      expect(fake.lastAddedConfig!.url, 'https://mcp.exa.ai/mcp');
      expect(find.text('Installed'), findsWidgets);
    });

    testWidgets('tapping a card toggles full description', (tester) async {
      await pumpMarketplace(tester);
      final card = find.text('Exa').first;
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('Exa'), findsOneWidget);
    });

    testWidgets('expanding a card does not overflow its bounds', (
      tester,
    ) async {
      await pumpMarketplace(tester);
      // Locate the Exa card by its private _MarketCard type and the Exa title.
      final exaCard = find.ancestor(
        of: find.text('Exa'),
        matching: find.byElementPredicate(
          (e) => e.widget.runtimeType.toString() == '_MarketCard',
        ),
      );
      expect(exaCard, findsOneWidget);
      final heightBefore = tester.getSize(exaCard).height;
      await tester.tap(find.text('Exa').first);
      await tester.pumpAndSettle();
      // Layout overflow is thrown as an assertion that takeException() surfaces.
      expect(tester.takeException(), isNull);
      final heightAfter = tester.getSize(exaCard).height;
      // Expanding must grow the card so the full description fits.
      expect(heightAfter, greaterThan(heightBefore));
      // The full description must be laid out (contains the closing sentence).
      expect(
        find.textContaining('grounded external information'),
        findsWidgets,
      );
    });

    testWidgets(
      'auth-gated servers show a Needs key badge, public ones do not',
      (tester) async {
        await pumpMarketplace(tester);
        // GitHub is auth-gated -> shows the "Needs key" badge.
        final githubCard = find.ancestor(
          of: find.text('GitHub'),
          matching: find.byElementPredicate(
            (e) => e.widget.runtimeType.toString() == '_MarketCard',
          ),
        );
        expect(
          find.descendant(of: githubCard, matching: find.text('Needs key')),
          findsOneWidget,
        );
        // Exa is public -> no "Needs key" badge on its card.
        final exaCard = find.ancestor(
          of: find.text('Exa'),
          matching: find.byElementPredicate(
            (e) => e.widget.runtimeType.toString() == '_MarketCard',
          ),
        );
        expect(
          find.descendant(of: exaCard, matching: find.text('Needs key')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Installed badge only appears on the button, not the title row',
      (tester) async {
        await pumpMarketplace(tester);
        // The Marketplace "Installed" tab exists, but no card title row should
        // carry a separate "Installed" badge before installation.
        final exaCard = find.ancestor(
          of: find.text('Exa'),
          matching: find.byElementPredicate(
            (e) => e.widget.runtimeType.toString() == '_MarketCard',
          ),
        );
        expect(
          find.descendant(of: exaCard, matching: find.text('Installed')),
          findsNothing,
        );
      },
    );
  });
}
