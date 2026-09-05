import 'package:chatorai/core/keyboard/shortcut_handler.dart';
import 'package:chatorai/core/keyboard/shortcuts.dart';
import 'package:chatorai/gui/features/settings/widgets/settings_window.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

// ===========================================================================
// SETTINGS MODAL (desktop two-column window)
// ===========================================================================

Future<void> showSettingsModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: ChatoraiColors.black30,
    builder: (_) => const _SettingsModalWindow(),
  );
}

class _SettingsModalWindow extends StatelessWidget {
  const _SettingsModalWindow();

  @override
  Widget build(BuildContext context) {
    final palette = ChatoraiSettingsWindow.of(context);
    final screen = MediaQuery.sizeOf(context);
    final maxW = (ChatoraiSettingsWindow.maxWindowWidth).clamp(
      0.0,
      screen.width * 0.94,
    );
    final maxH = (ChatoraiSettingsWindow.maxWindowHeight).clamp(
      ChatoraiSettingsWindow.minWindowHeight,
      screen.height * 0.88,
    );

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxW,
            maxHeight: maxH,
            minHeight: ChatoraiSettingsWindow.minWindowHeight,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xl),
              border: Border.all(color: palette.border, width: 1),
              boxShadow: ChatoraiShadows.windowShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xl),
              child: Material(
                color: palette.surface,
                child: ShortcutHandler(
                  autofocus: true,
                  shortcuts: [
                    AppShortcuts.closeDialog(() => Navigator.pop(context)),
                  ],
                  child: const SettingsWindow(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
