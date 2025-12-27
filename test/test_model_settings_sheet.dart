import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/widgets/chat/model_settings_sheet.dart';
import 'package:gen_ui_chat_ai/providers/model_settings_provider.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/models/model_settings.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('ModelSettingsSheet Widget Tests', () {
    late ModelSettingsProvider settingsProvider;
    late ThemeProvider themeProvider;

    setUp(() {
      settingsProvider = ModelSettingsProvider();
      themeProvider = ThemeProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ModelSettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
          ],
          home: Scaffold(
            body: const ModelSettingsSheet(),
          ),
        ),
      );
    }

    testWidgets('should render with active settings', (WidgetTester tester) async {
      // Arrange
      final settings = ModelSettings(
        modelId: 'test-model',
        temperature: 0.7,
        maxTokens: 2000,
        topP: 0.9,
        frequencyPenalty: 0.5,
        presencePenalty: 0.3,
        systemPrompt: 'You are helpful',
        stream: true,
      );

      // Set active settings
      await settingsProvider.setActiveModel('test-model');
      await settingsProvider.updateActiveSettings(settings);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Model Settings'), findsOneWidget);
      expect(find.text('Temperature'), findsOneWidget);
      expect(find.text('Max Tokens'), findsOneWidget);
      expect(find.text('Top P'), findsOneWidget);
    });

    testWidgets('should show no model selected when no active settings', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No model selected'), findsOneWidget);
    });

    testWidgets('should show API values in parameter fields', (WidgetTester tester) async {
      // Arrange
      final settings = ModelSettings(
        modelId: 'test-model',
        temperature: 0.7,
        maxTokens: 2000,
        apiMaxTokens: 4000,
        apiMaxTemperature: 2.0,
        apiMinTemperature: 0.0,
      );

      await settingsProvider.setActiveModel('test-model');
      await settingsProvider.updateActiveSettings(settings);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check that API info is displayed
      expect(find.text('Current: 0.7'), findsOneWidget);
      expect(find.text('Max: 2.0'), findsOneWidget);
      expect(find.text('Current: 2000'), findsOneWidget);
      expect(find.text('Max: 4000'), findsOneWidget);
    });

    testWidgets('should show system prompt field', (WidgetTester tester) async {
      // Arrange
      final settings = ModelSettings(
        modelId: 'test-model',
        temperature: 0.7,
        maxTokens: 2000,
        systemPrompt: 'You are a helpful assistant',
      );

      await settingsProvider.setActiveModel('test-model');
      await settingsProvider.updateActiveSettings(settings);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('System Prompt'), findsOneWidget);
      expect(find.text('You are a helpful assistant'), findsOneWidget);
    });
  });
}
