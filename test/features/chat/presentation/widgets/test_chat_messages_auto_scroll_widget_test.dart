import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/presentation/screens/chat_screen.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/providers/chat_screen_notifier.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/features/settings/providers/model_settings_provider.dart';
import 'package:chatorai/core/agents/agent_provider.dart';
import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/shared/theme/theme_provider.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/mcp/mcp_status_provider.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/session/session_stack.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/features/sessions/providers/session_providers.dart'
    show sessionStackProvider;
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/models/providers/model_provider.dart';
import 'package:chatorai/shared/utils/project_info_provider.dart';
import 'package:chatorai/features/sessions/providers/session_parts_provider.dart';
import 'package:chatorai/providers.dart'
    show
        sessionRepositoryProvider,
        chatScreenProvider,
        themeProvider,
        modelSettingsProvider,
        currentAgentProvider,
        providerCatalogServiceProvider,
        currentChatProvider,
        currentChatIdProvider,
        chatListProvider,
        modelProvider,
        toolRegistryProvider,
        compactionConfigProvider,
        currentSessionRunnerProvider,
        permissionServiceProvider,
        sessionPartsProvider,
        scaffoldKeyProvider,
        chatScrollIntentProvider;
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

class _EmptyChatListNotifier extends ChatListNotifier {
  @override
  AsyncValue<List<Chat>> build() {
    return AsyncValue.data([]);
  }
}

class _NoWelcomeSuggestionsNotifier extends ChatScreenNotifier {
  @override
  ChatScreenState build() => const ChatScreenState();

  @override
  void showWelcomeSuggestions(List<String> suggestions) {}
}

class _AutoScrollThemeNotifier extends ThemeNotifier {
  @override
  ThemeState build() => const ThemeState(autoScrollDuringStreaming: true);
}

const _longText =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod '
    'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim '
    'veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea '
    'commodo consequat. Duis aute irure dolor in reprehenderit in voluptate '
    'velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint '
    'occaecat cupidatat non proident, sunt in culpa qui officia deserunt '
    'mollit anim id est laborum.';

List<Message> _longMessages() {
  final now = DateTime.now();
  return List.generate(
    40,
    (i) => Message(
      id: 'm$i',
      role: i.isEven ? MessageRole.user : MessageRole.assistant,
      content: _longText,
      timestamp: now,
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
  );
}

Chat _chatWithContent() {
  return Chat(
    id: 'chat-auto-scroll',
    title: 'Auto-scroll',
    messages: _longMessages(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('ChatScreen auto-scroll', () {
    late MockSessionRepository mockSessionRepo;

    setUp(() {
      mockSessionRepo = MockSessionRepository();
      when(
        () => mockSessionRepo.cleanupOrphanSessions(),
      ).thenAnswer((_) async => 0);
      when(() => mockSessionRepo.findAll()).thenAnswer((_) async => []);
    });

    Widget buildTestWidget({required ScrollController scrollController}) {
      return ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) => mockSessionRepo),
          chatScreenProvider.overrideWith(
            () => _NoWelcomeSuggestionsNotifier(),
          ),
          themeProvider.overrideWith(() => _AutoScrollThemeNotifier()),
          modelSettingsProvider.overrideWith(() => ModelSettingsNotifier()),
          currentAgentProvider.overrideWith(() => CurrentAgentNotifier()),
          providerCatalogServiceProvider.overrideWith(
            (ref) => _FakeCatalogService(),
          ),
          currentChatProvider.overrideWithValue(_chatWithContent()),
          currentChatIdProvider.overrideWith(() => CurrentChatIdNotifier()),
          chatListProvider.overrideWith(() => _EmptyChatListNotifier()),
          modelProvider.overrideWith(() => ModelNotifier()),
          toolRegistryProvider.overrideWith(
            (ref) =>
                ToolRegistry(PermissionService(), PermissionRuleset(rules: [])),
          ),
          compactionConfigProvider.overrideWith((ref) => CompactionConfig()),
          sessionStackProvider.overrideWith(() => SessionStackNotifier()),
          permissionServiceProvider.overrideWith((ref) => PermissionService()),
          mcpStatusesProvider.overrideWith(
            (ref) async => <String, McpServerStatus>{},
          ),
          gitBranchProvider.overrideWith((_) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChatScreen(testScrollController: scrollController),
          ),
        ),
      );
    }

    testWidgets(
      'scroll up during streaming prevents auto-scroll on new chunk',
      (tester) async {
        final scrollController = ScrollController();

        await tester.pumpWidget(
          buildTestWidget(scrollController: scrollController),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        final position = scrollController.position;
        expect(position.maxScrollExtent, greaterThan(0));

        scrollController.jumpTo(position.maxScrollExtent);
        await tester.pump();
        expect(scrollController.offset, position.maxScrollExtent);

        final state = tester.state(find.byType(ChatScreen)) as dynamic;
        expect(state.autoScrollEnabledForTest, isTrue);

        // Reproduce the streaming race: auto-scroll is scheduled while the
        // user is still at the bottom, then the user scrolls up BEFORE the
        // post-frame callback runs.
        state.maybeAutoScrollDuringStreaming();
        scrollController.jumpTo(position.maxScrollExtent - 200);
        state.handleScroll();
        expect(state.autoScrollEnabledForTest, isFalse);

        await tester.pumpAndSettle();

        expect(scrollController.offset, position.maxScrollExtent - 200);
      },
    );

    testWidgets('at bottom auto-scrolls on new chunk', (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildTestWidget(scrollController: scrollController),
      );
      await tester.pumpAndSettle();

      final position = scrollController.position;
      expect(position.maxScrollExtent, greaterThan(0));

      scrollController.jumpTo(position.maxScrollExtent);
      await tester.pump();
      expect(scrollController.offset, position.maxScrollExtent);

      final state = tester.state(find.byType(ChatScreen)) as dynamic;
      expect(state.autoScrollEnabledForTest, isTrue);

      state.maybeAutoScrollDuringStreaming();
      await tester.pumpAndSettle();

      expect(scrollController.offset, position.maxScrollExtent);
    });

    testWidgets('scrollToBottom force=false does nothing when diff < 5', (
      tester,
    ) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildTestWidget(scrollController: scrollController),
      );
      await tester.pumpAndSettle();

      final position = scrollController.position;
      expect(position.maxScrollExtent, greaterThan(0));

      scrollController.jumpTo(position.maxScrollExtent - 2);
      await tester.pump();
      expect(scrollController.offset, position.maxScrollExtent - 2);

      final state = tester.state(find.byType(ChatScreen)) as dynamic;
      state.scrollToBottom(force: false);
      await tester.pumpAndSettle();

      expect(scrollController.offset, position.maxScrollExtent - 2);
    });

    testWidgets('Home/End shortcuts scroll the chat via intent', (
      tester,
    ) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildTestWidget(scrollController: scrollController),
      );
      await tester.pumpAndSettle();

      final position = scrollController.position;
      expect(position.maxScrollExtent, greaterThan(0));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      );

      container.read(chatScrollIntentProvider.notifier).scrollToEnd();
      await tester.pump();
      expect(scrollController.offset, position.maxScrollExtent);

      container.read(chatScrollIntentProvider.notifier).scrollToStart();
      await tester.pump();
      expect(scrollController.offset, 0);
    });

    testWidgets('unmounting ChatScreen does not touch providers', (
      tester,
    ) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildTestWidget(scrollController: scrollController),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
