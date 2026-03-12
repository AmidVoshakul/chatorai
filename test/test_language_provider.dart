import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers/language_provider.dart';

void main() {
  group('LanguageState', () {
    test('supportedLanguages contains expected languages', () {
      expect(LanguageState.supportedLanguages, contains('en'));
      expect(LanguageState.supportedLanguages, contains('ru'));
      expect(LanguageState.supportedLanguages, contains('zh'));
      expect(LanguageState.supportedLanguages, contains('ja'));
      expect(LanguageState.supportedLanguages, contains('ar'));
    });

    test('rtlLanguages contains expected RTL languages', () {
      expect(LanguageState.rtlLanguages, contains('ar'));
      expect(LanguageState.rtlLanguages, contains('he'));
      expect(LanguageState.rtlLanguages, contains('fa'));
    });

    test('isRTLanguage returns correct values', () {
      expect(LanguageState.isRTLanguage('ar'), true);
      expect(LanguageState.isRTLanguage('en'), false);
      expect(LanguageState.isRTLanguage('ru'), false);
    });

    test('getLanguageDisplayName returns correct names', () {
      expect(LanguageState.getLanguageDisplayName('en'), 'English');
      expect(LanguageState.getLanguageDisplayName('ru'), 'Русский');
      expect(LanguageState.getLanguageDisplayName('zh'), '中文');
      expect(LanguageState.getLanguageDisplayName('ja'), '日本語');
      expect(LanguageState.getLanguageDisplayName('ar'), 'العربية');
    });

    test('copyWith creates new instance with updated values', () {
      const state = LanguageState();
      final newState = state.copyWith(selectedLanguage: 'ru', isRTL: true);

      expect(newState.selectedLanguage, 'ru');
      expect(newState.isRTL, true);
      expect(newState.isLoading, true);
    });

    test('copyWith preserves original values when not specified', () {
      const state = LanguageState(
        selectedLanguage: 'ru',
        isRTL: true,
        isLoading: false,
      );
      final newState = state.copyWith(selectedLanguage: 'zh');

      expect(newState.selectedLanguage, 'zh');
      expect(newState.isRTL, true);
      expect(newState.isLoading, false);
    });
  });

  group('LanguageNotifier via ProviderContainer', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has default values', () {
      final state = container.read(languageProvider);
      expect(state.selectedLanguage, 'en');
      expect(state.isRTL, false);
      expect(state.isLoading, true);
    });

    test('setSelectedLanguage changes language', () {
      container.read(languageProvider.notifier).setSelectedLanguage('ru');
      final state = container.read(languageProvider);
      expect(state.selectedLanguage, 'ru');
    });

    test('setSelectedLanguage updates RTL for RTL languages', () {
      container.read(languageProvider.notifier).setSelectedLanguage('ar');
      final state = container.read(languageProvider);
      expect(state.selectedLanguage, 'ar');
      expect(state.isRTL, true);
    });

    test('setSelectedLanguage updates RTL for non-RTL languages', () {
      container.read(languageProvider.notifier).setSelectedLanguage('ar');
      expect(container.read(languageProvider).isRTL, true);

      container.read(languageProvider.notifier).setSelectedLanguage('en');
      expect(container.read(languageProvider).isRTL, false);
    });

    test('resetSettings resets to defaults', () async {
      container.read(languageProvider.notifier).setSelectedLanguage('ja');

      await container.read(languageProvider.notifier).resetSettings();

      final state = container.read(languageProvider);
      expect(state.selectedLanguage, 'en');
      expect(state.isRTL, false);
      expect(state.isLoading, false);
    });
  });
}
