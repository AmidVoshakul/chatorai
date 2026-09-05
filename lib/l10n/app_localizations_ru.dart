// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'ChatORAI';

  @override
  String get settings => 'Настройки';

  @override
  String get providerConfiguration => 'Конфигурация провайдера';

  @override
  String get apiKey => 'API Ключ';

  @override
  String get enterApiKey => 'Введите ваш OpenRouter API ключ';

  @override
  String get baseUrl => 'Базовый URL';

  @override
  String get validateApiKey => 'Проверить API ключ';

  @override
  String get apiKeyValid => 'API ключ валидный';

  @override
  String get apiKeyInvalid => 'Неверный формат API ключа';

  @override
  String get apiKeyEmpty => 'API ключ не может быть пустым';

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
  String get autoScrollDuringStreaming => 'Автоскролл во время стриминга';

  @override
  String get autoScrollDuringStreamingDesc => 'Прокручивать список вниз при появлении нового контента';

  @override
  String get showContinuationSuggestions => 'Показывать продолжения диалога';

  @override
  String get showContinuationSuggestionsDesc => 'Отображать предложения для продолжения после ответа AI';

  @override
  String get expandReasoningByDefault => 'Разворачивать reasoning по умолчанию';

  @override
  String get expandReasoningByDefaultDesc => 'Показывать блоки рассуждений развёрнутыми при ответе AI';

  @override
  String get slashCommandSkills => 'Показать доступные навыки';

  @override
  String get slashCommandNew => 'Начать новый чат';

  @override
  String get slashCommandClear => 'Очистить текущий чат';

  @override
  String get slashCommandCompact => 'Сжать контекст беседы';

  @override
  String get slashCommandHelp => 'Показать справку';

  @override
  String get slashCommandUndo => 'Отменить последнее действие';

  @override
  String get slashCommandRedo => 'Повторить отменённое действие';

  @override
  String get slashCommandSessions => 'Список сессий';

  @override
  String get slashCommandModels => 'Выбрать модель';

  @override
  String get slashCommandTheme => 'Сменить тему';

  @override
  String get slashCommandThinking => 'Переключить видимость reasoning';

  @override
  String get language => 'Язык';

  @override
  String get english => 'Английский';

  @override
  String get russian => 'Русский';

  @override
  String get ukrainian => 'Украинский';

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
  String errorLoadingChat(String error) {
    return 'Не удалось загрузить чат: $error';
  }

  @override
  String get confirmOpenLink => 'Вы действительно хотите открыть:';

  @override
  String get copy => 'Скопировать';

  @override
  String get apiKeyCopied => 'API ключ скопирован';

  @override
  String get apiKeySaved => 'API ключ успешно сохранен';

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
  String chatRenamedTo(Object name) {
    return 'Чат переименован в: $name';
  }

  @override
  String get appTitle => 'Chat ORAI';

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
  String contextMessages(Object percent, Object usable, Object used) {
    return 'Контекст: $used / $usable токенов ($percent%)';
  }

  @override
  String get contextInstructions => 'Инструкции';

  @override
  String get contextAgentPrompt => 'Промпт агента';

  @override
  String get contextUserPrompt => 'Промпт пользователя';

  @override
  String get contextCompactSession => 'Сжать сессию';

  @override
  String get contextCompacting => 'Сжатие…';

  @override
  String get contextUsageBreakdown => 'Использование';

  @override
  String get contextPromptTokens => 'Входные токены';

  @override
  String get contextOutputTokens => 'Токены вывода';

  @override
  String get contextCacheRead => 'Чтение кэша';

  @override
  String get contextCacheWrite => 'Запись кэша';

  @override
  String get contextToolTokens => 'Токены инструментов';

  @override
  String get contextSpentLabel => 'Потрачено';

  @override
  String get contextTokensIncludedInPrompt => 'Токены инструментов включены в промпт';

  @override
  String contextAutoCompactAt(Object buffer, Object percent) {
    return 'Автосжатие при $percent% · буфер $buffer токенов';
  }

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
  String get loadingMsg1 => 'Жду ответа сервера…';

  @override
  String get loadingMsg2 => 'Данные отправлены — осталось чуть-чуть…';

  @override
  String get loadingMsg3 => 'Складываю мысли в ответ…';

  @override
  String get loadingMsg4 => 'Подбираю лучший вариант…';

  @override
  String get loadingMsg5 => 'Загружаю ответ (почти)…';

  @override
  String get failedToSendMessage => 'Не удалось отправить сообщение';

  @override
  String get retry => 'Повторить';

  @override
  String get bootstrapErrorTitle => 'Не удалось запустить приложение';

  @override
  String get bootstrapErrorBody => 'Проверьте конфигурацию и повторите попытку.';

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
  String confirmDeleteMessage(Object chatTitle) {
    return 'Вы действительно хотите удалить чат \"$chatTitle\"?';
  }

  @override
  String get areYouSureYouWantToRegenerateThisMessage => 'Вы уверены, что хотите перегенерировать это сообщение?';

  @override
  String modelDoesNotSupportImages(Object modelId) {
    return 'Модель $modelId не поддерживает изображения. Вы можете прикрепить фото, но отправка не сработает.';
  }

  @override
  String chatTitleUpdated(Object title) {
    return 'Чат переименован в: $title';
  }

  @override
  String get messageDeletedSuccessfully => 'Сообщение успешно удалено';

  @override
  String get failedToDeleteMessage => 'Не удалось удалить сообщение';

  @override
  String get regenerationStarted => 'Перегенерация начата';

  @override
  String get failedToRegenerateMessage => 'Не удалось перегенерировать сообщение';

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
  String editToolTitle(String path) {
    return 'Редактировать $path';
  }

  @override
  String patchToolTitle(String path) {
    return 'Патч $path';
  }

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
  String get welcomeQuestion22 => 'Какие навыки в tech индустрии?';

  @override
  String get welcomeQuestion23 => 'Как договориться о повышении зарплаты?';

  @override
  String get welcomeQuestion24 => 'Какие топ tech компании для работы?';

  @override
  String get welcomeQuestion25 => 'Какие последние прорывы в космических исследованиях?';

  @override
  String get welcomeQuestion26 => 'Как ИИ меняет здравоохранение?';

  @override
  String get welcomeQuestion27 => 'Какие самые захватывающие технологии 2026 года?';

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
  String get welcomeQuestion33 => 'Какие языки программирования лучше учить в 2026 году?';

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

  @override
  String get welcomeQuestion81 => 'Какие лучшие практики для удаленной командной работы?';

  @override
  String get welcomeQuestion82 => 'Как проводить эффективные ревью кода?';

  @override
  String get welcomeQuestion83 => 'Какие топ навыки для software архитекторов?';

  @override
  String get welcomeQuestion84 => 'Как проектировать масштабируемые базы данных?';

  @override
  String get welcomeQuestion85 => 'Какие лучшие DevOps инструменты для изучения?';

  @override
  String get welcomeQuestion86 => 'Как внедрять CI/CD пайплайны?';

  @override
  String get welcomeQuestion87 => 'Что такое оркестрация контейнеров?';

  @override
  String get welcomeQuestion88 => 'Объясни преимущества serverless вычислений';

  @override
  String get welcomeQuestion89 => 'Какие лучшие практики для безопасности API?';

  @override
  String get welcomeQuestion90 => 'Как оптимизировать производительность мобильных приложений?';

  @override
  String get welcomeQuestion91 => 'Что такое прогрессивные веб-приложения?';

  @override
  String get welcomeQuestion92 => 'Как создавать доступные веб-приложения?';

  @override
  String get welcomeQuestion93 => 'Какие лучшие принципы UI/UX дизайна?';

  @override
  String get welcomeQuestion94 => 'Как эффективно проводить пользовательские исследования?';

  @override
  String get welcomeQuestion95 => 'Какие лучшие стратегии A/B тестирования?';

  @override
  String get welcomeQuestion96 => 'Как анализировать поведение пользователей?';

  @override
  String get welcomeQuestion97 => 'Какие лучшие техники growth hacking?';

  @override
  String get welcomeQuestion98 => 'Как построить сообщество вокруг продукта?';

  @override
  String get welcomeQuestion99 => 'Какие лучшие инструменты для поддержки клиентов?';

  @override
  String get welcomeQuestion100 => 'Как эффективно обрабатывать отзывы клиентов?';

  @override
  String get welcomeQuestion101 => 'В чем разница между React и Vue?';

  @override
  String get welcomeQuestion102 => 'Как TypeScript улучшает разработку на JavaScript?';

  @override
  String get welcomeQuestion103 => 'Какие лучшие практики для проектирования REST API?';

  @override
  String get welcomeQuestion104 => 'Как реализовать аутентификацию в веб-приложениях?';

  @override
  String get welcomeQuestion105 => 'Какие преимущества GraphQL перед REST?';

  @override
  String get welcomeQuestion106 => 'Как оптимизировать запросы к базе данных для производительности?';

  @override
  String get welcomeQuestion107 => 'Что такое паттерны архитектуры микросервисов?';

  @override
  String get welcomeQuestion108 => 'Как реализовать стратегии кэширования?';

  @override
  String get welcomeQuestion109 => 'Какие лучшие фреймворки для тестирования JavaScript?';

  @override
  String get welcomeQuestion110 => 'Как писать unit-тесты для React-компонентов?';

  @override
  String get welcomeQuestion111 => 'Что такое принципы SOLID в ООП?';

  @override
  String get welcomeQuestion112 => 'Как реализовать паттерны проектирования в Python?';

  @override
  String get welcomeQuestion113 => 'Какие лучшие практики для Git workflow?';

  @override
  String get welcomeQuestion114 => 'Как эффективно разрешать merge conflicts?';

  @override
  String get welcomeQuestion115 => 'Какие лучшие практики для контейнеризации?';

  @override
  String get welcomeQuestion116 => 'Как защитить Docker контейнеры?';

  @override
  String get welcomeQuestion117 => 'Что такое стратегии развертывания в Kubernetes?';

  @override
  String get welcomeQuestion118 => 'Как мониторить производительность приложения?';

  @override
  String get welcomeQuestion119 => 'Какие лучшие практики для логирования?';

  @override
  String get welcomeQuestion120 => 'Как реализовать обработку ошибок в распределенных системах?';

  @override
  String get continueConversation => 'Продолжить диалог';

  @override
  String get generatingSuggestions => 'Генерация предложений...';

  @override
  String get searchChats => 'Поиск чатов...';

  @override
  String noChatsFound(Object query) {
    return 'Чаты не найдены для \"$query\"';
  }

  @override
  String get tryDifferentSearchTerm => 'Попробуйте другой поисковый термин';

  @override
  String get appShortName => 'ChatORAI';

  @override
  String get typeYourMessage => 'Введите ваше сообщение...';

  @override
  String get addImage => 'Изображение';

  @override
  String get addCamera => 'Камера';

  @override
  String get addFile => 'Файл';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get searchFavorites => 'Поиск избранных...';

  @override
  String get showAllModels => 'Показать все модели';

  @override
  String get showFavoritesOnly => 'Показать только избранные';

  @override
  String get noFavoriteModels => 'Нет избранных моделей';

  @override
  String get tapHeartToAddFavorites => 'Нажмите на сердечко у моделей, чтобы добавить их в избранные';

  @override
  String get addToFavorites => 'Добавить в избранное';

  @override
  String get removeFromFavorites => 'Удалить из избранного';

  @override
  String get recentModels => 'Недавние';

  @override
  String get loadingSkills => 'Загрузка навыков...';

  @override
  String get noSkillsInstalled => 'Нет установленных навыков. Добавьте в .chatorai/skills/';

  @override
  String get noSkillsMatchSearch => 'Нет навыков, соответствующих поиску';

  @override
  String get allSkillsRequirePermission => 'Все навыки требуют разрешения';

  @override
  String skillExecuted(Object name) {
    return 'Навык выполнен: $name';
  }

  @override
  String get configuration => 'Конфигурация';

  @override
  String get stats => 'Статистика';

  @override
  String get usageStatistics => 'Статистика использования';

  @override
  String get totalSessions => 'Сеансы';

  @override
  String get totalMessages => 'Сообщения';

  @override
  String get days => 'Дни';

  @override
  String get totalTokens => 'Всего токенов';

  @override
  String get totalCost => 'Общая стоимость';

  @override
  String get avgCostPerDay => 'Средняя стоимость/день';

  @override
  String get avgTokensPerSession => 'Среднее токенов/сеанс';

  @override
  String get medianTokensPerSession => 'Медиана токенов/сеанс';

  @override
  String get cacheRead => 'Чтение кэша';

  @override
  String get cacheWrite => 'Запись кэша';

  @override
  String get toolUsage => 'Использование инструментов';

  @override
  String get modelUsage => 'Использование моделей';

  @override
  String get noStatsAvailable => 'Статистика недоступна';

  @override
  String get reasoningTokens => 'Рассуждения';

  @override
  String get addProvider => 'Добавить провайдера';

  @override
  String get applySettings => 'Применить настройки';

  @override
  String get copyCodeTooltip => 'Копировать код';

  @override
  String get copiedFeedback => 'Скопировано';

  @override
  String get defaultSuggestion1 => 'Что ты умеешь?';

  @override
  String get defaultSuggestion2 => 'Помоги написать код';

  @override
  String get defaultSuggestion3 => 'Объясни концепцию';

  @override
  String get deleteChat => 'Удалить чат';

  @override
  String get manageProviders => 'Управление AI провайдерами';

  @override
  String get micAutoRestart => 'Автоперезапуск микрофона...';

  @override
  String get micNoSpeechDetected => 'Речь не обнаружена';

  @override
  String get micStartFailed => 'Не удалось запустить микрофон';

  @override
  String get micUnavailable => 'Микрофон недоступен';

  @override
  String get modelParameters => 'Параметры модели';

  @override
  String get modelSettings => 'Настройки модели';

  @override
  String get noInternetConnection => 'Нет подключения к интернету';

  @override
  String get noModelSelected => 'Модель не выбрана';

  @override
  String get openaiCompatibleApi => 'AI Провайдеры';

  @override
  String get openaiCompatibleApiDescription => 'Настройте AI провайдеров и управляйте их API ключами и моделями';

  @override
  String get permissionAlways => 'Всегда разрешать';

  @override
  String get permissionAlwaysConfirm => 'Всегда разрешать';

  @override
  String get permissionDialogPatterns => 'Запрос доступа к:';

  @override
  String get permissionOnce => 'Один раз';

  @override
  String get permissionReject => 'Отклонить';

  @override
  String get providers => 'Провайдеры';

  @override
  String get refreshQuestions => 'Обновить вопросы';

  @override
  String get resetToDefaults => 'Сбросить к умолчанию';

  @override
  String get settingsApplied => 'Настройки применены';

  @override
  String get speechErrorNetwork => 'Ошибка сети';

  @override
  String get speechErrorNoMatch => 'Речь не распознана';

  @override
  String get speechErrorNotAuthorized => 'Не авторизован';

  @override
  String get speechErrorServer => 'Ошибка сервера';

  @override
  String get speechErrorTimeout => 'Время ожидания истекло';

  @override
  String get speechErrorTooManyRequests => 'Слишком много запросов';

  @override
  String get speechErrorUnknown => 'Неизвестная ошибка';

  @override
  String get speechListening => 'Слушаю...';

  @override
  String get speechPhase2 => 'Я вас не слышу...говорите громче';

  @override
  String get speechPreparing => 'Подготовка...';

  @override
  String get speechProcessing => 'Обработка...';

  @override
  String speechStartError(Object error) {
    return 'Ошибка запуска: $error';
  }

  @override
  String get systemPrompt => 'Системный промпт';

  @override
  String get systemPromptDescription => 'Инструкции, определяющие поведение ИИ';

  @override
  String get systemPromptSuggestion => 'Ты полезный ассистент.';

  @override
  String get supportBecomeSponsor => 'Стать спонсором';

  @override
  String get supportProjectSubtitle => 'Если вам нравится ChatORAI, поддержите проект:';

  @override
  String get supportProjectTitle => 'Поддержите проект';

  @override
  String get supportShareThoughts => 'Поделиться мнением';

  @override
  String get supportStarOnGitHub => 'Поставить звезду на GitHub';

  @override
  String get temperature => 'Температура';

  @override
  String get temperatureDescription => 'Более высокие значения делают вывод более случайным';

  @override
  String get toggleNavigatorTooltip => 'Переключить навигацию';

  @override
  String get userPromptSuggestion => 'Чем могу помочь сегодня?';

  @override
  String get versionLabel => 'Версия:';

  @override
  String get welcomeGreeting1 => 'Добро пожаловать!';

  @override
  String get welcomeGreeting2 => 'Чем я могу помочь?';

  @override
  String get welcomeGreeting3 => 'Спросите меня о чем угодно';

  @override
  String get welcomeGreeting4 => 'Я могу помочь вам с кодированием, написанием и анализом.';

  @override
  String get welcomeGreeting5 => 'Давайте начнем';

  @override
  String get welcomeGreeting6 => 'Над чем хотите поработать?';

  @override
  String get welcomeGreeting7 => 'Готов помочь';

  @override
  String get welcomeGreeting8 => 'Ваш AI-компаньон здесь';

  @override
  String get welcomeGreeting9 => 'Начните разговор';

  @override
  String get welcomeGreeting10 => 'Узнайте, что я умею';

  @override
  String get welcomeGreeting11 => 'Нужна помощь? Просто спросите';

  @override
  String get welcomeGreeting12 => 'Я здесь, чтобы помочь';

  @override
  String modelDoesNotSupportFiles(Object modelId) {
    return 'Эта модель не поддерживает вложение файлов';
  }

  @override
  String generatingSuggestionsFailed(Object error) {
    return 'Не удалось сгенерировать предложения';
  }

  @override
  String get toggleSidebarTooltip => 'Переключить боковую панель';

  @override
  String get openMenuTooltip => 'Открыть меню';

  @override
  String get addFileTooltip => 'Добавить файл';

  @override
  String get modelSettingsTooltip => 'Настройки модели';

  @override
  String get switchAgentTooltip => 'Сменить агента';

  @override
  String get selectModelTooltip => 'Выбрать модель';

  @override
  String get removeFileTooltip => 'Удалить файл';

  @override
  String get goToParentSessionTooltip => 'Перейти к родительской сессии';

  @override
  String get previousSiblingTooltip => 'Предыдущий сеанс';

  @override
  String get nextSiblingTooltip => 'Следующий сеанс';

  @override
  String get cancellingRetryTooltip => 'Отмена повторной попытки...';

  @override
  String get stopGenerationTooltip => 'Остановить генерацию';

  @override
  String get question => 'Вопрос';

  @override
  String get skip => 'Пропустить';

  @override
  String get answer => 'Ответ';

  @override
  String get noAgentsAvailable => 'Нет доступных агентов';

  @override
  String permissionAlwaysConfirmDescription(Object title) {
    return 'Это позволит \"$title\" до перезапуска приложения.';
  }

  @override
  String get chatActionsMenuTooltip => 'Меню чата';

  @override
  String get startListening => 'Начать голосовой ввод';

  @override
  String get stopListening => 'Остановить голосовой ввод';

  @override
  String get listening => 'Говорите...';

  @override
  String get linkCancel => 'Отмена';

  @override
  String get linkCopied => 'Ссылка скопирована';

  @override
  String get linkOpen => 'Перейти';

  @override
  String get linkOpenFailed => 'Не удалось открыть ссылку';

  @override
  String get sendMessage => 'Отправить сообщение';

  @override
  String get maxTokens => 'Макс. токенов';

  @override
  String get maxTokensDescription => 'Максимальная длина генерируемого ответа';

  @override
  String get activeModel => 'Активная модель';

  @override
  String apiLimitExceeded(Object limit) {
    return 'Превышен лимит API: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return 'Значение превышает лимит API ($limit). Будет использовано максимальное значение.';
  }

  @override
  String get micStopFailed => 'Не удалось остановить микрофон';

  @override
  String get errorProcessingRequest => 'Извините, произошла ошибка при обработке вашего запроса. Пожалуйста, попробуйте еще раз.';

  @override
  String rateLimitRetryMessage(Object seconds) {
    return 'Превышен лимит запросов. Повторная попытка через $seconds секунд...';
  }

  @override
  String get messageNotFound => 'Сообщение не найдено';

  @override
  String get errorEditingMessage => 'Ошибка редактирования сообщения';

  @override
  String get errorEditAndSendMessage => 'Ошибка редактирования и отправки сообщения';

  @override
  String get defaultSuggestion4 => 'Как это применяется на практике?';

  @override
  String get fileAttachedButNotSupported => 'Файл прикреплен, но не поддерживается текущей моделью';

  @override
  String get expandTooltip => 'Развернуть';

  @override
  String get collapseTooltip => 'Свернуть';

  @override
  String get addProviderTitleEdit => 'Редактировать провайдера';

  @override
  String get addProviderTitleAdd => 'Добавить провайдера';

  @override
  String get addProviderLabelProvider => 'Провайдер';

  @override
  String get addProviderCustomName => 'Свой провайдер...';

  @override
  String get addProviderFieldProviderName => 'Название провайдера';

  @override
  String get addProviderHintProviderName => 'например, Мой кастомный AI';

  @override
  String get addProviderLabelApiKey => 'API ключ';

  @override
  String get addProviderHintApiKey => 'Введите ваш API ключ';

  @override
  String get addProviderHintCustomApiKey => 'Необязательно для локальных провайдеров';

  @override
  String get addProviderLabelBaseUrl => 'Базовый URL';

  @override
  String get addProviderHintBaseUrl => 'https://api.example.com/v1';

  @override
  String get addProviderActionSave => 'Сохранить';

  @override
  String get addProviderErrorApiKeyRequired => 'Требуется API ключ';

  @override
  String get selectModels => 'Выбор моделей';

  @override
  String get deselectAll => 'Снять выделение';

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get modelsAvailable => 'Нет доступных моделей';

  @override
  String get modelsMatchSearch => 'Нет моделей, соответствующих поиску';

  @override
  String selectModelsCount(Object count, Object total) {
    return 'Выбрано $count из $total';
  }

  @override
  String modelsLoadError(Object error) {
    return 'Ошибка загрузки моделей: $error';
  }

  @override
  String get systemPromptHint => 'Вы полезный ассистент...';

  @override
  String get temperatureHint => '0.0 - 2.0';

  @override
  String get loadingSettings => 'Загрузка настроек...';

  @override
  String errorApplyingSettings(Object error) {
    return 'Ошибка применения настроек: $error';
  }

  @override
  String deleteProviderTitle(Object providerName) {
    return 'Удалить $providerName?';
  }

  @override
  String get deleteProviderContent => 'Это удалит провайдера и все его настройки. Вам нужно будет добавить его снова, чтобы использовать его модели.';

  @override
  String get errorLoadingProviders => 'Ошибка загрузки провайдеров';

  @override
  String get noProvidersConfigured => 'Нет настроенных провайдеров';

  @override
  String get addProviderToGetStarted => 'Добавьте провайдера с API ключом, чтобы начать';

  @override
  String statsError(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get total => 'Всего';

  @override
  String modelsProviderCountFormat(Object count, Object providerName) {
    return '$providerName · $count';
  }

  @override
  String get mcpServers => 'MCP-серверы';

  @override
  String get mcpAddServer => 'Добавить MCP-сервер';

  @override
  String get mcpAddServerTitle => 'Добавить MCP-сервер';

  @override
  String get mcpNameLabel => 'Имя';

  @override
  String get mcpNameHint => 'напр. filesystem';

  @override
  String get mcpNameHelper => 'Уникальный идентификатор в chatorai.json';

  @override
  String get mcpTypeLocal => 'Локальный';

  @override
  String get mcpTypeRemote => 'Удалённый';

  @override
  String get mcpTypeLocalTooltip => 'Запускается на вашем компьютере';

  @override
  String get mcpTypeRemoteTooltip => 'HTTP/SSE эндпоинт';

  @override
  String get mcpCommandLabel => 'Команда';

  @override
  String get mcpCommandHint => 'uvx mcp-server-filesystem ~/docs';

  @override
  String get mcpCommandHelper => 'Полная команда с аргументами через пробел';

  @override
  String get mcpUrlLabel => 'URL';

  @override
  String get mcpUrlHint => 'https://example.com/mcp';

  @override
  String get mcpUrlHelper => 'Полный URL MCP-эндпоинта';

  @override
  String get mcpEnvLabel => 'Переменные окружения (JSON)';

  @override
  String get mcpEnvHint => 'GITHUB_TOKEN=ghp_xxx';

  @override
  String get mcpEnvHelper => 'Необязательно. Вставьте JSON-объект со строковыми ключами, напр. одну запись TOKEN.';

  @override
  String get mcpTokenLabel => 'Токен доступа';

  @override
  String get mcpTokenHint => 'Вставьте только токен (без Bearer / кавычек)';

  @override
  String get mcpTokenHelper => 'Необязательно. Оставьте пустым для публичных серверов; вставьте только токен — заголовок добавляется автоматически.';

  @override
  String get mcpAuthTypeLabel => 'Тип токена';

  @override
  String get mcpAuthTypeHelper => 'Как отправляется токен: Bearer (Authorization), ApiKey (X-Api-Key) или просто Token.';

  @override
  String get mcpHeadersLabel => 'Заголовки (JSON)';

  @override
  String get mcpHeadersHint => 'Authorization=Bearer token';

  @override
  String get mcpHeadersHelper => 'Необязательно. Вставьте JSON-объект заголовков.';

  @override
  String get mcpFormTab => 'Форма';

  @override
  String get mcpRawTab => 'Сырой JSON';

  @override
  String get mcpRawLabel => 'Объект сервера (JSON)';

  @override
  String get mcpRawHelper => 'Вставьте объект сервера как в документации — имя сервера — внешний ключ (напр. searxng). Можно вставить весь блок вместе с обёрткой mcpServers.';

  @override
  String mcpParseError(Object field, Object message) {
    return 'Некорректный JSON в $field: $message';
  }

  @override
  String get mcpAddAction => 'Добавить';

  @override
  String get mcpCancelAction => 'Отмена';

  @override
  String get mcpRemoveTitle => 'Удалить MCP-сервер?';

  @override
  String mcpRemoveContent(Object name) {
    return 'Удалить \"$name\" из chatorai.json?';
  }

  @override
  String get mcpRemoveAction => 'Удалить';

  @override
  String get mcpEditAction => 'Изменить';

  @override
  String get mcpEditServerTitle => 'Изменить MCP-сервер';

  @override
  String get mcpSaveAction => 'Сохранить';

  @override
  String get mcpNoServers => 'MCP-серверы не настроены';

  @override
  String get mcpNoServersHint => 'Добавьте MCP-сервер для расширения инструментов';

  @override
  String get mcpTooltipAdd => 'Добавить сервер';

  @override
  String get mcpTooltipRefresh => 'Обновить';

  @override
  String get mcpMarketplaceTab => 'Каталог';

  @override
  String get mcpInstalledTab => 'Установлено';

  @override
  String get mcpInstall => 'Установить';

  @override
  String get mcpInstalled => 'Установлено';

  @override
  String get mcpMarketplaceSearchHint => 'Поиск серверов…';

  @override
  String get mcpMarketplaceEmpty => 'Нет серверов по вашему запросу';

  @override
  String get mcpMarketCategoryAll => 'Все';

  @override
  String get mcpMarketCategorySearch => 'Поиск';

  @override
  String get mcpMarketCategoryDocs => 'Документация';

  @override
  String get mcpMarketCategoryDesign => 'Дизайн';

  @override
  String get mcpMarketCategoryDev => 'Разработка';

  @override
  String get mcpMarketCategoryFinance => 'Финансы';

  @override
  String get mcpMarketCategoryTravel => 'Путешествия';

  @override
  String get mcpMarketCategoryJobs => 'Работа';

  @override
  String get mcpMarketCategoryProductivity => 'Продуктивность';

  @override
  String get mcpMarketCategorySocial => 'Соцсети';

  @override
  String get mcpMarketCategoryOther => 'Прочее';

  @override
  String get mcpMarketNeedsToken => 'Нужен ключ';

  @override
  String get mcpMarketDescExa => 'Exa предоставляет возможности веб-поиска и поиска по документации кода для рабочих процессов ИИ. Её коннектор обеспечивает помощникам контекстную информацию в режиме реального времени для поиска релевантных веб-страниц, технической документации и исходных материалов, когда для ответа требуется обоснованная внешняя информация.';

  @override
  String get mcpMarketDescContext7 => 'Context7 предоставляет актуальные примеры кода и документацию для программистов и редакторов кода на базе ИИ. Его коннектор MCP интегрирует текущий контекст библиотеки в рабочие процессы помощника, сокращая переключение между вкладками и помогая сгенерированному коду избегать устаревших API, несуществующих методов и устаревших шаблонов реализации.';

  @override
  String get mcpMarketDescHuggingFace => 'Hugging Face подключает голосовых помощников к Hugging Face Hub и тысячам приложений Gradio. Его коннектор интегрирует контекст модели, набора данных, пространства и приложения в рабочие процессы ИИ для поиска, экспериментов и исследований в области машинного обучения.';

  @override
  String get mcpMarketDescParallel => 'Parallel Search обеспечивает поиск в интернете в реальном времени и извлечение контента для рабочих процессов ИИ, основанных на поиске. Его удалённый сервер MCP помогает ассистентам получать текущий контекст веб-страниц, проверять страницы и использовать извлечённый контент при ответе на вопросы или исследовании тем, требующих актуальной информации.';

  @override
  String get mcpMarketDescTavily => 'Tavily предоставляет агентам ИИ доступ к веб-ресурсам в реальном времени через API для поиска, извлечения и исследования информации. Его коннектор помогает ассистентам основывать ответы на данных в реальном времени, извлекать релевантный контент и поддерживать рабочие процессы агентов в производственной среде с помощью средств контроля безопасности.';

  @override
  String get mcpMarketDescGithub => 'GitHub — это платформа для совместной работы над кодом, задачами, запросами на слияние и историей проектов. Её официальный удалённый сервер MCP предоставляет помощникам структурированный контекст репозитория для понимания изменений в исходном коде, обзоров, рабочих процессов разработки и состояния работ по проектам GitHub.';

  @override
  String get mcpMarketDescPostman => 'Postman предоставляет контекст API для агентов кодирования и рабочих процессов разработчиков. Его коннектор интегрирует определения API, документацию и контекст совместной работы в работу ассистентов, позволяя агентам анализировать интеграции и детали реализации.';

  @override
  String get mcpMarketDescSlack => 'Slack — это центр для совместной работы, объединяющий командные сообщения, каналы, пользователей и общие рабочие пространства. Его удалённый сервер MCP интегрирует контекст общения в рабочем пространстве в рабочие процессы помощников, помогая пользователям находить решения, обобщать обсуждения и понимать активность в разных каналах.';

  @override
  String get mcpMarketDescFigma => 'Figma — это платформа для совместной разработки продуктов, предназначенная для проектирования интерфейсов, прототипирования и передачи результатов разработчикам. Её удалённый сервер MCP передаёт файлы, проекты и контекст режима разработки в рабочие процессы помощников, позволяя агентам понимать визуальную работу и соотносить её с задачами реализации.';

  @override
  String get mcpMarketDescCanva => 'Canva — это платформа визуальной коммуникации для создания презентаций, графики для социальных сетей, документов и фирменных материалов. Её удалённый MCP-сервер обеспечивает доступ ассистентов к проектам, ресурсам, экспортированным файлам и комментариям Canva, позволяя обсуждать, редактировать и подготавливать креативные работы на основе полученной информации.';

  @override
  String get mcpMarketDescStripe => 'Stripe — это платформа для платежей и финансовой инфраструктуры, предназначенная для обработки платежей, выставления счетов, работы с клиентами и подготовки документации для разработчиков. Её удалённый MCP-сервер предоставляет помощникам контекст учётных записей и реализации, поддерживаемый Stripe, для понимания рабочих процессов клиентов, вопросов, связанных с выставлением счетов, и задач, связанных с платежами.';

  @override
  String get mcpMarketDescTrivago => 'Trivago помогает пользователям искать отели и варианты размещения по координатам, городам, странам, датам и контексту путешествия. Его коннектор предоставляет помощникам контекст поиска жилья для нахождения подходящих вариантов размещения рядом с пунктами назначения или достопримечательностями.';

  @override
  String get mcpMarketDescSend => 'Send помогает пользователям создавать документы, которыми можно делиться, одностраничные документы, презентации и слайды. Его коннектор позволяет ассистентам преобразовывать запрошенные материалы в опубликованные ссылки, интерактивные страницы и отслеживаемые рекламные материалы для получателей.';

  @override
  String get mcpMarketDescZiprecruiter => 'ZipRecruiter помогает пользователям искать актуальные вакансии по названию, компании, местоположению, зарплате, расстоянию, стилю работы, типу занятости и дате публикации. Его коннектор интегрирует контекст поиска работы в рабочие процессы помощника, прежде чем передать заявки обратно в ZipRecruiter.';

  @override
  String get mcpMarketDescAdobeCreativity => 'Adobe для творчества объединяет возможности Photoshop, Lightroom, Illustrator, Firefly, Premiere, Express, InDesign и Stock с творческой работой, выполняемой с помощью искусственного интеллекта. Пользователи могут создавать, редактировать и улучшать фотографии, дизайнерские материалы и видеопроекты, используя естественный язык, при этом работа остаётся привязанной к учётной записи Adobe.';

  @override
  String get mcpInstallToGlobal => 'Установить глобально';

  @override
  String get mcpInstallToProject => 'Установить в проект';

  @override
  String get mcpScopeGlobal => 'Глобально';

  @override
  String get mcpScopeProject => 'Проект';

  @override
  String get mcpScopeGlobalProject => 'Глобально + Проект';

  @override
  String mcpRemoveFromScope(String scope) {
    return 'Удалить из $scope';
  }

  @override
  String get mcpRemoveFromAll => 'Удалить из всех';

  @override
  String get mcpTokenDialogTitle => 'Аутентификация';

  @override
  String get mcpTokenDialogTitleHint => 'Выберите способ аутентификации с сервером';

  @override
  String get mcpTokenInputLabel => 'Токен';

  @override
  String get mcpTokenInputHint => 'Вставьте токен доступа';

  @override
  String get mcpTokenInputHelper => 'Отправляется как Authorization: Bearer <token>';

  @override
  String get mcpOAuthClientIdLabel => 'Client ID';

  @override
  String get mcpOAuthClientIdHint => 'Client ID для OAuth 2.1';

  @override
  String get mcpOAuthClientSecretLabel => 'Client Secret';

  @override
  String get mcpOAuthClientSecretHint => 'Client Secret для OAuth 2.1 (необязательно)';

  @override
  String get mcpOAuthScopeLabel => 'Scope';

  @override
  String get mcpOAuthScopeHint => 'например read write';

  @override
  String get mcpAuthConfirm => 'Подтвердить';

  @override
  String get agentsInstructions => 'Инструкции для агентов';

  @override
  String get agentsInstructionsSubtitle => 'Управление AGENTS.md и файлами инструкций';

  @override
  String get agentsMdHint => '# Правила проекта\n- Кратко\n- Сначала тесты';

  @override
  String get agentsMdSaved => 'AGENTS.md сохранён';

  @override
  String get instructionsAutoDetectedTitle => 'Обнаруженные файлы';

  @override
  String get instructionsAutoDetectedHelper => 'Найденные для этой области AGENTS.md и CLAUDE.md. Нажмите для просмотра или редактирования.';

  @override
  String get instructionsFileNotCreated => 'Ещё не создан';

  @override
  String get instructionsFileReadOnly => 'Только чтение';

  @override
  String get instructionsBadgeGlobal => 'Глобально';

  @override
  String get instructionsBadgeProject => 'Проект';

  @override
  String get instructionsViewFile => 'Просмотр';

  @override
  String get instructionsEditFile => 'Изменить';

  @override
  String get instructionsSectionTitle => 'Файлы инструкций';

  @override
  String get instructionsSectionHelper => 'Дополнительные Markdown-файлы добавляются после AGENTS.md по порядку.';

  @override
  String get instructionsAdd => 'Добавить инструкцию';

  @override
  String get instructionsAddInline => 'Написать вручную';

  @override
  String get instructionsUploadFile => 'Загрузить .md файл';

  @override
  String get instructionsEmpty => 'Пока нет файлов инструкций';

  @override
  String get instructionsEmptyHint => 'Добавьте инструкцию вручную или загрузите Markdown-файл.';

  @override
  String get instructionsNameLabel => 'Название';

  @override
  String get instructionsNameHint => 'coding-style';

  @override
  String get instructionsContentLabel => 'Содержимое';

  @override
  String get instructionsContentHint => 'Напишите инструкции в Markdown…';

  @override
  String get instructionsAddedInline => 'Инструкция добавлена';

  @override
  String instructionsAddedFile(Object name) {
    return 'Файл добавлен: $name';
  }

  @override
  String get instructionsRemoveTitle => 'Удалить инструкцию';

  @override
  String instructionsRemoveContent(Object name) {
    return 'Удалить «$name» из инструкций?';
  }

  @override
  String get instructionsRemoved => 'Инструкция удалена';

  @override
  String get instructionsEditTitle => 'Изменить путь инструкции';

  @override
  String get instructionsPathLabel => 'Путь';

  @override
  String get instructionsUpdated => 'Инструкция обновлена';

  @override
  String get instructionsScopeGlobal => 'Глобально';

  @override
  String get instructionsScopeProject => 'Проект';

  @override
  String get instructionsScopeGlobalHint => 'Применяется везде. Хранится в пользовательской конфигурации.';

  @override
  String get instructionsScopeProjectHint => 'Применяется к текущей папке проекта.';

  @override
  String get instructionsCreateAgents => 'Создать AGENTS.md';

  @override
  String instructionsSaveError(Object error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String get configScopeGlobal => 'Глобально';

  @override
  String get configScopeProject => 'Проект';

  @override
  String get configProjectOverrides => 'Настройки проекта переопределяют глобальные.';

  @override
  String get configPathLabel => 'Путь';

  @override
  String get configStatusLabel => 'Статус';

  @override
  String get configContentsTitle => 'Содержимое файла';

  @override
  String get configExists => 'Существует';

  @override
  String get configNotFound => 'Не найдено';

  @override
  String get configWillBeCreated => 'Будет создан при сохранении.';

  @override
  String get skillsTitle => 'Навыки';

  @override
  String get skillsSubtitle => 'Готовые наборы возможностей, которые ассистент подключает по запросу.';

  @override
  String get skillsSectionTitle => 'Установленные навыки';

  @override
  String get skillsSectionHelper => 'Каждый навык — это папка с файлом SKILL.md. Добавьте свой или установите по URL.';

  @override
  String get skillsNewSkill => 'Новый навык';

  @override
  String get skillsInstallFromUrl => 'Установить по URL';

  @override
  String get skillsNameLabel => 'Название';

  @override
  String get skillsNameHint => 'напр. Ревьюер кода';

  @override
  String get skillsDescriptionLabel => 'Описание';

  @override
  String get skillsDescriptionHint => 'Кратко о том, что делает навык';

  @override
  String get skillsContentLabel => 'Содержимое SKILL.md';

  @override
  String get skillsContentHint => '# Заголовок\nИнструкции для ассистента…';

  @override
  String get skillsUrlLabel => 'URL файла index.json';

  @override
  String get skillsUrlHint => 'https://example.com/skills';

  @override
  String get skillsApiKeyLabel => 'API-ключ (необязательно)';

  @override
  String get skillsReadOnly => 'Только чтение';

  @override
  String skillsFilesCount(int count) {
    return 'Файлов: $count';
  }

  @override
  String get skillsCreated => 'Навык создан';

  @override
  String get skillsSaved => 'Навык сохранён';

  @override
  String get skillsRemoved => 'Навык удалён';

  @override
  String skillsInstalled(int count) {
    return 'Установлено навыков: $count';
  }

  @override
  String get skillsInstallNone => 'По этому URL навыки не найдены';

  @override
  String get skillsRemoveTitle => 'Удалить навык';

  @override
  String skillsRemoveContent(String name) {
    return 'Удалить «$name»? Папка навыка будет удалена с диска.';
  }

  @override
  String skillsSaveError(String error) {
    return 'Не удалось выполнить: $error';
  }

  @override
  String get skillsEmpty => 'Пока нет навыков';

  @override
  String get skillsEmptyHint => 'Создайте навык или установите его по URL, чтобы начать.';

  @override
  String get skillsMarketplaceTab => 'Маркетплейс';

  @override
  String get skillsMarketplaceSearchHint => 'Поиск навыков';

  @override
  String get skillsMarketplaceEmpty => 'Ничего не найдено по запросу.';

  @override
  String get skillsInstalledBadge => 'Установлено';

  @override
  String get skillsInstallAction => 'Установить';

  @override
  String get skillsInstallToGlobal => 'Установить в Global';

  @override
  String get skillsInstallToProject => 'Установить в Project';

  @override
  String skillsInstalledToast(String name) {
    return '$name · установлено';
  }

  @override
  String get skillsTabGlobalTooltip => 'Навыки, доступные во всех проектах';

  @override
  String get skillsTabProjectTooltip => 'Навыки только для этого проекта';

  @override
  String get skillsTabMarketplaceTooltip => 'Просмотр и установка готовых навыков';

  @override
  String get skillsPreviewClose => 'Закрыть';

  @override
  String get skillsCategoryAll => 'Все';

  @override
  String get skillsCategoryCoding => 'Код';

  @override
  String get skillsCategoryWriting => 'Тексты';

  @override
  String get skillsCategoryResearch => 'Исследования';

  @override
  String get skillsCategoryDesign => 'Дизайн';

  @override
  String get skillsCategoryProductivity => 'Продуктивность';

  @override
  String get skillsCategoryData => 'Данные';

  @override
  String get skillsCategoryOther => 'Другое';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get commonRemove => 'Удалить';

  @override
  String get commonEdit => 'Изменить';

  @override
  String get toolResultOriginal => 'Оригинал';

  @override
  String get toolResultRestore => 'Вернуть';

  @override
  String get toolResultRestoredSnackbar => 'Файлы восстановлены до состояния перед редактированием';

  @override
  String get toolResultOriginalTitle => 'Исходное содержимое перед редактированием';

  @override
  String restoreFailed(String error) {
    return 'Не удалось восстановить: $error';
  }

  @override
  String get compactingIndicator => 'Сжатие...';

  @override
  String get compactionAgentName => 'Сжатие';

  @override
  String get workspaces => 'Рабочие директории';

  @override
  String get directoryTitle => 'Каталог';

  @override
  String get searchDirectories => 'Поиск каталогов';

  @override
  String get addDirectory => 'Добавить директорию';

  @override
  String get removeDirectory => 'Удалить директорию';

  @override
  String get noWorkspacesFound => 'Директории не найдены';

  @override
  String get switchWorkspaceTitle => 'Переключить рабочую директорию';

  @override
  String get currentSessionWillBeStopped => 'Текущая сессия будет остановлена.';

  @override
  String get continueText => 'Продолжить';

  @override
  String get changeWorkingDirectory => 'Сменить текущую директорию';

  @override
  String get sessionsTitle => 'Сессии';

  @override
  String get noSessions => 'Сессий пока нет';

  @override
  String get searchSessions => 'Поиск сессий';

  @override
  String get newSession => 'Новая сессия';

  @override
  String get autoApproveTitle => 'Автоподтверждение';

  @override
  String get autoApproveSubtitle => 'Настройка автоматического подтверждения разрешений';

  @override
  String get autoApproveExternalDirectoryDesc => 'Разрешить доступ к внешним директориям';

  @override
  String get autoApproveShellDesc => 'Разрешить выполнение shell-команд';

  @override
  String get autoApproveReadDesc => 'Разрешить чтение файлов';

  @override
  String get autoApproveEditDesc => 'Разрешить редактирование файлов';

  @override
  String get autoApproveWriteDesc => 'Разрешить запись файлов';

  @override
  String get autoApproveGlobDesc => 'Разрешить glob-поиск';

  @override
  String get autoApproveGrepDesc => 'Разрешить grep-поиск';

  @override
  String get autoApproveWebsearchDesc => 'Разрешить веб-поиск';

  @override
  String get autoApproveWebfetchDesc => 'Разрешить загрузку веб-страниц';

  @override
  String get autoApproveDoomLoopDesc => 'Разрешить обнаружение doom loop';

  @override
  String get autoApproveSkillDesc => 'Разрешить выполнение навыков';

  @override
  String get autoApproveLspDesc => 'Разрешить использование LSP';

  @override
  String get autoApproveTaskDesc => 'Разрешить использование task';

  @override
  String get autoApproveTodowriteDesc => 'Разрешить операции с todo';

  @override
  String get exceptionsTitle => 'Исключения';

  @override
  String get addPath => 'Добавить путь';

  @override
  String get addCommand => 'Добавить команду';

  @override
  String get scopeGlobal => 'Глобально';

  @override
  String get scopeProject => 'Проект';

  @override
  String get defaultInherit => 'По умолчанию (унаследовать)';

  @override
  String get defaultAllow => 'Разрешить';

  @override
  String get defaultAsk => 'Спрашивать';

  @override
  String get defaultDeny => 'Запретить';

  @override
  String autoApproveDefaultInherited(Object action) {
    return 'По умолчанию ($action)';
  }

  @override
  String get autoApproveGroupFileAccess => 'Доступ к файлам';

  @override
  String get autoApproveGroupShell => 'Оболочка и команды';

  @override
  String get autoApproveGroupNetwork => 'Сеть';

  @override
  String get autoApproveGroupAgents => 'Агенты и автоматизация';

  @override
  String get autoApproveCommandPatternLabel => 'Шаблон команды';

  @override
  String get autoApprovePathPatternLabel => 'Шаблон пути';

  @override
  String get autoApproveCommandPatternHint => 'git *';

  @override
  String get autoApprovePathPatternHint => '/home/**/*.txt';

  @override
  String get autoApproveScopeHint => 'Глобальные — везде · Проект — переопределяет для рабочей области';

  @override
  String get autoApproveNoExceptions => 'Нет исключений — для всех шаблонов действует умолчание';

  @override
  String get autoApproveBrowseDirectory => 'Выбрать директорию';

  @override
  String get autoApproveScopeProjectDisabledTooltip => 'Конфигурация проекта не найдена. Создайте .chatorai/chatorai.json для включения проектных разрешений.';

  @override
  String get autoApproveActionLabel => 'Action';

  @override
  String get autoApprovePatternHintFile => '/home/user/project/** • ~/Documents/*';

  @override
  String get autoApprovePatternHintCommand => 'npm run * • git status';

  @override
  String autoApproveError(Object error) {
    return 'Error: $error';
  }

  @override
  String get settingsMcpSubtitle => 'Manage Model Context Protocol tool servers';

  @override
  String get mcpAuthNoAuth => 'No Auth';

  @override
  String get mcpAuthToken => 'Token';

  @override
  String get mcpAuthOAuth => 'OAuth 2.1';

  @override
  String get statsInput => 'Input';

  @override
  String get statsOutput => 'Output';

  @override
  String get statsCacheRead => 'Cache Read';

  @override
  String get keyboardShortcuts => 'Горячие клавиши';

  @override
  String get keyboardShortcutsSubtitle => 'Настройка горячих клавиш приложения';

  @override
  String get keybindingsReadOnlyMobile => 'Горячие клавиши доступны только на настольных платформах';

  @override
  String get keyboardShortcutsResetConfirm => 'Вы уверены, что хотите сбросить все горячие клавиши к значениям по умолчанию?';

  @override
  String get bindingConflict => 'Конфликт';

  @override
  String get captureHint => 'Нажмите комбинацию клавиш...';

  @override
  String get shortcutCancelStreaming => 'Отменить ответ ИИ';

  @override
  String get shortcutCloseDialog => 'Закрыть диалог';

  @override
  String get shortcutOpenLatestChild => 'Открыть последнюю дочернюю сессию';

  @override
  String get shortcutNavPrevSibling => 'Предыдущая сессия-брат';

  @override
  String get shortcutNavNextSibling => 'Следующая сессия-брат';

  @override
  String get shortcutNavParent => 'Перейти к родительской сессии';

  @override
  String get shortcutCyclePrimaryAgent => 'Переключить основного агента';

  @override
  String get shortcutToggleSidebar => 'Переключить боковую панель';

  @override
  String get shortcutNewChat => 'Новый чат';

  @override
  String get shortcutOpenModelSelector => 'Открыть выбор модели';

  @override
  String get shortcutOpenSettings => 'Открыть настройки';

  @override
  String get shortcutOpenWorkspace => 'Открыть рабочую область';

  @override
  String get shortcutScrollToChatStart => 'Прокрутить вверх';

  @override
  String get shortcutScrollToChatEnd => 'Прокрутить вниз';
}
