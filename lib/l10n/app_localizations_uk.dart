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
  String get baseUrl => 'Базовий URL';

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
  String get showContinuationSuggestions => 'Показувати продовження діалогу';

  @override
  String get showContinuationSuggestionsDesc =>
      'Відображати пропозиції для продовження після відповіді AI';

  @override
  String get expandReasoningByDefault =>
      'Розгортати reasoning за замовчуванням';

  @override
  String get expandReasoningByDefaultDesc =>
      'Показувати блоки розмірковування розгорнутими при відповіді AI';

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
  String chatRenamedTo(Object name) {
    return 'Чат перейменовано на: $name';
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
  String get loadingMsg1 => 'Чекаю відповіді сервера…';

  @override
  String get loadingMsg2 => 'Дані надіслано — залишилось трохи…';

  @override
  String get loadingMsg3 => 'Збираю думки у відповідь…';

  @override
  String get loadingMsg4 => 'Підбираю найкращий варіант…';

  @override
  String get loadingMsg5 => 'Завантажую відповідь (майже)…';

  @override
  String get failedToSendMessage => 'Не вдалося надіслати повідомлення';

  @override
  String get retry => 'Повторити';

  @override
  String get bootstrapErrorTitle => 'Не вдалося запустити застосунок';

  @override
  String get bootstrapErrorBody => 'Перевірте конфігурацію і спробуйте ще раз.';

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
      'Які найбільш захопливі технології 2026 року?';

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
      'Які найкращі мови програмування варто вчити у 2026 році?';

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
  String get recentModels => 'Нещодавні';

  @override
  String get loadingSkills => 'Завантаження навичок...';

  @override
  String get noSkillsInstalled =>
      'Немає встановлених навичок. Додайте в .chatorai/skills/';

  @override
  String get noSkillsMatchSearch => 'Немає навичок, що відповідають пошуку';

  @override
  String get allSkillsRequirePermission => 'Всі навички вимагають дозволу';

  @override
  String skillExecuted(Object name) {
    return 'Навик виконано: $name';
  }

  @override
  String get configuration => 'Конфігурація';

  @override
  String get stats => 'Статистика';

  @override
  String get usageStatistics => 'Статистика використання';

  @override
  String get totalSessions => 'Сеанси';

  @override
  String get totalMessages => 'Повідомлення';

  @override
  String get days => 'Дні';

  @override
  String get totalTokens => 'Всього токенів';

  @override
  String get totalCost => 'Загальна вартість';

  @override
  String get avgCostPerDay => 'Середня вартість/день';

  @override
  String get avgTokensPerSession => 'Середнє токенів/сеанс';

  @override
  String get medianTokensPerSession => 'Медіана токенів/сеанс';

  @override
  String get cacheRead => 'Читання кешу';

  @override
  String get cacheWrite => 'Запис кешу';

  @override
  String get toolUsage => 'Використання інструментів';

  @override
  String get modelUsage => 'Використання моделей';

  @override
  String get noStatsAvailable => 'Статистика недоступна';

  @override
  String get reasoningTokens => 'Міркування';

  @override
  String get addProvider => 'Додати провайдера';

  @override
  String get applySettings => 'Застосувати налаштування';

  @override
  String get copyCodeTooltip => 'Копіювати код';

  @override
  String get copiedFeedback => 'Скопійовано';

  @override
  String get defaultSuggestion1 => 'Розкажіть більше про цю тему';

  @override
  String get defaultSuggestion2 => 'Чи можете навести приклади?';

  @override
  String get defaultSuggestion3 => 'Які є альтернативи?';

  @override
  String get deleteChat => 'Видалити чат';

  @override
  String get manageProviders => 'Керування провайдерами';

  @override
  String get micAutoRestart => 'Повторна спроба...';

  @override
  String get micNoSpeechDetected => 'Я вас не почув. Спробуйте ще раз.';

  @override
  String get micStartFailed => 'Не вдалося запустити мікрофон';

  @override
  String get micUnavailable => 'Мікрофон недоступний';

  @override
  String get modelParameters => 'Параметри моделі';

  @override
  String get modelSettings => 'Налаштування моделі';

  @override
  String get noInternetConnection => 'Немає підключення до інтернету';

  @override
  String get noModelSelected => 'Модель не вибрана';

  @override
  String get openaiCompatibleApi => 'OpenAI-сумісний API';

  @override
  String get openaiCompatibleApiDescription =>
      'Підключення до будь-якого OpenAI-сумісного API';

  @override
  String get permissionAlways => 'Завжди дозволяти';

  @override
  String get permissionAlwaysConfirm => 'Завжди дозволяти';

  @override
  String get permissionDialogPatterns => 'Запит доступу до:';

  @override
  String get permissionOnce => 'Один раз';

  @override
  String get permissionReject => 'Відхилити';

  @override
  String get providers => 'Провайдери';

  @override
  String get refreshQuestions => 'Оновити питання';

  @override
  String get resetToDefaults => 'Скинути до стандартних';

  @override
  String get settingsApplied => 'Налаштування успішно застосовано';

  @override
  String get speechErrorNetwork =>
      'Помилка мережі. Перевірте підключення до інтернету.';

  @override
  String get speechErrorNoMatch =>
      'Не вдалося розпізнати мову. Спробуйте ще раз.';

  @override
  String get speechErrorNotAuthorized =>
      'Немає доступу до мікрофона. Перевірте дозволи в налаштуваннях.';

  @override
  String get speechErrorServer =>
      'Помилка сервера розпізнавання. Спробуйте пізніше.';

  @override
  String get speechErrorTimeout =>
      'Час очікування вичерпано. Нічого не почуто.';

  @override
  String get speechErrorTooManyRequests =>
      'Занадто багато запитів. Спробуйте пізніше.';

  @override
  String get speechErrorUnknown => 'Помилка розпізнавання мови';

  @override
  String get speechListening => 'Говоріть...';

  @override
  String get speechPhase2 => 'Я вас не чую...говоріть голосніше';

  @override
  String get speechPreparing => 'Підготовка...';

  @override
  String get speechProcessing => 'Обробка...';

  @override
  String speechStartError(Object error) {
    return 'Помилка запуску: $error';
  }

  @override
  String get systemPrompt => 'Системний промпт';

  @override
  String get systemPromptDescription => 'Інструкції для AI-асистента';

  @override
  String get systemPromptSuggestion =>
      'Ви — корисний асистент. Продовжте діалог, запропонувавши 3 конкретні та логічні продовження останнього повідомлення. Відповідайте українською мовою.';

  @override
  String get temperature => 'Температура';

  @override
  String get temperatureDescription =>
      'Контролює випадковість: нижче = більш зосереджено, вище = більш креативно';

  @override
  String get toggleNavigatorTooltip => 'Перемкнути навігатор';

  @override
  String get userPromptSuggestion =>
      'Запропонуйте 3 конкретні та логічні продовження для цього повідомлення. Відповідайте тільки списком, без додаткового тексту.';

  @override
  String get versionLabel => 'Версія:';

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
  String modelDoesNotSupportFiles(Object modelId) {
    return 'Модель $modelId не підтримує файли. Ви можете прикріпити файл, але відправлення не спрацює.';
  }

  @override
  String generatingSuggestionsFailed(Object error) {
    return 'Не вдалося згенерувати пропозиції: $error';
  }

  @override
  String get toggleSidebarTooltip => 'Перемкнути бічну панель';

  @override
  String get openMenuTooltip => 'Відкрити меню';

  @override
  String get addFileTooltip => 'Додати файл';

  @override
  String get modelSettingsTooltip => 'Налаштування моделі';

  @override
  String get switchAgentTooltip => 'Змінити агента';

  @override
  String get selectModelTooltip => 'Вибрати модель';

  @override
  String get removeFileTooltip => 'Видалити файл';

  @override
  String get goToParentSessionTooltip => 'Перейти до батьківського сеансу';

  @override
  String get previousSiblingTooltip => 'Попередній сеанс';

  @override
  String get nextSiblingTooltip => 'Наступний сеанс';

  @override
  String get cancellingRetryTooltip => 'Скасування повторної спроби...';

  @override
  String get stopGenerationTooltip => 'Зупинити генерацію';

  @override
  String get question => 'Питання';

  @override
  String get skip => 'Пропустити';

  @override
  String get answer => 'Відповідь';

  @override
  String get noAgentsAvailable => 'Немає доступних агентів';

  @override
  String permissionAlwaysConfirmDescription(Object title) {
    return 'Це дозволить \"$title\" до перезапуску додатка.';
  }

  @override
  String get chatActionsMenuTooltip => 'Меню чату';

  @override
  String get startListening => 'Почати голосовий ввід';

  @override
  String get stopListening => 'Зупинити голосовий ввід';

  @override
  String get listening => 'Говоріть...';

  @override
  String get sendMessage => 'Надіслати повідомлення';

  @override
  String get maxTokens => 'Макс. токенів';

  @override
  String get maxTokensDescription =>
      'Максимальна довжина згенерованої відповіді';

  @override
  String get activeModel => 'Активна модель';

  @override
  String apiLimitExceeded(Object limit) {
    return 'Перевищено ліміт API: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return 'Значення перевищує ліміт API ($limit). Буде використано максимальне значення.';
  }

  @override
  String get micStopFailed => 'Не вдалося зупинити мікрофон';

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
  String get defaultSuggestion4 => 'Як це застосовується на практиці?';

  @override
  String get fileAttachedButNotSupported =>
      'Файл прикріплено, але не підтримується поточною моделлю';

  @override
  String get expandTooltip => 'Розгорнути';

  @override
  String get collapseTooltip => 'Згорнути';

  @override
  String get addProviderTitleEdit => 'Редагувати провайдера';

  @override
  String get addProviderTitleAdd => 'Додати провайдера';

  @override
  String get addProviderLabelProvider => 'Провайдер';

  @override
  String get addProviderCustomName => 'Власний провайдер...';

  @override
  String get addProviderFieldProviderName => 'Назва провайдера';

  @override
  String get addProviderHintProviderName => 'наприклад, Мій власний AI';

  @override
  String get addProviderLabelApiKey => 'API ключ';

  @override
  String get addProviderHintApiKey => 'Введіть ваш API ключ';

  @override
  String get addProviderHintCustomApiKey =>
      'Необов\'язково для локальних провайдерів';

  @override
  String get addProviderLabelBaseUrl => 'Базовий URL';

  @override
  String get addProviderHintBaseUrl => 'https://api.example.com/v1';

  @override
  String get addProviderActionSave => 'Зберегти';

  @override
  String get addProviderErrorApiKeyRequired => 'Потрібен API ключ';

  @override
  String get selectModels => 'Вибір моделей';

  @override
  String get deselectAll => 'Зняти вибір';

  @override
  String get selectAll => 'Вибрати все';

  @override
  String get modelsAvailable => 'Немає доступних моделей';

  @override
  String get modelsMatchSearch => 'Немає моделей, що відповідають пошуку';

  @override
  String selectModelsCount(Object count, Object total) {
    return 'Вибрано $count з $total';
  }

  @override
  String modelsLoadError(Object error) {
    return 'Помилка завантаження моделей: $error';
  }

  @override
  String get systemPromptHint => 'Ви корисний асистент...';

  @override
  String get temperatureHint => '0.0 - 2.0';

  @override
  String get loadingSettings => 'Завантаження налаштувань...';

  @override
  String errorApplyingSettings(Object error) {
    return 'Помилка застосування налаштувань: $error';
  }

  @override
  String deleteProviderTitle(Object providerName) {
    return 'Видалити $providerName?';
  }

  @override
  String get deleteProviderContent =>
      'Це видалить провайдера та всі його налаштування. Вам потрібно буде додати його знову, щоб використовувати його моделі.';

  @override
  String get errorLoadingProviders => 'Помилка завантаження провайдерів';

  @override
  String get noProvidersConfigured => 'Немає налаштованих провайдерів';

  @override
  String get addProviderToGetStarted =>
      'Додайте провайдера з API ключем, щоб почати';

  @override
  String statsError(Object error) {
    return 'Помилка: $error';
  }

  @override
  String get total => 'Всього';

  @override
  String modelsProviderCountFormat(Object count, Object providerName) {
    return '$providerName · $count';
  }

  @override
  String get mcpServers => 'MCP-сервери';

  @override
  String get mcpAddServer => 'Додати MCP-сервер';

  @override
  String get mcpAddServerTitle => 'Додати MCP-сервер';

  @override
  String get mcpNameLabel => 'Назва';

  @override
  String get mcpNameHint => 'напр. filesystem';

  @override
  String get mcpNameHelper => 'Унікальний ідентифікатор у chatorai.json';

  @override
  String get mcpTypeLocal => 'Локальний';

  @override
  String get mcpTypeRemote => 'Віддалений';

  @override
  String get mcpTypeLocalTooltip => 'Запускається на вашому комп\'ютері';

  @override
  String get mcpTypeRemoteTooltip => 'HTTP/SSE ендпоінт';

  @override
  String get mcpCommandLabel => 'Команда';

  @override
  String get mcpCommandHint => 'uvx mcp-server-filesystem ~/docs';

  @override
  String get mcpCommandHelper => 'Повна команда з аргументами через пробіл';

  @override
  String get mcpUrlLabel => 'URL';

  @override
  String get mcpUrlHint => 'https://example.com/mcp';

  @override
  String get mcpUrlHelper => 'Повна URL-адреса MCP-ендпоінта';

  @override
  String get mcpEnvLabel => 'Змінні середовища (JSON)';

  @override
  String get mcpEnvHint => 'GITHUB_TOKEN=ghp_xxx';

  @override
  String get mcpEnvHelper =>
      'Необов\'язково. Вставте JSON-об\'єкт із рядковими ключами, напр. одну запис TOKEN.';

  @override
  String get mcpTokenLabel => 'Токен доступу';

  @override
  String get mcpTokenHint => 'Вставте лише токен (без Bearer / лапок)';

  @override
  String get mcpTokenHelper =>
      'Необов\'язково. Залиште порожнім для публічних серверів; вставте лише токен — заголовок додається автоматично.';

  @override
  String get mcpAuthTypeLabel => 'Тип токена';

  @override
  String get mcpAuthTypeHelper =>
      'Як надсилається токен: Bearer (Authorization), ApiKey (X-Api-Key) або просто Token.';

  @override
  String get mcpHeadersLabel => 'Заголовки (JSON)';

  @override
  String get mcpHeadersHint => 'Authorization=Bearer token';

  @override
  String get mcpHeadersHelper =>
      'Необов\'язково. Вставте JSON-об\'єкт заголовків.';

  @override
  String get mcpFormTab => 'Форма';

  @override
  String get mcpRawTab => 'Сирий JSON';

  @override
  String get mcpRawLabel => 'Об\'єкт сервера (JSON)';

  @override
  String get mcpRawHelper =>
      'Вставте об\'єкт сервера як у документації — ім\'я сервера — зовнішній ключ (напр. searxng). Можна вставити весь блок разом з обгорткою mcpServers.';

  @override
  String mcpParseError(Object field, Object message) {
    return 'Некоректний JSON у $field: $message';
  }

  @override
  String get mcpAddAction => 'Додати';

  @override
  String get mcpCancelAction => 'Скасувати';

  @override
  String get mcpRemoveTitle => 'Видалити MCP-сервер?';

  @override
  String mcpRemoveContent(Object name) {
    return 'Видалити \"$name\" з chatorai.json?';
  }

  @override
  String get mcpRemoveAction => 'Видалити';

  @override
  String get mcpEditAction => 'Змінити';

  @override
  String get mcpEditServerTitle => 'Змінити MCP-сервер';

  @override
  String get mcpSaveAction => 'Зберегти';

  @override
  String get mcpNoServers => 'MCP-сервери не налаштовано';

  @override
  String get mcpNoServersHint =>
      'Додайте MCP-сервер для розширення інструментів';

  @override
  String get mcpTooltipAdd => 'Додати сервер';

  @override
  String get mcpTooltipRefresh => 'Оновити';

  @override
  String get mcpMarketplaceTab => 'Каталог';

  @override
  String get mcpInstalledTab => 'Встановлено';

  @override
  String get mcpInstall => 'Встановити';

  @override
  String get mcpInstalled => 'Встановлено';

  @override
  String get mcpMarketplaceSearchHint => 'Пошук серверів…';

  @override
  String get mcpMarketplaceEmpty => 'Немає серверів за вашим запитом';

  @override
  String get mcpMarketCategoryAll => 'Усі';

  @override
  String get mcpMarketCategorySearch => 'Пошук';

  @override
  String get mcpMarketCategoryDocs => 'Документація';

  @override
  String get mcpMarketCategoryDesign => 'Дизайн';

  @override
  String get mcpMarketCategoryDev => 'Розробка';

  @override
  String get mcpMarketCategoryFinance => 'Фінанси';

  @override
  String get mcpMarketCategoryTravel => 'Подорожі';

  @override
  String get mcpMarketCategoryJobs => 'Робота';

  @override
  String get mcpMarketCategoryProductivity => 'Продуктивність';

  @override
  String get mcpMarketCategorySocial => 'Соціальне';

  @override
  String get mcpMarketCategoryOther => 'Інше';

  @override
  String get mcpMarketNeedsToken => 'Потрібен ключ';

  @override
  String get mcpMarketDescExa =>
      'Exa надає можливості веб-пошуку та пошуку документації коду для робочих процесів ШІ. Її конектор забезпечує асистентів контекстною інформацією в реальному часі для пошуку релевантних веб-сторінок, технічної документації та вихідних матеріалів, коли для відповіді потрібна обґрунтована зовнішня інформація.';

  @override
  String get mcpMarketDescContext7 =>
      'Context7 надає актуальні приклади коду та документацію для програміс тів і редакторів коду на базі ШІ. Його MCP-конектор інтегрує поточний контекст бібліотеки у робочі процеси асистента, скорочуючи перемикання вкладок і допомагаючи згенерованому коду уникати застарілих API, неіснуючих методів і застарілих шаблонів реалізації.';

  @override
  String get mcpMarketDescHuggingFace =>
      'Hugging Face підключає голосових помічників до Hugging Face Hub та тисяч застосунків Gradio. Його конектор інтегрує контекст моделі, набору даних, простору та застосунку в робочі процеси ШІ для пошуку, експериментів і досліджень у машинному навчанні.';

  @override
  String get mcpMarketDescParallel =>
      'Parallel Search забезпечує пошук в інтернеті в реальному часі та вилучення вмісту для робочих процесів ШІ, що базуються на пошуку. Його віддалений MCP-сервер допомагає асистентам отримувати поточний контекст веб-сторінок, перевіряти сторінки та використовувати вилучений вміст під час відповіді на запитання чи дослідження тем, що потребують актуальної інформації.';

  @override
  String get mcpMarketDescTavily =>
      'Tavily надає агентам ШІ доступ до веб-ресурсів у реальному часі через API для пошуку, вилучення та дослідження інформації. Його конектор допомагає асистентам базувати відповіді на даних у реальному часі, вилучати релевантний вміст і підтримувати робочі процеси агентів у продакшені за допомогою засобів контролю безпеки.';

  @override
  String get mcpMarketDescGithub =>
      'GitHub — це платформа для спільної роботи над кодом, задачами, запитами на злиття та історією проєктів. Її офіційний віддалений MCP-сервер надає асистентам структурований контекст репозиторію для розуміння змін у вихідному коді, оглядів, робочих процесів розробки та стану робіт за проєктами GitHub.';

  @override
  String get mcpMarketDescPostman =>
      'Postman надає контекст API для агентів кодування та робочих процесів розробників. Його конектор інтегрує визначення API, документацію та контекст співпраці в роботу асистентів, дозволяючи агентам аналізувати інтеграції та деталі реалізації.';

  @override
  String get mcpMarketDescSlack =>
      'Slack — це центр спільної роботи, що об\'єднує командні повідомлення, канали, користувачів і спільні робочі простори. Його віддалений MCP-сервер інтегрує контекст спілкування в робочому просторі в робочі процеси асистентів, допомагаючи користувачам знаходити рішення, узагальнювати обговорення та розуміти активність у різних каналах.';

  @override
  String get mcpMarketDescFigma =>
      'Figma — це платформа для спільної розробки продуктів, призначена для проєктування інтерфейсів, прототипування та передачі результатів розробникам. Її віддалений MCP-сервер передає файли, проєкти та контекст режиму розробки в робочі процеси асистентів, дозволяючи агентам розуміти візуальну роботу та співвідносити її із завданнями реалізації.';

  @override
  String get mcpMarketDescCanva =>
      'Canva — це платформа візуальної комунікації для створення презентацій, графіки для соцмереж, документів і фірмових матеріалів. Її віддалений MCP-сервер забезпечує доступ асистентів до проєктів, ресурсів, експортованих файлів і коментарів Canva, дозволяючи обговорювати, редагувати та готувати креативні роботи на основі отриманої інформації.';

  @override
  String get mcpMarketDescStripe =>
      'Stripe — це платформа для платежів та фінансової інфраструктури, призначена для обробки платежів, виставлення рахунків, роботи з клієнтами та підготовки документації для розробників. Її віддалений MCP-сервер надає асистентам контекст облікових записів і реалізації, що підтримується Stripe, для розуміння клієнтських робочих процесів, питань виставлення рахунків і завдань, пов\'язаних із платежами.';

  @override
  String get mcpMarketDescTrivago =>
      'Trivago допомагає користувачам шукати готелі та варіанти проживання за координатами, містом, країною, датами та контекстом подорожі. Його конектор надає асистентам контекст пошуку житла для знаходження підходящих варіантів проживання поряд із пунктами призначення або визначними пам\'ятками.';

  @override
  String get mcpMarketDescSend =>
      'Send допомагає користувачам створювати документи, якими можна ділитися, односторінкові документи, презентації та слайди. Його конектор дозволяє асистентам перетворювати запитувані матеріали на опубліковані посилання, інтерактивні сторінки та відстежувані рекламні матеріали для отримувачів.';

  @override
  String get mcpMarketDescZiprecruiter =>
      'ZipRecruiter допомагає користувачам шукати актуальні вакансії за назвою, компанією, місцезнаходженням, зарплатою, відстанню, стилем роботи, типом зайнятості та датою публікації. Його конектор інтегрує контекст пошуку роботи в робочі процеси асистента, перш ніж передати заявки назад у ZipRecruiter.';

  @override
  String get mcpMarketDescAdobeCreativity =>
      'Adobe для творчості об\'єднує можливості Photoshop, Lightroom, Illustrator, Firefly, Premiere, Express, InDesign та Stock із творчою роботою, виконаною за допомогою штучного інтелекту. Користувачі можуть створювати, редагувати та покращувати фотографії, дизайнерські матеріали та відеопроєкти, використовуючи природну мову, тоді як робота залишається прив\'язаною до облікового запису Adobe.';

  @override
  String get agentsInstructions => 'Інструкції для агентів';

  @override
  String get agentsInstructionsSubtitle =>
      'Керування AGENTS.md і файлами інструкцій';

  @override
  String get agentsMdHint => '# Правила проєкту\n- Стисло\n- Спершу тести';

  @override
  String get agentsMdSaved => 'AGENTS.md збережено';

  @override
  String get instructionsAutoDetectedTitle => 'Виявлені файли';

  @override
  String get instructionsAutoDetectedHelper =>
      'Знайдені для цієї області AGENTS.md і CLAUDE.md. Натисніть, щоб переглянути або змінити.';

  @override
  String get instructionsFileNotCreated => 'Ще не створено';

  @override
  String get instructionsFileReadOnly => 'Лише читання';

  @override
  String get instructionsBadgeGlobal => 'Глобально';

  @override
  String get instructionsBadgeProject => 'Проєкт';

  @override
  String get instructionsViewFile => 'Перегляд';

  @override
  String get instructionsEditFile => 'Змінити';

  @override
  String get instructionsSectionTitle => 'Файли інструкцій';

  @override
  String get instructionsSectionHelper =>
      'Додаткові Markdown-файли додаються після AGENTS.md за порядком.';

  @override
  String get instructionsAdd => 'Додати інструкцію';

  @override
  String get instructionsAddInline => 'Написати вручну';

  @override
  String get instructionsUploadFile => 'Завантажити .md файл';

  @override
  String get instructionsEmpty => 'Ще немає файлів інструкцій';

  @override
  String get instructionsEmptyHint =>
      'Додайте інструкцію вручну або завантажте Markdown-файл.';

  @override
  String get instructionsNameLabel => 'Назва';

  @override
  String get instructionsNameHint => 'coding-style';

  @override
  String get instructionsContentLabel => 'Вміст';

  @override
  String get instructionsContentHint => 'Напишіть інструкції у Markdown…';

  @override
  String get instructionsAddedInline => 'Інструкцію додано';

  @override
  String instructionsAddedFile(Object name) {
    return 'Файл додано: $name';
  }

  @override
  String get instructionsRemoveTitle => 'Видалити інструкцію';

  @override
  String instructionsRemoveContent(Object name) {
    return 'Видалити «$name» з інструкцій?';
  }

  @override
  String get instructionsRemoved => 'Інструкцію видалено';

  @override
  String get instructionsEditTitle => 'Змінити шлях інструкції';

  @override
  String get instructionsPathLabel => 'Шлях';

  @override
  String get instructionsUpdated => 'Інструкцію оновлено';

  @override
  String get instructionsScopeGlobal => 'Глобально';

  @override
  String get instructionsScopeProject => 'Проєкт';

  @override
  String get instructionsScopeGlobalHint =>
      'Застосовується всюди. Зберігається в конфігурації користувача.';

  @override
  String get instructionsScopeProjectHint =>
      'Застосовується до поточної теки проєкту.';

  @override
  String get instructionsCreateAgents => 'Створити AGENTS.md';

  @override
  String instructionsSaveError(Object error) {
    return 'Не вдалося зберегти: $error';
  }

  @override
  String get configScopeGlobal => 'Глобально';

  @override
  String get configScopeProject => 'Проєкт';

  @override
  String get configProjectOverrides =>
      'Налаштування проєкту перевизначають глобальні.';

  @override
  String get configPathLabel => 'Шлях';

  @override
  String get configStatusLabel => 'Статус';

  @override
  String get configContentsTitle => 'Вміст файлу';

  @override
  String get configExists => 'Існує';

  @override
  String get configNotFound => 'Не знайдено';

  @override
  String get configWillBeCreated => 'Буде створено під час збереження.';

  @override
  String get skillsTitle => 'Навички';

  @override
  String get skillsSubtitle =>
      'Готові набори можливостей, які асистент підключає за потреби.';

  @override
  String get skillsSectionTitle => 'Встановлені навички';

  @override
  String get skillsSectionHelper =>
      'Кожна навичка — це тека з файлом SKILL.md. Додайте власну або встановіть за URL.';

  @override
  String get skillsNewSkill => 'Нова навичка';

  @override
  String get skillsInstallFromUrl => 'Встановити за URL';

  @override
  String get skillsNameLabel => 'Назва';

  @override
  String get skillsNameHint => 'напр. Рев\'юер коду';

  @override
  String get skillsDescriptionLabel => 'Опис';

  @override
  String get skillsDescriptionHint => 'Коротко про те, що робить навичка';

  @override
  String get skillsContentLabel => 'Вміст SKILL.md';

  @override
  String get skillsContentHint => '# Заголовок\nІнструкції для асистента…';

  @override
  String get skillsUrlLabel => 'URL файлу index.json';

  @override
  String get skillsUrlHint => 'https://example.com/skills';

  @override
  String get skillsApiKeyLabel => 'API-ключ (необов\'язково)';

  @override
  String get skillsReadOnly => 'Лише читання';

  @override
  String skillsFilesCount(int count) {
    return 'Файлів: $count';
  }

  @override
  String get skillsCreated => 'Навичку створено';

  @override
  String get skillsSaved => 'Навичку збережено';

  @override
  String get skillsRemoved => 'Навичку видалено';

  @override
  String skillsInstalled(int count) {
    return 'Встановлено навичок: $count';
  }

  @override
  String get skillsInstallNone => 'За цим URL навичок не знайдено';

  @override
  String get skillsRemoveTitle => 'Видалити навичку';

  @override
  String skillsRemoveContent(String name) {
    return 'Видалити «$name»? Теку навички буде видалено з диска.';
  }

  @override
  String skillsSaveError(String error) {
    return 'Не вдалося виконати: $error';
  }

  @override
  String get skillsEmpty => 'Ще немає навичок';

  @override
  String get skillsEmptyHint =>
      'Створіть навичку або встановіть її за URL, щоб почати.';

  @override
  String get skillsMarketplaceTab => 'Маркетплейс';

  @override
  String get skillsMarketplaceSearchHint => 'Пошук навичок';

  @override
  String get skillsMarketplaceEmpty => 'Нічого не знайдено за запитом.';

  @override
  String get skillsInstalledBadge => 'Встановлено';

  @override
  String get skillsInstallAction => 'Встановити';

  @override
  String get skillsInstallToGlobal => 'Встановити в Global';

  @override
  String get skillsInstallToProject => 'Встановити в Project';

  @override
  String skillsInstalledToast(String name) {
    return '$name · встановлено';
  }

  @override
  String get skillsTabGlobalTooltip => 'Навички, доступні в усіх проєктах';

  @override
  String get skillsTabProjectTooltip => 'Навички лише для цього проєкту';

  @override
  String get skillsTabMarketplaceTooltip =>
      'Перегляд і встановлення готових навичок';

  @override
  String get skillsPreviewClose => 'Закрити';

  @override
  String get skillsCategoryAll => 'Усі';

  @override
  String get skillsCategoryCoding => 'Код';

  @override
  String get skillsCategoryWriting => 'Тексти';

  @override
  String get skillsCategoryResearch => 'Дослідження';

  @override
  String get skillsCategoryDesign => 'Дизайн';

  @override
  String get skillsCategoryProductivity => 'Продуктивність';

  @override
  String get skillsCategoryData => 'Дані';

  @override
  String get skillsCategoryOther => 'Інше';

  @override
  String get skillsMarketDescCodeReviewer =>
      'Експертний огляд коду: баги, безпека, підтримуваність.';

  @override
  String get skillsMarketDescCleanCode =>
      'Перетворює робочий код на чистий і читабельний (Uncle Bob).';

  @override
  String get skillsMarketDescDry => 'Усуває дублювання знань і бізнес-логіки.';

  @override
  String get skillsMarketDescArchitectReview =>
      'Огляд архітектури за принципами чистих розподілених систем.';

  @override
  String get skillsMarketDescBackendArchitect =>
      'Проєктування масштабованих API, сервісів і даних.';

  @override
  String get skillsMarketDescFlutterExpert =>
      'Dart 3, просунуті віджети та мультиплатформна збірка.';

  @override
  String get skillsMarketDescAgentsMd =>
      'Створення та підтримка стислих, ємних agent-доків.';

  @override
  String get skillsMarketDescUxCopy => 'Зрозумілий, людяний UX-мікротекст.';

  @override
  String get skillsMarketDescDeepResearch =>
      'Планування, пошук і синтез дослідницьких звітів.';

  @override
  String get skillsMarketDescUiUxDesigner =>
      'Доступні, сучасні та швидкі інтерфейси.';

  @override
  String get skillsMarketDescUxuiPrinciples =>
      'Базові принципи UX/UI для будь-якого інтерфейсу.';

  @override
  String get skillsMarketDescCommit =>
      'Conventional-коміти з коректними посиланнями на задачі.';

  @override
  String get skillsMarketDescToolDesign =>
      'Створення інструментів, зручних для агентів.';

  @override
  String get skillsMarketDescProductManager =>
      'Вимоги, роадмапи та продуктові рішення.';

  @override
  String get skillsMarketDescDataScientist =>
      'Просунута аналітика, ML і статистичне моделювання.';

  @override
  String get skillsMarketDescDatabaseOptimizer =>
      'Оптимізація запитів і масштабовані схеми БД.';

  @override
  String get skillsMarketDescDebugger =>
      'Системне налагодження помилок і падінь тестів.';

  @override
  String get skillsMarketDescSecurityAuditor =>
      'Аудит вразливостей і виправлення небезпечного коду.';

  @override
  String get commonSave => 'Зберегти';

  @override
  String get commonCancel => 'Скасувати';

  @override
  String get commonAdd => 'Додати';

  @override
  String get commonRemove => 'Видалити';

  @override
  String get commonEdit => 'Змінити';
}
