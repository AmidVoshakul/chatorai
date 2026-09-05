import 'package:chatorai/core/keyboard/shortcut_handler.dart';
import 'package:chatorai/core/keyboard/shortcuts.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_scroll_follow_controller.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/session_context_window.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChildSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const ChildSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ChildSessionScreen> createState() => _ChildSessionScreenState();
}

class _ChildSessionScreenState extends ConsumerState<ChildSessionScreen> {
  static const String _fallbackTitle = 'Session';

  late String _currentId;
  List<String> _siblingIds = [];
  String? _parentId;
  final Map<String, String> _titleCache = {};
  int _titleRequestId = 0;
  PageController? _pageController;
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _currentId = widget.sessionId;
    _init();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final repo = await ref.read(sessionRepositoryProvider.future);
    final meta = await repo.getSessionMetaFromId(widget.sessionId);
    if (!mounted) return;

    final parentId = meta?.parentId?.value;
    var siblingIds = <String>[];
    if (parentId != null) {
      final siblings = await repo.getChildSessionsFromId(parentId);
      siblingIds = siblings.map((s) => s.id.value).toList();
    }
    if (!mounted) return;

    final startIndex = siblingIds.indexOf(widget.sessionId);
    final controller = PageController(
      initialPage: startIndex >= 0 ? startIndex : 0,
      keepPage: true,
    );
    setState(() {
      _parentId = parentId;
      _siblingIds = siblingIds;
      _titleCache[widget.sessionId] = (meta?.title.isEmpty ?? true)
          ? _fallbackTitle
          : meta!.title;
      _pageController = controller;
      _isLoadingSessions = false;
    });
  }

  // DB truth is the source for all navigation state; the Riverpod session
  // stack is only synced best-effort and never gates the UI.
  int get _currentIndex {
    final index = _siblingIds.indexOf(_currentId);
    return index >= 0 ? index : 0;
  }

  bool get _canGoPrev => _currentIndex > 0;

  bool get _canGoNext => _currentIndex < _siblingIds.length - 1;

  bool get _canGoUp => _parentId != null;

  void _goTo(int index) {
    final controller = _pageController;
    if (controller == null) return;
    if (index < 0 || index >= _siblingIds.length) return;
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void _onPageChanged(int index) {
    if (index < 0 || index >= _siblingIds.length) return;
    final oldId = _currentId;
    final newId = _siblingIds[index];
    if (newId == oldId) return;

    setState(() => _currentId = newId);
    _ensureTitle(newId);
    _syncStack(oldId, newId);
  }

  Future<void> _ensureTitle(String sessionId) async {
    final requestId = ++_titleRequestId;
    if (_titleCache.containsKey(sessionId)) return;
    final repo = await ref.read(sessionRepositoryProvider.future);
    final meta = await repo.getSessionMetaFromId(sessionId);
    if (!mounted) return;
    if (requestId != _titleRequestId) return;
    setState(() {
      _titleCache[sessionId] = (meta?.title.isEmpty ?? true)
          ? _fallbackTitle
          : meta!.title;
    });
  }

  void _syncStack(String oldId, String newId) {
    // Only rewrite the stack while it still points at the outgoing session;
    // otherwise it belongs to another navigation flow and must stay untouched.
    final stack = ref.read(sessionStackProvider);
    if (stack.current?.value != oldId) return;
    ref
        .read(sessionStackProvider.notifier)
        .replaceCurrent(SessionID.fromString(newId));
  }

  void _navigateToParent() {
    if (!_canGoUp) return;
    final stack = ref.read(sessionStackProvider);
    if (stack.current?.value == _currentId) {
      ref.read(sessionStackProvider.notifier).popToParent();
    }
    Navigator.pop(context);
  }

  void _onTaskTap(String? taskSessionId) {
    if (taskSessionId == null || taskSessionId.isEmpty) return;
    ref
        .read(sessionStackProvider.notifier)
        .push(SessionID.fromString(taskSessionId));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChildSessionScreen(sessionId: taskSessionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final pages = _siblingIds.isEmpty ? [_currentId] : _siblingIds;
    final navigationText = _siblingIds.length > 1
        ? '${_currentIndex + 1} of ${_siblingIds.length}'
        : '';

    Widget body;
    final controller = _pageController;
    if (_isLoadingSessions || controller == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          // Mouse drags must stay reserved for desktop text selection;
          // touch, stylus and trackpad input still flips pages.
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.invertedStylus,
            PointerDeviceKind.trackpad,
          },
        ),
        child: PageView.builder(
          itemCount: pages.length,
          controller: controller,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) => _ChildSessionPage(
            key: ValueKey(pages[index]),
            sessionId: pages[index],
            onTaskTap: _onTaskTap,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: _canGoUp
            ? IconButton(
                icon: const Icon(Icons.arrow_upward),
                onPressed: _navigateToParent,
                tooltip: localizations.goToParentSessionTooltip,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                tooltip: localizations.close,
              ),
        title: Text(_titleCache[_currentId] ?? _fallbackTitle),
        actions: <Widget>[
          if (_siblingIds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                navigationText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: _canGoPrev ? () => _goTo(_currentIndex - 1) : null,
              tooltip: localizations.previousSiblingTooltip,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: _canGoNext ? () => _goTo(_currentIndex + 1) : null,
              tooltip: localizations.nextSiblingTooltip,
            ),
          ],
        ],
      ),
      body: ShortcutHandler(
        shortcuts: [
          if (_canGoUp) AppShortcuts.goToParentSession(_navigateToParent),
          if (_canGoPrev)
            AppShortcuts.navigateToPreviousSibling(
              () => _goTo(_currentIndex - 1),
            ),
          if (_canGoNext)
            AppShortcuts.navigateToNextSibling(() => _goTo(_currentIndex + 1)),
        ],
        child: body,
      ),
    );
  }
}

class _ChildSessionPage extends ConsumerStatefulWidget {
  final String sessionId;
  final void Function(String? taskSessionId) onTaskTap;

  const _ChildSessionPage({
    super.key,
    required this.sessionId,
    required this.onTaskTap,
  });

  @override
  ConsumerState<_ChildSessionPage> createState() => _ChildSessionPageState();
}

class _ChildSessionPageState extends ConsumerState<_ChildSessionPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final ChatScrollFollowController _followController =
      ChatScrollFollowController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _followController.attach(_scrollController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _followController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    listenChatScrollIntent(ref, _scrollController);
    return SessionContextWindow(
      sessionId: widget.sessionId,
      scrollController: _scrollController,
      followController: _followController,
      onTaskTap: widget.onTaskTap,
    );
  }
}
