// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/constants/chat_constants.dart';
import 'package:chatorai/core/context/compaction_orchestrator.dart';
import 'package:chatorai/core/context/compaction_service.dart';
// import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/tools/tool_output_persistence.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/models/model_card_model.dart';
import 'package:chatorai/features/chat/presentation/screens/child_session_screen.dart';
import 'package:chatorai/features/chat/data/models/model_settings.dart';
import 'package:chatorai/features/chat/data/repositories/chat_storage_service.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_messages.dart';
import 'package:chatorai/features/chat/presentation/widgets/markdown_navigator_sidebar.dart';
import 'package:chatorai/features/chat/presentation/widgets/sidebar_wrapper.dart';
import 'package:chatorai/features/chat/presentation/widgets/speech_overlay.dart';
import 'package:chatorai/features/chat/presentation/widgets/welcome_questions_data.dart';
import 'package:chatorai/features/chat/services/continuation_suggestion_service.dart';
import 'package:chatorai/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart'
    show
        themeProvider,
        modelProvider,
        modelSettingsProvider,
        streamingMessageProvider,
        chatListProvider,
        chatStorageServiceProvider,
        chatAiServiceProvider,
        currentChatIdProvider,
        currentChatProvider,
        chatScreenProvider,
        toolRegistryProvider,
        currentAgentProvider,
        compactionConfigProvider,
        currentSessionRunnerProvider,
        sessionRepositoryProvider,
        sessionStackProvider;
import 'package:chatorai/shared/utils/chat_error_utils.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/markdown_parser.dart';
import 'package:chatorai/shared/utils/message_utils.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'chat_screen_ai.dart';
part 'chat_screen_build.dart';
part 'chat_screen_edits.dart';
part 'chat_screen_management.dart';
part 'chat_screen_messaging.dart';
part 'chat_screen_navigator.dart';
part 'chat_screen_scroll.dart';
part 'chat_screen_streaming.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.testScrollController});

  /// Test-only injection for ScrollController.
  final ScrollController? testScrollController;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  late ChatStorageService _chatStorageService;
  late ScrollController _messageScrollController;
  late Future<SessionRepository> _sessionRepositoryFuture;
  SessionRunnerSession? _sessionRunner;

  final GlobalKey<ChatMessagesState> _chatMessagesKey =
      GlobalKey<ChatMessagesState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DateTime? _lastScrollUpdate;
  static const _scrollThrottleDuration = Duration(milliseconds: 16);
  late final FocusNode _chatInputFocusNode;

  double _cachedScreenWidth = 0;
  bool _isMobile = false;

  Widget? _cachedSidebarDrawer;
  double _cachedDrawerWidth = 0;
  String? _cachedChatListHash;

  SpeechUiState _speechUiState = SpeechUiState.idle;
  String _speechStatusMessage = '';
  double _speechSoundLevel = 0.0;
  String _speechRecognizedText = '';

  final ContinuationSuggestionService _suggestionService =
      ContinuationSuggestionService();

  bool _autoScrollEnabled = true; // Auto-scroll enabled by default

  /// Reusable session ID across multiple message turns in the same chat.
  /// Created on the first message, reused on continuation.
  String? _currentSessionId;

  /// Test-only accessor for auto-scroll state.
  bool get autoScrollEnabledForTest => _autoScrollEnabled;

  /// Test-only accessor for the scroll controller.
  ScrollController get testScrollController => _messageScrollController;

  /// Test-only: scroll to bottom.
  @visibleForTesting
  void scrollToBottom({bool force = false}) => _scrollToBottom(force: force);

  /// Test-only: handle scroll event.
  @visibleForTesting
  void handleScroll() => _handleScroll();

  Chat? get currentChat => ref.watch(currentChatProvider);
  String get selectedModelId => ref.watch(modelProvider).selectedModelId;
  ChatModel? get selectedModelObject =>
      ref.watch(modelProvider).selectedModelObject;

  @override
  void initState() {
    super.initState();
    _chatStorageService = ref.read(chatStorageServiceProvider);
    _sessionRepositoryFuture = ref.read(sessionRepositoryProvider.future);
    _messageScrollController =
        widget.testScrollController ?? ScrollController();
    _messageScrollController.addListener(_handleScroll);
    _messageScrollController.addListener(_handleHeadingSync);
    _chatInputFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeSuggestions();
    });
  }

  @override
  void dispose() {
    _messageScrollController.removeListener(_handleScroll);
    _messageScrollController.removeListener(_handleHeadingSync);
    _messageScrollController.dispose();
    _chatInputFocusNode.dispose();
    _sessionRunner?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync current chat ID with session stack on first build
    final chatId = ref.read(currentChatIdProvider);
    if (chatId != null && ref.read(sessionStackProvider).rootChatId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sessionStackProvider.notifier).init(chatId);
      });
    }
  }

  void _showWelcomeSuggestions() {
    final questions = WelcomeQuestionsData.getRandomQuestions(
      context,
      count: 4,
    );
    ref.read(chatScreenProvider.notifier).showWelcomeSuggestions(questions);
  }

  void _updateSelectedModel(String modelId, dynamic modelObject) {
    ref.read(modelProvider.notifier).setSelectedModel(modelId);
  }

  bool _hasHeadings() {
    return ref.read(chatScreenProvider).navigatorHeadings.isNotEmpty;
  }

  Future<void> _showContinuationSuggestions(Message message) async {
    await _suggestionService.showSuggestions(
      ref: ref,
      context: context,
      messageContent: message.content,
      selectedModelId: selectedModelId,
      mounted: mounted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStreaming = ref.watch(
      chatScreenProvider.select((s) => s.isStreaming),
    );
    _cachedScreenWidth = MediaQuery.of(context).size.width;
    _isMobile = _cachedScreenWidth < ChatScreenConstants.mobileBreakpoint;

    final chatInput = ChatInput(
      onSendMessage: _handleSendMessage,
      onToggleStreaming: (_) {},
      onStopStreaming: _stopStreaming,
      isStreaming: isStreaming,
      focusNode: _chatInputFocusNode,
      onSpeechStateChanged: (state, message) {
        setState(() {
          _speechUiState = state;
          _speechStatusMessage = message;
        });
      },
      onSoundLevelChanged: (level) {
        setState(() {
          _speechSoundLevel = (level / 30).clamp(0.0, 1.0);
        });
      },
      onRecognizedText: (text) {
        setState(() {
          _speechRecognizedText = text;
        });
      },
      checkModelSupportsImages: (_) =>
          ref.read(modelProvider.notifier).modelSupportsImagesSelected(),
      onMessageAdded: () {
        // Scroll to bottom when a new message is added (e.g., from skill execution)
        _scrollToBottom(force: true);
      },
    );

    Widget baseLayout = _isMobile
        ? _buildMobileLayout(chatInput)
        : _buildDesktopLayout(chatInput);

    final uiState = ref.watch(chatScreenProvider);
    if (uiState.navigatorHeadings.isNotEmpty) {
      return Stack(
        children: [
          baseLayout,
          MarkdownNavigatorSidebar(
            headings: uiState.navigatorHeadings,
            activeHeadingIndex: uiState.activeHeadingIndex,
            isOpen: uiState.isNavigatorVisible,
            onClose: _toggleNavigator,
            onHeadingTap: _onHeadingTap,
          ),
        ],
      );
    }
    return baseLayout;
  }
}
