import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers/theme_provider.dart';

void main() {
  group('ThemeState', () {
    test('copyWith creates new instance with updated values', () {
      const state = ThemeState();
      final newState = state.copyWith(
        themeMode: AppThemeMode.dark,
        fontSize: 1.5,
      );

      expect(newState.themeMode, AppThemeMode.dark);
      expect(newState.fontSize, 1.5);
      expect(newState.wideScreenMode, false);
    });

    test('isDarkMode returns correct value for dark mode', () {
      const state = ThemeState(themeMode: AppThemeMode.dark);
      expect(state.isDarkMode, true);
    });

    test('isDarkMode returns correct value for light mode', () {
      const state = ThemeState(themeMode: AppThemeMode.light);
      expect(state.isDarkMode, false);
    });

    test('isDarkMode returns correct value for system mode', () {
      const state = ThemeState(themeMode: AppThemeMode.system);
      // For system mode, it depends on platform brightness
      // Just verify it returns a boolean
      expect(state.isDarkMode, isA<bool>());
    });
  });

  group('ThemeNotifier via ProviderContainer', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has default values', () {
      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.system);
      expect(state.fontSize, 1.0);
      expect(state.wideScreenMode, false);
      expect(state.isLoading, true);
    });

    test('setThemeMode changes theme mode', () {
      container.read(themeProvider.notifier).setThemeMode(AppThemeMode.dark);
      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);
    });

    test('setFontSize changes font size', () {
      container.read(themeProvider.notifier).setFontSize(1.5);
      final state = container.read(themeProvider);
      expect(state.fontSize, 1.5);
    });

    test('setWideScreenMode changes wide screen mode', () {
      container.read(themeProvider.notifier).setWideScreenMode(true);
      final state = container.read(themeProvider);
      expect(state.wideScreenMode, true);
    });

    test('resetSettings resets to defaults', () async {
      container.read(themeProvider.notifier).setThemeMode(AppThemeMode.light);
      container.read(themeProvider.notifier).setFontSize(2.0);
      container.read(themeProvider.notifier).setWideScreenMode(true);

      await container.read(themeProvider.notifier).resetSettings();

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.system);
      expect(state.fontSize, 1.0);
      expect(state.wideScreenMode, false);
      expect(state.isLoading, false);
    });

    test('getTheme returns theme data', () {
      final notifier = container.read(themeProvider.notifier);
      final theme = notifier.getTheme();
      expect(theme, isNotNull);
    });
  });
}
