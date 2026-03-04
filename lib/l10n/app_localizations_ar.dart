// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ChatORAI';

  @override
  String get settings => 'الإعدادات';

  @override
  String get providerConfiguration => 'تكوين المزود';

  @override
  String get apiKey => 'مفتاح API';

  @override
  String get enterApiKey => 'أدخل مفتاح OpenRouter API الخاص بك';

  @override
  String get baseUrl => 'عنوان URL الأساسي';

  @override
  String get validateApiKey => 'تحقق من مفتاح API';

  @override
  String get apiKeyValid => 'مفتاح API صالح';

  @override
  String get apiKeyInvalid => 'صيغة مفتاح API غير صالحة';

  @override
  String get apiKeyEmpty => 'لا يمكن أن يكون مفتاح API فارغاً';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get system => 'النظام';

  @override
  String get useSystemTheme => 'استخدام سمة النظام';

  @override
  String get light => 'فاتح';

  @override
  String get useLightTheme => 'استخدام السمة الفاتحة';

  @override
  String get dark => 'داكن';

  @override
  String get useDarkTheme => 'استخدام السمة الداكنة';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String currentSize(Object percentage) {
    return 'الحجم الحالي: $percentage%';
  }

  @override
  String get accessibility => 'إمكانية الوصول';

  @override
  String get reduceMotion => 'تقليل الحركة';

  @override
  String get disableAnimation => 'تعطيل أو تقليل تأثيرات الرسوم المتحركة';

  @override
  String get highContrast => 'تباين عالي';

  @override
  String get increaseContrast => 'زيادة التباين لتحسين القراءة';

  @override
  String get wideScreenMode => 'وضع الشاشة العريضة';

  @override
  String get useFullScreenWidth => 'استخدام عرض الشاشة بالكامل لمحتوى الدردشة';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get russian => 'الروسية';

  @override
  String get ukrainian => 'الأوكرانية';

  @override
  String get arabic => 'العربية (من اليمين لليسار)';

  @override
  String get chinese => 'الصينية';

  @override
  String get japanese => 'اليابانية';

  @override
  String get resetSettings => 'إعادة تعيين الإعدادات';

  @override
  String get resetAllSettings => 'إعادة تعيين جميع الإعدادات إلى القيم الافتراضية';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';

  @override
  String get copy => 'نسخ';

  @override
  String get apiKeyCopied => 'تم نسخ مفتاح API';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات!';

  @override
  String get settingsReset => 'تمت إعادة تعيين الإعدادات إلى القيم الافتراضية';

  @override
  String get appInfo => 'معلومات التطبيق';

  @override
  String get appDescription => 'تطبيق دردشة مع نماذج الذكاء الاصطناعي عبر OpenRouter API.\n\nالميزات:\n• الدردشة مع نماذج ذكاء اصطناعي مختلفة\n• تخزين سجل الدردشة\n• السمات الداكنة والفاتحة\n• واجهة تكيفية\n\nالإصدار: 1.0.1.1\n\nتم التطوير ب ❤️ باستخدام Flutter';

  @override
  String get shareChat => 'مشاركة الدردشة';

  @override
  String get copyChat => 'نسخ الدردشة';

  @override
  String get renameChat => 'إعادة تسمية الدردشة';

  @override
  String get deleteChat => 'حذف الدردشة';

  @override
  String get failedToShowMenu => 'فشل في عرض القائمة';

  @override
  String get failedToRenameChat => 'فشل في إعادة تسمية الدردشة';

  @override
  String get failedToCopyChat => 'فشل في نسخ الدردشة';

  @override
  String get chatSharingNotImplemented => 'مشاركة الدردشة لم يتم تنفيذها بعد';

  @override
  String get newChat => 'دردشة جديدة';

  @override
  String get noChatsYet => 'لا توجد دردشات بعد';

  @override
  String get startConversation => 'ابدأ محادثة عن طريق النقر على \"دردشة جديدة\"';

  @override
  String get reasoning => 'التفكير';

  @override
  String get tapToExpand => 'اضغط للتوسيع';

  @override
  String get collapse => 'طي';

  @override
  String get expand => 'توسيع';

  @override
  String chatRenamedTo(Object title) {
    return 'تمت إعادة تسمية الدردشة إلى: $title';
  }

  @override
  String get appTitle => 'دردشة ذكاء اصطناعي';

  @override
  String get justNow => 'الآن';

  @override
  String minAgo(Object minutes) {
    return 'قبل $minutes دقيقة';
  }

  @override
  String get onlyOneMinuteAgo => 'قبل دقيقة واحدة';

  @override
  String hoursAgo(Object hours) {
    return 'قبل $hours ساعة';
  }

  @override
  String get onlyOneHourAgo => 'قبل ساعة واحدة';

  @override
  String daysAgo(Object days) {
    return 'قبل $days يوم';
  }

  @override
  String get onlyOneDayAgo => 'قبل يوم واحد';

  @override
  String get renameChatTitle => 'إعادة تسمية الدردشة';

  @override
  String get enterNewChatName => 'أدخل اسم الدردشة الجديد';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get ok => 'موافق';

  @override
  String get modelSelected => 'تم تحديد النموذج';

  @override
  String get errorLoadingModels => 'خطأ في تحميل النماذج';

  @override
  String get models => 'النماذج';

  @override
  String get searchModels => 'بحث عن نماذج';

  @override
  String get refresh => 'تحديث';

  @override
  String get details => 'التفاصيل';

  @override
  String get context => 'السياق';

  @override
  String get free => 'مجاني';

  @override
  String get paid => 'مدفوع';

  @override
  String get multimodal => 'متعدد الوسائط';

  @override
  String get vision => 'الرؤية';

  @override
  String get tools => 'الأدوات';

  @override
  String get available => 'متاح';

  @override
  String get description => 'الوصف';

  @override
  String get technicalDetails => 'التفاصيل التقنية';

  @override
  String get provider => 'المزود';

  @override
  String get inputTokens => 'رموز الإدخال';

  @override
  String get notAvailable => 'غير متاح';

  @override
  String get outputTokens => 'رموز الإخراج';

  @override
  String get features => 'الميزات';

  @override
  String get featuresDisplayedBasedOnActualModelCapabilities => 'يتم عرض الميزات بناءً على قدرات النموذج الفعلية';

  @override
  String get noModelsFound => 'لم يتم العثور على نماذج';

  @override
  String get noAvailableModels => 'لا توجد نماذج متاحة';

  @override
  String get tryADifferentSearchQuery => 'جرب استعلام بحث مختلف';

  @override
  String get tryRefreshingOrCheckYourInternetConnection => 'حاول التحديث أو تحقق من اتصال الإنترنت';

  @override
  String get aiIsTyping => 'الذكاء الاصطناعي يكتب';

  @override
  String get failedToSendMessage => 'فشل في إرسال الرسالة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get enterYourMessage => 'أدخل رسالتك...';

  @override
  String get saveAndSend => 'حفظ وإرسال';

  @override
  String get messageEditedSuccessfully => 'تم تعديل الرسالة بنجاح';

  @override
  String get failedToEditMessage => 'فشل في تعديل الرسالة';

  @override
  String get messageEditedAndResponseRegenerated => 'تم تعديل الرسالة وإعادة توليد الاستجابة';

  @override
  String get failedToEditAndSendMessage => 'فشل في تعديل وإرسال الرسالة';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'هل أنت متأكد أنك تريد حذف هذه الرسالة؟';

  @override
  String confirmDeleteMessage(Object chatTitle) {
    return 'هل أنت متأكد أنك تريد حذف الدردشة\"$chatTitle\"؟';
  }

  @override
  String get areYouSureYouWantToRegenerateThisMessage => 'هل أنت متأكد أنك تريد إعادة توليد هذه الرسالة؟';

  @override
  String modelDoesNotSupportImages(Object modelId) {
    return 'النموذج $modelId لا يدعم الصور. يمكنك إرفاق صورة، لكن الإرسال لن يعمل.';
  }

  @override
  String chatTitleUpdated(Object title) {
    return 'تم إعادة تسمية الدردشة إلى: $title';
  }

  @override
  String get messageDeletedSuccessfully => 'تم حذف الرسالة بنجاح';

  @override
  String get failedToDeleteMessage => 'فشل في حذف الرسالة';

  @override
  String get regenerationStarted => 'بدأت إعادة التوليد';

  @override
  String get failedToRegenerateMessage => 'فشل في إعادة توليد الرسالة';

  @override
  String get messageCopied => 'تم نسخ الرسالة';

  @override
  String get failedToCopyMessage => 'فشل في نسخ الرسالة';

  @override
  String get messageShared => 'تمت مشاركة الرسالة';

  @override
  String get failedToShareMessage => 'فشل في مشاركة الرسالة';

  @override
  String get edit => 'تعديل';

  @override
  String get share => 'مشاركة';

  @override
  String get copyMessage => 'نسخ الرسالة';

  @override
  String get delete => 'حذف';

  @override
  String get listen => 'استمع';

  @override
  String get regenerate => 'إعادة توليد';

  @override
  String get continueResponse => 'متابعة الاستجابة';

  @override
  String get like => 'أعجبني';

  @override
  String get dislike => 'لم يعجبني';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get failedToCopy => 'فشل في النسخ';

  @override
  String get messageDeleted => 'تم حذف الرسالة';

  @override
  String get errorMessage => 'رسالة خطأ';

  @override
  String get welcomeMessage => 'مرحباً! كيف يمكنني مساعدتك اليوم؟';

  @override
  String get welcomeQuestion1 => 'اشرح حوسبة الكم بعبارات بسيطة';

  @override
  String get welcomeQuestion2 => 'ما هي أحدث الاتجاهات في الذكاء الاصطناعي؟';

  @override
  String get welcomeQuestion3 => 'ساعدني في كتابة بريد إلكتروني احترافي لفريقي';

  @override
  String get welcomeQuestion4 => 'ماذا يجب أن أتعلم لأصبح مبرمجاً أفضل؟';

  @override
  String get welcomeQuestion5 => 'أعطني 5 أفكار إبداعية لمشروع نهاية الأسبوع';

  @override
  String get welcomeQuestion6 => 'ما هي بعض الكتب الجيدة للتنمية الشخصية؟';

  @override
  String get welcomeQuestion7 => 'ساعدني في ابتكار أسماء لشركتي الناشئة';

  @override
  String get welcomeQuestion8 => 'أنشئ خطة وجبات ل أسبوع صحي';

  @override
  String get welcomeQuestion9 => 'ما هي أفضل الممارسات لتطوير Flutter؟';

  @override
  String get welcomeQuestion10 => 'اشرح الفرق بين البرمجة غير المتزامنة والمتزامنة';

  @override
  String get welcomeQuestion11 => 'كيف أحسّن أداء الكود الخاص بي؟';

  @override
  String get welcomeQuestion12 => 'ما هي أنماط التصميم الأكثر فائدة؟';

  @override
  String get welcomeQuestion13 => 'علّمني أساسيات التعلم الآلي';

  @override
  String get welcomeQuestion14 => 'ما هي المفاهيم الأساسية للحوسبة السحابية؟';

  @override
  String get welcomeQuestion15 => 'اشرح تقنية البلوك تشين للمبتدئين';

  @override
  String get welcomeQuestion16 => 'كيف يعمل الإنترنت من منظور تقني؟';

  @override
  String get welcomeQuestion17 => 'ما هي أفضل تقنيات الإنتاجية؟';

  @override
  String get welcomeQuestion18 => 'كيف يمكنني تحسين تركيزي وانتباهي؟';

  @override
  String get welcomeQuestion19 => 'أعطني روتين يومي للإنتاجية القصوى';

  @override
  String get welcomeQuestion20 => 'ما هي بعض العادات الجيدة للنجاح؟';

  @override
  String get welcomeQuestion21 => 'كيف أستعد لمقابلة هندسة البرمجيات؟';

  @override
  String get welcomeQuestion22 => 'ما هي المهارات الأكثر قيمة في صناعة التكنولوجيا؟';

  @override
  String get welcomeQuestion23 => 'كيف أتفاوض على زيادة الراتب؟';

  @override
  String get welcomeQuestion24 => 'ما هي أفضل شركات التكنولوجيا للعمل فيها؟';

  @override
  String get welcomeQuestion25 => 'ما هي أحدث الاختراقات في استكشاف الفضاء؟';

  @override
  String get welcomeQuestion26 => 'كيف يغير الذكاء الاصطناعي الرعاية الصحية؟';

  @override
  String get welcomeQuestion27 => 'ما هي أكثر تقنيات عام 2025 إثارة؟';

  @override
  String get welcomeQuestion28 => 'اشرح مستقبل الطاقة المتجددة';

  @override
  String get welcomeQuestion29 => 'ما هي أهم الأسئلة الفلسفية؟';

  @override
  String get welcomeQuestion30 => 'كيف أفكر بشكل نقدي أكثر عن المشاكل؟';

  @override
  String get welcomeQuestion31 => 'ما هي أفضل الطرق لتعلم مهارات جديدة؟';

  @override
  String get welcomeQuestion32 => 'كيف أحافظ على الحافز عند تعلم شيء صعب؟';

  @override
  String get welcomeQuestion33 => 'ما هي أفضل لغات البرمجة لتعلمها في عام 2025؟';

  @override
  String get welcomeQuestion34 => 'كيف أبني محفظة قوية لوظائف التكنولوجيا؟';

  @override
  String get welcomeQuestion35 => 'ما هي أفضل أدوات الذكاء الاصطناعي للإنتاجية؟';

  @override
  String get welcomeQuestion36 => 'كيف يعمل التعلم الآلي فعلياً؟';

  @override
  String get welcomeQuestion37 => 'ما هي أفضل الممارسات لمراجعة الكود؟';

  @override
  String get welcomeQuestion38 => 'كيف أكتب كوداً نظيفاً وسهلاً للصيانة؟';

  @override
  String get welcomeQuestion39 => 'ما هي الخدمات الصغيرة ومتى تستخدمها؟';

  @override
  String get welcomeQuestion40 => 'اشرح الفرق بين REST API و GraphQL';

  @override
  String get welcomeQuestion41 => 'ما هي أفضل منصات سحابية لتعلمها؟';

  @override
  String get welcomeQuestion42 => 'كيف أستعد للمقابلات التقنية؟';

  @override
  String get welcomeQuestion43 => 'ما هي المهارات الناعمة التي يحتاجها كل مطور؟';

  @override
  String get welcomeQuestion44 => 'كيف أتفاوض على الراتب كمطور؟';

  @override
  String get welcomeQuestion45 => 'ما هي أفضل أدوات العمل عن بعد؟';

  @override
  String get welcomeQuestion46 => 'كيف أبقى منتجاً عند العمل من المنزل؟';

  @override
  String get welcomeQuestion47 => 'ما هي أفضل منهجيات إدارة المشاريع؟';

  @override
  String get welcomeQuestion48 => 'كيف أتعامل مع الزملاء الصعبين؟';

  @override
  String get welcomeQuestion49 => 'ما هي أفضل الكتب عن القيادة؟';

  @override
  String get welcomeQuestion50 => 'كيف أطلق شركة ناشئة ناجحة في مجال التكنولوجيا؟';

  @override
  String get welcomeQuestion51 => 'ما هي أحدث الاتجاهات في تطوير الويب؟';

  @override
  String get welcomeQuestion52 => 'كيف تعمل تقنية البلوك تشين؟';

  @override
  String get welcomeQuestion53 => 'ما هي NFT وهل يجب أن أهتم؟';

  @override
  String get welcomeQuestion54 => 'اشرح مفهوم الميتافيرس';

  @override
  String get welcomeQuestion55 => 'ما هي أفضل نماذج الذكاء الاصطناعي للبرمجة؟';

  @override
  String get welcomeQuestion56 => 'كيف أستخدم ChatGPT بفعالية؟';

  @override
  String get welcomeQuestion57 => 'ما هي أخلاقيات الذكاء الاصطناعي؟';

  @override
  String get welcomeQuestion58 => 'كيف سيغير الذكاء الاصطناعي الوظائف في المستقبل؟';

  @override
  String get welcomeQuestion59 => 'ما هي أفضل ممارسات الأمن السيبراني؟';

  @override
  String get welcomeQuestion60 => 'كيف أحمي خصوصيتي على الإنترنت؟';

  @override
  String get welcomeQuestion61 => 'ما هي أفضل أدوات علم البيانات؟';

  @override
  String get welcomeQuestion62 => 'كيف أظهر البيانات بشكل فعال؟';

  @override
  String get welcomeQuestion63 => 'ما هي أفضل أطر تطبيقات الجوال؟';

  @override
  String get welcomeQuestion64 => 'كيف أبني تطبيقات متعددة المنصات؟';

  @override
  String get welcomeQuestion65 => 'ما هي أفضل محركات تطوير الألعاب؟';

  @override
  String get welcomeQuestion66 => 'كيف أبدأ في النمذجة ثلاثية الأبعاد؟';

  @override
  String get welcomeQuestion67 => 'ما هي أفضل أدوات تحرير الفيديو؟';

  @override
  String get welcomeQuestion68 => 'كيف أنشئ محتوى جذاباً؟';

  @override
  String get welcomeQuestion69 => 'ما هي أفضل استراتيجيات وسائل التواصل الاجتماعي؟';

  @override
  String get welcomeQuestion70 => 'كيف أبني علامة تجارية شخصية؟';

  @override
  String get welcomeQuestion71 => 'ما هي أفضل نصائح للتوظيف؟';

  @override
  String get welcomeQuestion72 => 'كيف أقدم عرضاً تقديماً ممتازاً؟';

  @override
  String get welcomeQuestion73 => 'ما هي أفضل تقنيات إدارة الوقت؟';

  @override
  String get welcomeQuestion74 => 'كيف أتجنب الاحتراق الوظيفي؟';

  @override
  String get welcomeQuestion75 => 'ما هي أفضل تطبيقات التأمل؟';

  @override
  String get welcomeQuestion76 => 'كيف أحسن جودة النوم؟';

  @override
  String get welcomeQuestion77 => 'ما هي أفضل التمارين الرياضية؟';

  @override
  String get welcomeQuestion78 => 'كيف أكل بشكل صحي بميزانية محدودة؟';

  @override
  String get welcomeQuestion79 => 'ما هي أفضل وجهات السفر لعمال التكنولوجيا؟';

  @override
  String get welcomeQuestion80 => 'كيف أتعلم لغة جديدة بسرعة؟';

  @override
  String get welcomeQuestion81 => 'ما هي أفضل الممارسات للتعاون عن بعد؟';

  @override
  String get welcomeQuestion82 => 'كيف أجري مراجعات كود فعالة؟';

  @override
  String get welcomeQuestion83 => 'ما هي المهارات الرئيسية لمصممي البرمجيات؟';

  @override
  String get welcomeQuestion84 => 'كيف أصمم أنظمة قواعد بيانات قابلة للتطوير؟';

  @override
  String get welcomeQuestion85 => 'ما هي أفضل أدوات DevOps لتعلمها؟';

  @override
  String get welcomeQuestion86 => 'كيف أنفذ خطوط أنابيب CI/CD؟';

  @override
  String get welcomeQuestion87 => 'ما هي منصات أوركسترا Containers؟';

  @override
  String get welcomeQuestion88 => 'اشرح مزايا الحوسبة بدون خادم';

  @override
  String get welcomeQuestion89 => 'ما هي أفضل ممارسات أمان API؟';

  @override
  String get welcomeQuestion90 => 'كيف أحسّن أداء تطبيقات الجوال؟';

  @override
  String get welcomeQuestion91 => 'ما هي تطبيقات الويب التقدمية؟';

  @override
  String get welcomeQuestion92 => 'كيف أبني تطبيقات ويب قابلة للوصول؟';

  @override
  String get welcomeQuestion93 => 'ما هي أفضل مبادئ تصميم UI/UX؟';

  @override
  String get welcomeQuestion94 => 'كيف أجري أبحاث المستخدمين بفعالية؟';

  @override
  String get welcomeQuestion95 => 'ما هي أفضل استراتيجيات اختبار A/B؟';

  @override
  String get welcomeQuestion96 => 'كيف أحلل سلوك المستخدمين؟';

  @override
  String get welcomeQuestion97 => 'ما هي أفضل تقنيات هاكينغ النمو؟';

  @override
  String get welcomeQuestion98 => 'كيف أبني مجتمعاً حول منتجك؟';

  @override
  String get welcomeQuestion99 => 'ما هي أفضل أدوات دعم العملاء؟';

  @override
  String get welcomeQuestion100 => 'كيف أتعامل مع ملاحظات العملاء بفعالية؟';

  @override
  String get welcomeQuestion101 => 'ما الفرق بين React و Vue؟';

  @override
  String get welcomeQuestion102 => 'كيف يحسن TypeScript تطوير JavaScript؟';

  @override
  String get welcomeQuestion103 => 'ما هي أفضل ممارسات تصميم REST API؟';

  @override
  String get welcomeQuestion104 => 'كيف أنفذ المصادقة في تطبيقات الويب؟';

  @override
  String get welcomeQuestion105 => 'ما هي مزايا GraphQL مقابل REST؟';

  @override
  String get welcomeQuestion106 => 'كيف أحسّن استعلامات قاعدة البيانات للأداء؟';

  @override
  String get welcomeQuestion107 => 'ما هي أنماط معمارية الخدمات الصغيرة؟';

  @override
  String get welcomeQuestion108 => 'كيف أنفذ استراتيجيات التخزين المؤقت؟';

  @override
  String get welcomeQuestion109 => 'ما هي أفضل أطر اختبار JavaScript؟';

  @override
  String get welcomeQuestion110 => 'كيف أكتب اختبارات وحدة لمكونات React؟';

  @override
  String get welcomeQuestion111 => 'ما هي مبادئ SOLID في البرمجة الكائنية؟';

  @override
  String get welcomeQuestion112 => 'كيف أنفذ أنماط التصميم في Python؟';

  @override
  String get welcomeQuestion113 => 'ما هي أفضل ممارسات سير عمل Git؟';

  @override
  String get welcomeQuestion114 => 'كيف أحل تعارضات الدمج بفعالية؟';

  @override
  String get welcomeQuestion115 => 'ما هي أفضل ممارسات الحاويات؟';

  @override
  String get welcomeQuestion116 => 'كيف أحمي حاويات Docker؟';

  @override
  String get welcomeQuestion117 => 'ما هي استراتيجيات النشر في Kubernetes؟';

  @override
  String get welcomeQuestion118 => 'كيف أراقب أداء التطبيق؟';

  @override
  String get welcomeQuestion119 => 'ما هي أفضل ممارسات التسجيل؟';

  @override
  String get welcomeQuestion120 => 'كيف أنفذ معالجة الأخطاء في الأنظمة الموزعة؟';

  @override
  String get continueConversation => 'متابعة المحادثة';

  @override
  String get generatingSuggestions => 'جاري إنشاء الاقتراحات...';

  @override
  String get searchChats => 'البحث في الدردشات...';

  @override
  String noChatsFound(Object query) {
    return 'لم يتم العثور على دردشات لـ \"$query\"';
  }

  @override
  String get tryDifferentSearchTerm => 'جرب مصطلح بحث مختلف';

  @override
  String get appShortName => 'ChatORAI';

  @override
  String get typeYourMessage => 'اكتب رسالتك...';

  @override
  String get addImage => 'صورة';

  @override
  String get addCamera => 'الكاميرا';

  @override
  String get addFile => 'ملف';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get searchFavorites => 'البحث في المفضلة...';

  @override
  String get showAllModels => 'إظهار جميع النماذج';

  @override
  String get showFavoritesOnly => 'إظهار المفضلة فقط';

  @override
  String get noFavoriteModels => 'لا توجد نماذج مفضلة';

  @override
  String get tapHeartToAddFavorites => 'اضغط على أيقونة القلب على النماذج لإضافتها إلى المفضلة';

  @override
  String get startListening => 'بدء الإدخال الصوتي';

  @override
  String get stopListening => 'إيقاف الإدخال الصوتي';

  @override
  String get listening => 'تحدث الآن...';

  @override
  String get micUnavailable => 'الميكروفون غير متاح';

  @override
  String get sendMessage => 'إرسال الرسالة';

  @override
  String get modelSettings => 'إعدادات النموذج';

  @override
  String get temperature => 'درجة الحرارة';

  @override
  String get temperatureDescription => 'التحكم في العشوائية: أقل = أكثر تركيزًا، أعلى = أكثر إبداعًا';

  @override
  String get maxTokens => 'الحد الأقصى للرموز';

  @override
  String get maxTokensDescription => 'الحد الأقصى لطول الاستجابة المولدة';

  @override
  String get topP => 'Top P';

  @override
  String get topPDescription => 'العينة النواة: أقل = أكثر تركيزًا، أعلى = أكثر تنوعًا';

  @override
  String get frequencyPenalty => 'عقوبة التكرار';

  @override
  String get frequencyPenaltyDescription => 'يقلل من تكرار الرموز المتشابهة';

  @override
  String get presencePenalty => 'عقوبة الوجود';

  @override
  String get presencePenaltyDescription => 'يشجع على المواضيع الجديدة';

  @override
  String get systemPrompt => 'موجه النظام';

  @override
  String get systemPromptDescription => 'تعليمات مساعد الذكاء الاصطناعي';

  @override
  String get streamResponse => 'استجابة تدفق';

  @override
  String get streamResponseDescription => 'تلقى الاستجابات في الوقت الفعلي';

  @override
  String get resetToDefaults => 'إعادة تعيين إلى الافتراضي';

  @override
  String get applySettings => 'تطبيق الإعدادات';

  @override
  String get modelParameters => 'معلمات النموذج';

  @override
  String get activeModel => 'النموذج النشط';

  @override
  String get noModelSelected => 'لم يتم اختيار نموذج';

  @override
  String get settingsApplied => 'تم تطبيق الإعدادات بنجاح';

  @override
  String get enableReasoning => 'تمكين التفكير';

  @override
  String get enableReasoningDescription => 'تضمين تفكير/استدلال النموذج في الردود';

  @override
  String apiLimitExceeded(Object limit) {
    return 'تم تجاوز حد API: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return 'القيمة تتجاوز حد API ($limit). سيتم استخدام القيمة القصوى.';
  }

  @override
  String get micStartFailed => 'فشل تشغيل الميكروفون';

  @override
  String get micStopFailed => 'فشل إيقاف الميكروفون';

  @override
  String get speechErrorNoMatch => 'تعذر التعرف على الكلام. حاول مرة أخرى.';

  @override
  String get speechErrorTimeout => 'انتهت مهلة الاستماع. لم يتم سماع أي شيء.';

  @override
  String get speechErrorNetwork => 'خطأ في الشبكة. تحقق من اتصال الإنترنت.';

  @override
  String get speechErrorNotAuthorized => 'لا يوجد وصول إلى الميكروفون. تحقق من الأذونات في الإعدادات.';

  @override
  String get speechErrorServer => 'خطأ في خادم التعرف. حاول مرة أخرى لاحقًا.';

  @override
  String get speechErrorTooManyRequests => 'الطلبات كثيرة جدًا. حاول مرة أخرى لاحقًا.';

  @override
  String get speechErrorUnknown => 'خطأ التعرف على الكلام';

  @override
  String get speechPreparing => 'جاري التحضير...';

  @override
  String get speechListening => 'تحدث الآن...';

  @override
  String get speechProcessing => 'جاري المعالجة...';

  @override
  String get micNoSpeechDetected => 'لم أسمعك. يرجى المحاولة مرة أخرى.';

  @override
  String get micAutoRestart => 'إعادة المحاولة...';

  @override
  String get speechPhase2 => 'لا أسمعك...تحدث بصوت أعلى';

  @override
  String speechStartError(Object error) {
    return 'خطأ في البدء: $error';
  }

  @override
  String get errorProcessingRequest => 'عذرًا، حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى.';

  @override
  String rateLimitRetryMessage(Object seconds) {
    return 'تم تجاوز حد المعدل. إعادة المحاولة خلال $seconds ثوانٍ...';
  }

  @override
  String get messageNotFound => 'الرسالة غير موجودة';

  @override
  String get errorEditingMessage => 'خطأ في تعديل الرسالة';

  @override
  String get errorEditAndSendMessage => 'خطأ في تعديل وإرسال الرسالة';

  @override
  String generatingSuggestionsFailed(Object error) {
    return 'فشل في إنشاء الاقتراحات: $error';
  }

  @override
  String get selectModelTooltip => 'اختيار النموذج';

  @override
  String get toggleNavigatorTooltip => 'تبديل الملاحة';

  @override
  String get defaultSuggestion1 => 'أخبرني المزيد عن هذا الموضوع';

  @override
  String get defaultSuggestion2 => 'هل يمكنك تقديم أمثلة؟';

  @override
  String get defaultSuggestion3 => 'ما هي البدائل؟';

  @override
  String get defaultSuggestion4 => 'كيف يتم تطبيق هذا في الممارسة العملية؟';

  @override
  String get systemPromptSuggestion => 'أنت مساعد مفيد. استمر في المحادثة من خلال تقديم 3 استمرارات محددة ومنطقية لآخر رسالة. رد باللغة نفسها التي يستخدمها المستخدم.';

  @override
  String get userPromptSuggestion => 'قدم 3 استمرارات محددة ومنطقية لهذه الرسالة. أجب بالقائمة فقط، بدون نص إضافي.';

  @override
  String get refreshQuestions => 'تحديث الأسئلة';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String modelDoesNotSupportFiles(Object modelId) {
    return 'النموذج $modelId لا يدعم الملفات. يمكنك إرفاق ملف، لكن الإرسال لن يعمل.';
  }

  @override
  String get fileAttachedButNotSupported => 'تم إرفاق الملف ولكن النموذج الحالي لا يدعمه';

  @override
  String get copyCodeTooltip => 'نسخ الكود';

  @override
  String get expandTooltip => 'توسيع';

  @override
  String get collapseTooltip => 'طي';
}
