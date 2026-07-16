/// Provider definitions barrel file.
///
/// Imports all built-in provider definitions and exports a single
/// [builtInProviders] function.
/// each provider is defined in its own file (~20-30 lines) and the
/// barrel file composes them into a list.
///
/// Usage:
/// ```dart
/// import 'package:chatorai/core/ai/catalog/providers/built_in_providers.dart';
///
/// final providers = builtInProviders();
/// ```
///
/// To add a new provider:
/// 1. Create a new file in this directory
/// 2. Export a top-level function returning [ProviderConfig]
/// 3. Import and add it to [builtInProviders] below
library;

import 'package:chatorai/core/llm/models/provider_config.dart';

import 'ai302.dart';
import 'alibaba.dart';
import 'amazon_bedrock.dart';
import 'anthropic.dart';
import 'azure.dart';
import 'baseten.dart';
import 'cerebras.dart';
import 'cloudflare_ai_gateway.dart';
import 'cloudflare_workers_ai.dart';
import 'cohere.dart';
import 'deepinfra.dart';
import 'deepseek.dart';
import 'fireworks.dart';
import 'github_copilot.dart';
import 'gitlab.dart';
import 'google.dart';
import 'google_vertex.dart';
import 'groq.dart';
import 'huggingface.dart';
import 'kilo.dart';
import 'llmgateway.dart';
import 'lmstudio.dart';
import 'mistral.dart';
import 'novita.dart';
import 'nvidia.dart';
import 'ollama.dart';
import 'openai.dart';
import 'openai_compatible.dart';
import 'opencode.dart';
import 'openrouter.dart';
import 'perplexity.dart';
import 'sap_ai_core.dart';
import 'togetherai.dart';
import 'venice.dart';
import 'vercel.dart';
import 'vllm.dart';
import 'xai.dart';
import 'zenmux.dart';

/// Returns the list of all built-in provider configurations.
///
/// Each provider is defined in a separate file under [providers/].
/// Providers are returned as function calls (not const) to allow
/// for future dynamic configuration (e.g., loading from remote source).
///
/// Only [openrouterProvider] and [ollamaProvider] are enabled by default:
/// - OpenRouter: broad access via single API key
/// - Ollama: local-first, zero-config
List<ProviderConfig> builtInProviders() => [
  openrouterProvider(),
  openaiProvider(),
  anthropicProvider(),
  googleProvider(),
  groqProvider(),
  deepseekProvider(),
  togetheraiProvider(),
  mistralProvider(),
  novitaProvider(),
  kiloProvider(),
  nvidiaProvider(),
  xaiProvider(),
  cohereProvider(),
  perplexityProvider(),
  cerebrasProvider(),
  deepinfraProvider(),
  fireworksProvider(),
  alibabaProvider(),
  azureProvider(),
  amazonBedrockProvider(),
  cloudflareWorkersAiProvider(),
  cloudflareAiGatewayProvider(),
  githubCopilotProvider(),
  googleVertexProvider(),
  opencodeProvider(),
  sapAiCoreProvider(),
  veniceProvider(),
  vercelProvider(),
  zenmuxProvider(),
  llmgatewayProvider(),
  gitlabProvider(),
  huggingfaceProvider(),
  basetenProvider(),
  ai302Provider(),
  ollamaProvider(),
  vllmProvider(),
  lmstudioProvider(),
  openaiCompatibleProvider(),
];
