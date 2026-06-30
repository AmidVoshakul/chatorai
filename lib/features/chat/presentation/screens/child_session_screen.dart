import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/session/session_state.dart'
    show SessionState, ToolResult;
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart'
    show Chat, Message, MessageRole;
import 'package:chatorai/features/chat/presentation/widgets/chat_messages.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/message_data.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChildSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const ChildSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ChildSessionScreen> createState() => _ChildSessionScreenState();
}

class _ChildSessionScreenState extends ConsumerState<ChildSessionScreen> {
  SessionRepository? _sessionRepository;

  final ScrollController _messageScrollController = ScrollController();

  List<String> _childIds = [];
  String? _parentId;
  String _sessionTitle = 'Session';
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _messageScrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final repo = await ref.read(sessionRepositoryProvider.future);
    _sessionRepository = repo;

    final currentSessionId = widget.sessionId;
    final meta = await repo.getSessionMetaFromId(currentSessionId);
    if (!mounted) return;
    if (meta != null) {
      _sessionTitle = meta.title.isEmpty ? 'Session' : meta.title;
    }
    await _loadChildSessions(repo, currentSessionId);
  }

  Future<void> _loadChildSessions(
    SessionRepository repo,
    String currentSessionId,
  ) async {
    final children = await repo.getChildSessionsFromId(currentSessionId);
    if (!mounted) return;

    final childIds = children.map((s) => s.id.value).toList();
    final parentState = await _getParent(repo, currentSessionId);

    if (!mounted) return;

    setState(() {
      _childIds = childIds.toList();
      _parentId = parentState?.id.value;
      _isLoadingSessions = false;
    });
  }

  Future<dynamic> _getParent(
    SessionRepository repo,
    String sessionId,
  ) async {
    try {
      final state = await repo.getSessionMetaFromId(sessionId);
      if (state?.parentId == null) return null;
      return repo.getSessionMetaFromId(state!.parentId!.value);
    } catch (_) {
      return null;
    }
  }

  void _navigateToSibling(int direction) {
    if (_childIds.isEmpty) return;

    final currentIndex = _childIds.indexOf(widget.sessionId);
    final selectedIndex =
        currentIndex >= 0 ? currentIndex : _childIds.length - 1;

    final newIndex = selectedIndex + direction;
    if (newIndex < 0 || newIndex >= _childIds.length) return;

    final targetId = _childIds[newIndex];
    if (!mounted) return;

    setState(() {
      _sessionTitle = 'Session';
    });

    _loadSiblingSession(targetId);
  }

  Future<void> _loadSiblingSession(String targetId) async {
    final repo = _sessionRepository;
    if (repo == null) return;
    final meta = await repo.getSessionMetaFromId(targetId);
    if (meta != null && mounted) {
      setState(() {
        _sessionTitle = meta.title.isEmpty ? 'Session' : meta.title;
      });
    }
  }

  Future<void> _navigateToParent() async {
    if (_parentId == null) return;
    if (!mounted) return;
    Navigator.pop(context);
  }

  List<Message> _buildMessages(
    SessionState state,
    List<ToolResult> toolResults,
  ) {
    final result = <Message>[];

    for (final m in state.messages) {
      final roleName = m.role.toString().split('.').last;
      final content = m.content;
      final id = m.id;
      final reasoning = m.reasoning;
      final createdAt = m.createdAt;

      if (roleName == 'user') {
        result.add(
          Message(
            id: id,
            role: MessageRole.user,
            content: content,
            timestamp: createdAt,
          ),
        );
      } else if (roleName == 'assistant') {
        final partsJson = <Map<String, dynamic>>[];

        if (reasoning != null && reasoning.isNotEmpty) {
          partsJson.add({'type': 'reasoning', 'content': reasoning});
        }

        for (final tr in toolResults) {
          partsJson.add({
            'type': 'tool_result',
            'toolCallId': tr.id,
            'toolName': tr.toolName,
            'result': tr.status == 'error' ? null : tr.outputText,
            'error': tr.status == 'error' ? tr.outputText : null,
            'state': _toolStatusToState(tr.status),
            'duration': tr.durationMs > 0 ? tr.durationMs : null,
            'input': tr.input,
          });
        }

        // Add text part if content exists or if message is in error state
        // (error text is stored in parts, not in content field)
        if (content.isNotEmpty || m.error != null) {
          partsJson.add({'type': 'text', 'content': content});
        } else {
          // Streaming placeholder - show typing indicator
          partsJson.add({'type': 'text', 'content': ''});
        }

        // При streaming TextEnded ещё не пришёл, поэтому content может быть пустым.
        // Показываем сообщение как complete если content не пустой.
        // Если content пустой - это streaming placeholder, но UI всё равно должен его показывать.
        final isComplete = content.isNotEmpty;

        result.add(
          Message(
            id: id,
            role: MessageRole.assistant,
            content: content,
            timestamp: createdAt,
            model: m.model,
            reasoning: reasoning,
            partsJson: partsJson.isNotEmpty ? partsJson : null,
            isComplete: isComplete,
          ),
        );
      }
    }

    return result;
  }

  String _toolStatusToState(String status) {
    switch (status) {
      case 'running':
        return 'running';
      case 'error':
        return 'error';
      default:
        return 'completed';
    }
  }

  Future<void> _onSendMessage(MessageData messageData) async {}

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final stateAsync = ref.watch(
      childSessionStateProvider(widget.sessionId),
    );
    final toolResultsAsync = ref.watch(
      childSessionToolResultsProvider(widget.sessionId),
    );

    final currentIndex = _childIds.indexOf(widget.sessionId);
    final selectedIndex = currentIndex >= 0 ? currentIndex : 0;

    final canGoPrev = selectedIndex > 0 && _childIds.isNotEmpty;
    final canGoNext = selectedIndex < _childIds.length - 1;
    final canGoUp = _parentId != null;

    Widget body;
    if (_isLoadingSessions) {
      body = const Center(child: CircularProgressIndicator());
    } else if (stateAsync.isLoading || toolResultsAsync.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (stateAsync.hasError || toolResultsAsync.hasError) {
      body = Center(
        child: Text(
          localizations.noChatsYet,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    } else {
      final state = stateAsync.value ??
          SessionState(
            id: SessionID.fromString(widget.sessionId),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
      final toolResults = toolResultsAsync.value ?? <ToolResult>[];

      final legacyMessages = _buildMessages(state, toolResults);
      if (legacyMessages.isEmpty) {
        final theme = Theme.of(context);
        body = Center(
          child: Text(
            localizations.noChatsYet,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        );
      } else {
        final activeSessionId = _childIds.isEmpty ||
                selectedIndex < 0 ||
                selectedIndex >= _childIds.length
            ? widget.sessionId
            : _childIds[selectedIndex];

        final chat = Chat(
          id: activeSessionId,
          title: _sessionTitle,
          messages: legacyMessages,
          createdAt: legacyMessages.first.timestamp,
          updatedAt: legacyMessages.last.timestamp,
        );

        body = Column(
          children: [
            Expanded(
              child: ChatMessages(
                key: ValueKey(activeSessionId),
                chatStorageService: ref.read(chatStorageServiceProvider),
                chat: chat,
                selectedModel: ref.watch(modelProvider).selectedModelId,
                onSendMessage: _onSendMessage,
                onMessageDeleted: () {},
                onMessageEdited: (_, _) {},
                onMessageEditAndSend: (_, _) {},
                onContinueResponse: (_) {},
                onRegenerateResponse: (_) {},
                scrollController: _messageScrollController,
              ),
            ),
          ],
        );
      }
    }

    final actions = <Widget>[
      if (canGoUp)
        IconButton(
          icon: const Icon(Icons.arrow_upward),
          onPressed: _navigateToParent,
          tooltip: 'Go to parent session',
        ),
      if (canGoPrev)
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => _navigateToSibling(-1),
          tooltip: 'Previous sibling',
        ),
      if (canGoNext)
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => _navigateToSibling(1),
          tooltip: 'Next sibling',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: localizations.close,
        ),
        title: Text(_sessionTitle),
        actions: actions,
      ),
      body: body,
    );
  }
}
