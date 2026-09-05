import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/core/constants/chat_messages_constants.dart';

/// Direction a global Home/End shortcut should scroll the chat list.
enum ChatScrollTarget { start, end }

/// Immutable scroll request fired by global shortcuts.
///
/// `generation` increments on every press so listeners can distinguish a new
/// request from the previous one, even when the target is identical.
class ChatScrollIntent {
  const ChatScrollIntent({required this.generation, required this.target});

  final int generation;
  final ChatScrollTarget target;
}

/// Broadcasts Home/End scroll requests from [GlobalShortcutHandler].
///
/// Screens own their own [ScrollController] and subscribe via
/// [listenChatScrollIntent] in `build()`, so this provider is only ever
/// mutated from shortcut handlers — never from a widget lifecycle — which
/// keeps it safe to read and write during navigation and workspace switches.
final chatScrollIntentProvider =
    NotifierProvider<ChatScrollIntentNotifier, ChatScrollIntent>(
      ChatScrollIntentNotifier.new,
    );

class ChatScrollIntentNotifier extends Notifier<ChatScrollIntent> {
  @override
  ChatScrollIntent build() =>
      const ChatScrollIntent(generation: 0, target: ChatScrollTarget.end);

  void scrollToStart() {
    state = ChatScrollIntent(
      generation: state.generation + 1,
      target: ChatScrollTarget.start,
    );
  }

  void scrollToEnd() {
    state = ChatScrollIntent(
      generation: state.generation + 1,
      target: ChatScrollTarget.end,
    );
  }
}

/// Subscribes [controller] to scroll intents for the lifetime of the calling
/// element.
///
/// Must be called from `build()` on every build (same rule as `ref.listen`).
/// The controller is only touched when it has clients, so a screen whose
/// scroll view is not mounted yet simply ignores the request.
void listenChatScrollIntent(WidgetRef ref, ScrollController controller) {
  ref.listen<ChatScrollIntent>(chatScrollIntentProvider, (previous, next) {
    if (previous?.generation == next.generation) return;
    if (!controller.hasClients) return;
    // The chat list is top-down: offset 0 is the oldest content, growing
    // offsets move towards the newest content (maxScrollExtent).
    if (next.target == ChatScrollTarget.start) {
      controller.jumpTo(0);
    } else {
      controller.jumpTo(controller.position.maxScrollExtent);
    }
  });
}

// ---------------------------------------------------------------------------
// Scroll helper — single source of truth for "where is the bottom".
//
// The chat list is top-down (`SingleChildScrollView` without reverse):
// offset 0 shows the oldest content and growing offsets move towards the
// newest content (maxScrollExtent).
// ---------------------------------------------------------------------------

/// Whether [controller] sits within [threshold] pixels of the newest content
/// (maxScrollExtent). Safe to call anytime: returns `false` when unattached.
///
/// Defaults to [ChatMessagesConstants.userScrolledAwayBand], the tight band
/// used to detect that the user has manually scrolled away from the bottom.
bool chatIsNearBottom(ScrollController controller, {double? threshold}) {
  if (!controller.hasClients) return false;
  final band = threshold ?? ChatMessagesConstants.userScrolledAwayBand;
  return controller.offset >= controller.position.maxScrollExtent - band;
}
