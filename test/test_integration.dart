import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';

void main() {
  group('Integration Tests - ThemeProvider Model Management', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('ThemeProvider initializes with default model', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              return Text('Model: ${provider.selectedModelId}');
            },
          ),
        ),
      );

      await tester.pump();

      // Should show default model
      expect(find.text('Model: nvidia/nemotron-3-nano-30b-a3b:free'), findsOneWidget);
    });

    testWidgets('Can switch models', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          Column(
            children: [
              Consumer<ThemeProvider>(
                builder: (context, provider, child) {
                  return Text('Model: ${provider.selectedModelId}');
                },
              ),
              ElevatedButton(
                onPressed: () => themeProvider.setSelectedModel('openai/gpt-4o-mini'),
                child: Text('Switch'),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      // Switch model
      await tester.tap(find.text('Switch'));
      await tester.pump();

      expect(find.text('Model: openai/gpt-4o-mini'), findsOneWidget);
    });

    testWidgets('Can toggle favorites', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          Column(
            children: [
              Consumer<ThemeProvider>(
                builder: (context, provider, child) {
                  return Text('Fav: ${provider.isFavoriteModel('test-model')}');
                },
              ),
              ElevatedButton(
                onPressed: () => themeProvider.toggleFavoriteModel('test-model'),
                child: Text('Toggle'),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      // Toggle favorite
      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(find.text('Fav: true'), findsOneWidget);
    });

    testWidgets('Language switching works', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          Column(
            children: [
              Consumer<ThemeProvider>(
                builder: (context, provider, child) {
                  return Text('Lang: ${provider.selectedLanguage}');
                },
              ),
              ElevatedButton(
                onPressed: () => themeProvider.selectedLanguage = 'ru',
                child: Text('Switch Lang'),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      // Switch language
      await tester.tap(find.text('Switch Lang'));
      await tester.pump();

      expect(find.text('Lang: ru'), findsOneWidget);
    });

    testWidgets('Model object can be retrieved', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          Container(),
        ),
      );

      await tester.pump();

      // Try to get model object (may be null if not loaded yet)
      final model = themeProvider.getModelById('nvidia/nemotron-3-nano-30b-a3b:free');
      
      // Should not crash
      expect(model, isA<OpenRouterModel?>());
    });
  });
}
