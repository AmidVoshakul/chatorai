// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'GenUI Chat AI';

  @override
  String get settings => 'Settings';

  @override
  String get openRouterConfiguration => 'OpenRouter Configuration';

  @override
  String get apiKey => 'API Key';

  @override
  String get enterApiKey => 'Enter your OpenRouter API key';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get useSystemTheme => 'Use system theme';

  @override
  String get light => 'Light';

  @override
  String get useLightTheme => 'Use light theme';

  @override
  String get dark => 'Dark';

  @override
  String get useDarkTheme => 'Use dark theme';

  @override
  String get fontSize => 'Font Size';

  @override
  String currentSize(Object percentage) {
    return 'Current size: $percentage%';
  }

  @override
  String get accessibility => 'Accessibility';

  @override
  String get reduceMotion => 'Reduce Motion';

  @override
  String get disableAnimation => 'Disable or reduce animation effects';

  @override
  String get highContrast => 'High Contrast';

  @override
  String get increaseContrast => 'Increase contrast for better readability';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get arabic => 'Arabic (RTL)';

  @override
  String get chinese => 'Chinese';

  @override
  String get japanese => 'Japanese';

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get resetAllSettings => 'Reset all settings to default values';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String get apiKeyCopied => 'API key copied';

  @override
  String get settingsSaved => 'Settings saved!';

  @override
  String get settingsReset => 'Settings reset to default values';

  @override
  String get appInfo => 'App Info';

  @override
  String get appDescription => 'Chat application with AI models through OpenRouter API.\n\nFeatures:\n• Chat with various AI models\n• Chat history storage\n• Dark and light themes\n• Adaptive interface\n\nDeveloped with ❤️ using Flutter';

  @override
  String get ok => 'OK';
}
