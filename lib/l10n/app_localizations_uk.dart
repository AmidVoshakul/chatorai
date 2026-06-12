// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appName => 'ChatORAI';

  @override
  String get settings => 'Налаштування';

  @override
  String get providerConfiguration => 'Конфігурація провайдера';

  @override
  String get apiKey => 'API ключ';

  @override
  String get enterApiKey => 'Введіть ваш OpenRouter API ключ';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get validateApiKey => 'Перевірити API ключ';

  @override
  String get apiKeyValid => 'API ключ валідний';

  @override
  String get apiKeyInvalid => 'Невірний формат API ключа';

  @override
  String get apiKeyEmpty => 'API ключ не може бути порожнім';

  @override
  String get appearance => 'Зовнішній вигляд';

  @override
  String get theme => 'Тема';

  @override
  String get system => 'Системна';

  @override
  String get useSystemTheme => 'Використовувати системну тему';

  @override
  String get light => 'Світла';

  @override
  String get useLightTheme => 'Використовувати світлу тему';

  @override
  String get dark => 'Темна';

  @override
  String get useDarkTheme => 'Використовувати темну тему';

  @override
  String get fontSize => 'Розмір шрифту';

  @override
  String currentSize(Object percentage) {
    return 'Поточний розмір: $percentage%';
  }

  @override
  String get accessibility => 'Доступність';

  @override
  String get reduceMotion => 'Зменшити рух';

  @override
  String get disableAnimation => 'Вимкнути або зменшити ефекти анімації';

  @override
  String get highContrast => 'Висока контрастність';

  @override
  String get increaseContrast =>
      'Збільшити контрастність для кращої читабельності';

  @override
  String get wideScreenMode => 'Режим широкого екрану';

  @override
  String get useFullScreenWidth => 'Використовувати всю ширину екрану для чату';

  @override
  String get autoScrollDuringStreaming => 'Автоскрол під час стрімінгу';

  @override
  String get autoScrollDuringStreamingDesc =>
      'Автоматично прокручувати список вниз при появи нового контенту';

  @override
  String get language => 'Мова';

  @override
  String get english => 'Англійська';

  @override
  String get russian => 'Російська';

  @override
  String get ukrainian => 'Українська';

  @override
  String get arabic => 'Арабська (RTL)';

  @override
  String get chinese => 'Китайська';

  @override
  String get japanese => 'Японська';

  @override
  String get resetSettings => 'Скинути налаштування';

  @override
  String get resetAllSettings =>
      'Скинути всі налаштування до значень за замовчуванням';

  @override
  String get save => 'Зберегти';

  @override
  String get cancel => 'Скасувати';

  @override
  String get close => 'Закрити';

  @override
  String get copy => 'Копіювати';

  @override
  String get apiKeyCopied => 'API ключ скопійовано';

  @override
  String get apiKeySaved => 'API ключ успішно збережено';

  @override
  String get settingsSaved => 'Налаштування збережено!';

  @override
  String get settingsReset =>
      'Налаштування скинуто до значень за замовчуванням';

  @override
  String get appInfo => 'Інформація';

  @override
  String get appDescription =>
      'Додаток для спілкування з AI моделями через OpenRouter API.\n\nМожливості:\n• Спілкування з різними AI моделями\n• Збереження історії чатів\n• Темна та світла теми\n• Адаптивний інтерфейс\n\nРозроблено з ❤️ з використанням Flutter';

  @override
  String get shareChat => 'Поділитися чатом';

  @override
  String get copyChat => 'Копіювати чат';

  @override
  String get renameChat => 'Перейменувати чат';

  @override
  String get deleteChat => 'Видалити чат';

  @override
  String get failedToShowMenu => 'Не вдалося показати меню';

  @override
  String get failedToRenameChat => 'Не вдалося перейменувати чат';

  @override
  String get failedToCopyChat => 'Не вдалося скопіювати чат';

  @override
  String get chatSharingNotImplemented =>
      'Спільний доступ до чату ще не реалізовано';

  @override
  String get newChat => 'Новий чат';

  @override
  String get noChatsYet => 'Чатів ще немає';

  @override
  String get startConversation => 'Начните разговор, нажав \"Новый чат\"';

  @override
  String get reasoning => 'Міркування';

  @override
  String get tapToExpand => 'Натисніть для розгортання';

  @override
  String get collapse => 'Згорнути';

  @override
  String get expand => 'Розгорнути';

  @override
  String chatRenamedTo(Object title) {
    return 'Чат перейменовано на: $title';
  }

  @override
  String get appTitle => 'Чат AI';

  @override
  String get justNow => 'Щойно';

  @override
  String minAgo(Object minutes) {
    return '$minutes хв тому';
  }

  @override
  String get onlyOneMinuteAgo => '1 хв тому';

  @override
  String hoursAgo(Object hours) {
    return '$hours годин тому';
  }

  @override
  String get onlyOneHourAgo => '1 годину тому';

  @override
  String daysAgo(Object days) {
    return '$days днів тому';
  }

  @override
  String get onlyOneDayAgo => '1 день тому';

  @override
  String get renameChatTitle => 'Перейменувати чат';

  @override
  String get enterNewChatName => 'Введіть нову назву чату';

  @override
  String get rename => 'Перейменувати';

  @override
  String get ok => 'OK';

  @override
  String get modelSelected => 'Модель вибрано';

  @override
  String get errorLoadingModels => 'Помилка завантаження моделей';

  @override
  String get models => 'Моделі';

  @override
  String get searchModels => 'Пошук моделей';

  @override
  String get refresh => 'Оновити';

  @override
  String get details => 'Деталі';

  @override
  String get context => 'Контекст';

  @override
  String get free => 'Безкоштовно';

  @override
  String get paid => 'Платно';

  @override
  String get multimodal => 'Мультимодальна';

  @override
  String get vision => 'Зір';

  @override
  String get tools => 'Інструменти';

  @override
  String get available => 'Доступно';

  @override
  String get description => 'Опис';

  @override
  String get technicalDetails => 'Технічні деталі';

  @override
  String get provider => 'Провайдер';

  @override
  String get inputTokens => 'Токени вводу';

  @override
  String get notAvailable => 'Недоступно';

  @override
  String get outputTokens => 'Токени виводу';

  @override
  String get features => 'Можливості';

  @override
  String get featuresDisplayedBasedOnActualModelCapabilities =>
      'Можливості відображаються на основі реальних можливостей моделі';

  @override
  String get noModelsFound => 'Моделі не знайдено';

  @override
  String get noAvailableModels => 'Немає доступних моделей';

  @override
  String get tryADifferentSearchQuery => 'Спробуйте інший пошуковий запит';

  @override
  String get tryRefreshingOrCheckYourInternetConnection =>
      'Спробуйте оновити або перевірте інтернет-з\'єднання';

  @override
  String get aiIsTyping => 'AI друкує';

  @override
  String get failedToSendMessage => 'Не вдалося надіслати повідомлення';

  @override
  String get retry => 'Повторити';

  @override
  String get enterYourMessage => 'Введіть ваше повідомлення...';

  @override
  String get saveAndSend => 'Зберегти та надіслати';

  @override
  String get messageEditedSuccessfully => 'Повідомлення успішно відредаговано';

  @override
  String get failedToEditMessage => 'Не вдалося відредагувати повідомлення';

  @override
  String get messageEditedAndResponseRegenerated =>
      'Повідомлення відредаговано та відповідь перегенеровано';

  @override
  String get failedToEditAndSendMessage =>
      'Не вдалося відредагувати та надіслати повідомлення';

  @override
  String get areYouSureYouWantToDeleteThisMessage =>
      'Ви впевнені, що хочете видалити це повідомлення?';

  @override
  String confirmDeleteMessage(Object chatTitle) {
    return 'Ви впевнені, що хочете видалити чат \"$chatTitle\"?';
  }

  @override
  String get areYouSureYouWantToRegenerateThisMessage =>
      'Ви впевнені, що хочете перегенерувати це повідомлення?';

  @override
  String modelDoesNotSupportImages(Object modelId) {
    return 'Модель $modelId не підтримує зображення. Ви можете прикріпити фото, але відправлення не спрацює.';
  }

  @override
  String chatTitleUpdated(Object title) {
    return 'Чат перейменовано на: $title';
  }

  @override
  String get messageDeletedSuccessfully => 'Повідомлення успішно видалено';

  @override
  String get failedToDeleteMessage => 'Не вдалося видалити повідомлення';

  @override
  String get regenerationStarted => 'Перегенерація розпочата';

  @override
  String get failedToRegenerateMessage =>
      'Не вдалося перегенерувати повідомлення';

  @override
  String get messageCopied => 'Повідомлення скопійовано';

  @override
  String get failedToCopyMessage => 'Не вдалося скопіювати повідомлення';

  @override
  String get messageShared => 'Повідомлення поширено';

  @override
  String get failedToShareMessage => 'Не вдалося поділитися повідомленням';

  @override
  String get edit => 'Редагувати';

  @override
  String get share => 'Поділитися';

  @override
  String get copyMessage => 'Копіювати повідомлення';

  @override
  String get delete => 'Видалити';

  @override
  String get listen => 'Слухати';

  @override
  String get regenerate => 'Перегенерувати';

  @override
  String get continueResponse => 'Продовжити відповідь';

  @override
  String get like => 'Подобається';

  @override
  String get dislike => 'Не подобається';

  @override
  String get copiedToClipboard => 'Скопійовано в буфер обміну';

  @override
  String get failedToCopy => 'Не вдалося скопіювати';

  @override
  String get messageDeleted => 'Повідомлення видалено';

  @override
  String get errorMessage => 'Повідомлення про помилку';

  @override
  String get welcomeMessage => 'Вітаю! Чим я можу вам допомогти сьогодні?';

  @override
  String get welcomeQuestion1 =>
      'Поясніть квантові обчислення простими словами';

  @override
  String get welcomeQuestion2 => 'Які останні тенденції в штучному інтелекті?';

  @override
  String get welcomeQuestion3 =>
      'Допоможіть мені написати професійний email до моєї команди';

  @override
  String get welcomeQuestion4 =>
      'Що мені вчити, щоб стати кращим програмістом?';

  @override
  String get welcomeQuestion5 =>
      'Дайте мені 5 креативних ідей для вихідного проекту';

  @override
  String get welcomeQuestion6 =>
      'Які є хороші книги для особистісного розвитку?';

  @override
  String get welcomeQuestion7 =>
      'Допоможіть мені придумати назви для мого стартапу';

  @override
  String get welcomeQuestion8 => 'Створіть план харчування на здоровий тиждень';

  @override
  String get welcomeQuestion9 =>
      'Які найкращі практики для розробки на Flutter?';

  @override
  String get welcomeQuestion10 =>
      'Поясніть різницю між асинхронним та синхронним програмуванням';

  @override
  String get welcomeQuestion11 =>
      'Як оптимізувати код для кращої продуктивності?';

  @override
  String get welcomeQuestion12 => 'Які найкорисніші шаблони проектування?';

  @override
  String get welcomeQuestion13 => 'Навчіть мене основ машинного навчання';

  @override
  String get welcomeQuestion14 => 'Які ключові концепції хмарних обчислень?';

  @override
  String get welcomeQuestion15 => 'Поясніть технологію блокчейн початківцю';

  @override
  String get welcomeQuestion16 => 'Як працює інтернет з технічної точки зору?';

  @override
  String get welcomeQuestion17 => 'Які найкращі техніки продуктивності?';

  @override
  String get welcomeQuestion18 => 'Як покращити концентрацію уваги?';

  @override
  String get welcomeQuestion19 =>
      'Дайте мені щоденну рутину для максимальної продуктивності';

  @override
  String get welcomeQuestion20 => 'Які є хороші звички для успіху?';

  @override
  String get welcomeQuestion21 =>
      'Як підготуватися до співбесіди з програмної інженерії?';

  @override
  String get welcomeQuestion22 => 'Які навички найцінніші в IT-індустрії?';

  @override
  String get welcomeQuestion23 => 'Як домогтися підвищення зарплати?';

  @override
  String get welcomeQuestion24 => 'Які провідні IT-компанії варто обирати?';

  @override
  String get welcomeQuestion25 =>
      'Які останні прориви в космічних дослідженнях?';

  @override
  String get welcomeQuestion26 => 'Як ШІ змінює охорону здоров\'я?';

  @override
  String get welcomeQuestion27 =>
      'Які найбільш захопливі технології 2025 року?';

  @override
  String get welcomeQuestion28 => 'Поясніть майбутнє відновлюваної енергетики';

  @override
  String get welcomeQuestion29 => 'Які найважливіші філософські питання?';

  @override
  String get welcomeQuestion30 => 'Як мислити більш критично про проблеми?';

  @override
  String get welcomeQuestion31 => 'Які найкращі способи вивчати нові навички?';

  @override
  String get welcomeQuestion32 =>
      'Як зберігати мотивацію при вивченні чогось складного?';

  @override
  String get welcomeQuestion33 =>
      'Які найкращі мови програмування варто вчити у 2025 році?';

  @override
  String get welcomeQuestion34 =>
      'Як побудувати сильне портфоліо для IT-вакансій?';

  @override
  String get welcomeQuestion35 =>
      'Які провідні інструменти ШІ для продуктивності?';

  @override
  String get welcomeQuestion36 => 'Як насправді працює машинне навчання?';

  @override
  String get welcomeQuestion37 => 'Які найкращі практики для код-рев\'ю?';

  @override
  String get welcomeQuestion38 => 'Як писати чистий та підтримуваний код?';

  @override
  String get welcomeQuestion39 =>
      'Що таке мікросервіси і коли їх використовувати?';

  @override
  String get welcomeQuestion40 => 'Поясніть REST API vs GraphQL';

  @override
  String get welcomeQuestion41 => 'Які найкращі хмарні платформи для вивчення?';

  @override
  String get welcomeQuestion42 => 'Як підготуватися до технічних співбесід?';

  @override
  String get welcomeQuestion43 =>
      'Які м\'які навички потрібні кожному розробнику?';

  @override
  String get welcomeQuestion44 => 'Як домовлятися про зарплату як розробник?';

  @override
  String get welcomeQuestion45 =>
      'Які найкращі інструменти для віддаленої роботи?';

  @override
  String get welcomeQuestion46 => 'Як залишатися продуктивним працюючи з дому?';

  @override
  String get welcomeQuestion47 =>
      'Які найкращі методології управління проектами?';

  @override
  String get welcomeQuestion48 => 'Як поводитися з важкими колегами?';

  @override
  String get welcomeQuestion49 => 'Які найкращі книги з лідерства?';

  @override
  String get welcomeQuestion50 => 'Як розпочати успішний IT-стартап?';

  @override
  String get welcomeQuestion51 => 'Які останні тенденції у веб-розробці?';

  @override
  String get welcomeQuestion52 => 'Як працює технологія блокчейн?';

  @override
  String get welcomeQuestion53 => 'Що таке NFT і чи варто звертати увагу?';

  @override
  String get welcomeQuestion54 => 'Поясніть концепцію метавсесвіту';

  @override
  String get welcomeQuestion55 => 'Які найкращі моделі ШІ для кодування?';

  @override
  String get welcomeQuestion56 => 'Як ефективно використовувати ChatGPT?';

  @override
  String get welcomeQuestion57 => 'Яка етика ШІ?';

  @override
  String get welcomeQuestion58 => 'Як ШІ змінить робочі місця в майбутньому?';

  @override
  String get welcomeQuestion59 => 'Які найкращі практики кібербезпеки?';

  @override
  String get welcomeQuestion60 =>
      'Як захистити свою конфіденційність в інтернеті?';

  @override
  String get welcomeQuestion61 =>
      'Які найкращі інструменти для науки про дані?';

  @override
  String get welcomeQuestion62 => 'Як ефективно візуалізувати дані?';

  @override
  String get welcomeQuestion63 =>
      'Які найкращі фреймворки для мобільних додатків?';

  @override
  String get welcomeQuestion64 => 'Як створювати крос-платформні додатки?';

  @override
  String get welcomeQuestion65 => 'Які найкращі движки для розробки ігор?';

  @override
  String get welcomeQuestion66 => 'Як розпочати роботу з 3D-моделюванням?';

  @override
  String get welcomeQuestion67 => 'Які найкращі інструменти для відеомонтажу?';

  @override
  String get welcomeQuestion68 => 'Як створювати цікавий контент?';

  @override
  String get welcomeQuestion69 =>
      'Які найкращі стратегії для соціальних мереж?';

  @override
  String get welcomeQuestion70 => 'Як побудувати особистий бренд?';

  @override
  String get welcomeQuestion71 => 'Які найкращі поради для нетворкінгу?';

  @override
  String get welcomeQuestion72 => 'Як дати чудову презентацію?';

  @override
  String get welcomeQuestion73 => 'Які найкращі техніки тайм-менеджменту?';

  @override
  String get welcomeQuestion74 => 'Як уникнути вигорання?';

  @override
  String get welcomeQuestion75 => 'Які найкращі додатки для медитації?';

  @override
  String get welcomeQuestion76 => 'Як покращити якість сну?';

  @override
  String get welcomeQuestion77 => 'Які найкращі вправи?';

  @override
  String get welcomeQuestion78 => 'Як харчуватися здорово за бюджету?';

  @override
  String get welcomeQuestion79 => 'Які найкращі подорожі для IT-працівників?';

  @override
  String get welcomeQuestion80 => 'Як швидко вивчити нову мову?';

  @override
  String get welcomeQuestion81 =>
      'Які найкращі практики для віддаленої командної роботи?';

  @override
  String get welcomeQuestion82 => 'Як проводити ефективні код-рев\'ю?';

  @override
  String get welcomeQuestion83 =>
      'Які провідні навички для архітекторів програмного забезпечення?';

  @override
  String get welcomeQuestion84 => 'Як проектувати масштабовані бази даних?';

  @override
  String get welcomeQuestion85 =>
      'Які найкращі DevOps-інструменти для вивчення?';

  @override
  String get welcomeQuestion86 => 'Як реалізувати CI/CD конвеєри?';

  @override
  String get welcomeQuestion87 => 'Що таке платформи оркестрації контейнерів?';

  @override
  String get welcomeQuestion88 => 'Поясніть переваги безсерверних обчислень';

  @override
  String get welcomeQuestion89 => 'Які найкращі практики для безпеки API?';

  @override
  String get welcomeQuestion90 =>
      'Як оптимізувати продуктивність мобільних додатків?';

  @override
  String get welcomeQuestion91 => 'Що таке прогресивні веб-додатки?';

  @override
  String get welcomeQuestion92 => 'Як створювати доступні веб-додатки?';

  @override
  String get welcomeQuestion93 => 'Які найкращі принципи UI/UX-дизайну?';

  @override
  String get welcomeQuestion94 =>
      'Як ефективно проводити дослідження користувачів?';

  @override
  String get welcomeQuestion95 => 'Які найкращі стратегії A/B-тестування?';

  @override
  String get welcomeQuestion96 => 'Як аналізувати поведінку користувачів?';

  @override
  String get welcomeQuestion97 => 'Які найкращі техніки гачкінгу?';

  @override
  String get welcomeQuestion98 =>
      'Як побудувати спільноту навколо вашого продукту?';

  @override
  String get welcomeQuestion99 =>
      'Які найкращі інструменти для підтримки клієнтів?';

  @override
  String get welcomeQuestion100 =>
      'Як ефективно обробляти зворотний зв\'язок від клієнтів?';

  @override
  String get welcomeQuestion101 => 'Які відмінності між React та Vue?';

  @override
  String get welcomeQuestion102 =>
      'Як TypeScript покращує розробку на JavaScript?';

  @override
  String get welcomeQuestion103 =>
      'Які найкращі практики для проектування REST API?';

  @override
  String get welcomeQuestion104 =>
      'Як реалізувати автентифікацію у веб-додатках?';

  @override
  String get welcomeQuestion105 => 'Які переваги GraphQL над REST?';

  @override
  String get welcomeQuestion106 =>
      'Як оптимізувати запити до бази даних для продуктивності?';

  @override
  String get welcomeQuestion107 =>
      'Що таке архітектурні шаблони мікросервісів?';

  @override
  String get welcomeQuestion108 => 'Як реалізувати стратегії кешування?';

  @override
  String get welcomeQuestion109 =>
      'Які найкращі фреймворки для тестування JavaScript?';

  @override
  String get welcomeQuestion110 =>
      'Як писати unit-тести для React-компонентів?';

  @override
  String get welcomeQuestion111 => 'Що таке принципи SOLID в ООП?';

  @override
  String get welcomeQuestion112 =>
      'Як реалізувати шаблони проектування в Python?';

  @override
  String get welcomeQuestion113 => 'Які найкращі практики для Git-воркфлоу?';

  @override
  String get welcomeQuestion114 => 'Як ефективно вирішувати конфлікти злиття?';

  @override
  String get welcomeQuestion115 => 'Які найкращі практики контейнеризації?';

  @override
  String get welcomeQuestion116 => 'Як захистити Docker-контейнери?';

  @override
  String get welcomeQuestion117 =>
      'Що таке стратегії розгортання в Kubernetes?';

  @override
  String get welcomeQuestion118 => 'Як моніторити продуктивність додатків?';

  @override
  String get welcomeQuestion119 => 'Які найкращі практики логування?';

  @override
  String get welcomeQuestion120 =>
      'Як реалізувати обробку помилок у розподілених системах?';

  @override
  String get continueConversation => 'Продовжити діалог';

  @override
  String get generatingSuggestions => 'Генерація пропозицій...';

  @override
  String get searchChats => 'Пошук чатів...';

  @override
  String noChatsFound(Object query) {
    return 'Чаты не найдені для \"$query\"';
  }

  @override
  String get tryDifferentSearchTerm => 'Спробуйте інший пошуковий термін';

  @override
  String get appShortName => 'ChatORAI';

  @override
  String get typeYourMessage => 'Введіть ваше повідомлення...';

  @override
  String get addImage => 'Зображення';

  @override
  String get addCamera => 'Камера';

  @override
  String get addFile => 'Файл';

  @override
  String get selectLanguage => 'Оберіть мову';

  @override
  String get searchFavorites => 'Пошук вибраних...';

  @override
  String get showAllModels => 'Показати всі моделі';

  @override
  String get showFavoritesOnly => 'Показати тільки вибрані';

  @override
  String get noFavoriteModels => 'Немає вибраних моделей';

  @override
  String get tapHeartToAddFavorites =>
      'Натисніть на сердечко біля моделей, щоб додати їх до вибраних';

  @override
  String get addToFavorites => 'Додати в обране';

  @override
  String get removeFromFavorites => 'Видалити з обраного';

  @override
  String get startListening => 'Почати голосовий ввід';

  @override
  String get stopListening => 'Зупинити голосовий ввід';

  @override
  String get listening => 'Говоріть...';

  @override
  String get micUnavailable => 'Мікрофон недоступний';

  @override
  String get sendMessage => 'Надіслати повідомлення';

  @override
  String get modelSettings => 'Налаштування моделі';

  @override
  String get temperature => 'Температура';

  @override
  String get temperatureDescription =>
      'Контролює випадковість: нижче = більш зосереджено, вище = більш креативно';

  @override
  String get maxTokens => 'Макс. токенів';

  @override
  String get maxTokensDescription =>
      'Максимальна довжина згенерованої відповіді';

  @override
  String get systemPrompt => 'Системний промпт';

  @override
  String get systemPromptDescription => 'Інструкції для AI-асистента';

  @override
  String get resetToDefaults => 'Скинути до стандартних';

  @override
  String get applySettings => 'Застосувати налаштування';

  @override
  String get modelParameters => 'Параметри моделі';

  @override
  String get activeModel => 'Активна модель';

  @override
  String get noModelSelected => 'Модель не вибрана';

  @override
  String get settingsApplied => 'Налаштування успішно застосовано';

  @override
  String apiLimitExceeded(Object limit) {
    return 'Перевищено ліміт API: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return 'Значення перевищує ліміт API ($limit). Буде використано максимальне значення.';
  }

  @override
  String get micStartFailed => 'Не вдалося запустити мікрофон';

  @override
  String get micStopFailed => 'Не вдалося зупинити мікрофон';

  @override
  String get speechErrorNoMatch =>
      'Не вдалося розпізнати мову. Спробуйте ще раз.';

  @override
  String get speechErrorTimeout =>
      'Час очікування вичерпано. Нічого не почуто.';

  @override
  String get speechErrorNetwork =>
      'Помилка мережі. Перевірте підключення до інтернету.';

  @override
  String get speechErrorNotAuthorized =>
      'Немає доступу до мікрофона. Перевірте дозволи в налаштуваннях.';

  @override
  String get speechErrorServer =>
      'Помилка сервера розпізнавання. Спробуйте пізніше.';

  @override
  String get speechErrorTooManyRequests =>
      'Занадто багато запитів. Спробуйте пізніше.';

  @override
  String get speechErrorUnknown => 'Помилка розпізнавання мови';

  @override
  String get speechPreparing => 'Підготовка...';

  @override
  String get speechListening => 'Говоріть...';

  @override
  String get speechProcessing => 'Обробка...';

  @override
  String get micNoSpeechDetected => 'Я вас не почув. Спробуйте ще раз.';

  @override
  String get micAutoRestart => 'Повторна спроба...';

  @override
  String get speechPhase2 => 'Я вас не чую...говоріть голосніше';

  @override
  String speechStartError(Object error) {
    return 'Помилка запуску: $error';
  }

  @override
  String get errorProcessingRequest =>
      'Вибачте, сталася помилка при обробці вашого запиту. Будь ласка, спробуйте ще раз.';

  @override
  String rateLimitRetryMessage(Object seconds) {
    return 'Перевищено ліміт запитів. Повторна спроба через $seconds секунд...';
  }

  @override
  String get messageNotFound => 'Повідомлення не знайдено';

  @override
  String get errorEditingMessage => 'Помилка редагування повідомлення';

  @override
  String get errorEditAndSendMessage =>
      'Помилка редагування та відправлення повідомлення';

  @override
  String generatingSuggestionsFailed(Object error) {
    return 'Не вдалося згенерувати пропозиції: $error';
  }

  @override
  String get selectModelTooltip => 'Вибрати модель';

  @override
  String get toggleNavigatorTooltip => 'Перемкнути навігатор';

  @override
  String get defaultSuggestion1 => 'Розкажіть більше про цю тему';

  @override
  String get defaultSuggestion2 => 'Чи можете навести приклади?';

  @override
  String get defaultSuggestion3 => 'Які є альтернативи?';

  @override
  String get defaultSuggestion4 => 'Як це застосовується на практиці?';

  @override
  String get systemPromptSuggestion =>
      'Ви — корисний асистент. Продовжте діалог, запропонувавши 3 конкретні та логічні продовження останнього повідомлення. Відповідайте українською мовою.';

  @override
  String get userPromptSuggestion =>
      'Запропонуйте 3 конкретні та логічні продовження для цього повідомлення. Відповідайте тільки списком, без додаткового тексту.';

  @override
  String get refreshQuestions => 'Оновити питання';

  @override
  String get noInternetConnection => 'Немає підключення до інтернету';

  @override
  String modelDoesNotSupportFiles(Object modelId) {
    return 'Модель $modelId не підтримує файли. Ви можете прикріпити файл, але відправлення не спрацює.';
  }

  @override
  String get fileAttachedButNotSupported =>
      'Файл прикріплено, але не підтримується поточною моделлю';

  @override
  String get copyCodeTooltip => 'Копіювати код';

  @override
  String get expandTooltip => 'Розгорнути';

  @override
  String get collapseTooltip => 'Згорнути';

  @override
  String get welcomeGreeting1 =>
      'Питай, досліджуй, створюй — давай розберемося разом.';

  @override
  String get welcomeGreeting2 =>
      'Постав питання, опиши завдання або просто почни розмову.';

  @override
  String get welcomeGreeting3 => 'Постав питання або почни дослідження.';

  @override
  String get welcomeGreeting4 =>
      'Постав будь-яке питання, поділися ідеєю або попроси допомоги — я тут, щоб допомогти.';

  @override
  String get welcomeGreeting5 => 'Є ідея? Давай розберемося.';

  @override
  String get welcomeGreeting6 => 'Задай напрямок для розмови.';

  @override
  String get welcomeGreeting7 => 'Що сьогодні досліджуємо?';

  @override
  String get welcomeGreeting8 => 'Напиши думку. Розберемося разом.';

  @override
  String get welcomeGreeting9 => 'Цікавість вітається.';

  @override
  String get welcomeGreeting10 => 'Твоє питання — моя наступна відповідь.';

  @override
  String get welcomeGreeting11 => 'Давай перетворимо ідею на відповідь.';

  @override
  String get welcomeGreeting12 => 'Введи питання. Решта — моя робота.';

  @override
  String get versionLabel => 'Версія:';

  @override
  String get permissionDialogPatterns => 'Запит доступу до:';

  @override
  String get permissionOnce => 'Один раз';

  @override
  String get permissionAlways => 'Завжди дозволяти';

  @override
  String get permissionReject => 'Відхилити';

  @override
  String get permissionAlwaysConfirm => 'Always allow';

  @override
  String get providers => 'Providers';

  @override
  String get manageProviders => 'Manage AI providers';

  @override
  String get openaiCompatibleApi => 'AI Providers';

  @override
  String get openaiCompatibleApiDescription =>
      'Configure AI providers and manage their API keys and models';

  @override
  String get addProvider => 'Add Provider';
}
