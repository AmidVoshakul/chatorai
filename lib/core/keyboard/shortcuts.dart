import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central shortcut definitions.
///
/// Change the [activator] to rebind any shortcut.
/// [isActive] is set at the call site to keep core dependency-free.
class AppShortcuts {
  AppShortcuts._();

  static KeyboardShortcut cancelStreaming(
    void Function() onExecute, {
    bool Function(WidgetRef)? isActive,
  }) {
    return KeyboardShortcut(
      id: 'cancel_streaming',
      description: 'Cancel AI response (double ESC)',
      activator: const KeyActivator.escapeDoublePress(),
      isActive: isActive,
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut closeDialog(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'close_dialog',
      description: 'Close dialog (Escape)',
      activator: const KeyActivator.escape(),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut openLatestChildSession(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'open_latest_child',
      description: 'Open the latest child session (Ctrl+↓)',
      activator: const KeyActivator.ctrlDown(),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut navigateToPreviousSibling(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'nav_prev_sibling',
      description: 'Previous sibling session (←)',
      activator: const KeyActivator.arrowLeft(),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut navigateToNextSibling(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'nav_next_sibling',
      description: 'Next sibling session (→)',
      activator: const KeyActivator.arrowRight(),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut goToParentSession(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'nav_parent',
      description: 'Go to parent session (↑)',
      activator: const KeyActivator.arrowUp(),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut cyclePrimaryAgent(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'cycle_primary_agent',
      description: 'Cycle primary agent (Ctrl+Tab)',
      activator: const KeyActivator.ctrlTab(),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut toggleSidebar(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'toggle_sidebar',
      description: 'Toggle sidebar (Ctrl+B)',
      activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyB),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut newChat(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'new_chat',
      description: 'New chat (Ctrl+N)',
      activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyN),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut openModelSelector(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'open_model_selector',
      description: 'Open model selector (Ctrl+M)',
      activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyM),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut openSettings(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'open_settings',
      description: 'Open settings (Ctrl+P)',
      activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyP),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut scrollToChatStart(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'scroll_to_chat_start',
      description: 'Scroll chat to the top (Home)',
      activator: const KeyActivator.home(),
      onExecute: (_, _) => onExecute(),
    );
  }

  static KeyboardShortcut scrollToChatEnd(void Function() onExecute) {
    return KeyboardShortcut(
      id: 'scroll_to_chat_end',
      description: 'Scroll chat to the bottom (End)',
      activator: const KeyActivator.end(),
      onExecute: (_, _) => onExecute(),
    );
  }
}
