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
  String get wideScreenMode => 'Широкоэкранный режим';

  @override
  String get useFullScreenWidth => 'Использовать полную ширину экрана для чата';

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
  String get shareChat => 'Поделиться чатом';

  @override
  String get copyChat => 'Копировать чат';

  @override
  String get renameChat => 'Переименовать чат';

  @override
  String get deleteChat => 'Удалить чат';

  @override
  String get failedToShowMenu => 'Не удалось показать меню';

  @override
  String get failedToRenameChat => 'Не удалось переименовать чат';

  @override
  String get failedToCopyChat => 'Не удалось скопировать чат';

  @override
  String get chatSharingNotImplemented => 'Функция деления чата пока не реализована';

  @override
  String get newChat => 'Новый чат';

  @override
  String get noChatsYet => 'Пока нет чатов';

  @override
  String get startConversation => 'Начните разговор, нажав \"Новый чат\"';

  @override
  String get reasoning => 'Рассуждения';

  @override
  String get tapToExpand => 'Нажмите чтобы развернуть';

  @override
  String get collapse => 'Свернуть';

  @override
  String get expand => 'Развернуть';

  @override
  String chatRenamedTo(Object title) {
    return 'Чат переименован в: $title';
  }

  @override
  String get appTitle => 'Chat AI';

  @override
  String get justNow => 'Только что';

  @override
  String minAgo(Object minutes) {
    return '$minutes мин назад';
  }

  @override
  String get onlyOneMinuteAgo => '1 мин назад';

  @override
  String hoursAgo(Object hours) {
    return '$hours часов назад';
  }

  @override
  String get onlyOneHourAgo => '1 час назад';

  @override
  String daysAgo(Object days) {
    return '$days дней назад';
  }

  @override
  String get onlyOneDayAgo => '1 день назад';

  @override
  String get renameChatTitle => 'Переименовать чат';

  @override
  String get enterNewChatName => 'Введите новое имя чата';

  @override
  String get rename => 'Переименовать';

  @override
  String get ok => 'ОК';

  @override
  String get modelSelected => 'Модель выбрана';

  @override
  String get errorLoadingModels => 'Ошибка загрузки моделей';

  @override
  String get models => 'Модели';

  @override
  String get searchModels => 'Поиск моделей';

  @override
  String get refresh => 'Обновить';

  @override
  String get details => 'Детали';

  @override
  String get context => 'Контекст';

  @override
  String get free => 'Бесплатно';

  @override
  String get paid => 'Платно';

  @override
  String get multimodal => 'Мультимодально';

  @override
  String get vision => 'Зрение';

  @override
  String get tools => 'Инструменты';

  @override
  String get available => 'Доступно';

  @override
  String get description => 'Описание';

  @override
  String get technicalDetails => 'Технические детали';

  @override
  String get provider => 'Провайдер';

  @override
  String get inputTokens => 'Токены ввода';

  @override
  String get notAvailable => 'Недоступно';

  @override
  String get outputTokens => 'Токены вывода';

  @override
  String get features => 'Особенности';

  @override
  String get featuresDisplayedBasedOnActualModelCapabilities => 'Особенности отображаются на основе реальных возможностей модели';

  @override
  String get noModelsFound => 'Модели не найдены';

  @override
  String get noAvailableModels => 'Нет доступных моделей';

  @override
  String get tryADifferentSearchQuery => 'Попробуйте другой поисковый запрос';

  @override
  String get tryRefreshingOrCheckYourInternetConnection => 'Попробуйте обновить или проверьте подключение к интернету';

  @override
  String get aiIsTyping => 'AI печатает';

  @override
  String get failedToSendMessage => 'Не удалось отправить сообщение';

  @override
  String get retry => 'Повторить';

  @override
  String get enterYourMessage => 'Введите ваше сообщение...';

  @override
  String get saveAndSend => 'Сохранить и отправить';

  @override
  String get messageEditedSuccessfully => 'Сообщение успешно отредактировано';

  @override
  String get failedToEditMessage => 'Не удалось отредактировать сообщение';

  @override
  String get messageEditedAndResponseRegenerated => 'Сообщение отредактировано и ответ перегенерирован';

  @override
  String get failedToEditAndSendMessage => 'Не удалось отредактировать и отправить сообщение';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'Вы уверены, что хотите удалить это сообщение?';

  @override
  String get messageDeletedSuccessfully => 'Сообщение успешно удалено';

  @override
  String get failedToDeleteMessage => 'Не удалось удалить сообщение';

  @override
  String get messageCopied => 'Сообщение скопировано';

  @override
  String get failedToCopyMessage => 'Не удалось скопировать сообщение';

  @override
  String get messageShared => 'Сообщение поделено';

  @override
  String get failedToShareMessage => 'Не удалось поделиться сообщением';

  @override
  String get edit => 'Редактировать';

  @override
  String get share => 'Поделиться';

  @override
  String get copyMessage => 'Копировать сообщение';

  @override
  String get delete => 'Удалить';

  @override
  String get listen => 'Прослушать';

  @override
  String get regenerate => 'Перегенерировать';

  @override
  String get continueResponse => 'Продолжить ответ';

  @override
  String get like => 'Нравится';

  @override
  String get dislike => 'Не нравится';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get failedToCopy => 'Не удалось скопировать';

  @override
  String get messageDeleted => 'Сообщение удалено';

  @override
  String get errorMessage => 'Сообщение об ошибке';
}
