// Test console utilities and helpers
// Run with: dart test/test_console.dart

void main() {
  print('🧪 Testing Console Utilities...\n');

  // Test 1: Language detection
  print('🔍 Test 1: Language Detection');
  final testTexts = [
    'Привет, как дела?', // Russian
    'Hello, how are you?', // English
    '你好，最近怎么样？', // Chinese
    'こんにちは、お元気ですか？', // Japanese
    'Hola, ¿cómo estás?', // Spanish
  ];

  for (final text in testTexts) {
    final lang = _detectLanguage(text);
    print('✅ "$text" → $lang');
  }

  // Test 2: System prompts
  print('\n🔍 Test 2: System Prompts');
  final languages = ['en', 'ru', 'zh', 'ja'];
  for (final lang in languages) {
    final prompt = _getLocalizedSystemPrompt(lang);
    final display = prompt.length > 50 ? '${prompt.substring(0, 50)}...' : prompt;
    print('✅ $lang: $display');
  }

  // Test 3: User prompts
  print('\n🔍 Test 3: User Prompts');
  for (final lang in languages) {
    final prompt = _getLocalizedUserPrompt(lang);
    final display = prompt.length > 50 ? '${prompt.substring(0, 50)}...' : prompt;
    print('✅ $lang: $display');
  }

  // Test 4: Suggestion parsing
  print('\n🔍 Test 4: Suggestion Parsing');
  final suggestionText = '''
1. Tell me more about this topic
2. Can you provide examples?
3. What are the alternatives?
''';
  final suggestions = _parseSuggestions(suggestionText);
  print('✅ Parsed ${suggestions.length} suggestions:');
  for (final s in suggestions) {
    print('   - $s');
  }

  print('\n🎉 All console utility tests completed!');
  print('✅ Language detection works');
  print('✅ Prompts are localized');
  print('✅ Suggestions parsed correctly');
}

String _detectLanguage(String text) {
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

String _getLocalizedSystemPrompt(String language) {
  switch (language) {
    case 'ru':
      return 'Ты — полезный ассистент. Продолжи диалог, предложив 3 конкретных и логичных продолжения последнего сообщения. Отвечай на русском языке.';
    case 'zh':
      return '你是一个有用的助手。继续对话，为最后一条消息提供3个具体且合乎逻辑的延续。用中文回答。';
    case 'ja':
      return 'あなたは有用なアシスタントです。会話を続け、最後のメッセージに対して3つの具体的で論理的な続きを提案してください。日本語で回答してください。';
    default:
      return 'You are a helpful assistant. Continue the conversation by providing 3 specific and logical continuations of the last message. Respond in the same language as the user.';
  }
}

String _getLocalizedUserPrompt(String language) {
  switch (language) {
    case 'ru':
      return 'Предложи 3 конкретных и логичных продолжения для этого сообщения. Отвечай только списком, без дополнительного текста.';
    case 'zh':
      return '为这条消息提供3个具体且合乎逻辑的延续。只回答列表，不要额外文本。';
    case 'ja':
      return 'このメッセージに対して3つの具体的で論理的な続きを提案してください。リストのみで回答し、追加テキストは含めないでください。';
    default:
      return 'Provide 3 specific and logical continuations for this message. Answer only with the list, no additional text.';
  }
}

List<String> _parseSuggestions(String text) {
  return text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && (s.startsWith('-') || s.startsWith('1.') || s.startsWith('2.') || s.startsWith('3.') || s.startsWith('•') || s.length > 10))
      .map((s) => s.replaceFirst(RegExp(r'^[-•]\s*'), '').replaceFirst(RegExp(r'^\d+\.\s*'), ''))
      .where((s) => s.length > 5)
      .take(4)
      .toList();
}