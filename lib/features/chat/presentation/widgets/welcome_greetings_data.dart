import 'package:flutter/widgets.dart';
import 'package:chatorai/l10n/app_localizations.dart';

class WelcomeGreetingsData {
  static List<String> getAllGreetings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return [
      l10n.welcomeGreeting1,
      l10n.welcomeGreeting2,
      l10n.welcomeGreeting3,
      l10n.welcomeGreeting4,
      l10n.welcomeGreeting5,
      l10n.welcomeGreeting6,
      l10n.welcomeGreeting7,
      l10n.welcomeGreeting8,
      l10n.welcomeGreeting9,
      l10n.welcomeGreeting10,
      l10n.welcomeGreeting11,
      l10n.welcomeGreeting12,
    ];
  }

  static String getRandomGreeting(BuildContext context) {
    final greetings = getAllGreetings(context);
    if (greetings.isEmpty) return 'Welcome! How can I help you today?';

    final random = DateTime.now().millisecondsSinceEpoch;
    return greetings[random % greetings.length];
  }
}
