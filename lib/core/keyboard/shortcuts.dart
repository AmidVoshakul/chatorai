import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
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
}
