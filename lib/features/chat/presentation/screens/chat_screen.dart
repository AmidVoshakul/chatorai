// ignore_for_file: avoid_print

import 'dart:async';

import 'package:chatorai/core/constants/chat_constants.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/services/chat_actions.dart';
import 'package:chatorai/features/chat/presentation/screens/child_session_screen.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_desktop_layout.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_messages_area.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_mobile_layout.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_scroll_follow_controller.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_sidebar_drawer.dart';
import 'package:chatorai/features/chat/presentation/widgets/markdown_navigator_sidebar.dart';
import 'package:chatorai/features/chat/presentation/widgets/welcome_questions_data.dart';
import 'package:chatorai/features/chat/services/continuation_suggestion_service.dart';
import 'package:chatorai/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/features/models/screens/models_screen.dart';
import 'package:chatorai/features/settings/widgets/model_settings_sheet.dart';
import 'package:chatorai/features/settings/widgets/settings_modal.dart';
import 'package:chatorai/providers.dart'
    show
        themeProvider,
        modelProvider,
        currentChatIdProvider,
        currentChatProvider,
        chatScreenProvider,
        currentSessionRunnerProvider,
        sessionRepositoryProvider,
        sessionStackProvider,
        scaffoldKeyProvider,
        listenChatScrollIntent;
