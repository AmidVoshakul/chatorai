import 'package:ai_sdk_openai/ai_sdk_openai.dart';
import 'package:chatorai/core/ai/openrouter_config.dart' as or;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefApiKey = 'openrouter_api_key';
const _prefBaseUrl = 'openrouter_base_url';

final openRouterAiProvider = FutureProvider<OpenAIProvider>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final apiKey = prefs.getString(_prefApiKey);

  if (apiKey == null || apiKey.isEmpty) {
    throw StateError('OpenRouter API key not found in SharedPreferences.');
  }

  final baseUrl = prefs.getString(_prefBaseUrl)?.trim();
  return or.openRouterProvider(
    apiKey: apiKey,
    baseUrl: baseUrl == null || baseUrl.isEmpty ? null : baseUrl,
  );
});
