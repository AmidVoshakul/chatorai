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
  String get autoScrollDuringStreaming => 'التمرير التلقائي أثناء البث';

  @override
  String get autoScrollDuringStreamingDesc => 'التمرير لأسفل القائمة تلقائيًا عند ظهور محتوى جديد';

  @override
  String get showContinuationSuggestions => 'إظهار اقتراحات المتابعة';

  @override
  String get showContinuationSuggestionsDesc => 'عرض اقتراحات المتابعة بعد رد الذكاء الاصطناعي';

  @override
  String get expandReasoningByDefault => 'توسيع الاستدلال افتراضياً';

  @override
  String get expandReasoningByDefaultDesc => 'عرض كتل الاستدلال/التفكير مفتوحة عند رد الذكاء الاصطناعي';

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
  String get apiKeySaved => 'تم حفظ مفتاح API بنجاح';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات!';

  @override
  String get settingsReset => 'تمت إعادة تعيين الإعدادات إلى القيم الافتراضية';

  @override
  String get appInfo => 'معلومات التطبيق';

  @override
  String get appDescription => 'تطبيق دردشة مع نماذج الذكاء الاصطناعي عبر OpenRouter API.\n\nالميزات:\n• الدردشة مع نماذج ذكاء اصطناعي مختلفة\n• تخزين سجل الدردشة\n• السمات الداكنة والفاتحة\n• واجهة تكيفية\n\nتم التطوير ب ❤️ باستخدام Flutter';

  @override
  String get shareChat => 'مشاركة الدردشة';

  @override
  String get copyChat => 'نسخ الدردشة';

  @override
  String get renameChat => 'إعادة تسمية الدردشة';

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
  String chatRenamedTo(Object name) {
    return 'تمت إعادة تسمية الدردشة إلى: $name';
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
  String get loadingMsg1 => 'انتظار رد الخادم…';

  @override
  String get loadingMsg2 => 'تم إرسال البيانات — باقٍ القليل…';

  @override
  String get loadingMsg3 => 'أجمّع الأفكار…';

  @override
  String get loadingMsg4 => 'أبحث عن أفضل إجابة…';

  @override
  String get loadingMsg5 => 'تحميل الإجابة (تقريبًا)…';

  @override
  String get failedToSendMessage => 'فشل في إرسال الرسالة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get bootstrapErrorTitle => 'تعذر تشغيل التطبيق';

  @override
  String get bootstrapErrorBody => 'تحقق من الإعدادات وحاول مرة أخرى.';

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
  String get welcomeQuestion27 => 'ما هي أكثر تقنيات عام 2026 إثارة؟';

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
  String get welcomeQuestion33 => 'ما هي أفضل لغات البرمجة لتعلمها في عام 2026؟';

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
  String get addToFavorites => 'إضافة إلى المفضلة';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get recentModels => 'الأخيرة';

  @override
  String get loadingSkills => 'جاري تحميل المهارات';

  @override
  String get noSkillsInstalled => 'لا توجد مهارات مثبتة';

  @override
  String get noSkillsMatchSearch => 'لا توجد مهارات تطابق البحث';

  @override
  String get allSkillsRequirePermission => 'جميع المهارات تتطلب إذناً';

  @override
  String skillExecuted(Object name) {
    return 'تم تنفيذ المهارة';
  }

  @override
  String get configuration => 'التكوين';

  @override
  String get stats => 'الإحصائيات';

  @override
  String get usageStatistics => 'إحصائيات الاستخدام';

  @override
  String get totalSessions => 'الجلسات';

  @override
  String get totalMessages => 'الرسائل';

  @override
  String get days => 'الأيام';

  @override
  String get totalTokens => 'إجمالي الرموز';

  @override
  String get totalCost => 'التكلفة الإجمالية';

  @override
  String get avgCostPerDay => 'متوسط التكلفة/يوم';

  @override
  String get avgTokensPerSession => 'متوسط الرموز/جلسة';

  @override
  String get medianTokensPerSession => 'وسيط الرموز/جلسة';

  @override
  String get cacheRead => 'قراءة ذاكرة التخزين المؤقت';

  @override
  String get cacheWrite => 'كتابة ذاكرة التخزين المؤقت';

  @override
  String get toolUsage => 'استخدام الأدوات';

  @override
  String get modelUsage => 'استخدام النماذج';

  @override
  String get noStatsAvailable => 'لا توجد إحصائيات متاحة';

  @override
  String get reasoningTokens => 'رموز الاستدلال';

  @override
  String get addProvider => 'إضافة مزود';

  @override
  String get applySettings => 'تطبيق الإعدادات';

  @override
  String get copyCodeTooltip => 'نسخ الكود';

  @override
  String get copiedFeedback => 'تم النسخ';

  @override
  String get defaultSuggestion1 => 'أخبرني المزيد عن هذا الموضوع';

  @override
  String get defaultSuggestion2 => 'هل يمكنك تقديم أمثلة؟';

  @override
  String get defaultSuggestion3 => 'ما هي البدائل؟';

  @override
  String get deleteChat => 'حذف الدردشة';

  @override
  String get manageProviders => 'إدارة المزودين';

  @override
  String get micAutoRestart => 'إعادة المحاولة...';

  @override
  String get micNoSpeechDetected => 'لم أسمعك. يرجى المحاولة مرة أخرى.';

  @override
  String get micStartFailed => 'فشل تشغيل الميكروفون';

  @override
  String get micUnavailable => 'الميكروفون غير متاح';

  @override
  String get modelParameters => 'معلمات النموذج';

  @override
  String get modelSettings => 'إعدادات النموذج';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get noModelSelected => 'لم يتم اختيار نموذج';

  @override
  String get openaiCompatibleApi => 'واجهة برمجة تطبيقات متوافقة مع OpenAI';

  @override
  String get openaiCompatibleApiDescription => 'الاتصال بأي نقطة نهاية لواجهة برمجة تطبيقات متوافقة مع OpenAI';

  @override
  String get permissionAlways => 'السماح دائماً';

  @override
  String get permissionAlwaysConfirm => 'Always allow';

  @override
  String get permissionDialogPatterns => 'طلب الوصول إلى:';

  @override
  String get permissionOnce => 'مرة واحدة';

  @override
  String get permissionReject => 'رفض';

  @override
  String get providers => 'مزودو الخدمة';

  @override
  String get refreshQuestions => 'تحديث الأسئلة';

  @override
  String get resetToDefaults => 'إعادة تعيين إلى الافتراضي';

  @override
  String get settingsApplied => 'تم تطبيق الإعدادات بنجاح';

  @override
  String get speechErrorNetwork => 'خطأ في الشبكة. تحقق من اتصال الإنترنت.';

  @override
  String get speechErrorNoMatch => 'تعذر التعرف على الكلام. حاول مرة أخرى.';

  @override
  String get speechErrorNotAuthorized => 'لا يوجد وصول إلى الميكروفون. تحقق من الأذونات في الإعدادات.';

  @override
  String get speechErrorServer => 'خطأ في خادم التعرف. حاول مرة أخرى لاحقًا.';

  @override
  String get speechErrorTimeout => 'انتهت مهلة الاستماع. لم يتم سماع أي شيء.';

  @override
  String get speechErrorTooManyRequests => 'الطلبات كثيرة جدًا. حاول مرة أخرى لاحقًا.';

  @override
  String get speechErrorUnknown => 'خطأ التعرف على الكلام';

  @override
  String get speechListening => 'تحدث الآن...';

  @override
  String get speechPhase2 => 'لا أسمعك...تحدث بصوت أعلى';

  @override
  String get speechPreparing => 'جاري التحضير...';

  @override
  String get speechProcessing => 'جاري المعالجة...';

  @override
  String speechStartError(Object error) {
    return 'خطأ في البدء: $error';
  }

  @override
  String get systemPrompt => 'موجه النظام';

  @override
  String get systemPromptDescription => 'تعليمات مساعد الذكاء الاصطناعي';

  @override
  String get systemPromptSuggestion => 'أنت مساعد مفيد. استمر في المحادثة من خلال تقديم 3 استمرارات محددة ومنطقية لآخر رسالة. رد باللغة نفسها التي يستخدمها المستخدم.';

  @override
  String get temperature => 'درجة الحرارة';

  @override
  String get temperatureDescription => 'التحكم في العشوائية: أقل = أكثر تركيزًا، أعلى = أكثر إبداعًا';

  @override
  String get toggleNavigatorTooltip => 'تبديل الملاحة';

  @override
  String get userPromptSuggestion => 'قدم 3 استمرارات محددة ومنطقية لهذه الرسالة. أجب بالقائمة فقط، بدون نص إضافي.';

  @override
  String get versionLabel => 'الإصدار:';

  @override
  String get welcomeGreeting1 => 'اسأل، استكشف، اصنع — دعنا نكتشف معًا.';

  @override
  String get welcomeGreeting2 => 'اطرح سؤالًا، صف مهمة، أو ابدأ محادثة فقط.';

  @override
  String get welcomeGreeting3 => 'اطرح سؤالًا أو ابدأ استكشافًا.';

  @override
  String get welcomeGreeting4 => 'اطرح أي سؤال، شارك فكرة، أو اطلب المساعدة — أنا هنا للمساعدة.';

  @override
  String get welcomeGreeting5 => 'لديك فكرة؟ دعنا نكتشف.';

  @override
  String get welcomeGreeting6 => 'حدد اتجاه المحادثة.';

  @override
  String get welcomeGreeting7 => 'ماذا نستكشف اليوم؟';

  @override
  String get welcomeGreeting8 => 'اكتب فكرة. دعنا نحللها معًا.';

  @override
  String get welcomeGreeting9 => 'الفضول مرحب به.';

  @override
  String get welcomeGreeting10 => 'سؤالك هو إجابتي التالية.';

  @override
  String get welcomeGreeting11 => 'دعنا نحول الفكرة إلى إجابة.';

  @override
  String get welcomeGreeting12 => 'أدخل سؤالًا. الباقي عملي.';

  @override
  String modelDoesNotSupportFiles(Object modelId) {
    return 'النموذج $modelId لا يدعم الملفات. يمكنك إرفاق ملف، لكن الإرسال لن يعمل.';
  }

  @override
  String generatingSuggestionsFailed(Object error) {
    return 'فشل في إنشاء الاقتراحات: $error';
  }

  @override
  String get toggleSidebarTooltip => 'تبديل الشريط الجانبي';

  @override
  String get openMenuTooltip => 'فتح القائمة';

  @override
  String get addFileTooltip => 'إضافة ملف';

  @override
  String get modelSettingsTooltip => 'إعدادات النموذج';

  @override
  String get switchAgentTooltip => 'تبديل الوكيل';

  @override
  String get selectModelTooltip => 'اختيار النموذج';

  @override
  String get removeFileTooltip => 'إزالة الملف';

  @override
  String get goToParentSessionTooltip => 'الانتقال إلى الجلسة الأصل';

  @override
  String get previousSiblingTooltip => 'الشقيق السابق';

  @override
  String get nextSiblingTooltip => 'الشقيق التالي';

  @override
  String get cancellingRetryTooltip => 'جاري إلغاء إعادة المحاولة...';

  @override
  String get stopGenerationTooltip => 'إيقاف التوليد';

  @override
  String get question => 'سؤال';

  @override
  String get skip => 'تخطي';

  @override
  String get answer => 'إجابة';

  @override
  String get noAgentsAvailable => 'لا توجد وكلاء متاحون';

  @override
  String permissionAlwaysConfirmDescription(Object title) {
    return 'سيسمح هذا بـ \"$title\" حتى إعادة تشغيل التطبيق.';
  }

  @override
  String get chatActionsMenuTooltip => 'قائمة الدردشة';

  @override
  String get startListening => 'بدء الإدخال الصوتي';

  @override
  String get stopListening => 'إيقاف الإدخال الصوتي';

  @override
  String get listening => 'تحدث الآن...';

  @override
  String get sendMessage => 'إرسال الرسالة';

  @override
  String get maxTokens => 'الحد الأقصى للرموز';

  @override
  String get maxTokensDescription => 'الحد الأقصى لطول الاستجابة المولدة';

  @override
  String get activeModel => 'النموذج النشط';

  @override
  String apiLimitExceeded(Object limit) {
    return 'تم تجاوز حد API: $limit';
  }

  @override
  String valueExceedsApiLimit(Object limit) {
    return 'القيمة تتجاوز حد API ($limit). سيتم استخدام القيمة القصوى.';
  }

  @override
  String get micStopFailed => 'فشل إيقاف الميكروفون';

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
  String get defaultSuggestion4 => 'كيف يتم تطبيق هذا في الممارسة العملية؟';

  @override
  String get fileAttachedButNotSupported => 'تم إرفاق الملف ولكن النموذج الحالي لا يدعمه';

  @override
  String get expandTooltip => 'توسيع';

  @override
  String get collapseTooltip => 'طي';

  @override
  String get addProviderTitleEdit => 'تعديل المزود';

  @override
  String get addProviderTitleAdd => 'إضافة مزود';

  @override
  String get addProviderLabelProvider => 'المزود';

  @override
  String get addProviderCustomName => 'مزود مخصص...';

  @override
  String get addProviderFieldProviderName => 'اسم المزود';

  @override
  String get addProviderHintProviderName => 'مثال: مزودي المخصص';

  @override
  String get addProviderLabelApiKey => 'مفتاح API';

  @override
  String get addProviderHintApiKey => 'أدخل مفتاح API الخاص بك';

  @override
  String get addProviderHintCustomApiKey => 'اختياري للمزودين المحليين';

  @override
  String get addProviderLabelBaseUrl => 'عنوان URL الأساسي';

  @override
  String get addProviderHintBaseUrl => 'https://api.example.com/v1';

  @override
  String get addProviderActionSave => 'حفظ';

  @override
  String get addProviderErrorApiKeyRequired => 'مفتاح API مطلوب';

  @override
  String get selectModels => 'اختيار النماذج';

  @override
  String get deselectAll => 'إلغاء تحديد الكل';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get modelsAvailable => 'لا توجد نماذج متاحة';

  @override
  String get modelsMatchSearch => 'لا توجد نماذج تطابق البحث';

  @override
  String selectModelsCount(Object count, Object total) {
    return 'تم تحديد $count من $total';
  }

  @override
  String modelsLoadError(Object error) {
    return 'فشل تحميل النماذج: $error';
  }

  @override
  String get systemPromptHint => 'أنت مساعد مفيد...';

  @override
  String get temperatureHint => '0.0 - 2.0';

  @override
  String get loadingSettings => 'جاري تحميل الإعدادات...';

  @override
  String errorApplyingSettings(Object error) {
    return 'خطأ في تطبيق الإعدادات: $error';
  }

  @override
  String deleteProviderTitle(Object providerName) {
    return 'حذف $providerName?';
  }

  @override
  String get deleteProviderContent => 'سيؤدي هذا إلى إزالة المزود وجميع إعداداته. ستحتاج إلى إضافته مرة أخرى لاستخدام نماذجه.';

  @override
  String get errorLoadingProviders => 'خطأ في تحميل المزودين';

  @override
  String get noProvidersConfigured => 'لم يتم تكوين أي مزودين';

  @override
  String get addProviderToGetStarted => 'أضف مزودًا بمفتاح API للبدء';

  @override
  String statsError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get total => 'المجموع';

  @override
  String modelsProviderCountFormat(Object count, Object providerName) {
    return '$providerName · $count';
  }

  @override
  String get mcpServers => 'خوادم MCP';

  @override
  String get mcpAddServer => 'إضافة خادم MCP';

  @override
  String get mcpAddServerTitle => 'إضافة خادم MCP';

  @override
  String get mcpNameLabel => 'الاسم';

  @override
  String get mcpNameHint => 'مثال: filesystem';

  @override
  String get mcpNameHelper => 'معرف فريد مستخدم في chatorai.json';

  @override
  String get mcpTypeLocal => 'محلي';

  @override
  String get mcpTypeRemote => 'عن بعد';

  @override
  String get mcpTypeLocalTooltip => 'يعمل على جهازك';

  @override
  String get mcpTypeRemoteTooltip => 'نقطة نهاية HTTP/SSE';

  @override
  String get mcpCommandLabel => 'الأمر';

  @override
  String get mcpCommandHint => 'uvx mcp-server-filesystem ~/docs';

  @override
  String get mcpCommandHelper => 'الأمر الكامل مع الوسائط مفصولة بمسافات';

  @override
  String get mcpUrlLabel => 'URL';

  @override
  String get mcpUrlHint => 'https://example.com/mcp';

  @override
  String get mcpUrlHelper => 'عنوان URL الكامل لنقطة نهاية MCP';

  @override
  String get mcpEnvLabel => 'متغيرات البيئة (JSON)';

  @override
  String get mcpEnvHint => 'GITHUB_TOKEN=ghp_xxx';

  @override
  String get mcpEnvHelper => 'اختياري. الصق كائن JSON بمفاتيح نصية، مثل إدخال TOKEN واحد.';

  @override
  String get mcpTokenLabel => 'رمز الوصول';

  @override
  String get mcpTokenHint => 'الصق الرمز فقط (دون Bearer / علامات اقتباس)';

  @override
  String get mcpTokenHelper => 'اختياري. اتركه فارغًا للخوادم العامة؛ الصق الرمز فقط فيُضاف الترويس تلقائيًا.';

  @override
  String get mcpAuthTypeLabel => 'نوع الرمز';

  @override
  String get mcpAuthTypeHelper => 'كيفية إرسال الرمز: Bearer (Authorization) أو ApiKey (X-Api-Key) أو Token عادي.';

  @override
  String get mcpHeadersLabel => 'الترويسات (JSON)';

  @override
  String get mcpHeadersHint => 'Authorization=Bearer token';

  @override
  String get mcpHeadersHelper => 'اختياري. الصق كائن JSON للترويسات.';

  @override
  String get mcpFormTab => 'نموذج';

  @override
  String get mcpRawTab => 'JSON خام';

  @override
  String get mcpRawLabel => 'كائن الخادم (JSON)';

  @override
  String get mcpRawHelper => 'الصق كائن الخادم كما في التوثيق — اسم الخادم هو المفتاح الخارجي (مثل searxng). يمكنك لصق الكتلة الكاملة بما فيها الغلاف mcpServers.';

  @override
  String mcpParseError(Object field, Object message) {
    return 'JSON غير صالح في $field: $message';
  }

  @override
  String get mcpAddAction => 'إضافة';

  @override
  String get mcpCancelAction => 'إلغاء';

  @override
  String get mcpRemoveTitle => 'حذف خادم MCP؟';

  @override
  String mcpRemoveContent(Object name) {
    return 'إزالة \"$name\" من chatorai.json؟';
  }

  @override
  String get mcpRemoveAction => 'حذف';

  @override
  String get mcpEditAction => 'تعديل';

  @override
  String get mcpEditServerTitle => 'تعديل خادم MCP';

  @override
  String get mcpSaveAction => 'حفظ';

  @override
  String get mcpNoServers => 'لم يتم تكوين خوادم MCP';

  @override
  String get mcpNoServersHint => 'أضف خادم بروتوكول سياق النموذج لإ扩展 الأدوات';

  @override
  String get mcpTooltipAdd => 'إضافة خادم';

  @override
  String get mcpTooltipRefresh => 'تحديث';

  @override
  String get mcpMarketplaceTab => 'السوق';

  @override
  String get mcpInstalledTab => 'مثبّت';

  @override
  String get mcpInstall => 'تثبيت';

  @override
  String get mcpInstalled => 'مثبّت';

  @override
  String get mcpMarketplaceSearchHint => 'ابحث عن الخوادم…';

  @override
  String get mcpMarketplaceEmpty => 'لا توجد خوادم تطابق بحثك';

  @override
  String get mcpMarketCategoryAll => 'الكل';

  @override
  String get mcpMarketCategorySearch => 'بحث';

  @override
  String get mcpMarketCategoryDocs => 'وثائق';

  @override
  String get mcpMarketCategoryDesign => 'تصميم';

  @override
  String get mcpMarketCategoryDev => 'تطوير';

  @override
  String get mcpMarketCategoryFinance => 'مالية';

  @override
  String get mcpMarketCategoryTravel => 'سفر';

  @override
  String get mcpMarketCategoryJobs => 'وظائف';

  @override
  String get mcpMarketCategoryProductivity => 'إنتاجية';

  @override
  String get mcpMarketCategorySocial => 'تواصل اجتماعي';

  @override
  String get mcpMarketCategoryOther => 'أخرى';

  @override
  String get mcpMarketNeedsToken => 'يتطلب مفتاحًا';

  @override
  String get mcpMarketDescExa => 'يوفّر Exa إمكانات البحث على الويب والبحث في توثيق الأكواد لسير عمل الذكاء الاصطناعي. يزوّد موصِّله بسياق لحظي للعثور على صفحات ويب ذات صلة وتوثيق تقني ومواد مصدرية عند الحاجة إلى معلومات خارجية موثوقة للإجابة.';

  @override
  String get mcpMarketDescContext7 => 'يوفّر Context7 أمثلة التعليمات البرمجية وتوثيقًا محدّثًا للمبرمجين ومحرري الأكواد المدعومين بالذكاء الاصطناعي. يدمج موصِّله سياق المكتبة الحالي في سير العمل، فيقلّل التنقّل بين التبويبات ويساعد الكود المولّد على تجنّب واجهات برمجة التطبيقات القديمة والدوال غير الموجودة وأنماط التنفيذ البالية.';

  @override
  String get mcpMarketDescHuggingFace => 'يربط Hugging Face المساعدين الصوتيين بـ Hugging Face Hub وبآلاف تطبيقات Gradio. يدمج موصِّله سياق النموذج ومجموعة البيانات والمساحة والتطبيق في سير عمل الذكاء الاصطناعي لاكتشاف التجارب وأبحاث تعلّم الآلة.';

  @override
  String get mcpMarketDescParallel => 'يوفّر Parallel Search بحثًا لحظيًا على الويب واستخراج محتوى لسير عمل الذكاء الاصطناعي المعتمدة على البحث. يساعد خادمه البعيد الموصِّلات على جلب سياق صفحات الويب الحالي والتحقق من الصفحات واستخدام المحتوى المستخرج عند الإجابة عن أسئلة أو دراسة مواضيع تتطلب معلومات طازجة.';

  @override
  String get mcpMarketDescTavily => 'يمنح Tavily وكلاء الذكاء الاصطناعي وصولًا لحظيًا إلى موارد الويب عبر واجهات برمجة التطبيقات للبحث والاسترجاع والدراسة. يساعد موصِّله الوكلاء على بناء الإجابات على بيانات حيّة واستخراج محتوى ذي صلة ودعم سير عمل الوكلاء في الإنتاج مع ضوابط أمان.';

  @override
  String get mcpMarketDescGithub => 'GitHub منصة للتعاون على الأكواد والقضايا وطلبات الدمج وتاريخ المشاريع. يمنح خادمه البعيد الرسمي الموصِّلات سياقًا منظّمًا للمستودع لفهم التغييرات في المصدر والمراجعات ومسارات التطوير وحالة مشاريع GitHub.';

  @override
  String get mcpMarketDescPostman => 'يوفّر Postman سياق واجهات برمجة التطبيقات لوكلاء البرمجة وسير عمل المطوّرين. يدمج موصِّله تعريفات الواجهات والتوثيق وسياق التعاون في عمل الموصِّل، متيحًا للوكلاء تحليل التكاملات وتفاصيل التنفيذ.';

  @override
  String get mcpMarketDescSlack => 'Slack حاضنة للتعاون تجمع رسائل الفرق والقنوات والمستخدمين ومساحات العمل المشتركة. يدمج خادمه البعيد سياق المحادثات في مساحة العمل في سير عمل الموصِّلات، ويساعد المستخدمين على إيجاد إجابات وتلخيص النقاشات وفهم النشاط عبر القنوات.';

  @override
  String get mcpMarketDescFigma => 'Figma منصة لتصميم المنتجات تُعنى بتصميم الواجهات والنماذج الأولية وتسليم العمل للمطوّرين. ينقل خادمه البعيد الملفات والمشاريع وسياق وضع التطوير إلى سير عمل الموصِّلات، ويسمح للوكلاء بفهم العمل البصري ومقارنته بمهام التنفيذ.';

  @override
  String get mcpMarketDescCanva => 'Canva منصة تواصل بصري لإنشاء العروض التقديمية ورسومات التواصل الاجتماعي والمستندات والمواد التجارية. يمنح خادمه البعيد الموصِّلات وصولًا إلى مشاريع Canva وأصولها والملفات المصدّرة والتعليقات، فيتيح مناقشة الأعمال الإبداعية وتحريرها وتجهيزها من المعلومات المجمّعة.';

  @override
  String get mcpMarketDescStripe => 'Stripe منصة للمدفوعات والبنية التحتية المالية لمعالجة المدفوعات والفوترة والعملاء وتوثيق المطوّرين. يمنح خادمه البعيد الموصِّلات سياق الحساب والتنفيذ المدعوم من Stripe لفهم مسارات العملاء وأسئلة الفوترة ومهام الدفع.';

  @override
  String get mcpMarketDescTrivago => 'يساعد Trivago المستخدمين على البحث عن الفنادق وخيارات الإقامة حسب الإحداثيات والمدن والدول والتواريخ وسياق السفر. يزوّد موصِّله بسياق البحث عن السكن لإيجاد خيارات مناسبة قرب الوجهات أو المعالم.';

  @override
  String get mcpMarketDescSend => 'يساعد Send المستخدمين على إنشاء مستندات قابلة للمشاركة وصفحات مفردة وعروض تقديمية وشرائح. يتيح موصِّله للوكلاء تحويل المواد المطلوبة إلى روابط منشورة وصفحات تفاعلية ومواد قابلة للتتبّع للمستلمين.';

  @override
  String get mcpMarketDescZiprecruiter => 'يساعد ZipRecruiter المستخدمين على البحث عن الوظائف الحيّة حسب المسمى والشركة والموقع والراتب والمسافة وأسلوب العمل ونوع التوظيف وتاريخ النشر. يدمج موصِّله سياق البحث عن العمل في سير عمل الموصِّل قبل إعادة الطلبات إلى ZipRecruiter.';

  @override
  String get mcpMarketDescAdobeCreativity => 'يجمع Adobe for Creativity قدرات Photoshop وLightroom وIllustrator وFirefly وPremiere وExpress وInDesign وStock مع العمل الإبداعي المدفوع بالذكاء الاصطناعي. يمكن للمستخدمين إنشاء الصور وتحريرها وتحسينها والأصول التصميمية والمشاريع المرئية بلغة طبيعية مع بقاء العمل مرتبطًا بحساب Adobe.';
}
