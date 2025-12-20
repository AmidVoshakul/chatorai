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

  @override
  String get welcomeMessage => 'Добро пожаловать! Чем я могу помочь сегодня?';

  @override
  String get welcomeQuestion1 => 'Объясни квантовые вычисления простыми словами';

  @override
  String get welcomeQuestion2 => 'Какие последние тренды в искусственном интеллекте?';

  @override
  String get welcomeQuestion3 => 'Помоги мне написать профессиональное письмо моей команде';

  @override
  String get welcomeQuestion4 => 'Что мне изучить, чтобы стать лучшим программистом?';

  @override
  String get welcomeQuestion5 => 'Дай 5 креативных идей для проекта на выходные';

  @override
  String get welcomeQuestion6 => 'Какие хорошие книги по личностному росту?';

  @override
  String get welcomeQuestion7 => 'Помоги придумать названия для моего стартапа';

  @override
  String get welcomeQuestion8 => 'Составь план питания на здоровую неделю';

  @override
  String get welcomeQuestion9 => 'Какие лучшие практики для Flutter разработки?';

  @override
  String get welcomeQuestion10 => 'Объясни разницу между асинхронным и синхронным программированием';

  @override
  String get welcomeQuestion11 => 'Как оптимизировать код для лучшей производительности?';

  @override
  String get welcomeQuestion12 => 'Какие самые полезные паттерны проектирования?';

  @override
  String get welcomeQuestion13 => 'Научи меня основам машинного обучения';

  @override
  String get welcomeQuestion14 => 'Какие ключевые концепции облачных вычислений?';

  @override
  String get welcomeQuestion15 => 'Объясни блокчейн технологию для новичка';

  @override
  String get welcomeQuestion16 => 'Как работает интернет с технической точки зрения?';

  @override
  String get welcomeQuestion17 => 'Какие лучшие техники продуктивности?';

  @override
  String get welcomeQuestion18 => 'Как улучшить концентрацию и фокус?';

  @override
  String get welcomeQuestion19 => 'Дай распорядок дня для максимальной продуктивности';

  @override
  String get welcomeQuestion20 => 'Какие хорошие привычки для успеха?';

  @override
  String get welcomeQuestion21 => 'Как подготовиться к собеседованию в IT?';

  @override
  String get welcomeQuestion22 => 'Какие навыки最有价值 в tech индустрии?';

  @override
  String get welcomeQuestion23 => 'Как договориться о повышении зарплаты?';

  @override
  String get welcomeQuestion24 => 'Какие топ tech компании для работы?';

  @override
  String get welcomeQuestion25 => 'Какие последние прорывы в космических исследованиях?';

  @override
  String get welcomeQuestion26 => 'Как ИИ меняет здравоохранение?';

  @override
  String get welcomeQuestion27 => 'Какие самые захватывающие технологии 2025 года?';

  @override
  String get welcomeQuestion28 => 'Объясни будущее возобновляемой энергетики';

  @override
  String get welcomeQuestion29 => 'Какие самые важные философские вопросы?';

  @override
  String get welcomeQuestion30 => 'Как научиться мыслить более критически?';

  @override
  String get welcomeQuestion31 => 'Какие лучшие способы изучения новых навыков?';

  @override
  String get welcomeQuestion32 => 'Как сохранить мотивацию при изучении сложного материала?';

  @override
  String get welcomeQuestion33 => 'Какие языки программирования лучше учить в 2025 году?';

  @override
  String get welcomeQuestion34 => 'Как создать сильное портфолио для IT вакансий?';

  @override
  String get welcomeQuestion35 => 'Какие топ AI инструменты для продуктивности?';

  @override
  String get welcomeQuestion36 => 'Как на самом деле работает машинное обучение?';

  @override
  String get welcomeQuestion37 => 'Какие лучшие практики для ревью кода?';

  @override
  String get welcomeQuestion38 => 'Как писать чистый и поддерживаемый код?';

  @override
  String get welcomeQuestion39 => 'Что такое микросервисы и когда их использовать?';

  @override
  String get welcomeQuestion40 => 'Объясни разницу REST API и GraphQL';

  @override
  String get welcomeQuestion41 => 'Какие облачные платформы лучше учить?';

  @override
  String get welcomeQuestion42 => 'Как подготовиться к техническим собеседованиям?';

  @override
  String get welcomeQuestion43 => 'Какие мягкие навыки нужны каждому разработчику?';

  @override
  String get welcomeQuestion44 => 'Как договориться о зарплате разработчику?';

  @override
  String get welcomeQuestion45 => 'Какие лучшие инструменты для удаленной работы?';

  @override
  String get welcomeQuestion46 => 'Как оставаться продуктивным на удаленке?';

  @override
  String get welcomeQuestion47 => 'Какие лучшие методологии управления проектами?';

  @override
  String get welcomeQuestion48 => 'Как работать с трудными коллегами?';

  @override
  String get welcomeQuestion49 => 'Какие лучшие книги по лидерству?';

  @override
  String get welcomeQuestion50 => 'Как запустить успешный tech стартап?';

  @override
  String get welcomeQuestion51 => 'Какие последние тренды в веб-разработке?';

  @override
  String get welcomeQuestion52 => 'Как работает блокчейн технология?';

  @override
  String get welcomeQuestion53 => 'Что такое NFT и стоит ли обращать внимание?';

  @override
  String get welcomeQuestion54 => 'Объясни концепцию метавселенной';

  @override
  String get welcomeQuestion55 => 'Какие лучшие AI модели для программирования?';

  @override
  String get welcomeQuestion56 => 'Как эффективно использовать ChatGPT?';

  @override
  String get welcomeQuestion57 => 'Какие этические аспекты AI?';

  @override
  String get welcomeQuestion58 => 'Как AI изменит работу в будущем?';

  @override
  String get welcomeQuestion59 => 'Какие лучшие практики кибербезопасности?';

  @override
  String get welcomeQuestion60 => 'Как защитить свою приватность в интернете?';

  @override
  String get welcomeQuestion61 => 'Какие лучшие инструменты для data science?';

  @override
  String get welcomeQuestion62 => 'Как эффективно визуализировать данные?';

  @override
  String get welcomeQuestion63 => 'Какие лучшие фреймворки для мобильных приложений?';

  @override
  String get welcomeQuestion64 => 'Как создавать кроссплатформенные приложения?';

  @override
  String get welcomeQuestion65 => 'Какие лучшие движки для разработки игр?';

  @override
  String get welcomeQuestion66 => 'Как начать работать с 3D моделированием?';

  @override
  String get welcomeQuestion67 => 'Какие лучшие инструменты для видеомонтажа?';

  @override
  String get welcomeQuestion68 => 'Как создавать контент, который вовлекает?';

  @override
  String get welcomeQuestion69 => 'Какие лучшие стратегии для соцсетей?';

  @override
  String get welcomeQuestion70 => 'Как построить личный бренд?';

  @override
  String get welcomeQuestion71 => 'Какие лучшие советы для нетворкинга?';

  @override
  String get welcomeQuestion72 => 'Как сделать отличную презентацию?';

  @override
  String get welcomeQuestion73 => 'Какие лучшие техники тайм-менеджмента?';

  @override
  String get welcomeQuestion74 => 'Как избежать выгорания?';

  @override
  String get welcomeQuestion75 => 'Какие лучшие приложения для медитации?';

  @override
  String get welcomeQuestion76 => 'Как улучшить качество сна?';

  @override
  String get welcomeQuestion77 => 'Какие лучшие тренировки?';

  @override
  String get welcomeQuestion78 => 'Как питаться здоровой едой с ограниченным бюджетом?';

  @override
  String get welcomeQuestion79 => 'Какие лучшие места для путешествий для tech специалистов?';

  @override
  String get welcomeQuestion80 => 'Как быстро выучить новый язык?';
}
