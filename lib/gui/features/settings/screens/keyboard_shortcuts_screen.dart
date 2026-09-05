import 'package:chatorai/core/keyboard/keybinding_provider.dart';
import 'package:chatorai/core/keyboard/keyboard_shortcut.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// KEYBOARD SHORTCUTS SCREEN
// ===========================================================================

class KeyboardShortcutsScreen extends ConsumerWidget {
  const KeyboardShortcutsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keybindings = ref.watch(keybindingProvider);
    final conflicts = ref.watch(keybindingProvider.notifier).conflicts();
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (embedded) {
      return _KeyboardShortcutsContent(
        localizations: localizations,
        isDark: isDark,
        keybindings: keybindings,
        conflicts: conflicts,
        isMobile: isMobile,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.keyboardShortcuts),
        centerTitle: true,
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _KeyboardShortcutsContent(
        localizations: localizations,
        isDark: isDark,
        keybindings: keybindings,
        conflicts: conflicts,
        isMobile: isMobile,
      ),
    );
  }
}

// ===========================================================================
// CONTENT WIDGETS
// ===========================================================================

class _KeyboardShortcutsContent extends ConsumerStatefulWidget {
  const _KeyboardShortcutsContent({
    required this.localizations,
    required this.isDark,
    required this.keybindings,
    required this.conflicts,
    required this.isMobile,
  });

  final AppLocalizations localizations;
  final bool isDark;
  final Map<String, String> keybindings;
  final Set<String> conflicts;
  final bool isMobile;

  @override
  ConsumerState<_KeyboardShortcutsContent> createState() =>
      _KeyboardShortcutsContentState();
}

class _KeyboardShortcutsContentState
    extends ConsumerState<_KeyboardShortcutsContent> {
  final _capturingId = ValueNotifier<String?>(null);
  final _captureFocusNode = FocusNode();

  @override
  void dispose() {
    _capturingId.value = null;
    _captureFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = _allShortcuts();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.localizations.keyboardShortcutsSubtitle,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.base,
              color: widget.isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: ChatoraiSpacing.lg),
          if (widget.isMobile)
            Container(
              padding: const EdgeInsets.all(ChatoraiSpacing.md),
              decoration: BoxDecoration(
                color: ChatoraiColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
                border: Border.all(
                  color: ChatoraiColors.orange.withValues(alpha: 0.3),
                  width: ChatoraiBorderWidth.thin,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: ChatoraiColors.orange,
                  ),
                  const SizedBox(width: ChatoraiSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.localizations.keybindingsReadOnlyMobile,
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.base,
                        color: widget.isDark
                            ? ChatoraiColors.darkTextColor
                            : ChatoraiColors.lightTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: ChatoraiSpacing.lg),
          ...shortcuts.map((shortcut) {
            final override = widget.keybindings[shortcut.id];
            final combo = override ?? shortcut.activator.format();
            final hasConflict = widget.conflicts.contains(shortcut.id);

            return _ShortcutRow(
              shortcut: shortcut,
              combo: combo,
              hasConflict: hasConflict,
              isDark: widget.isDark,
              isMobile: widget.isMobile,
              localizations: widget.localizations,
              onCapture: _captureShortcut,
              capturingId: _capturingId,
              captureFocusNode: _captureFocusNode,
            );
          }),
          const SizedBox(height: ChatoraiSpacing.lg),
          Divider(
            height: 1,
            thickness: ChatoraiBorderWidth.thin,
            color: widget.isDark
                ? ChatoraiColors.darkInputBorder
                : ChatoraiColors.inputBorder,
          ),
          const SizedBox(height: ChatoraiSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(widget.localizations.resetToDefaults),
                    content: Text(
                      widget.localizations.keyboardShortcutsResetConfirm,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(widget.localizations.commonCancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: ChatoraiColors.orange,
                          foregroundColor: ChatoraiColors.pureWhite,
                        ),
                        child: Text(widget.localizations.resetToDefaults),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(keybindingProvider.notifier).resetToDefaults();
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.localizations.settingsReset),
                        backgroundColor: ChatoraiColors.orange,
                      ),
                    );
                  }
                }
              },
              icon: Icon(
                Icons.restore_outlined,
                size: 18,
                color: widget.isDark
                    ? ChatoraiColors.darkSecondaryTextColor
                    : ChatoraiColors.secondaryTextColor,
              ),
              label: Text(widget.localizations.resetToDefaults),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.isDark
                    ? ChatoraiColors.darkSecondaryTextColor
                    : ChatoraiColors.secondaryTextColor,
                side: BorderSide(
                  color: widget.isDark
                      ? ChatoraiColors.darkInputBorder
                      : ChatoraiColors.inputBorder,
                  width: ChatoraiBorderWidth.thin,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatoraiSpacing.lg,
                  vertical: ChatoraiSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
                ),
                textStyle: TextStyle(
                  fontSize: ChatoraiFontSizes.base,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _captureShortcut(String id) {
    if (widget.isMobile) return;
    setState(() {
      _capturingId.value = _capturingId.value == id ? null : id;
    });
    if (_capturingId.value == id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureFocusNode.requestFocus();
      });
    }
  }
}

