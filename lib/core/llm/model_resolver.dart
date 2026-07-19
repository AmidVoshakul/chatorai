/// Model resolution and LanguageModel building service.
///
/// Resolves model identifiers (e.g., 'openrouter/openai/gpt-4o')
/// to [ModelConfig] objects and constructs the corresponding ai_sdk_dart
/// [LanguageModelV3] instances with proper provider, API key, and base URL.
///
///  catalog patterns where each provider definition includes
/// a model factory and the resolver handles provider-specific SDK creation.
library;

import 'package:ai_sdk_anthropic/ai_sdk_anthropic.dart' as anthro;
import 'package:ai_sdk_google/ai_sdk_google.dart';
import 'package:ai_sdk_openai/ai_sdk_openai.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
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
  /// `providerId/modelName` (e.g., 'openrouter/gpt-4o'). The provider part is
  /// extracted and validated against the catalog, and it is verified that the
  /// provider actually contains a model with the given [modelName].
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

    if (provider.getModel(modelName) == null) {
      throw ModelResolutionError(
        'Model $modelName not found in provider $providerId. '
        'Check that the model identifier is correct.',
      );
    }

    return provider;
  }

  /// Convenience wrapper that resolves the owning [ProviderConfig] from a
  /// [ModelConfig] (whose [ModelConfig.id] is `providerId/modelName`).
  ProviderConfig getProviderForModelConfig(ModelConfig model) =>
      getProviderForModel(model.id);

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
    // For config-driven providers the key lives in the JSON (auth.apiKey),
    // not in SecureStorage. Fall back to it when no stored key is present.
    final storedKey = await _catalog.getApiKey(provider.id);
    final apiKey = overrideApiKey ?? storedKey ?? provider.auth.apiKey;
    final baseUrl =
        overrideBaseUrl ??
        _catalog.getCustomBaseUrl(provider.id) ??
        provider.baseUrl;

    if (provider.auth.type != AuthType.none &&
        (apiKey == null || apiKey.isEmpty)) {
      LogTags.network.logError(
        '[Resolver] buildLanguageModel AUTH FAILED: '
        'provider=${provider.id} '
        'apiKey=$apiKey '
        'length=${apiKey?.length ?? -1} '
        'isEmpty=${apiKey?.isEmpty ?? true}',
      );
      throw ModelResolutionError(
        'API key not configured for provider: ${provider.id}. '
        'Please set it in Settings.',
      );
    }

    final effectiveModelName = model.modelName;

    // Dispatch to provider-specific SDK based on provider.sdk
    final sdkId = provider.sdk;

    // Validate Bedrock auth requirements early
    if (sdkId == 'bedrock') {
      final auth = provider.auth;
      if (auth.type != AuthType.aws) {
        throw ModelResolutionError(
          'Bedrock provider requires AuthType.aws. '
          'Configure awsAccessKeyId, awsSecretAccessKey, and awsRegion.',
        );
      }
      if (auth.awsAccessKeyId == null || auth.awsAccessKeyId!.isEmpty) {
        throw ModelResolutionError(
          'AWS access key ID is required for Bedrock provider: ${provider.id}. '
          'Configure it in Settings.',
        );
      }
      if (auth.awsSecretAccessKey == null || auth.awsSecretAccessKey!.isEmpty) {
        throw ModelResolutionError(
          'AWS secret access key is required for Bedrock provider: ${provider.id}. '
          'Configure it in Settings.',
        );
      }
      if (auth.awsRegion == null || auth.awsRegion!.isEmpty) {
        throw ModelResolutionError(
          'AWS region is required for Bedrock provider: ${provider.id}. '
          'Configure it in Settings.',
        );
      }
      // Bedrock requires native SDK integration (AWS SigV4 signing + Converse API).
      // A custom LanguageModelV3 implementation is needed to handle
      // AWS authentication and Bedrock-specific request/response format.
      throw ModelResolutionError(
        'Bedrock provider (${provider.id}) requires native AWS SigV4 integration. '
        'Use a Bedrock-compatible provider or enable OpenAI-compatible mode '
        'until Bedrock native support is implemented.',
      );
    }

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
        final google = GoogleGenerativeAIProvider(
          apiKey: apiKey,
          baseUrl: baseUrl,
        );
        return google.call(effectiveModelName);
      }

      // Default: OpenAI-compatible provider
      final openAI = OpenAIProvider(apiKey: apiKey, baseUrl: baseUrl);
      return openAI.call(effectiveModelName);
    } catch (e) {
      LogTags.network.logError(
        '[Resolver] buildLanguageModel fallback suppressed for ${provider.id}',
        e,
      );
      rethrow;
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
  /// Delegates to [ProviderConfig.buildProviderHeaders] which merges headers
  /// in order (later wins): provider defaults, variant headers, overrides.
  ///
  /// can be overridden at each level (provider → model → variant → call).
  Map<String, String> getHeadersForModel(
    ModelConfig model, {
    ModelVariant? variant,
    Map<String, String>? overrideHeaders,
  }) {
    final provider = getProviderForModel(model.id);
    return provider.buildProviderHeaders(
      variant: variant,
      overrideHeaders: overrideHeaders,
    );
  }

  /// Get the effective body parameters for a model call.
  ///
  /// Delegates to [ProviderConfig.buildProviderOptions] which merges body
  /// fields in order (later wins): provider defaultBody, model providerOptions
  /// metadata, variant body.
  ///
  /// thinkingConfig, OpenAI reasoningEffort, Bedrock promptCacheKey) are
  /// declared at the provider/model level and merged at call time.
  Map<String, dynamic>? getBodyForModel(
    ModelConfig model, {
    ModelVariant? variant,
  }) {
    final provider = getProviderForModel(model.id);
    final body = provider.buildProviderOptions(model, variant: variant);
    return body.isNotEmpty ? body : null;
  }
}
