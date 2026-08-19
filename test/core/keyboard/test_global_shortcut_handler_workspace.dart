import 'package:chatorai/core/keyboard/global_shortcut_handler.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/workspace/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() =>
      const WorkspaceState(currentPath: '', initialized: true);

  @override
  Future<void> init() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester, GlobalKey<NavigatorState> navKey) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceProvider.overrideWith(() => _NoopWorkspaceNotifier()),
        ],
        child: MaterialApp(
          navigatorKey: navKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: GlobalShortcutHandler(
            navigatorKey: navKey,
            child: const Scaffold(body: Text('home')),
          ),
        ),
      ),
    );
  }

  testWidgets('Ctrl+W opens workspace dialog via overlay context', (
    tester,
  ) async {
    final navKey = GlobalKey<NavigatorState>();
    await pumpApp(tester, navKey);
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Workspaces'), findsOneWidget,
        reason: 'Ctrl+W must open the workspace dialog');
  });
}