class _ShortcutRow extends ConsumerWidget {
  const _ShortcutRow({
    required this.shortcut,
    required this.combo,
    required this.hasConflict,
    required this.isDark,
    required this.isMobile,
    required this.localizations,
    required this.onCapture,
    required this.capturingId,
    required this.captureFocusNode,
  });

  final KeyboardShortcut shortcut;
  final String combo;
  final bool hasConflict;
  final bool isDark;
  final bool isMobile;
  final AppLocalizations localizations;
  final void Function(String) onCapture;
  final ValueNotifier<String?> capturingId;
  final FocusNode captureFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCapturing = capturingId.value == shortcut.id;
    final title = _titleForId(shortcut.id);

    return Container(
      margin: const EdgeInsets.only(bottom: ChatoraiSpacing.sm),
      padding: const EdgeInsets.all(ChatoraiSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(
          color: isDark
              ? ChatoraiColors.darkInputBorder
              : ChatoraiColors.inputBorder,
          width: ChatoraiBorderWidth.thin,
        ),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.base,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? ChatoraiColors.darkTextColor
                        : ChatoraiColors.lightTextColor,
                  ),
                ),
                if (hasConflict) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: ChatoraiColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        localizations.bindingConflict,
                        style: TextStyle(
                          fontSize: ChatoraiFontSizes.xs,
                          color: ChatoraiColors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: ChatoraiSpacing.md),
          if (isCapturing)
            Focus(
              focusNode: captureFocusNode,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  final key = event.logicalKey;
                  if (key == LogicalKeyboardKey.escape) {
                    capturingId.value = null;
                    return KeyEventResult.ignored;
                  }
                  final isCtrl = HardwareKeyboard.instance.isControlPressed;
                  final isShift = HardwareKeyboard.instance.isShiftPressed;
                  final isAlt = HardwareKeyboard.instance.isAltPressed;
                  final isMeta = HardwareKeyboard.instance.isMetaPressed;

                  final hasModifier = isCtrl || isShift || isAlt || isMeta;
                  final isNonPrintable =
                      key == LogicalKeyboardKey.escape ||
                      key == LogicalKeyboardKey.tab ||
                      key == LogicalKeyboardKey.home ||
                      key == LogicalKeyboardKey.end ||
                      key == LogicalKeyboardKey.arrowLeft ||
                      key == LogicalKeyboardKey.arrowRight ||
                      key == LogicalKeyboardKey.arrowUp ||
                      key == LogicalKeyboardKey.arrowDown;

                  if (!hasModifier && !isNonPrintable) {
                    return KeyEventResult.ignored;
                  }

                  final parts = <String>[];
                  if (isCtrl) parts.add('Ctrl');
                  if (isShift) parts.add('Shift');
                  if (isAlt) parts.add('Alt');
                  if (isMeta) parts.add('Meta');

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
                      keyName = key.keyLabel.isNotEmpty
                          ? key.keyLabel.toUpperCase()
                          : key.toString();
                  }

                  final combo = parts.isEmpty
                      ? keyName
                      : '${parts.join('+')}+$keyName';

