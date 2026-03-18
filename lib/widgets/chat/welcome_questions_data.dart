import 'package:flutter/widgets.dart';
import 'package:chatorai/l10n/app_localizations.dart';

/// Welcome questions data for new chats
///
/// This file contains a curated list of popular questions that users can start with.
/// Questions are loaded from localization files for multi-language support.
class WelcomeQuestionsData {
  /// Get all available welcome questions using localization
  static List<String> getAllQuestions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return [];

    return [
      l10n.welcomeQuestion1,
      l10n.welcomeQuestion2,
      l10n.welcomeQuestion3,
      l10n.welcomeQuestion4,
      l10n.welcomeQuestion5,
      l10n.welcomeQuestion6,
      l10n.welcomeQuestion7,
      l10n.welcomeQuestion8,
      l10n.welcomeQuestion9,
      l10n.welcomeQuestion10,
      l10n.welcomeQuestion11,
      l10n.welcomeQuestion12,
      l10n.welcomeQuestion13,
      l10n.welcomeQuestion14,
      l10n.welcomeQuestion15,
      l10n.welcomeQuestion16,
      l10n.welcomeQuestion17,
      l10n.welcomeQuestion18,
      l10n.welcomeQuestion19,
      l10n.welcomeQuestion20,
      l10n.welcomeQuestion21,
      l10n.welcomeQuestion22,
      l10n.welcomeQuestion23,
      l10n.welcomeQuestion24,
      l10n.welcomeQuestion25,
      l10n.welcomeQuestion26,
      l10n.welcomeQuestion27,
      l10n.welcomeQuestion28,
      l10n.welcomeQuestion29,
      l10n.welcomeQuestion30,
      l10n.welcomeQuestion31,
      l10n.welcomeQuestion32,
      l10n.welcomeQuestion33,
      l10n.welcomeQuestion34,
      l10n.welcomeQuestion35,
      l10n.welcomeQuestion36,
      l10n.welcomeQuestion37,
      l10n.welcomeQuestion38,
      l10n.welcomeQuestion39,
      l10n.welcomeQuestion40,
      l10n.welcomeQuestion41,
      l10n.welcomeQuestion42,
      l10n.welcomeQuestion43,
      l10n.welcomeQuestion44,
      l10n.welcomeQuestion45,
      l10n.welcomeQuestion46,
      l10n.welcomeQuestion47,
      l10n.welcomeQuestion48,
      l10n.welcomeQuestion49,
      l10n.welcomeQuestion50,
      l10n.welcomeQuestion51,
      l10n.welcomeQuestion52,
      l10n.welcomeQuestion53,
      l10n.welcomeQuestion54,
      l10n.welcomeQuestion55,
      l10n.welcomeQuestion56,
      l10n.welcomeQuestion57,
      l10n.welcomeQuestion58,
      l10n.welcomeQuestion59,
      l10n.welcomeQuestion60,
      l10n.welcomeQuestion61,
      l10n.welcomeQuestion62,
      l10n.welcomeQuestion63,
      l10n.welcomeQuestion64,
      l10n.welcomeQuestion65,
      l10n.welcomeQuestion66,
      l10n.welcomeQuestion67,
      l10n.welcomeQuestion68,
      l10n.welcomeQuestion69,
      l10n.welcomeQuestion70,
      l10n.welcomeQuestion71,
      l10n.welcomeQuestion72,
      l10n.welcomeQuestion73,
      l10n.welcomeQuestion74,
      l10n.welcomeQuestion75,
      l10n.welcomeQuestion76,
      l10n.welcomeQuestion77,
      l10n.welcomeQuestion78,
      l10n.welcomeQuestion79,
      l10n.welcomeQuestion80,
      l10n.welcomeQuestion81,
      l10n.welcomeQuestion82,
      l10n.welcomeQuestion83,
      l10n.welcomeQuestion84,
      l10n.welcomeQuestion85,
      l10n.welcomeQuestion86,
      l10n.welcomeQuestion87,
      l10n.welcomeQuestion88,
      l10n.welcomeQuestion89,
      l10n.welcomeQuestion90,
      l10n.welcomeQuestion91,
      l10n.welcomeQuestion92,
      l10n.welcomeQuestion93,
      l10n.welcomeQuestion94,
      l10n.welcomeQuestion95,
      l10n.welcomeQuestion96,
      l10n.welcomeQuestion97,
      l10n.welcomeQuestion98,
      l10n.welcomeQuestion99,
      l10n.welcomeQuestion100,
      l10n.welcomeQuestion101,
      l10n.welcomeQuestion102,
      l10n.welcomeQuestion103,
      l10n.welcomeQuestion104,
      l10n.welcomeQuestion105,
      l10n.welcomeQuestion106,
      l10n.welcomeQuestion107,
      l10n.welcomeQuestion108,
      l10n.welcomeQuestion109,
      l10n.welcomeQuestion110,
      l10n.welcomeQuestion111,
      l10n.welcomeQuestion112,
      l10n.welcomeQuestion113,
      l10n.welcomeQuestion114,
      l10n.welcomeQuestion115,
      l10n.welcomeQuestion116,
      l10n.welcomeQuestion117,
      l10n.welcomeQuestion118,
      l10n.welcomeQuestion119,
      l10n.welcomeQuestion120,
    ];
  }

  /// Get a random subset of questions
  static List<String> getRandomQuestions(
    BuildContext context, {
    int count = 4,
  }) {
    final allQuestions = getAllQuestions(context);
    if (count >= allQuestions.length) {
      return allQuestions;
    }

    // Create a copy to avoid modifying the original
    final shuffled = List<String>.from(allQuestions)..shuffle();
    return shuffled.take(count).toList();
  }
}
