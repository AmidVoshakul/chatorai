import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/logger.dart';

/// Bridges [PermissionService.onAsked] → UI dialog.
class PermissionOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const PermissionOverlay({super.key, required this.child});

  @override
  ConsumerState<PermissionOverlay> createState() => _PermissionOverlayState();
}

class _PermissionOverlayState extends ConsumerState<PermissionOverlay> {
  StreamSubscription<PermissionRequest>? _sub;
  StreamSubscription<QuestionRequest>? _questionSub;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    final service = ref.read(permissionServiceProvider);
    _sub ??= service.onAsked.listen(_onRequest);
    _questionSub ??= service.onQuestionAsked.listen(_onQuestionRequest);
  }

  Future<void> _onRequest(PermissionRequest req) async {
    LogTags.permission.logInfo(
      'PermissionOverlay._onRequest: START for tool=${req.toolName}',
    );
    if (!mounted) {
      LogTags.permission.logWarning(
        'PermissionOverlay._onRequest: Widget not mounted, aborting',
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    LogTags.permission.logInfo(
      'PermissionOverlay._onRequest: Showing dialog for tool=${req.toolName}',
    );

    final reply = await showModalBottomSheet<PermissionReply>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return _PremiumSheetShell(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(child: _PremiumHandle()),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _PremiumAvatar(
                        icon: Icons.shield_outlined,
                        glow: ChatoraiColors.orange,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.toolName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: ChatoraiColors.premiumText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _premiumSectionLabel(
                              ctx,
                              l10n.permissionDialogPatterns,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...req.patterns.map(
                          (p) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 3,
                            ),
                            child: _PremiumCommandChip(command: p),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      _premiumGhostButton(
                        context: ctx,
                        onPressed: () =>
                            Navigator.pop(ctx, PermissionReply.reject),
                        child: Text(l10n.permissionReject),
                      ),
                      const Spacer(),
                      _premiumTonalButton(
                        context: ctx,
                        onPressed: () =>
                            Navigator.pop(ctx, PermissionReply.once),
                        child: Text(l10n.permissionOnce),
                      ),
                      const SizedBox(width: 10),
                      _premiumPrimaryButton(
                        context: ctx,
                        onPressed: () =>
                            Navigator.pop(ctx, PermissionReply.always),
                        child: Text(l10n.permissionAlways),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    LogTags.permission.logInfo(
      'PermissionOverlay._onRequest: Dialog closed with reply=$reply for tool=${req.toolName}',
    );

    if (!mounted) {
      LogTags.permission.logWarning(
        'PermissionOverlay._onRequest: Widget not mounted after dialog, aborting reply',
      );
      return;
    }

    final service = ref.read(permissionServiceProvider);
    if (reply == null) {
      LogTags.permission.logInfo(
        'PermissionOverlay._onRequest: Reply=reject (null) for tool=${req.toolName}',
      );
      service.reply(req.id, PermissionReply.reject);
    } else {
      LogTags.permission.logInfo(
        'PermissionOverlay._onRequest: Reply=$reply for tool=${req.toolName}',
      );
      service.reply(req.id, reply);
    }
  }

  Future<void> _onQuestionRequest(QuestionRequest req) async {
    LogTags.permission.logInfo(
      'PermissionOverlay._onQuestionRequest: START id=${req.id}, question="${req.question}"',
    );

    _customController.clear();
    final selectedOptions = <String>{};

    final answer = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: false,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final localizations = AppLocalizations.of(ctx)!;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return _PremiumSheetShell(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    const Center(child: _PremiumHandle()),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _PremiumAvatar(
                            icon: Icons.auto_awesome,
                            glow: ChatoraiColors.orange,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations.question,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                    color: ChatoraiColors.premiumText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  req.question,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: ChatoraiColors.premiumTextMuted,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (req.options.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ...req.options.map((option) {
                                final selected = selectedOptions.contains(
                                  option.label,
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 3,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        if (req.multiple) {
                                          if (selected) {
                                            selectedOptions.remove(
                                              option.label,
                                            );
                                          } else {
                                            selectedOptions.add(option.label);
                                          }
                                        } else {
                                          selectedOptions.clear();
                                          selectedOptions.add(option.label);
                                          _customController.clear();
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(
                                      ChatoraiBorderRadius.md,
                                    ),
                                    child: AnimatedContainer(
                                      duration: ChatoraiDurations.fast,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: selected
                                            ? ChatoraiGradients.selection
                                            : null,
                                        color: selected
                                            ? null
                                            : ChatoraiColors
                                                  .premiumSurfaceRaised,
                                        borderRadius: BorderRadius.circular(
                                          ChatoraiBorderRadius.md,
                                        ),
                                        border: Border.all(
                                          color: selected
                                              ? ChatoraiColors.premiumBorder
                                              : ChatoraiColors
                                                    .premiumBorderSoft,
                                        ),
                                        boxShadow: selected
                                            ? [
                                                BoxShadow(
                                                  color: ChatoraiColors
                                                      .pureBlack
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            req.multiple
                                                ? (selected
                                                      ? Icons.check_box
                                                      : Icons
                                                            .check_box_outline_blank)
                                                : (selected
                                                      ? Icons
                                                            .radio_button_checked
                                                      : Icons
                                                            .radio_button_unchecked),
                                            size: 20,
                                            color: selected
                                                ? ChatoraiColors.pureWhite
                                                : ChatoraiColors
                                                      .premiumTextMuted,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  option.label,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: selected
                                                            ? ChatoraiColors
                                                                  .pureWhite
                                                            : ChatoraiColors
                                                                  .premiumText,
                                                        fontWeight: selected
                                                            ? FontWeight.w700
                                                            : null,
                                                      ),
                                                ),
                                                if (option.description !=
                                                        null &&
                                                    option
                                                        .description!
                                                        .isNotEmpty)
                                                  Text(
                                                    option.description!,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: selected
                                                              ? ChatoraiColors
                                                                    .white90
                                                              : ChatoraiColors
                                                                    .premiumTextMuted
                                                                    .withValues(
                                                                      alpha:
                                                                          0.8,
                                                                    ),
                                                          fontSize:
                                                              ChatoraiFontSizes
                                                                  .xs,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: TextField(
                                controller: _customController,
                                style: const TextStyle(
                                  color: ChatoraiColors.premiumText,
                                ),
                                decoration: InputDecoration(
                                  labelText: req.options.isNotEmpty
                                      ? 'Or type your answer...'
                                      : 'Your answer',
                                  isDense: true,
                                  filled: true,
                                  fillColor:
                                      ChatoraiColors.premiumSurfaceRaised,
                                  labelStyle: const TextStyle(
                                    color: ChatoraiColors.premiumTextMuted,
                                  ),
                                  hintStyle: const TextStyle(
                                    color: ChatoraiColors.premiumTextMuted,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      ChatoraiBorderRadius.md,
                                    ),
                                    borderSide: const BorderSide(
                                      color: ChatoraiColors.premiumBorderSoft,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      ChatoraiBorderRadius.md,
                                    ),
                                    borderSide: const BorderSide(
                                      color: ChatoraiColors.premiumBorder,
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                                maxLines: 3,
                                minLines: 1,
                                maxLength: 1000,
                                onChanged: (_) {
                                  setDialogState(() {
                                    selectedOptions.clear();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Row(
                        children: [
                          _premiumGhostButton(
                            context: ctx,
                            onPressed: () => Navigator.pop(ctx, ''),
                            child: Text(localizations.skip),
                          ),
                          const Spacer(),
                          _premiumPrimaryButton(
                            context: ctx,
                            onPressed: () {
                              if (_customController.text.trim().isNotEmpty) {
                                Navigator.pop(
                                  ctx,
                                  _customController.text.trim(),
                                );
                              } else if (selectedOptions.isNotEmpty) {
                                final answer = req.multiple
                                    ? jsonEncode(selectedOptions.toList())
                                    : selectedOptions.first;
                                Navigator.pop(ctx, answer);
                              }
                            },
                            child: Text(localizations.answer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    LogTags.permission.logInfo(
      'PermissionOverlay._onQuestionRequest: answer="$answer" for id=${req.id}',
    );

    if (!mounted) return;
    final service = ref.read(permissionServiceProvider);
    if (answer == null) {
      service.cancelPendingQuestion(req.id);
    } else if (answer.isEmpty) {
      service.cancelPendingQuestion(req.id);
    } else {
      service.answerQuestion(req.id, answer);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _questionSub?.cancel();
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ===========================================================================
// PREMIUM PERMISSION SHEET PRIMITIVES
// ===========================================================================
//
// Shared visual building blocks for the permission and question bottom sheets.
// All colors and gradients come from the design system in
// `app_theme.dart` (`ChatoraiColors.premium*`, `ChatoraiGradients`).

const BorderRadius _premiumSheetTopRadius = BorderRadius.vertical(
  top: Radius.circular(ChatoraiBorderRadius.xl),
);

/// Simple dark panel with a solid border (no gradient, no blur).
class _PremiumSheetShell extends StatelessWidget {
  final Widget child;

  const _PremiumSheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChatoraiColors.premiumSurface,
        borderRadius: _premiumSheetTopRadius,
        border: const Border(
          top: BorderSide(color: ChatoraiColors.premiumBorderSoft, width: 1),
        ),
      ),
      child: ClipRRect(borderRadius: _premiumSheetTopRadius, child: child),
    );
  }
}

/// Metallic pill handle.
class _PremiumHandle extends StatelessWidget {
  const _PremiumHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        gradient: ChatoraiGradients.metallic,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
        boxShadow: [
          BoxShadow(
            color: ChatoraiColors.pureBlack.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Circular icon badge with a brand accent gradient and a soft glow.
class _PremiumAvatar extends StatelessWidget {
  final IconData icon;
  final Color glow;

  const _PremiumAvatar({required this.icon, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: ChatoraiGradients.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: ChatoraiColors.pureWhite, size: 22),
    );
  }
}

/// Small-caps section label.
Widget _premiumSectionLabel(BuildContext context, String text) {
  return Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 1.6,
      fontWeight: FontWeight.w700,
      color: ChatoraiColors.premiumTextMuted,
    ),
  );
}

/// Terminal-style chip for a single permission pattern.
class _PremiumCommandChip extends StatelessWidget {
  final String command;

  const _PremiumCommandChip({required this.command});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: ChatoraiColors.premiumSurfaceRaised,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(color: ChatoraiColors.premiumBorderSoft),
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal, size: 14, color: Color(0xFF8A8A8A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              command,
              style: ChatoraiFontSizes.mono(
                12.5,
                color: ChatoraiColors.premiumText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill button with a brand accent gradient background and a soft glow.
Widget _premiumPrimaryButton({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: ChatoraiGradients.accent,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
      boxShadow: [
        BoxShadow(
          color: ChatoraiColors.orange.withValues(alpha: 0.4),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: ChatoraiColors.pureWhite,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      child: child,
    ),
  );
}

/// Dark tonal pill button for secondary actions.
Widget _premiumTonalButton({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
}) {
  return FilledButton.tonal(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: ChatoraiColors.premiumSurfaceRaised,
      foregroundColor: ChatoraiColors.premiumText,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
      ),
      side: BorderSide(color: ChatoraiColors.premiumBorderSoft),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    child: child,
  );
}

/// Quiet ghost button for dismissive actions.
Widget _premiumGhostButton({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: ChatoraiColors.premiumTextMuted,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    child: child,
  );
}
