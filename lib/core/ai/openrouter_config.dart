import 'package:ai_sdk_openai/ai_sdk_openai.dart';

const kOpenRouterBaseUrl = 'https://openrouter.ai/api/v1';
const kOpenRouterHeaders = <String, String>{
  'HTTP-Referer': 'https://chatorai.app',
  'X-Title': 'ChatORAI',
};
OpenAIProvider openRouterProvider({required String apiKey, String? baseUrl}) =>
    OpenAIProvider(apiKey: apiKey, baseUrl: baseUrl ?? kOpenRouterBaseUrl);
