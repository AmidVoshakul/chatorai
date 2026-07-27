import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShortcutHandler extends ConsumerStatefulWidget {
  final List<KeyboardShortcut> shortcuts;
  final Widget child;

  const ShortcutHandler({
    super.key,
    required this.shortcuts,
    required this.child,
  });

  @override
  ConsumerState<ShortcutHandler> createState() => _ShortcutHandlerState();
}

class _ShortcutHandlerState extends ConsumerState<ShortcutHandler> {
  DateTime? _doublePressTimestamp;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    for (final shortcut in widget.shortcuts) {
      if (!shortcut.activator.matches(event)) continue;
      if (shortcut.isActive != null && !shortcut.isActive!(ref)) continue;

      if (shortcut.activator.doublePress) {
        final now = DateTime.now();
        final doublePressed =
            _doublePressTimestamp != null &&
            now.difference(_doublePressTimestamp!).inMilliseconds <
                shortcut.activator.doublePressWindowMs;
        if (doublePressed) {
          _doublePressTimestamp = null;
          shortcut.onExecute(context, ref);
        } else {
          _doublePressTimestamp = now;
        }
        return KeyEventResult.handled;
      }

      shortcut.onExecute(context, ref);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: widget.child,
    );
  }
}
