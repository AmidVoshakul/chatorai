import 'package:chatorai/core/agents/agent_provider.dart';
import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/providers/chat_screen_notifier.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_messages.dart';
import 'package:chatorai/features/settings/providers/model_settings_provider.dart';
import 'package:chatorai/core/llm/catalog_providers.dart'
    show providerCatalogServiceProvider;
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart'
    show
        chatScreenProvider,
        themeProvider,
        modelSettingsProvider,
        sessionRepositoryProvider,
        currentAgentProvider;
import 'package:chatorai/shared/theme/theme_provider.dart';
import 'package:chatorai/shared/utils/markdown_parser.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class _FakeCatalogService extends ProviderCatalogService {
  _FakeCatalogService()
    : super(
        secureStorage: _FakeSecureStorageService(),
        prefs: SharedPreferences.getInstance() as SharedPreferences,
        builtInProviders: const [],
      );

  @override
  ModelConfig? getModel(String modelId) => null;
}

class _FakeSecureStorageService extends SecureStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ChatMessages headings', () {
    testWidgets(
      'onHeadingsUpdated fires after widget build with correct headings',
      (tester) async {
        final headings = <List<MarkdownHeadingInfoWithKey>>[];
        final mockRepo = MockSessionRepository();
        final chat = Chat(
          id: 'chat-1',
          title: 'Test',
          messages: [
            Message(
              id: 'm1',
              role: MessageRole.assistant,
              content: '# Foo\nbar',
              timestamp: DateTime.now(),
              isComplete: true,
              synthetic: false,
              tokensInput: 0,
              tokensOutput: 0,
              tokensReasoning: 0,
              contextLength: 0,
              model: null,
              agent: null,
              reasoning: null,
              partsJson: const [],
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionRepositoryProvider.overrideWith((ref) => mockRepo),
              chatScreenProvider.overrideWith(() => ChatScreenNotifier()),
              themeProvider.overrideWith(() => ThemeNotifier()),
              modelSettingsProvider.overrideWith(() => ModelSettingsNotifier()),
              currentAgentProvider.overrideWith(() => CurrentAgentNotifier()),
              providerCatalogServiceProvider.overrideWith(
                (ref) => _FakeCatalogService(),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChatMessages(
                  sessionRepository: mockRepo,
                  chat: chat,
                  onSendMessage: (_) {},
                  onMessageDeleted: () {},
                  onHeadingsUpdated: (h) => headings.add(h),
                ),
              ),
            ),
          ),
        );

        // After build: post-frame callback has fired with correct headings.
        expect(headings, hasLength(1));
        expect(headings.single.map((h) => h.text), ['Foo']);
      },
    );

    testWidgets('didUpdateWidget updates headings when messages change', (
      tester,
    ) async {
      final headings = <List<MarkdownHeadingInfoWithKey>>[];
      final mockRepo = MockSessionRepository();
      final chatA = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: '# Foo',
            timestamp: DateTime.now(),
            isComplete: true,
            synthetic: false,
            tokensInput: 0,
            tokensOutput: 0,
            tokensReasoning: 0,
            contextLength: 0,
            model: null,
            agent: null,
            reasoning: null,
            partsJson: const [],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final chatB = Chat(
        id: 'chat-1',
        title: 'Test',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.assistant,
            content: '# Bar',
            timestamp: DateTime.now(),
            isComplete: true,
            synthetic: false,
            tokensInput: 0,
            tokensOutput: 0,
            tokensReasoning: 0,
            contextLength: 0,
            model: null,
            agent: null,
            reasoning: null,
            partsJson: const [],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) => mockRepo),
            chatScreenProvider.overrideWith(() => ChatScreenNotifier()),
            themeProvider.overrideWith(() => ThemeNotifier()),
            modelSettingsProvider.overrideWith(() => ModelSettingsNotifier()),
            currentAgentProvider.overrideWith(() => CurrentAgentNotifier()),
            providerCatalogServiceProvider.overrideWith(
              (ref) => _FakeCatalogService(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ChatMessages(
                sessionRepository: mockRepo,
                chat: chatA,
                onSendMessage: (_) {},
                onMessageDeleted: () {},
                onHeadingsUpdated: (h) => headings.add(h),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(headings, hasLength(1));
      expect(headings.single.map((h) => h.text), ['Foo']);

      // Update widget with new messages.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionRepositoryProvider.overrideWith((ref) => mockRepo),
            chatScreenProvider.overrideWith(() => ChatScreenNotifier()),
            themeProvider.overrideWith(() => ThemeNotifier()),
            modelSettingsProvider.overrideWith(() => ModelSettingsNotifier()),
            currentAgentProvider.overrideWith(() => CurrentAgentNotifier()),
            providerCatalogServiceProvider.overrideWith(
              (ref) => _FakeCatalogService(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ChatMessages(
                sessionRepository: mockRepo,
                chat: chatB,
                onSendMessage: (_) {},
                onMessageDeleted: () {},
                onHeadingsUpdated: (h) => headings.add(h),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(headings, hasLength(2));
      expect(headings.last.map((h) => h.text), ['Bar']);
    });
  });
}
