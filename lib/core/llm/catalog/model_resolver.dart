/// Model resolution and LanguageModel building service.
///
/// Resolves model identifiers (e.g., 'openrouter/openai/gpt-4o')
/// to [ModelConfig] objects and constructs the corresponding ai_sdk_dart
/// [LanguageModelV3] instances with proper provider, API key, and base URL.
///
/// Follows OpenCode catalog patterns where each provider definition includes
/// a model factory and the resolver handles provider-specific SDK creation.
library;

import 'package:ai_sdk_anthropic/ai_sdk_anthropic.dart' as anthro;
import 'package:ai_sdk_openai/ai_sdk_openai.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';
import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';
import 'package:chatorai/core/llm/catalog/provider_catalog_service.dart';
import 'package:chatorai/shared/utils/logger.dart';

/// Error thrown when a model cannot be resolved.
class ModelResolutionError implements Exception {
  final String message;
  const ModelResolutionError(this.message);

  @override
  String toString() => 'ModelResolutionError: $message';
}

/// Resolves model identifiers to [ModelConfig] and builds [LanguageModelV3].
///
/// Acts as the bridge between the catalog (static configuration) and the
/// runtime AI SDK (actual model instances for API calls).
class ModelResolver {
  final ProviderCatalogService _catalog;

  ModelResolver(this._catalog);

  // ===========================================================================
  // RESOLUTION
  // ===========================================================================

  /// Resolve a model identifier string to a [ModelConfig].
  ModelConfig resolve(String modelId) {
    final model = _catalog.getModel(modelId);
    if (model == null) {
      throw ModelResolutionError('Model not found in catalog: $modelId');
    }
    return model;
  }

  /// Get the [ProviderConfig] that owns a given model.
  ///
  /// [modelId] must be a full model identifier in the format
  /// `providerId/modelName` (e.g., 'openrouter/gpt-4o') or legacy
  /// `providerId:modelName`. The provider part is extracted and validated
  /// against the catalog, and it is verified that the provider actually
  /// contains a model with the given [modelName].
  ///
  /// Throws [ModelResolutionError] if the format is invalid, provider not
  /// found, or model does not belong to that provider.
  ProviderConfig getProviderForModel(String modelId) {
    String providerId;
    String modelName;

    if (modelId.contains('/')) {
      final parts = modelId.split('/');
      providerId = parts[0];
      modelName = parts.sublist(1).join('/');
    } else if (modelId.contains(':')) {
      final parts = modelId.split(':');
      providerId = parts[0];
      modelName = parts.sublist(1).join(':');
    } else {
      throw ModelResolutionError(
        'Invalid model identifier: $modelId. '
        'Use full format: providerId/modelName (e.g., openrouter/gpt-4o).',
      );
    }

    final provider = _catalog.getProvider(providerId);
    if (provider == null) {
      throw ModelResolutionError('Provider not found: $providerId');
    }

    // Verify that the model exists in this provider.
    if (!provider.models.any((m) => m.modelName == modelName)) {
      throw ModelResolutionError(
        'Model $modelName not found in provider $providerId. '
        'Check that the model identifier is correct.',
      );
    }

    return provider;
  }

  // ===========================================================================
  // LanguageModel BUILDING
  // ===========================================================================

