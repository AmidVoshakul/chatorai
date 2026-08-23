import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KeyActivator {
  final LogicalKeyboardKey key;
  final bool ctrl;
  final bool shift;
  final bool alt;
  final bool meta;
  final bool doublePress;
  final int doublePressWindowMs;

  const KeyActivator._({
    required this.key,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
    this.doublePress = false,
    this.doublePressWindowMs = 500,
  });

  const KeyActivator.escapeDoublePress()
    : this._(key: LogicalKeyboardKey.escape, doublePress: true);

  const KeyActivator.escape() : this._(key: LogicalKeyboardKey.escape);

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

  factory KeyActivator.fromString(String s) {
    final trimmed = s.trim();
    final lower = trimmed.toLowerCase();

    // Double-press detection: "Esc Esc" or "Escape Escape"
    if (lower == 'esc esc' || lower == 'escape escape') {
      return const KeyActivator.escapeDoublePress();
    }

    final parts = trimmed.split('+').map((p) => p.trim()).toList();
    if (parts.isEmpty) {
      throw FormatException('Empty shortcut string');
    }

    bool ctrl = false;
    bool shift = false;
    bool alt = false;
    bool meta = false;
    LogicalKeyboardKey? key;

    for (final part in parts) {
      final lowerPart = part.toLowerCase();
      if (lowerPart == 'ctrl' || lowerPart == 'control') {
        ctrl = true;
      } else if (lowerPart == 'shift') {
        shift = true;
      } else if (lowerPart == 'alt' || lowerPart == 'option') {
        alt = true;
      } else if (lowerPart == 'meta' ||
          lowerPart == 'cmd' ||
          lowerPart == 'command' ||
          lowerPart == 'win') {
        meta = true;
      } else if (key != null) {
        throw FormatException('Multiple keys specified in "$s"');
      } else {
        key = _parseKey(part);
      }
    }

    if (key == null) {
      throw FormatException('No key specified in "$s"');
    }

    return KeyActivator._(
      key: key,
      ctrl: ctrl,
      shift: shift,
      alt: alt,
      meta: meta,
    );
  }

  static LogicalKeyboardKey _parseKey(String part) {
    final lower = part.toLowerCase();
    switch (lower) {
      case 'esc':
      case 'escape':
        return LogicalKeyboardKey.escape;
      case 'tab':
        return LogicalKeyboardKey.tab;
      case 'home':
        return LogicalKeyboardKey.home;
      case 'end':
        return LogicalKeyboardKey.end;
      case '←':
      case 'arrowleft':
      case 'left':
        return LogicalKeyboardKey.arrowLeft;
      case '→':
      case 'arrowright':
      case 'right':
        return LogicalKeyboardKey.arrowRight;
      case '↑':
      case 'arrowup':
      case 'up':
        return LogicalKeyboardKey.arrowUp;
      case '↓':
      case 'arrowdown':
      case 'down':
        return LogicalKeyboardKey.arrowDown;
      default:
        // Single character key
        if (lower.length == 1) {
          return LogicalKeyboardKey(lower.codeUnitAt(0));
        }
        throw FormatException('Unknown key: "$part"');
    }
  }

  String format() {
    if (doublePress) {
      return 'Esc Esc';
    }

    final modifiers = <String>[];
    if (ctrl) modifiers.add('Ctrl');
    if (shift) modifiers.add('Shift');
    if (alt) modifiers.add('Alt');
    if (meta) modifiers.add('Meta');

    String keyName;
    switch (key) {
      case LogicalKeyboardKey.escape:
        keyName = 'Esc';
        break;
      case LogicalKeyboardKey.tab:
        keyName = 'Tab';
        break;
      case LogicalKeyboardKey.home:
        keyName = 'Home';
        break;
      case LogicalKeyboardKey.end:
        keyName = 'End';
        break;
      case LogicalKeyboardKey.arrowLeft:
        keyName = '←';
        break;
      case LogicalKeyboardKey.arrowRight:
        keyName = '→';
        break;
      case LogicalKeyboardKey.arrowUp:
        keyName = '↑';
        break;
      case LogicalKeyboardKey.arrowDown:
        keyName = '↓';
        break;
      default:
        keyName = key.keyLabel.isNotEmpty ? key.keyLabel : key.toString();
        if (keyName.length == 1) {
          keyName = keyName.toUpperCase();
        }
    }

    if (modifiers.isEmpty) {
      return keyName;
    }
    return '${modifiers.join('+')}+$keyName';
  }

  bool matches(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != key) return false;
    if (ctrl != HardwareKeyboard.instance.isControlPressed) return false;
    if (shift != HardwareKeyboard.instance.isShiftPressed) return false;
    if (alt != HardwareKeyboard.instance.isAltPressed) return false;
    if (meta != HardwareKeyboard.instance.isMetaPressed) return false;
    return true;
  }

  @override
  String toString() => format();
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

  KeyboardShortcut copyWith({
    KeyActivator? activator,
    String? description,
    bool Function(WidgetRef)? isActive,
    void Function(BuildContext context, WidgetRef ref)? onExecute,
  }) {
    return KeyboardShortcut(
      id: id,
      description: description ?? this.description,
      activator: activator ?? this.activator,
      isActive: isActive ?? this.isActive,
      onExecute: onExecute ?? this.onExecute,
    );
  }
}
