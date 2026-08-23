import 'dart:async';

import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/agents/agent_provider.dart';
import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
import 'package:chatorai/core/keyboard/keybinding_provider.dart';
import 'package:chatorai/core/keyboard/shortcut_handler.dart';
import 'package:chatorai/core/keyboard/shortcuts.dart';
import 'package:chatorai/core/constants/chat_constants.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/presentation/screens/child_session_screen.dart';
import 'package:chatorai/features/chat/presentation/widgets/workspace_dialog.dart';
import 'package:chatorai/features/chat/presentation/widgets/welcome_questions_data.dart';
import 'package:chatorai/features/models/screens/models_screen.dart';
import 'package:chatorai/features/settings/widgets/settings_modal.dart';
import 'package:chatorai/features/sessions/providers/session_providers.dart';
import 'package:chatorai/features/chat/presentation/providers/chat_stream_actions.dart';
import 'package:chatorai/providers.dart'
    show
        chatScreenProvider,
        currentSessionRunnerProvider,
        sessionPartsProvider,
        chatListProvider,
        currentChatIdProvider,
        permissionServiceProvider,
        scaffoldKeyProvider,
        chatScrollIntentProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalShortcutHandler extends ConsumerWidget {
  const GlobalShortcutHandler({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keybindings = ref.watch(keybindingProvider);
    final shortcuts =
        <KeyboardShortcut>[
          AppShortcuts.cancelStreaming(
            _stopStreaming(ref),
            isActive: (r) => r.read(chatScreenProvider).isStreaming,
          ),
          AppShortcuts.closeDialog(_closeTopWindow),
          AppShortcuts.scrollToChatStart(_scrollToTop(ref)),
          AppShortcuts.scrollToChatEnd(_scrollToBottom(ref)),
          AppShortcuts.openWorkspace(_openWorkspace(context, ref)),
          AppShortcuts.openLatestChildSession(_openLatestChildSession(ref)),
          AppShortcuts.cyclePrimaryAgent(_cyclePrimaryAgent(ref)),
          AppShortcuts.toggleSidebar(_toggleSidebar(ref)),
          AppShortcuts.newChat(_newChat(ref, context)),
          AppShortcuts.openModelSelector(_openModelSelector(ref)),
          AppShortcuts.openSettings(_openSettings(ref)),
        ].map((s) {
          final override = keybindings[s.id];
          if (override != null) {
            try {
              return s.copyWith(activator: KeyActivator.fromString(override));
            } on FormatException {
              // keep default if override is invalid
            }
          }
          return s;
        }).toList();

    return ShortcutHandler(shortcuts: shortcuts, autofocus: true, child: child);
  }

  VoidCallback _stopStreaming(WidgetRef ref) {
    return () {
      stopActiveStreaming(ref);
    };
  }

  VoidCallback _openLatestChildSession(WidgetRef ref) {
    return () {
      String? sessionId;

      sessionId = ref
          .read(currentSessionRunnerProvider.notifier)
          .activeChildSessionId;

      if (sessionId == null) {
        final streamingSessionId = ref
            .read(chatScreenProvider)
            .streamingSessionId;
        if (streamingSessionId != null) {
          final sessionAsyncState = ref.read(
            sessionPartsProvider(streamingSessionId),
          );
          final sessionState = sessionAsyncState.value;
          if (sessionState != null) {
            for (final part in sessionState.parts.reversed) {
              if (part is AssistantTask &&
                  part.taskSessionId != null &&
                  part.taskSessionId!.isNotEmpty) {
                sessionId = part.taskSessionId;
                break;
              }
            }
          }
        }
      }

      if (sessionId == null) {
        final chatListAsync = ref.read(chatListProvider);
        final currentChatId = ref.read(currentChatIdProvider);
        Chat? chat;
        try {
          chat = chatListAsync.whenOrNull(
            data: (chats) => chats.firstWhere((c) => c.id == currentChatId),
          );
        } catch (_) {}
        if (chat != null) {
          for (final msg in chat.messages.reversed) {
            if (msg.partsJson == null) continue;
            for (final partJson in msg.partsJson!.reversed) {
              if (partJson['type'] == 'task') {
                final sid = partJson['sessionId'] as String?;
                if (sid != null && sid.isNotEmpty) {
                  sessionId = sid;
                  break;
                }
              }
            }
            if (sessionId != null) break;
          }
        }
      }

      if (sessionId == null) return;

      ref
          .read(sessionStackProvider.notifier)
          .push(SessionID.fromString(sessionId));
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ChildSessionScreen(sessionId: sessionId!),
        ),
      );
    };
  }

  VoidCallback _cyclePrimaryAgent(WidgetRef ref) {
    return () {
      final primaryAgents = AgentRegistry().getPrimaryAgents();
      if (primaryAgents.length <= 1) return;
      final currentAgent = ref.read(currentAgentProvider);
      final currentIndex = primaryAgents.indexWhere(
        (a) => a.id == currentAgent.id,
      );
      final nextIndex = (currentIndex + 1) % primaryAgents.length;
      ref
          .read(currentAgentProvider.notifier)
          .setAgent(primaryAgents[nextIndex]);
    };
  }

  VoidCallback _toggleSidebar(WidgetRef ref) {
    return () {
      final scaffold = ref.read(scaffoldKeyProvider).currentState;
      if (scaffold == null) return;
      if (scaffold.isDrawerOpen) {
        navigatorKey.currentState?.pop();
      } else {
        // Unfocus any focused input before opening drawer
        FocusManager.instance.primaryFocus?.unfocus();
        scaffold.openDrawer();
      }
    };
  }

  VoidCallback _newChat(WidgetRef ref, BuildContext buildContext) {
    final questions = WelcomeQuestionsData.getRandomQuestions(
      buildContext,
      count: 4,
    );
    return () {
      // Fire-and-forget: the shortcut handler does not await callbacks.
      unawaited(
        ref.read(chatListProvider.notifier).createNewChat().then((newChat) {
          if (!ref.exists(currentChatIdProvider)) return;
          ref.read(currentChatIdProvider.notifier).setChatId(newChat.id);
          ref.read(permissionServiceProvider).clearSession();
          // Restore welcome suggestions after creating a new chat.
          ref
              .read(chatScreenProvider.notifier)
              .showWelcomeSuggestions(questions);
        }),
      );
    };
  }

  VoidCallback _openModelSelector(WidgetRef ref) {
    return () {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const ModelsScreen()),
      );
    };
  }

  VoidCallback _openSettings(WidgetRef ref) {
    return () {
      final overlayContext = navigatorKey.currentState?.overlay?.context;
      if (overlayContext == null) return;
      final width = MediaQuery.of(overlayContext).size.width;
      if (width >= ChatScreenConstants.mobileBreakpoint) {
        showSettingsModal(overlayContext);
      } else {
        navigatorKey.currentState?.pushNamed('/settings');
      }
    };
  }

  VoidCallback _closeTopWindow() {
    return () {
      final nav = navigatorKey.currentState;
      if (nav != null && nav.canPop()) {
        nav.pop();
      }
    };
  }

  VoidCallback _scrollToTop(WidgetRef ref) {
    return () => ref.read(chatScrollIntentProvider.notifier).scrollToStart();
  }

  VoidCallback _scrollToBottom(WidgetRef ref) {
    return () => ref.read(chatScrollIntentProvider.notifier).scrollToEnd();
  }

  VoidCallback _openWorkspace(BuildContext context, WidgetRef ref) {
    return () {
      final overlayContext = navigatorKey.currentState?.overlay?.context;
      if (overlayContext == null) return;
      showWorkspaceDialog(overlayContext, ref);
    };
  }
}