import 'package:chatorai/shared/utils/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.testScrollController});

  /// Test-only injection for ScrollController.
  final ScrollController? testScrollController;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  late ScrollController _messageScrollController;
  late final ChatScrollFollowController _follow;
  late Future<SessionRepository> _sessionRepositoryFuture;
  late final ChatActions _chatActions;

  late final GlobalKey<ScaffoldState> _scaffoldKey;

  DateTime? _lastHeadingUpdate;
  static const _scrollThrottleDuration = Duration(milliseconds: 32);
  late final FocusNode _chatInputFocusNode;

  double _cachedScreenWidth = 0;
  bool _isMobile = false;
  bool _isInputPopupVisible = false;

  SpeechUiState _speechUiState = SpeechUiState.idle;
  String _speechStatusMessage = '';
  double _speechSoundLevel = 0.0;
  String _speechRecognizedText = '';

  final ContinuationSuggestionService _suggestionService =
      ContinuationSuggestionService();

  /// Test-only accessor for the scroll controller.
  ScrollController get testScrollController => _messageScrollController;

  /// Test-only: instant snap to the newest message.
  @visibleForTesting
  void snapToBottom() => _follow.snapToBottom();

  Chat? get currentChat => ref.watch(currentChatProvider);
  String get selectedModelId => ref.watch(modelProvider).selectedModelId;
  ModelConfig? get selectedModelObject =>
      ref.watch(modelProvider).selectedModelObject;

  @override
  void initState() {
    super.initState();
    _sessionRepositoryFuture = ref.read(sessionRepositoryProvider.future);
    _messageScrollController =
        widget.testScrollController ?? ScrollController();
    _follow = ChatScrollFollowController();
    _follow.attach(_messageScrollController);
    _messageScrollController.addListener(_onScroll);
    _chatInputFocusNode = FocusNode();
    _scaffoldKey = ref.read(scaffoldKeyProvider);
    _chatActions = ChatActions(ref);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeSuggestions();
    });
  }

  @override
  void dispose() {
    _messageScrollController.removeListener(_onScroll);
    _messageScrollController.dispose();
    _follow.dispose();
    _chatInputFocusNode.dispose();
    _chatActions.dispose();
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

  void _openModelSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ModelsScreen()),
    );
  }

  void _openModelSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => const ModelSettingsSheet(),
      ),
    );
  }

  void _openSettings() {
    final width = MediaQuery.of(context).size.width;
    if (width >= ChatScreenConstants.mobileBreakpoint) {
      showSettingsModal(context);
    } else {
      Navigator.of(context).pushNamed('/settings');
    }
  }

  // ── Scroll methods ──────────────────────────────────────────────────

  // The message list is top-down: offset 0 is the oldest, maxScrollExtent
  // is the newest. [_follow] is the sole emitter of programmatic jumps;
  // the listener here only feeds heading sync. Home/End user jumps stay
  // direct in [listenChatScrollIntent].
  void _onScroll() {
    _follow.onScroll();
    _handleHeadingSync();
  }

  void _snapToBottom() => _follow.snapToBottom();

  void _handleHeadingSync() {
    final now = DateTime.now();
    if (_lastHeadingUpdate != null &&
        now.difference(_lastHeadingUpdate!) < _scrollThrottleDuration) {
      return;
    }
    _lastHeadingUpdate = now;

    final navigatorHeadings = ref.read(chatScreenProvider).navigatorHeadings;
    if (!_messageScrollController.hasClients || navigatorHeadings.isEmpty) {
      return;
    }

    final currentOffset = _messageScrollController.offset;
    final viewportHeight = _messageScrollController.position.viewportDimension;
    int newActiveIndex = -1;

    for (int i = 0; i < navigatorHeadings.length; i++) {
      final heading = navigatorHeadings[i];
      final ctx = heading.anchorKey.currentContext;
      if (ctx == null || !ctx.mounted) continue;
      try {
        final RenderBox? box = ctx.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final position = box.localToGlobal(Offset.zero);
          if (position.dy < viewportHeight / 2 && position.dy > -50) {
            newActiveIndex = i;
            break;
          }
        }
      } catch (e) {
        // Ignore render errors
      }
    }

    if (newActiveIndex == -1) {
      final scrollMax = _messageScrollController.position.maxScrollExtent;
      if (currentOffset <= 100) {
        newActiveIndex = 0;
      } else if (currentOffset >= scrollMax - 100) {
        newActiveIndex = navigatorHeadings.length - 1;
      }
    }

    final activeHeadingIndex = ref.read(
      chatScreenProvider.select((s) => s.activeHeadingIndex),
    );
    if (newActiveIndex != -1 && newActiveIndex != activeHeadingIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && newActiveIndex != -1) {
          ref
              .read(chatScreenProvider.notifier)
              .setActiveHeadingIndex(newActiveIndex);
        }
      });
    }
  }

  // ── Navigator methods ───────────────────────────────────────────────

  void _onHeadingsUpdated(List<MarkdownHeadingInfoWithKey> headings) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatScreenProvider.notifier).setNavigatorHeadings(headings);
      }
    });
  }

  void _toggleNavigator() {
    ref.read(chatScreenProvider.notifier).toggleNavigator();
  }

  void _onHeadingTap(String headingText, String messageId, int level) {
    final navigatorHeadings = ref.read(
      chatScreenProvider.select((s) => s.navigatorHeadings),
    );
    final normalizedTapText = stripMarkdownFormatting(headingText).trim();
    int headingIndex = navigatorHeadings.indexWhere(
      (h) =>
          h.messageId == messageId &&
          h.level == level &&
          stripMarkdownFormatting(h.text).trim() == normalizedTapText,
    );
    // fallback: поиск без учёта messageId (если якорь пересоздан) или только по тексту
    if (headingIndex < 0) {
      headingIndex = navigatorHeadings.indexWhere(
        (h) =>
            h.level == level &&
            stripMarkdownFormatting(h.text).trim() == normalizedTapText,
      );
    }

    if (headingIndex >= 0) {
      ref.read(chatScreenProvider.notifier).setActiveHeadingIndex(headingIndex);
      final heading = navigatorHeadings[headingIndex];

      void performScroll() {
        final ctx = heading.anchorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          // The chat list is top-down: the axis "leading" edge is the TOP
          // of the viewport, so aligning a heading flush under the AppBar
          // means pinning it to the LEADING edge (0.0).
          final position = Scrollable.of(ctx).position;
          final reversed = position.axisDirection == AxisDirection.up;
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: reversed ? 1.0 : 0.0,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          );
        } else if (_messageScrollController.hasClients) {
          // Fallback: если контекст ещё не смонтирован (редкий случай
          // после prune/пересоздания), скроллим к началу/концу эвристикой
          // уже нельзя — просто логируем, т.к. с SingleChildScrollView
          // все якоря должны быть смонтированы сразу.
          debugPrint(
            '[ChatScreen] heading tap: anchor not mounted id=${heading.anchor.id}',
          );
        }
      }

      final ctx = heading.anchorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        performScroll();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) performScroll();
        });
      }
    } else {
      debugPrint(
        '[ChatScreen] heading tap: not found text=$headingText msg=$messageId lvl=$level',
      );
    }
    ref.read(chatScreenProvider.notifier).setNavigatorVisible(false);
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    listenChatScrollIntent(ref, _messageScrollController);
    final isStreaming = ref.watch(
      chatScreenProvider.select((s) => s.isStreaming),
    );
    _cachedScreenWidth = MediaQuery.of(context).size.width;
    _isMobile = _cachedScreenWidth < ChatScreenConstants.mobileBreakpoint;

    final chat = currentChat;
    final continuationSuggestions = ref.watch(
      chatScreenProvider.select((s) => s.continuationSuggestions),
    );
    final showSuggestions = ref.watch(
      chatScreenProvider.select((s) => s.showSuggestions),
    );
    final isSuggestionsLoading = ref.watch(
      chatScreenProvider.select((s) => s.isSuggestionsLoading),
    );
    final welcomeSuggestions = ref.watch(
      chatScreenProvider.select((s) => s.welcomeSuggestions),
    );
    final showWelcomeSuggestions = ref.watch(
      chatScreenProvider.select((s) => s.showWelcomeSuggestions),
    );
    final isNavigatorVisible = ref.watch(
      chatScreenProvider.select((s) => s.isNavigatorVisible),
    );
    final wideScreenMode = ref.watch(
      themeProvider.select((s) => s.wideScreenMode),
    );

    final chatInput = ChatInput(
      onSendMessage: (messageData) {
        _chatActions.handleSendMessage(
          messageData,
          context: context,
          scrollController: _messageScrollController,
          chatInputFocusNode: _chatInputFocusNode,
          isMounted: () => mounted,
          showWelcomeSuggestions: _showWelcomeSuggestions,
          scrollToBottom: _snapToBottom,
        );
      },
      onToggleStreaming: (_) {},
      onStopStreaming: () {
        _chatActions.stopStreaming(context: context, isMounted: () => mounted);
      },
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
      onOpenModelSettings: _openModelSettings,
      onCompact: () async {
        final chat = ref.read(currentChatProvider);
        if (chat == null || chat.messages.isEmpty) return;
        await _chatActions.runCompaction(chat);
      },
      onPopupVisibilityChanged: (visible) {
        if (mounted) {
          setState(() {
            _isInputPopupVisible = visible;
          });
        }
      },
    );

    final chatMessagesArea = ChatMessagesArea(
      chat: chat,
      sessionRepositoryFuture: _sessionRepositoryFuture,
      scrollController: _messageScrollController,
      followController: _follow,
      selectedModel: selectedModelId,
      onSendMessage: (messageData) {
        _chatActions.handleSendMessage(
          messageData,
          context: context,
          scrollController: _messageScrollController,
          chatInputFocusNode: _chatInputFocusNode,
          isMounted: () => mounted,
          showWelcomeSuggestions: _showWelcomeSuggestions,
          scrollToBottom: _snapToBottom,
        );
      },
      onMessageDeleted: () {
        _chatActions.refreshChatMessages(
          context: context,
          isMounted: () => mounted,
          showWelcomeSuggestions: _showWelcomeSuggestions,
        );
      },
      onMessageEdited: (messageId, newContent) {
        _chatActions.handleMessageEdited(
          messageId,
          newContent,
          context: context,
          isMounted: () => mounted,
          showWelcomeSuggestions: _showWelcomeSuggestions,
        );
      },
      onMessageEditAndSend: (messageId, newContent) {
        _chatActions.handleMessageEditAndSend(
          messageId,
          newContent,
          context: context,
          isMounted: () => mounted,
          showWelcomeSuggestions: _showWelcomeSuggestions,
          scrollToBottom: _snapToBottom,
          scrollController: _messageScrollController,
          chatInputFocusNode: _chatInputFocusNode,
        );
      },
      onContinueResponse: (lastMessageId) {
        _chatActions.continueAIResponse(
          lastMessageId,
          context: context,
          isMounted: () => mounted,
          showWelcomeSuggestions: _showWelcomeSuggestions,
          scrollToBottom: _snapToBottom,
          scrollController: _messageScrollController,
          chatInputFocusNode: _chatInputFocusNode,
        );
      },
      onRegenerateResponse: (messageId) {
        _chatActions.regenerateResponse(
          messageId,
          context: context,
          isMounted: () => mounted,
          showWelcomeSuggestions: _showWelcomeSuggestions,
          scrollToBottom: _snapToBottom,
          scrollController: _messageScrollController,
          chatInputFocusNode: _chatInputFocusNode,
        );
      },
      continuationSuggestions: continuationSuggestions,
      showSuggestions: showSuggestions,
      isSuggestionsLoading: isSuggestionsLoading,
      onSuggestionsClose: () =>
          ref.read(chatScreenProvider.notifier).hideSuggestions(),
      onSuggestionsRefresh: () {
        if (chat != null && chat.messages.isNotEmpty) {
          _chatActions.showContinuationSuggestions(
            chat.messages.last,
            context: context,
            isMounted: () => mounted,
            suggestionService: _suggestionService,
          );
        }
      },
      welcomeSuggestions: welcomeSuggestions,
      showWelcomeSuggestions: showWelcomeSuggestions,
      onWelcomeSuggestionsClose: () =>
          ref.read(chatScreenProvider.notifier).hideWelcomeSuggestions(),
      onHeadingsUpdated: _onHeadingsUpdated,
      onToggleNavigator: _toggleNavigator,
      onQuestionAnswer: (messageId, answer) {
        _chatActions.handleQuestionAnswer(
          messageId,
          answer,
          context: context,
          scrollController: _messageScrollController,
          chatInputFocusNode: _chatInputFocusNode,
          isMounted: () => mounted,
          showWelcomeSuggestions: _showWelcomeSuggestions,
          scrollToBottom: _snapToBottom,
        );
      },
      onTaskTap: (partSessionId) {
        final isRealSessionId =
            partSessionId != null && partSessionId.startsWith('ses_');
        final effectiveId = isRealSessionId
            ? partSessionId
            : ref
                  .read(currentSessionRunnerProvider.notifier)
                  .activeChildSessionId;
        if (effectiveId != null && effectiveId.isNotEmpty) {
          ref
              .read(sessionStackProvider.notifier)
              .push(SessionID.fromString(effectiveId));
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChildSessionScreen(sessionId: effectiveId),
            ),
          );
        }
      },
      sessionId: _chatActions.currentSessionId,
      wrapWithGesture: _isMobile,
      hasHeadings: _hasHeadings,
      toggleNavigator: _toggleNavigator,
    );

    final baseLayout = _isMobile
        ? ChatMobileLayout(
            chatInput: chatInput,
            scaffoldKey: _scaffoldKey,
            hasHeadings: _hasHeadings,
            onToggleNavigator: _toggleNavigator,
            onModelSelected: _updateSelectedModel,
            onOpenModelSelector: _openModelSelector,
            onMenuPressed: () {
              FocusScope.of(context).unfocus();
              _scaffoldKey.currentState?.openDrawer();
            },
            drawer: ChatSidebarDrawer(
              width: ChatScreenConstants.sidebarWidth,
              onToggleSidebar: () => Navigator.pop(context),
              onChatSelect: (chatId) {
                unawaited(
                  _chatActions.selectChat(
                    chatId,
                    isMounted: () => mounted,
                    showWelcomeSuggestions: _showWelcomeSuggestions,
                    scrollToBottom: _snapToBottom,
                  ),
                );
                Navigator.of(context).pop();
              },
              onChatDelete: (chatId) {
                _chatActions.deleteChat(
                  chatId,
                  context: context,
                  isMounted: () => mounted,
                  showWelcomeSuggestions: _showWelcomeSuggestions,
                );
              },
              onNewChat: () {
                _chatActions.createNewChat(
                  showWelcomeSuggestions: _showWelcomeSuggestions,
                );
                Navigator.of(context).pop();
              },
              onOpenSettings: _openSettings,
            ),
            speechUiState: _speechUiState,
            speechStatusMessage: _speechStatusMessage,
            speechSoundLevel: _speechSoundLevel,
            speechRecognizedText: _speechRecognizedText,
            chatMessagesArea: chatMessagesArea,
            screenWidth: _cachedScreenWidth,
            isNavigatorVisible: isNavigatorVisible,
            wideScreenMode: wideScreenMode,
            selectedModel: selectedModelId,
            selectedModelObject: selectedModelObject,
            isInputPopupVisible: _isInputPopupVisible,
          )
        : ChatDesktopLayout(
            chatInput: chatInput,
            scaffoldKey: _scaffoldKey,
            hasHeadings: _hasHeadings,
            onToggleNavigator: _toggleNavigator,
            onModelSelected: _updateSelectedModel,
            onOpenModelSelector: _openModelSelector,
            onMenuPressed: () {
              FocusScope.of(context).unfocus();
              _scaffoldKey.currentState?.openDrawer();
            },
            drawer: ChatSidebarDrawer(
              width: ChatScreenConstants.sidebarWidth,
              onToggleSidebar: () => Navigator.pop(context),
              onChatSelect: (chatId) {
                unawaited(
                  _chatActions.selectChat(
                    chatId,
                    isMounted: () => mounted,
                    showWelcomeSuggestions: _showWelcomeSuggestions,
                    scrollToBottom: _snapToBottom,
                  ),
                );
                Navigator.of(context).pop();
              },
              onChatDelete: (chatId) {
                _chatActions.deleteChat(
                  chatId,
                  context: context,
                  isMounted: () => mounted,
                  showWelcomeSuggestions: _showWelcomeSuggestions,
                );
              },
              onNewChat: () {
                _chatActions.createNewChat(
                  showWelcomeSuggestions: _showWelcomeSuggestions,
                );
                Navigator.of(context).pop();
              },
              onOpenSettings: _openSettings,
            ),
            speechUiState: _speechUiState,
            speechStatusMessage: _speechStatusMessage,
            speechSoundLevel: _speechSoundLevel,
            speechRecognizedText: _speechRecognizedText,
            chatMessagesArea: chatMessagesArea,
            screenWidth: _cachedScreenWidth,
            isNavigatorVisible: isNavigatorVisible,
            wideScreenMode: wideScreenMode,
            selectedModel: selectedModelId,
            selectedModelObject: selectedModelObject,
            isInputPopupVisible: _isInputPopupVisible,
          );

    final navigatorHeadings = ref.watch(
      chatScreenProvider.select((s) => s.navigatorHeadings),
    );
    final screenContent = navigatorHeadings.isNotEmpty
        ? Stack(
            children: [
              baseLayout,
              MarkdownNavigatorSidebar(
                headings: navigatorHeadings,
                activeHeadingIndex: ref.watch(
                  chatScreenProvider.select((s) => s.activeHeadingIndex),
                ),
                isOpen: isNavigatorVisible,
                onClose: _toggleNavigator,
                onHeadingTap: _onHeadingTap,
              ),
            ],
          )
        : baseLayout;

    return screenContent;
  }
}
