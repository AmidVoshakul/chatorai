import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:chatorai/core/chat/services/chat_ai_service.dart';

// ─── Mocks ──────────────────────────────────────────────────────────────

class _MockSecureStorage extends Mock implements SecureStorageService {}

class _MockSharedPreferences extends Mock implements SharedPreferences {}

// ─── Fake LanguageModelV4 that emits AiNoSuchToolError from doStream ────

class _ErrorEmittingLanguageModelV4 extends LanguageModelV4 {
  _ErrorEmittingLanguageModelV4(this.error);

  final Object error;

  @override
  String get provider => 'fake';

  @override
  String get modelId => 'fake-error-model';

  @override
  String get specificationVersion => 'v4';

  @override
  Future<LanguageModelV4GenerateResult> doGenerate(
    LanguageModelV4CallOptions options,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<LanguageModelV4StreamResult> doStream(
    LanguageModelV4CallOptions options,
  ) async {
    throw error;
  }
}

// ─── Custom ModelResolver that returns the fake model ──────────────────

class _FakeModelResolver extends ModelResolver {
  _FakeModelResolver(super.catalog, this._fakeModel);

  final LanguageModelV4? _fakeModel;

  @override
  ModelConfig resolve(String modelId) {
    return ModelConfig.basic(
      providerId: 'fake',
      modelName: 'error-model',
      displayName: 'Fake Error Model',
      contextLength: 4096,
    );
  }

  @override
  ProviderConfig getProviderForModel(String modelId) {
    return ProviderConfig.basic(
      id: 'fake',
      name: 'Fake Provider',
      baseUrl: 'http://fake.local',
      auth: AuthConfig.none(),
      sdk: 'openai',
    );
  }

  @override
  Map<String, String> getHeadersForModel(
    ModelConfig model, {
    ModelVariant? variant,
    Map<String, String>? overrideHeaders,
  }) {
    return <String, String>{};
  }

  @override
  Future<LanguageModelV4> buildLanguageModel(
    ModelConfig model, {
    ModelVariant? variant,
    String? overrideApiKey,
    String? overrideBaseUrl,
    Map<String, String>? overrideHeaders,
  }) async {
    if (_fakeModel != null) return _fakeModel!;
    return super.buildLanguageModel(
      model,
      variant: variant,
      overrideApiKey: overrideApiKey,
      overrideBaseUrl: overrideBaseUrl,
      overrideHeaders: overrideHeaders,
    );
  }
}

// ─── Testable ChatAiService ─────────────────────────────────────────────

class _TestableChatAiService extends ChatAiService {
  _TestableChatAiService({
    required ModelResolver resolver,
    Map<String, String>? headers,
  }) : super(resolver: resolver, headers: headers ?? const {});

  static ModelResolver _createFakeResolverWithModel(LanguageModelV4 model) {
    final mockSecureStorage = _MockSecureStorage();
    final mockPrefs = _MockSharedPreferences();

    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.getInt(any())).thenReturn(null);

    final catalog = ProviderCatalogService(
      secureStorage: mockSecureStorage,
      prefs: mockPrefs,
      builtInProviders: [],
    );
    return _FakeModelResolver(catalog, model);
  }
}

// ─── Tests ──────────────────────────────────────────────────────────────

void main() {
  group('ChatAiService.streamChatCompletion — AiNoSuchToolError', () {
    test(
      'gracefully finalizes on AiNoSuchToolError without throwing',
      () async {
        final error = AiNoSuchToolError('unknown tool "write"');
        final fakeModel = _ErrorEmittingLanguageModelV4(error);
        final resolver = _TestableChatAiService._createFakeResolverWithModel(
          fakeModel,
        );

        final service = _TestableChatAiService(
          resolver: resolver,
          headers: const {},
        );
        service.currentModelForTesting = 'fake/error-model';
        service.currentTemperatureForTesting = 0.7;

        final chunks = <String>[];
        final toolStarts = <(String, String, Map<String, dynamic>)>[];
        final toolErrors = <(String, String, String)>[];
        var completionCalled = false;
        var completionText = '';

        await service.streamChatCompletion(
          messages: const [
            {'role': 'user', 'content': 'Hello'},
          ],
          model: 'fake/error-model',
          temperature: 0.7,
          onChunk: (chunk) async => chunks.add(chunk),
          onReasoning: (_) async {},
          onCompletion: (text) async {
            completionCalled = true;
            completionText = text;
          },
          onToolStart: (callId, toolName, input) async {
            toolStarts.add((callId, toolName, input));
          },
          onToolError: (callId, toolName, error) async {
            toolErrors.add((callId, toolName, error));
          },
          onUsage: (_, __, ___, ____, _____, ______) {},
        );

        expect(completionCalled, isTrue);
        expect(completionText, '');
        expect(toolStarts.length, 1);
        expect(toolStarts.first.$2, 'write');
        expect(toolErrors.length, 1);
        expect(toolErrors.first.$2, 'write');
      },
    );

    test(
      'onCompletion failure after AiNoSuchToolError is logged, not thrown',
      () async {
        final error = AiNoSuchToolError('unknown tool "write"');
        final fakeModel = _ErrorEmittingLanguageModelV4(error);
        final resolver = _TestableChatAiService._createFakeResolverWithModel(
          fakeModel,
        );

        final service = _TestableChatAiService(
          resolver: resolver,
          headers: const {},
        );
        service.currentModelForTesting = 'fake/error-model';
        service.currentTemperatureForTesting = 0.7;

        var onCompletionCalled = false;

        await service.streamChatCompletion(
          messages: const [
            {'role': 'user', 'content': 'Hello'},
          ],
          model: 'fake/error-model',
          temperature: 0.7,
          onChunk: (_) async {},
          onReasoning: (_) async {},
          onCompletion: (_) async {
            onCompletionCalled = true;
            throw StateError('completion boom');
          },
          onUsage: (_, __, ___, ____, _____, ______) {},
        );

        expect(onCompletionCalled, isTrue);
      },
    );
  });
}
