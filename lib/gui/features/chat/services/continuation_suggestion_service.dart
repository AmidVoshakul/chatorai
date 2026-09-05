import 'package:chatorai/gui/shared/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart'
    show chatScreenProvider, chatAiServiceProvider, modelSettingsProvider;
import 'package:chatorai/shared/utils/chat_language_utils.dart';
import 'package:chatorai/shared/utils/chat_suggestion_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContinuationSuggestionService {
  Future<void> showSuggestions({
    required WidgetRef ref,
    required BuildContext context,
    required String messageContent,
    required String selectedModelId,
    required bool mounted,
  }) async {
    final chatState = ref.read(chatScreenProvider);
    if (chatState.isSuggestionsLoading) return;

    ref.read(chatScreenProvider.notifier).setSuggestionsLoading(true);

    try {
      final language = ChatLanguageUtils.detectLanguage(messageContent);
      final suggestions = await getSuggestions(
        ref: ref,
        context: context,
        content: messageContent,
        language: language,
        selectedModelId: selectedModelId,
        mounted: mounted,
      );

      if (suggestions.isNotEmpty) {
        ref
            .read(chatScreenProvider.notifier)
            .showContinuationSuggestions(suggestions);
      }
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      final localizations = AppLocalizations.of(context)!;
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.generatingSuggestionsFailed('Error'),
        icon: Icons.error,
      );
    } finally {
      ref.read(chatScreenProvider.notifier).setSuggestionsLoading(false);
    }
  }

  Future<List<String>> getSuggestions({
    required WidgetRef ref,
    required BuildContext context,
    required String content,
    required String language,
    required String selectedModelId,
    required bool mounted,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final systemPrompt = localizations.systemPromptSuggestion;
    final userPrompt = localizations.userPromptSuggestion;

    final suggestionPrompt = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'assistant', 'content': content},
      {'role': 'user', 'content': userPrompt},
    ];

    final settings = await ref
        .read(modelSettingsProvider.notifier)
        .getSettings(selectedModelId);
    final suggestionSettings = settings.copyWith(temperature: 0.7);

    if (suggestionSettings.systemPrompt != null) {
      suggestionPrompt.insert(0, {
        'role': 'system',
        'content': suggestionSettings.systemPrompt!,
      });
    }

    try {
      final response = await ref
          .read(chatAiServiceProvider)
          .generateCompletion(
            model: selectedModelId,
            messages: suggestionPrompt,
            temperature: suggestionSettings.temperature,
          );
      return parseSuggestions(response);
    } catch (e) {
      if (!mounted) {
        return ['Tell me more', 'Examples?', 'Alternatives?'];
      }
      if (!context.mounted) {
        return ['Tell me more', 'Examples?', 'Alternatives?'];
      }
      final localizations = AppLocalizations.of(context)!;
      return [
        localizations.defaultSuggestion1,
        localizations.defaultSuggestion2,
        localizations.defaultSuggestion3,
      ];
    }
  }
}
