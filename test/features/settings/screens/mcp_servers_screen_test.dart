import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/gui/features/settings/providers/mcp_management_provider.dart';
import 'package:chatorai/gui/features/settings/screens/mcp_servers_screen.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake [McpManagementNotifier] that records the last [addServer] call
/// instead of touching the real config file or spawning MCP subprocesses.
class _FakeMcpManagementNotifier extends McpManagementNotifier {
  String? capturedName;
  McpServerConfig? capturedConfig;

  @override
  Future<McpManagementState> build() async => const McpManagementState();

  @override
  Future<void> addServer(
    String name,
    McpServerConfig config, {
    McpScope scope = McpScope.global,
  }) async {
    capturedName = name;
    capturedConfig = config;
  }
}

void main() {
  group('Add MCP server dialog', () {
    late _FakeMcpManagementNotifier fake;

    Future<void> openDialog(WidgetTester tester) async {
      fake = _FakeMcpManagementNotifier();
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
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
    }

    testWidgets('adds a local server with environment variables', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'github');
      await tester.enterText(
        find.widgetWithText(TextField, 'Command'),
        'npx -y @modelcontextprotocol/server-github',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Environment variables (JSON)'),
        '{"GITHUB_PERSONAL_ACCESS_TOKEN":"ghp_secret"}',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(fake.capturedName, 'github');
      final config = fake.capturedConfig!;
      expect(config.isLocal, isTrue);
      expect(config.command, 'npx');
      expect(config.args, ['-y', '@modelcontextprotocol/server-github']);
      expect(config.environment['GITHUB_PERSONAL_ACCESS_TOKEN'], 'ghp_secret');
    });

    testWidgets('adds a remote server from a bare token (Bearer)', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Remote'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'api');
      await tester.enterText(
        find.widgetWithText(TextField, 'URL'),
        'https://example.com/mcp',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Access token'),
        'tok',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(fake.capturedName, 'api');
      final config = fake.capturedConfig!;
      expect(config.isRemote, isTrue);
      expect(config.url, 'https://example.com/mcp');
      expect(config.headers, {'Authorization': 'Bearer tok'});
    });

    testWidgets('remote server wraps a token in Bearer', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('Remote'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'api');
      await tester.enterText(
        find.widgetWithText(TextField, 'URL'),
        'https://example.com/mcp',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Access token'),
        'tok',
      );
      // AuthType defaults to Token (Bearer), so no dropdown change needed.
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(fake.capturedName, 'api');
      final config = fake.capturedConfig!;
      expect(config.headers, {'Authorization': 'Bearer tok'});
    });

    testWidgets('remote server can be added without a token', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('Remote'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'public');
      await tester.enterText(
        find.widgetWithText(TextField, 'URL'),
        'https://example.com/mcp',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(fake.capturedName, 'public');
      final config = fake.capturedConfig!;
      expect(config.headers, isEmpty);
    });

    testWidgets('rejects malformed environment JSON with an error', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'broken');
      await tester.enterText(
        find.widgetWithText(TextField, 'Command'),
        'npx -y server',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Environment variables (JSON)'),
        '{not valid}',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(fake.capturedConfig, isNull);
      // The dialog stays open: a malformed JSON value must not be saved.
      // Allow the error snackbar timer to elapse so no pending timer remains.
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('raw JSON tab uses the outer key as the server name', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Raw JSON'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Server object (JSON)'),
        '{"time":{"type":"local","command":"npx","args":["-y","mcp-time"],'
        '"environment":{"TZ":"UTC"}}}',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(fake.capturedName, 'time');
      final config = fake.capturedConfig!;
      expect(config.isLocal, isTrue);
      expect(config.environment['TZ'], 'UTC');
    });

    testWidgets('raw JSON tab accepts the full mcpServers block from docs', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Raw JSON'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Server object (JSON)'),
        '{"mcpServers":{"sequential-thinking":{"command":"npx",'
        '"args":["-y","@modelcontextprotocol/server-sequential-thinking"]}}}',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(fake.capturedName, 'sequential-thinking');
      final config = fake.capturedConfig!;
      expect(config.isLocal, isTrue);
      expect(config.command, 'npx');
      expect(config.args, [
        '-y',
        '@modelcontextprotocol/server-sequential-thinking',
      ]);
    });

    testWidgets('raw JSON tab rejects multiple servers in the wrapper', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Raw JSON'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Server object (JSON)'),
        '{"mcpServers":{"a":{"type":"local","command":"x"},'
        '"b":{"type":"local","command":"y"}}}',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(fake.capturedConfig, isNull);
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('raw JSON tab hides the Name field', (tester) async {
      await openDialog(tester);

      // In Form mode the Name field is present.
      expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);

      await tester.tap(find.text('Raw JSON'));
      await tester.pumpAndSettle();

      // In Raw JSON mode the Name field is hidden — the name comes from JSON.
      expect(find.widgetWithText(TextField, 'Name'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'Server object (JSON)'),
        '{"sequential-thinking":{"command":"npx",'
        '"args":["-y","@modelcontextprotocol/server-sequential-thinking"]}}',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(fake.capturedName, 'sequential-thinking');
      expect(fake.capturedConfig, isNotNull);
    });
  });
}
