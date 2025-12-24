// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appName => 'ChatORAI Chat AI';

  @override
  String get settings => 'Налаштування';

  @override
  String get openRouterConfiguration => 'Конфігурація OpenRouter';

  @override
  String get apiKey => 'API ключ';

  @override
  String get enterApiKey => 'Введіть ваш OpenRouter API ключ';

  @override
  String get baseUrl => 'Base URL';

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
  String get increaseContrast => 'Збільшити контрастність для кращої читабельності';

  @override
  String get wideScreenMode => 'Режим широкого екрану';

  @override
  String get useFullScreenWidth => 'Використовувати всю ширину екрану для чату';

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
  String get resetAllSettings => 'Скинути всі налаштування до значень за замовчуванням';

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
  String get settingsSaved => 'Налаштування збережено!';

  @override
  String get settingsReset => 'Налаштування скинуто до значень за замовчуванням';

  @override
  String get appInfo => 'Інформація';

  @override
  String get appDescription => 'Додаток для спілкування з AI моделями через OpenRouter API.\n\nМожливості:\n• Спілкування з різними AI моделями\n• Збереження історії чатів\n• Темна та світла теми\n• Адаптивний інтерфейс\n\nВерсія: 1.0.0\n\nРозроблено з ❤️ з використанням Flutter';

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
  String get chatSharingNotImplemented => 'Функція обміну чатом ще не реалізована';

  @override
  String get newChat => 'Новий чат';

  @override
  String get noChatsYet => 'Поки що немає чатів';

  @override
  String get startConversation => 'Почніть розмову, натиснувши \"Новий чат\"';

  @override
  String get reasoning => 'Міркування';

  @override
  String get tapToExpand => 'Натисніть щоб розгорнути';

  @override
  String get collapse => 'Згорнути';

  @override
  String get expand => 'Розгорнути';

  @override
  String chatRenamedTo(Object title) {
    return 'Чат перейменовано на: $title';
  }

  @override
  String get appTitle => 'Chat AI';

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
  String get ok => 'ОК';

  @override
  String get modelSelected => 'Модель обрано';

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
  String get multimodal => 'Мультимодально';

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
  String get features => 'Особливості';

  @override
  String get featuresDisplayedBasedOnActualModelCapabilities => 'Особливості відображаються на основі реальних можливостей моделі';

  @override
  String get noModelsFound => 'Моделі не знайдені';

  @override
  String get noAvailableModels => 'Немає доступних моделей';

  @override
  String get tryADifferentSearchQuery => 'Спробуйте інший пошуковий запит';

  @override
  String get tryRefreshingOrCheckYourInternetConnection => 'Спробуйте оновити або перевірте підключення до інтернету';

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
  String get messageEditedAndResponseRegenerated => 'Повідомлення відредаговано та відновлено';

  @override
  String get failedToEditAndSendMessage => 'Не вдалося відредагувати та надіслати повідомлення';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'Ви впевнені, що хочете видалити це повідомлення?';

  @override
  String get areYouSureYouWantToRegenerateThisMessage => 'Ви впевнені, що хочете відновити це повідомлення?';

  @override
  String get messageDeletedSuccessfully => 'Повідомлення успішно видалено';

  @override
  String get failedToDeleteMessage => 'Не вдалося видалити повідомлення';

  @override
  String get regenerationStarted => 'Відновлення розпочато';

  @override
  String get failedToRegenerateMessage => 'Не вдалося відновити повідомлення';

  @override
  String get messageCopied => 'Повідомлення скопійовано';

  @override
  String get failedToCopyMessage => 'Не вдалося скопіювати повідомлення';

  @override
  String get messageShared => 'Поділилися повідомленням';

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
  String get regenerate => 'Відновити';

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
  String get welcomeMessage => 'Ласкаво просимо! Чим я можу допомогти сьогодні?';

  @override
  String get welcomeQuestion1 => 'Поясни квантові обчислення простими словами';

  @override
  String get welcomeQuestion2 => 'Які останні тренди в штучному інтелекті?';

  @override
  String get welcomeQuestion3 => 'Допоможи мені написати професійного листа моїй команді';

  @override
  String get welcomeQuestion4 => 'Що мені вивчити, щоб стати кращим програмістом?';

  @override
  String get welcomeQuestion5 => 'Дай 5 креативних ідей для проекту на вихідні';

  @override
  String get welcomeQuestion6 => 'Які хороші книги по особистісному зростанню?';

  @override
  String get welcomeQuestion7 => 'Допоможи придумати назви для мого стартапу';

  @override
  String get welcomeQuestion8 => 'Склади план харчування на здоровий тиждень';

  @override
  String get welcomeQuestion9 => 'Які найкращі практики для Flutter розробки?';

  @override
  String get welcomeQuestion10 => 'Поясни різницю між асинхронним та синхронним програмуванням';

  @override
  String get welcomeQuestion11 => 'Як оптимізувати код для кращої продуктивності?';

  @override
  String get welcomeQuestion12 => 'Які найкорисніші паттерни проектування?';

  @override
  String get welcomeQuestion13 => 'Навчи мене основ машинного навчання';

  @override
  String get welcomeQuestion14 => 'Які ключові концепції хмарних обчислень?';

  @override
  String get welcomeQuestion15 => 'Поясни блокчейн технологію для новачка';

  @override
  String get welcomeQuestion16 => 'Як працює інтернет з технічної точки зору?';

  @override
  String get welcomeQuestion17 => 'Які найкращі техніки продуктивності?';

  @override
  String get welcomeQuestion18 => 'Як покращити концентрацію та фокус?';

  @override
  String get welcomeQuestion19 => 'Дай розпорядок дня для максимальної продуктивності';

  @override
  String get welcomeQuestion20 => 'Які хороші звички для успіху?';

  @override
  String get welcomeQuestion21 => 'Як підготуватися до співбесіди в IT?';

  @override
  String get welcomeQuestion22 => 'Які навички в tech індустрії?';

  @override
  String get welcomeQuestion23 => 'Як домовитися про підвищення зарплати?';

  @override
  String get welcomeQuestion24 => 'Які топ tech компанії для роботи?';

  @override
  String get welcomeQuestion25 => 'Які останні прориви в космічних дослідженнях?';

  @override
  String get welcomeQuestion26 => 'Як ІІ змінює охорону здоров\'я?';

  @override
  String get welcomeQuestion27 => 'Які найзахопливіші технології 2025 року?';

  @override
  String get welcomeQuestion28 => 'Поясни майбутнє відновлюваної енергетики';

  @override
  String get welcomeQuestion29 => 'Які найважливіші філософські питання?';

  @override
  String get welcomeQuestion30 => 'Як навчитися мислити більш критично?';

  @override
  String get welcomeQuestion31 => 'Які найкращі способи вивчення нових навичок?';

  @override
  String get welcomeQuestion32 => 'Як зберегти мотивацію при вивченні складного матеріалу?';

  @override
  String get welcomeQuestion33 => 'Які мови програмування краще вчити в 2025 році?';

  @override
  String get welcomeQuestion34 => 'Як створити сильне портфоліо для IT вакансій?';

  @override
  String get welcomeQuestion35 => 'Які топ AI інструменти для продуктивності?';

  @override
  String get welcomeQuestion36 => 'Як насправді працює машинне навчання?';

  @override
  String get welcomeQuestion37 => 'Які найкращі практики для рев\'ю коду?';

  @override
  String get welcomeQuestion38 => 'Як писати чистий та підтримуваний код?';

  @override
  String get welcomeQuestion39 => 'Що таке мікросервіси і коли їх використовувати?';

  @override
  String get welcomeQuestion40 => 'Поясни різницю REST API та GraphQL';

  @override
  String get welcomeQuestion41 => 'Які хмарні платформи краще вчити?';

  @override
  String get welcomeQuestion42 => 'Як підготуватися до технічних співбесід?';

  @override
  String get welcomeQuestion43 => 'Які м\'які навички потрібні кожному розробнику?';

  @override
  String get welcomeQuestion44 => 'Як домовитися про зарплату розробнику?';

  @override
  String get welcomeQuestion45 => 'Які найкращі інструменти для віддаленої роботи?';

  @override
  String get welcomeQuestion46 => 'Як залишатися продуктивним на віддаленці?';

  @override
  String get welcomeQuestion47 => 'Які найкращі методології управління проектами?';

  @override
  String get welcomeQuestion48 => 'Як працювати з важкими колегами?';

  @override
  String get welcomeQuestion49 => 'Які найкращі книги по лідерству?';

  @override
  String get welcomeQuestion50 => 'Як запустити успішний tech стартап?';

  @override
  String get welcomeQuestion51 => 'Які останні тренди у веб-розробці?';

  @override
  String get welcomeQuestion52 => 'Як працює блокчейн технологія?';

  @override
  String get welcomeQuestion53 => 'Що таке NFT і чи варто звертати увагу?';

  @override
  String get welcomeQuestion54 => 'Поясни концепцію метавсесвіту';

  @override
  String get welcomeQuestion55 => 'Які найкращі AI моделі для програмування?';

  @override
  String get welcomeQuestion56 => 'Як ефективно використовувати ChatGPT?';

  @override
  String get welcomeQuestion57 => 'Які етичні аспекти AI?';

  @override
  String get welcomeQuestion58 => 'Як AI змінить роботу в майбутньому?';

  @override
  String get welcomeQuestion59 => 'Які найкращі практики кібербезпеки?';

  @override
  String get welcomeQuestion60 => 'Як захистити свою приватність в інтернеті?';

  @override
  String get welcomeQuestion61 => 'Які найкращі інструменти для data science?';

  @override
  String get welcomeQuestion62 => 'Як ефективно візуалізувати дані?';

  @override
  String get welcomeQuestion63 => 'Які найкращі фреймворки для мобільних додатків?';

  @override
  String get welcomeQuestion64 => 'Як створювати кросплатформенні додатки?';

  @override
  String get welcomeQuestion65 => 'Які найкращі движки для розробки ігор?';

  @override
  String get welcomeQuestion66 => 'Як почати працювати з 3D моделюванням?';

  @override
  String get welcomeQuestion67 => 'Які найкращі інструменти для відеомонтажу?';

  @override
  String get welcomeQuestion68 => 'Як створювати контент, який залучає?';

  @override
  String get welcomeQuestion69 => 'Які найкращі стратегії для соцмереж?';

  @override
  String get welcomeQuestion70 => 'Як побудувати особистий бренд?';

  @override
  String get welcomeQuestion71 => 'Які найкращі поради для нетворкінгу?';

  @override
  String get welcomeQuestion72 => 'Як зробити чудову презентацію?';

  @override
  String get welcomeQuestion73 => 'Які найкращі техніки тайм-менеджменту?';

  @override
  String get welcomeQuestion74 => 'Як уникнути вигорання?';

  @override
  String get welcomeQuestion75 => 'Які найкращі додатки для медитації?';

  @override
  String get welcomeQuestion76 => 'Як покращити якість сну?';

  @override
  String get welcomeQuestion77 => 'Які найкращі тренування?';

  @override
  String get welcomeQuestion78 => 'Як харчуватися здоровою їжею з обмеженим бюджетом?';

  @override
  String get welcomeQuestion79 => 'Які найкращі місця для подорожей для tech спеціалістів?';

  @override
  String get welcomeQuestion80 => 'Як швидко вивчити нову мову?';

  @override
  String get welcomeQuestion81 => 'Які найкращі практики для віддаленої командної роботи?';

  @override
  String get welcomeQuestion82 => 'Як проводити ефективні рев\'ю коду?';

  @override
  String get welcomeQuestion83 => 'Які топ навички для software архітекторів?';

  @override
  String get welcomeQuestion84 => 'Як проектувати масштабовані бази даних?';

  @override
  String get welcomeQuestion85 => 'Які найкращі DevOps інструменти для вивчення?';

  @override
  String get welcomeQuestion86 => 'Як впроваджувати CI/CD пайплайни?';

  @override
  String get welcomeQuestion87 => 'Що таке оркестрація контейнерів?';

  @override
  String get welcomeQuestion88 => 'Поясни переваги serverless обчислень';

  @override
  String get welcomeQuestion89 => 'Які найкращі практики для безпеки API?';

  @override
  String get welcomeQuestion90 => 'Як оптимізувати продуктивність мобільних додатків?';

  @override
  String get welcomeQuestion91 => 'Що таке прогресивні веб-додатки?';

  @override
  String get welcomeQuestion92 => 'Як створювати доступні веб-додатки?';

  @override
  String get welcomeQuestion93 => 'Які найкращі принципи UI/UX дизайну?';

  @override
  String get welcomeQuestion94 => 'Як ефективно проводити користувацькі дослідження?';

  @override
  String get welcomeQuestion95 => 'Які найкращі стратегії A/B тестування?';

  @override
  String get welcomeQuestion96 => 'Як аналізувати поведінку користувачів?';

  @override
  String get welcomeQuestion97 => 'Які найкращі техніки growth hacking?';

  @override
  String get welcomeQuestion98 => 'Як побудувати спільноту навколо продукту?';

  @override
  String get welcomeQuestion99 => 'Які найкращі інструменти для підтримки клієнтів?';

  @override
  String get welcomeQuestion100 => 'Як ефективно обробляти відгуки клієнтів?';

  @override
  String get welcomeQuestion101 => 'У чому різниця між React та Vue?';

  @override
  String get welcomeQuestion102 => 'Як TypeScript покращує розробку на JavaScript?';

  @override
  String get welcomeQuestion103 => 'Які найкращі практики для проектування REST API?';

  @override
  String get welcomeQuestion104 => 'Як реалізувати аутентифікацію у веб-додатках?';

  @override
  String get welcomeQuestion105 => 'Які переваги GraphQL перед REST?';

  @override
  String get welcomeQuestion106 => 'Як оптимізувати запити до бази даних для продуктивності?';

  @override
  String get welcomeQuestion107 => 'Що таке паттерни архітектури мікросервісів?';

  @override
  String get welcomeQuestion108 => 'Як реалізувати стратегії кешування?';

  @override
  String get welcomeQuestion109 => 'Які найкращі фреймворки для тестування JavaScript?';

  @override
  String get welcomeQuestion110 => 'Як писати unit-тести для React-компонентів?';

  @override
  String get welcomeQuestion111 => 'Що таке принципи SOLID в ООП?';

  @override
  String get welcomeQuestion112 => 'Як реалізувати паттерни проектування в Python?';

  @override
  String get welcomeQuestion113 => 'Які найкращі практики для Git workflow?';

  @override
  String get welcomeQuestion114 => 'Як ефективно розв\'язувати merge conflicts?';

  @override
  String get welcomeQuestion115 => 'Які найкращі практики для контейнерізації?';

  @override
  String get welcomeQuestion116 => 'Як захистити Docker контейнери?';

  @override
  String get welcomeQuestion117 => 'Що таке стратегії розгортання в Kubernetes?';

  @override
  String get welcomeQuestion118 => 'Як моніторити продуктивність додатку?';

  @override
  String get welcomeQuestion119 => 'Які найкращі практики для логування?';

  @override
  String get welcomeQuestion120 => 'Як реалізувати обробку помилок у розподілених системах?';

  @override
  String get continueConversation => 'Продовжити діалог';

  @override
  String get generatingSuggestions => 'Генерація пропозицій...';

  @override
  String get searchChats => 'Пошук чатів...';

  @override
  String noChatsFound(Object query) {
    return 'Чати не знайдені для \"$query\"';
  }

  @override
  String get tryDifferentSearchTerm => 'Спробуйте інший пошуковий термін';

  @override
  String get appShortName => 'ChatORAI';

  @override
  String get typeYourMessage => 'Введіть ваше повідомлення...';

  @override
  String get addImageToFile => '+ додати зображення у файл';

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
  String get tapHeartToAddFavorites => 'Натисніть на сердечко біля моделей, щоб додати їх до вибраних';
}
