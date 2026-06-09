class ChatLanguageUtils {
  ChatLanguageUtils._();

  static String detectLanguage(String text) {
    final hasCyrillic = RegExp(r'[а-яА-Я]').hasMatch(text);
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(text);
    final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    final hasJapanese = RegExp(r'[\u3040-\u309f\u30a0-\u30ff]').hasMatch(text);

    if (hasCyrillic) return 'ru';
    if (hasChinese) return 'zh';
    if (hasJapanese) return 'ja';
    if (hasLatin) return 'en';

    return 'en';
  }

  static const List<String> _supportedLanguages = [
    'ru',
    'zh',
    'ja',
    'ar',
    'uk',
  ];

  static bool isSupportedLanguage(String lang) {
    return _supportedLanguages.contains(lang);
  }
}
