import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KeyActivator {
  final LogicalKeyboardKey key;
  final bool ctrl;
  final bool doublePress;
  final int doublePressWindowMs;

  const KeyActivator._({
    required this.key,
    this.ctrl = false,
    this.doublePress = false,
    this.doublePressWindowMs = 500,
  });

  const KeyActivator.escapeDoublePress()
    : this._(key: LogicalKeyboardKey.escape, doublePress: true);

  const KeyActivator.ctrlDown()
    : this._(key: LogicalKeyboardKey.arrowDown, ctrl: true);

  const KeyActivator.arrowLeft() : this._(key: LogicalKeyboardKey.arrowLeft);

  const KeyActivator.arrowRight() : this._(key: LogicalKeyboardKey.arrowRight);

  const KeyActivator.arrowUp() : this._(key: LogicalKeyboardKey.arrowUp);

  const KeyActivator.home() : this._(key: LogicalKeyboardKey.home);

  const KeyActivator.end() : this._(key: LogicalKeyboardKey.end);

  const KeyActivator.ctrlTab()
    : this._(key: LogicalKeyboardKey.tab, ctrl: true);

  /// Generic `Ctrl+<key>` combo, e.g. `KeyActivator.ctrlKey(LogicalKeyboardKey.keyB)`.
  const KeyActivator.ctrlKey(LogicalKeyboardKey key)
    : this._(key: key, ctrl: true);

  bool matches(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != key) return false;
    if (ctrl != HardwareKeyboard.instance.isControlPressed) return false;
    return true;
  }
}

class KeyboardShortcut {
  final String id;
  final String description;
  final KeyActivator activator;
  final bool Function(WidgetRef)? isActive;
  final void Function(BuildContext context, WidgetRef ref) onExecute;

  const KeyboardShortcut({
    required this.id,
    required this.description,
    required this.activator,
    this.isActive,
    required this.onExecute,
  });
}
