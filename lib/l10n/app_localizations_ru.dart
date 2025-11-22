// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'GenUI Chat AI';

  @override
  String get settings => 'Настройки';

  @override
  String get openRouterConfiguration => 'OpenRouter Конфигурация';

  @override
  String get apiKey => 'API Ключ';

  @override
  String get enterApiKey => 'Введите ваш OpenRouter API ключ';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get theme => 'Тема';

  @override
  String get system => 'Системная';

  @override
  String get useSystemTheme => 'Использовать тему системы';

  @override
  String get light => 'Светлая';

  @override
  String get useLightTheme => 'Использовать светлую тему';

  @override
  String get dark => 'Темная';

  @override
  String get useDarkTheme => 'Использовать темную тему';

  @override
  String get fontSize => 'Размер шрифта';

  @override
  String currentSize(Object percentage) {
    return 'Текущий размер: $percentage%';
  }

  @override
  String get accessibility => 'Доступность';

  @override
  String get reduceMotion => 'Уменьшить анимацию';

  @override
  String get disableAnimation => 'Отключить или уменьшить анимационные эффекты';

  @override
  String get highContrast => 'Высокая контрастность';

  @override
  String get increaseContrast => 'Увеличить контрастность для лучшей читаемости';

  @override
  String get language => 'Язык';

  @override
  String get english => 'Английский';

  @override
  String get russian => 'Русский';

  @override
  String get arabic => 'Арабский (RTL)';

  @override
  String get chinese => 'Китайский';

  @override
  String get japanese => 'Японский';

  @override
  String get resetSettings => 'Сброс настроек';

  @override
  String get resetAllSettings => 'Сбросить все настройки к значениям по умолчанию';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get close => 'Закрыть';

  @override
  String get copy => 'Скопировать';

  @override
  String get apiKeyCopied => 'API ключ скопирован';

  @override
  String get settingsSaved => 'Настройки сохранены!';

  @override
  String get settingsReset => 'Настройки сброшены к значениям по умолчанию';

  @override
  String get appInfo => 'Информация';

  @override
  String get appDescription => 'Приложение для общения с AI моделями через OpenRouter API.\n\nВозможности:\n• Общение с различными AI моделями\n• Сохранение истории чатов\n• Темная и светлая темы\n• Адаптивный интерфейс\n\nРазработано с ❤️ с использованием Flutter';

  @override
  String get ok => 'ОК';
}
