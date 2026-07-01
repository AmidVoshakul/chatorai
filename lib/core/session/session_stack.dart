import 'package:chatorai/core/session/session_db_provider.dart'
    show sessionRepositoryProvider;
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionStackState {
  final List<SessionID> stack;
  final String? rootChatId;

  const SessionStackState({
    this.stack = const [],
    this.rootChatId,
  });

  SessionID? get current => stack.isNotEmpty ? stack.last : null;
  SessionID? get parent => stack.length >= 2 ? stack[stack.length - 2] : null;
  bool get hasParent => parent != null;
  bool get isEmpty => stack.isEmpty;
  bool get isRoot => stack.length == 1;
  int get depth => stack.length;

  SessionStackState copyWith({List<SessionID>? stack, String? rootChatId}) {
    return SessionStackState(
      stack: stack ?? this.stack,
      rootChatId: rootChatId ?? this.rootChatId,
    );
  }
}

class SessionStackNotifier extends Notifier<SessionStackState> {
  @override
  SessionStackState build() => SessionStackState();

  void init(String? currentChatId) {
    state = SessionStackState(rootChatId: currentChatId);
  }

  void push(SessionID sessionId) {
    final newStack = [...state.stack, sessionId];
    state = state.copyWith(stack: newStack);
  }

  bool pop() {
    if (state.stack.isEmpty) return false;
    final newStack = state.stack.sublist(0, state.stack.length - 1);
    state = state.copyWith(stack: newStack);
    return true;
  }

  bool popToParent() {
    if (state.stack.length < 2) return false;
    final newStack = state.stack.sublist(0, state.stack.length - 1);
    state = state.copyWith(stack: newStack);
    return true;
  }

  void navigateToParent() {
    popToParent();
  }

  void replaceCurrent(SessionID sessionId) {
    if (state.stack.isEmpty) return;
    final newStack = [...state.stack];
    newStack[newStack.length - 1] = sessionId;
    state = state.copyWith(stack: newStack);
  }

  Future<SessionID?> getSiblingId(int direction) async {
    if (state.stack.length < 2) return null;

    final currentId = state.current;
    if (currentId == null) return null;

    final parentId = state.parent;
    if (parentId == null) return null;

    try {
      final repo = await ref.read(sessionRepositoryProvider.future);
      final children = await repo.getChildSessionsFromId(parentId.value);
      final childIds = children.map((s) => s.id).toList();
      final currentIndex = childIds.indexOf(currentId);
      if (currentIndex < 0) return null;

      final targetIndex = currentIndex + direction;
      if (targetIndex < 0 || targetIndex >= childIds.length) return null;

      return childIds[targetIndex];
    } catch (e, stack) {
      LogTags.session.logError('getSiblingId failed for direction=$direction', e, stack);
      return null;
    }
  }

  Future<void> navigateToSibling(int direction) async {
    final siblingId = await getSiblingId(direction);
    if (siblingId == null) {
      LogTags.session.logInfo(
        'navigateToSibling: direction=$direction returned null sibling',
      );
      return;
    }

    final newStack = state.stack.sublist(0, state.stack.length - 1)
      ..add(siblingId);
    state = state.copyWith(stack: newStack);
  }

  Future<bool> canGoSiblingAsync(int direction) async {
    final id = await getSiblingId(direction);
    return id != null;
  }
}