                  try {
                    ref
                        .read(keybindingProvider.notifier)
                        .setBinding(shortcut.id, combo);
                  } catch (_) {
                    // Invalid combos are pre-filtered by the modifier guard.
                  }
                  capturingId.value = null;

                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatoraiSpacing.md,
                  vertical: ChatoraiSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: ChatoraiColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
                  border: Border.all(
                    color: ChatoraiColors.orange,
                    width: ChatoraiBorderWidth.thinBold,
                  ),
                ),
                child: Text(
                  localizations.captureHint,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.sm,
                    color: ChatoraiColors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatoraiSpacing.md,
                vertical: ChatoraiSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2F2F2F)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              ),
              child: Text(
                combo,
                style: ChatoraiFontSizes.mono(
                  ChatoraiFontSizes.sm,
                  color: isDark
                      ? ChatoraiColors.pureWhite
                      : ChatoraiColors.pureBlack,
                ),
              ),
            ),
          const SizedBox(width: ChatoraiSpacing.sm),
          if (!isMobile)
            IconButton(
              onPressed: () => onCapture(shortcut.id),
              icon: Icon(
                isCapturing ? Icons.close : Icons.edit_outlined,
                size: 18,
                color: isCapturing
                    ? ChatoraiColors.orange
                    : (isDark
                          ? ChatoraiColors.darkSecondaryTextColor
                          : ChatoraiColors.secondaryTextColor),
              ),
              tooltip: isCapturing
                  ? localizations.close
                  : localizations.captureHint,
              style: IconButton.styleFrom(
                backgroundColor: isCapturing
                    ? ChatoraiColors.orange.withValues(alpha: 0.1)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  String _titleForId(String id) {
    switch (id) {
      case 'cancel_streaming':
        return localizations.shortcutCancelStreaming;
      case 'close_dialog':
        return localizations.shortcutCloseDialog;
      case 'open_latest_child':
        return localizations.shortcutOpenLatestChild;
      case 'nav_prev_sibling':
        return localizations.shortcutNavPrevSibling;
      case 'nav_next_sibling':
        return localizations.shortcutNavNextSibling;
      case 'nav_parent':
        return localizations.shortcutNavParent;
      case 'cycle_primary_agent':
        return localizations.shortcutCyclePrimaryAgent;
      case 'toggle_sidebar':
        return localizations.shortcutToggleSidebar;
      case 'new_chat':
        return localizations.shortcutNewChat;
      case 'open_model_selector':
        return localizations.shortcutOpenModelSelector;
      case 'open_settings':
        return localizations.shortcutOpenSettings;
      case 'open_workspace':
        return localizations.shortcutOpenWorkspace;
      case 'scroll_to_chat_start':
        return localizations.shortcutScrollToChatStart;
      case 'scroll_to_chat_end':
        return localizations.shortcutScrollToChatEnd;
      default:
        return id;
    }
  }
}

// ===========================================================================
// SHORTCUT REGISTRY
// ===========================================================================

List<KeyboardShortcut> _allShortcuts() {
  return [
    KeyboardShortcut(
      id: 'cancel_streaming',
      description: 'Cancel AI response (double ESC)',
      activator: const KeyActivator.escapeDoublePress(),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'close_dialog',
      description: 'Close dialog (Escape)',
      activator: const KeyActivator.escape(),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'open_latest_child',
      description: 'Open the latest child session (Ctrl+↓)',
      activator: const KeyActivator.ctrlDown(),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'nav_prev_sibling',
      description: 'Previous sibling session (←)',
      activator: const KeyActivator.arrowLeft(),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'nav_next_sibling',
      description: 'Next sibling session (→)',
      activator: const KeyActivator.arrowRight(),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'nav_parent',
      description: 'Go to parent session (↑)',
      activator: const KeyActivator.arrowUp(),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'cycle_primary_agent',
      description: 'Cycle primary agent (Ctrl+Tab)',
      activator: const KeyActivator.ctrlTab(),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'toggle_sidebar',
      description: 'Toggle sidebar (Ctrl+B)',
      activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyB),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'new_chat',
      description: 'New chat (Ctrl+N)',
      activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyN),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'open_model_selector',
      description: 'Open model selector (Ctrl+M)',
      activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyM),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'open_settings',
      description: 'Open settings (Ctrl+P)',
      activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyP),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'open_workspace',
      description: 'Open workspace (Ctrl+W)',
      activator: const KeyActivator.ctrlKey(LogicalKeyboardKey.keyW),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'scroll_to_chat_start',
      description: 'Scroll chat to the top (Home)',
      activator: const KeyActivator.home(),
      onExecute: (context, event) {},
    ),
    KeyboardShortcut(
      id: 'scroll_to_chat_end',
      description: 'Scroll chat to the bottom (End)',
      activator: const KeyActivator.end(),
      onExecute: (context, event) {},
    ),
  ];
}
