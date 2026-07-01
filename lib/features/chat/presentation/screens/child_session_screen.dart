import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/data/providers/session_providers.dart';
import 'package:chatorai/features/chat/presentation/widgets/session_context_window.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChildSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const ChildSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ChildSessionScreen> createState() =>
      _ChildSessionScreenState();
}

class _ChildSessionScreenState extends ConsumerState<ChildSessionScreen> {
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

    final meta = await repo.getSessionMetaFromId(widget.sessionId);
    if (!mounted) return;
    if (meta != null) {
      _sessionTitle = meta.title.isEmpty ? 'Session' : meta.title;
    }
    await _loadChildSessions(repo);
  }

  Future<void> _loadChildSessions(SessionRepository repo) async {
    final currentSessionId = widget.sessionId;
    final currentMeta = await repo.getSessionMetaFromId(currentSessionId);
    String? parentId = currentMeta?.parentId?.value;
    List<String> siblingIds = [];

    if (parentId != null) {
      final siblings = await repo.getChildSessionsFromId(parentId);
      siblingIds = siblings.map((s) => s.id.value).toList();
    }

    if (!mounted) return;

    setState(() {
      _childIds = siblingIds;
      _parentId = parentId;
      _isLoadingSessions = false;
    });
  }

  Future<void> _navigateToSibling(int direction) async {
    // Resolve sibling ID BEFORE mutating stack state to avoid desync
    final siblingId = await ref.read(sessionStackProvider.notifier).getSiblingId(direction);
    if (siblingId == null || !mounted) return;
    if (siblingId.value == widget.sessionId) return;

    // Update stack then navigate
    ref.read(sessionStackProvider.notifier).replaceCurrent(siblingId);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChildSessionScreen(sessionId: siblingId.value),
      ),
    );
  }

  void _navigateToParent() {
    if (_parentId == null) return;
    ref.read(sessionStackProvider.notifier).popToParent();
    Navigator.pop(context);
  }

  void _onTaskTap(String? taskSessionId) {
    if (taskSessionId == null || taskSessionId.isEmpty) return;
    ref.read(sessionStackProvider.notifier).push(
      SessionID.fromString(taskSessionId),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChildSessionScreen(sessionId: taskSessionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final stackState = ref.watch(sessionStackProvider);
    final isTop = !stackState.hasParent;

    final currentIndex = _childIds.indexOf(widget.sessionId);
    final selectedIndex = currentIndex >= 0 ? currentIndex : 0;
    final canGoPrev = selectedIndex > 0 && _childIds.isNotEmpty;
    final canGoNext = selectedIndex < _childIds.length - 1;
    final canGoUp = _parentId != null && !isTop;

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

    Widget body;
    if (_isLoadingSessions) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = SessionContextWindow(
        sessionId: widget.sessionId,
        scrollController: _messageScrollController,
        onTaskTap: _onTaskTap,
      );
    }

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