  /// Build an ai_sdk_dart [LanguageModelV3] from a [ModelConfig].
  ///
  /// The returned [LanguageModelV3] is configured with the provider's API key
  /// and base URL. Custom headers and body parameters must be passed at call
  /// time via `streamText(..., headers: ...)` / `generateText(..., headers: ...)`.
  ///
  /// Use [getHeadersForModel] to resolve the effective headers for a model call,
  /// which merges provider default headers, variant headers, and overrides.
  ///
  /// NOTE: The current implementation uses `OpenAIProvider` for all providers.
  /// This works for OpenAI-compatible APIs (OpenRouter, Groq, Ollama, etc.)
  /// but may not support native Anthropic or Google APIs fully.
  /// Native SDK support is planned for a future phase.
  Future<LanguageModelV3> buildLanguageModel(
    ModelConfig model, {
    ModelVariant? variant,
    String? overrideApiKey,
    String? overrideBaseUrl,
    Map<String, String>? overrideHeaders,
  }) async {
    final provider = getProviderForModel(model.id);
    final apiKey = overrideApiKey ?? await _catalog.getApiKey(provider.id);
    final baseUrl =
        overrideBaseUrl ??
        _catalog.getCustomBaseUrl(provider.id) ??
        provider.baseUrl;

    if (provider.auth.type != AuthType.none &&
        (apiKey == null || apiKey.isEmpty)) {
      throw ModelResolutionError(
        'API key not configured for provider: ${provider.id}. '
        'Please set it in Settings.',
      );
    }

    final effectiveModelName = model.modelName;

    // Dispatch to provider-specific SDK based on provider.sdk
    final sdkId = provider.sdk;
    try {
      LogTags.network.logDebug(
        '[Resolver] buildLanguageModel: provider=${provider.id} sdk=$sdkId baseUrl=$baseUrl apiKeyPresent=${apiKey?.isNotEmpty ?? false} modelName=$effectiveModelName',
      );
      if (sdkId == 'anthropic') {
        final anthropic = anthro.AnthropicProvider(
          apiKey: apiKey,
          baseUrl: baseUrl,
        );
        return anthropic.call(effectiveModelName);
      }

      if (sdkId == 'google') {
        // Treat Google as OpenAI-compatible for now; replace with native
        // Google SDK adapter when available.
        final googleCompat = OpenAIProvider(apiKey: apiKey, baseUrl: baseUrl);
        return googleCompat.call(effectiveModelName);
      }

      // Default: OpenAI-compatible provider
      final openAI = OpenAIProvider(apiKey: apiKey, baseUrl: baseUrl);
      return openAI.call(effectiveModelName);
    } catch (e) {
      // If provider-specific build fails, attempt fallback to OpenAI-compatible
      final fallback = OpenAIProvider(apiKey: apiKey, baseUrl: baseUrl);
      return fallback.call(effectiveModelName);
    }
  }

  /// Build a LanguageModel with graceful failure (returns null on error).
  Future<LanguageModelV3?> tryBuildLanguageModel(
    ModelConfig model, {
    ModelVariant? variant,
  }) async {
    try {
      return await buildLanguageModel(model, variant: variant);
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // HEADERS RESOLUTION
  // ===========================================================================

  /// Get the effective HTTP headers for a model call.
  ///
  /// Merges headers in order (later wins):
  /// 1. Provider [defaultHeaders] from [ProviderConfig]
  /// 2. [variant] headers (if specified)
  /// 3. [overrideHeaders] from call site
  ///
  /// Use the returned headers with [LanguageModelV3CallOptions.headers]
  /// when calling [streamText] or [generateText].
  ///
  /// Follows OpenCode pattern where headers are resolved per-call and
  /// can be overridden at each level (provider → model → variant → call).
  Map<String, String> getHeadersForModel(
    ModelConfig model, {
    ModelVariant? variant,
    Map<String, String>? overrideHeaders,
  }) {
    final provider = getProviderForModel(model.id);
    final headers = <String, String>{
      ...provider.defaultHeaders,
      ...?variant?.headers,
      ...?overrideHeaders,
    };
    return headers;
  }

  /// Get the effective body parameters for a model call.
  ///
  /// Merges body parameters in order (later wins):
  /// 1. Provider [defaultBody] from [ProviderConfig]
  /// 2. [variant] body (if specified)
  ///
  /// These can be passed alongside the standard payload at call time.
  Map<String, dynamic>? getBodyForModel(
    ModelConfig model, {
    ModelVariant? variant,
  }) {
    final provider = getProviderForModel(model.id);
    final body = <String, dynamic>{
      if (provider.defaultBody != null) ...provider.defaultBody!,
      if (variant != null && variant.body != null) ...variant.body!,
    };
    return body.isNotEmpty ? body : null;
  }
}
