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
  String get baseUrl => 'Base URL';

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
  String get startListening => 'Начать голосовой ввод';

  @override
  String get stopListening => 'Остановить голосовой ввод';

  @override
  String get listening => 'Говорите...';

  @override
  String get micUnavailable => 'Микрофон недоступен';

  @override
  String get sendMessage => 'Отправить сообщение';

  @override
  String get modelSettings => 'Настройки модели';

  @override
  String get temperature => 'Temperature';

  @override
  String get temperatureDescription => 'Контролирует случайность: ниже = более сфокусировано, выше = более креативно';

  @override
  String get maxTokens => 'Макс. токенов';

  @override
  String get maxTokensDescription => 'Максимальная длина генерируемого ответа';

  @override
  String get topP => 'Top P';

  @override
  String get topPDescription => 'Ядерная выборка: ниже = более сфокусировано, выше = более разнообразно';

  @override
  String get frequencyPenalty => 'Штраф за частоту';

  @override
  String get frequencyPenaltyDescription => 'Уменьшает повторение похожих токенов';

  @override
  String get presencePenalty => 'Штраф за присутствие';

  @override
  String get presencePenaltyDescription => 'Поощряет новые темы';

  @override
  String get systemPrompt => 'Системный промпт';

  @override
  String get systemPromptDescription => 'Инструкции для AI-ассистента';

  @override
  String get resetToDefaults => 'Сбросить к настройкам по умолчанию';

  @override
  String get applySettings => 'Применить настройки';

  @override
  String get modelParameters => 'Параметры модели';

  @override
  String get activeModel => 'Активная модель';

  @override
  String get noModelSelected => 'Модель не выбрана';

  @override
  String get settingsApplied => 'Настройки успешно применены';

  @override
  String apiLimitExceeded(Object limit) {
    return 'Превышен лимит API: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return 'Значение превышает лимит API ($limit). Будет использовано максимальное значение.';
  }

  @override
  String get micStartFailed => 'Не удалось запустить микрофон';

  @override
  String get micStopFailed => 'Не удалось остановить микрофон';

  @override
  String get speechErrorNoMatch => 'Не удалось распознать речь. Попробуйте еще раз.';

  @override
  String get speechErrorTimeout => 'Время ожидания истекло. Ничего не услышали.';

  @override
  String get speechErrorNetwork => 'Ошибка сети. Проверьте подключение к интернету.';

  @override
  String get speechErrorNotAuthorized => 'Нет доступа к микрофону. Проверьте разрешения в настройках.';

  @override
  String get speechErrorServer => 'Ошибка сервера распознавания. Попробуйте позже.';

  @override
  String get speechErrorTooManyRequests => 'Слишком много запросов. Попробуйте позже.';

  @override
  String get speechErrorUnknown => 'Ошибка распознавания речи';

  @override
  String get speechPreparing => 'Подготовка...';

  @override
  String get speechListening => 'Говорите...';

  @override
  String get speechProcessing => 'Обрабатываю...';

  @override
  String get micNoSpeechDetected => 'Я вас не услышал. Попробуйте еще раз.';

  @override
  String get micAutoRestart => 'Повторная попытка...';

  @override
  String get speechPhase2 => 'Я вас не слышу...говорите громче';

  @override
  String speechStartError(Object error) {
    return 'Ошибка запуска: $error';
  }

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
  String generatingSuggestionsFailed(Object error) {
    return 'Не удалось сгенерировать предложения: $error';
  }

  @override
  String get selectModelTooltip => 'Выбрать модель';

  @override
  String get toggleNavigatorTooltip => 'Переключить навигатор';

  @override
  String get defaultSuggestion1 => 'Расскажите подробнее об этой теме';

  @override
  String get defaultSuggestion2 => 'Можете привести примеры?';

  @override
  String get defaultSuggestion3 => 'Какие есть альтернативы?';

  @override
  String get defaultSuggestion4 => 'Как это применяется на практике?';

  @override
  String get systemPromptSuggestion => 'Ты — полезный ассистент. Продолжи диалог, предложив 3 конкретных и логичных продолжения последнего сообщения. Отвечай на русском языке.';

  @override
  String get userPromptSuggestion => 'Предложи 3 конкретных и логичных продолжения для этого сообщения. Отвечай только списком, без дополнительного текста.';

  @override
  String get refreshQuestions => 'Обновить вопросы';

  @override
  String get noInternetConnection => 'Нет подключения к интернету';

  @override
  String modelDoesNotSupportFiles(Object modelId) {
    return 'Модель $modelId не поддерживает файлы. Вы можете прикрепить файл, но отправка не сработает.';
  }

  @override
  String get fileAttachedButNotSupported => 'Файл прикреплен, но не поддерживается текущей моделью';

  @override
  String get copyCodeTooltip => 'Копировать код';

  @override
  String get expandTooltip => 'Развернуть';

  @override
  String get collapseTooltip => 'Свернуть';

  @override
  String get welcomeGreeting1 => 'Спрашивайте, исследуйте, создавайте — давайте разберёмся вместе.';

  @override
  String get welcomeGreeting2 => 'Задайте вопрос, опишите задачу или просто начните разговор.';

  @override
  String get welcomeGreeting3 => 'Задайте вопрос или начните исследование.';

  @override
  String get welcomeGreeting4 => 'Задайте любой вопрос, поделитесь идеей или попросите помощи — я здесь, чтобы помочь.';

  @override
  String get welcomeGreeting5 => 'Есть идея? Давайте разберём.';

  @override
  String get welcomeGreeting6 => 'Задайте направление для разговора.';

  @override
  String get welcomeGreeting7 => 'Что сегодня исследуем?';

  @override
  String get welcomeGreeting8 => 'Напишите мысль. Разберём её вместе.';

  @override
  String get welcomeGreeting9 => 'Любопытство приветствуется.';

  @override
  String get welcomeGreeting10 => 'Ваш вопрос — мой следующий ответ.';

  @override
  String get welcomeGreeting11 => 'Давайте превратим идею в ответ.';

  @override
  String get welcomeGreeting12 => 'Введите вопрос. Остальное — моя работа.';

  @override
  String get versionLabel => 'Версия:';
}
