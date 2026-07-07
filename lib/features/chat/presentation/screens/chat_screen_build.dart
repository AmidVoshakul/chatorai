part of 'chat_screen.dart';

extension _ChatScreenBuildExt on _ChatScreenState {
  Widget _buildSidebarDrawer({required double width}) {
    final chatListState = ref.watch(chatListProvider);
    final chatListHash = chatListState.when(
      data: (chats) =>
          chats.fold<String>('', (hash, chat) => '$hash${chat.id}'),
      loading: () => 'loading',
      error: (e, st) => 'error',
    );

    if (_cachedSidebarDrawer == null ||
        _cachedDrawerWidth != width ||
        _cachedChatListHash != chatListHash) {
      _cachedDrawerWidth = width;
      _cachedChatListHash = chatListHash;
      _cachedSidebarDrawer = Drawer(
        width: width,
        child: SidebarWrapper(
          width: width,
          onToggleSidebar: () => Navigator.pop(context),
          onChatSelect: (chatId) {
            _selectChat(chatId);
            Navigator.of(context).pop();
          },
          onChatDelete: _deleteChat,
          onNewChat: () {
            _createNewChat();
            Navigator.of(context).pop();
          },
        ),
      );
    }
    return _cachedSidebarDrawer!;
  }

  Widget _buildChatMessages({bool wrapWithGesture = false}) {
    final chatState = ref.watch(chatScreenProvider);
    final chat = currentChat;
    final chatMessages = ChatMessages(
      key: _chatMessagesKey,
      chatStorageService: _chatStorageService,
      chat: chat,
      selectedModel: selectedModelId,
      sessionId: _currentSessionId,
      onSendMessage: _handleSendMessage,
      onMessageDeleted: _refreshChatMessages,
      onMessageEdited: _handleMessageEdited,
      onMessageEditAndSend: _handleMessageEditAndSend,
      onContinueResponse: _continueAIResponse,
      onRegenerateResponse: _regenerateResponse,
      scrollController: _messageScrollController,
      continuationSuggestions: chatState.continuationSuggestions,
      showSuggestions: chatState.showSuggestions,
      isSuggestionsLoading: chatState.isSuggestionsLoading,
      onSuggestionsClose: () =>
          ref.read(chatScreenProvider.notifier).hideSuggestions(),
      onSuggestionsRefresh: () {
        if (chat != null && chat.messages.isNotEmpty) {
          _showContinuationSuggestions(chat.messages.last);
        }
      },
      welcomeSuggestions: chatState.welcomeSuggestions,
      showWelcomeSuggestions: chatState.showWelcomeSuggestions,
      onWelcomeSuggestionsClose: () =>
          ref.read(chatScreenProvider.notifier).hideWelcomeSuggestions(),
      onHeadingsUpdated: _onHeadingsUpdated,
      onToggleNavigator: _toggleNavigator,
      onQuestionAnswer: _handleQuestionAnswer,
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
    );

    if (wrapWithGesture) {
      return GestureDetector(
        onDoubleTap: () {
          if (_hasHeadings()) _toggleNavigator();
        },
        child: chatMessages,
      );
    }
    return chatMessages;
  }

  Widget _buildMobileLayout(Widget chatInput) {
    final hasHeadings = _hasHeadings();
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSidebarDrawer(width: ChatScreenConstants.sidebarWidth),
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          if (details.globalPosition.dx < 50) {
            FocusScope.of(context).unfocus();
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        child: Column(
          children: [
            ChatAppBar(
              selectedModel: selectedModelId,
              selectedModelObject: selectedModelObject,
              hasHeadings: () => hasHeadings,
              onToggleNavigator: _toggleNavigator,
              onModelSelected: _updateSelectedModel,
              onMenuPressed: () {
                FocusScope.of(context).unfocus();
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            Expanded(
              child: _buildChatContentWrapper(
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildChatMessages(wrapWithGesture: true),
                          if (_speechUiState != SpeechUiState.idle)
                            SpeechOverlayWidget(
                              state: _speechUiState,
                              message: _speechStatusMessage,
                              soundLevel: _speechSoundLevel,
                              recognizedText: _speechRecognizedText,
                              bottomInset: 0,
                            ),
                        ],
                      ),
                    ),
                    chatInput,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Widget chatInput) {
    final hasHeadings = _hasHeadings();
    return Scaffold(
      key: _scaffoldKey,
      appBar: ChatAppBar(
        selectedModel: selectedModelId,
        selectedModelObject: selectedModelObject,
        hasHeadings: () => hasHeadings,
        onToggleNavigator: _toggleNavigator,
        onModelSelected: _updateSelectedModel,
        onMenuPressed: () {
          FocusScope.of(context).unfocus();
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      drawer: _buildSidebarDrawer(width: ChatScreenConstants.sidebarWidth),
      body: Column(
        children: [
          Expanded(
            child: _buildChatContentWrapper(
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildChatMessages(),
                        if (_speechUiState != SpeechUiState.idle)
                          SpeechOverlayWidget(
                            state: _speechUiState,
                            message: _speechStatusMessage,
                            soundLevel: _speechSoundLevel,
                            recognizedText: _speechRecognizedText,
                            bottomInset: 0,
                          ),
                      ],
                    ),
                  ),
                  chatInput,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContentWrapper({required Widget child}) {
    final screenWidth = _cachedScreenWidth;
    final isNavigatorVisible = ref.watch(
      chatScreenProvider.select((s) => s.isNavigatorVisible),
    );
    final wideScreenMode = ref.watch(
      themeProvider.select((s) => s.wideScreenMode),
    );

    Widget content = GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_hasHeadings() && !isNavigatorVisible) {
          if (details.primaryDelta! < -10 &&
              details.globalPosition.dx > screenWidth - 30) {
            _toggleNavigator();
          }
        }
      },
      child: child,
    );

    if (screenWidth >= ChatScreenConstants.mobileBreakpoint) {
      if (wideScreenMode) return content;
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          width: screenWidth * 0.65,
          child: content,
        ),
      );
    }
    return content;
  }
}
