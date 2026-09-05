import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/android_storage_permission.dart';
import 'package:chatorai/shared/widgets/premium_sheet.dart';

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
    final showAllFilesHint =
        req.permission == 'external_directory' &&
        !(await isAllFilesAccessGranted());
    if (!mounted) return;
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
        return PremiumSheetShell(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(child: PremiumHandle()),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const PremiumAvatar(
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
                            premiumSectionLabel(
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
                    // Three action buttons must share the available width or the
                    // Row overflows on narrow screens (the dialog is 288 wide,
                    // but the buttons + gaps want ~379). Each button is
                    // Flexible so it shrinks instead of pushing siblings off.
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: premiumGhostButton(
                          context: ctx,
                          onPressed: () =>
                              Navigator.pop(ctx, PermissionReply.reject),
                          child: Text(l10n.permissionReject),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        fit: FlexFit.loose,
                        child: premiumTonalButton(
                          context: ctx,
                          onPressed: () =>
                              Navigator.pop(ctx, PermissionReply.once),
                          child: Text(
                            l10n.permissionOnce,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        fit: FlexFit.loose,
                        child: premiumPrimaryButton(
                          context: ctx,
                          onPressed: () =>
                              Navigator.pop(ctx, PermissionReply.always),
                          child: Text(
                            l10n.permissionAlways,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showAllFilesHint)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          allFilesAccessHint(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ChatoraiColors.gray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        premiumTonalButton(
                          context: ctx,
                          onPressed: () async {
                            final granted = await ensureAllFilesAccess();
                            if (granted && ctx.mounted) {
                              Navigator.pop(ctx, PermissionReply.once);
                            }
                          },
                          child: const Text('Enable all files access'),
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
      await service.reply(req.id, reply);
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
            return PremiumSheetShell(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    const Center(child: PremiumHandle()),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PremiumAvatar(
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
                          premiumGhostButton(
                            context: ctx,
                            onPressed: () => Navigator.pop(ctx, ''),
                            child: Text(localizations.skip),
                          ),
                          const Spacer(),
                          premiumPrimaryButton(
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
// PREMIUM COMMAND CHIP (permission-only primitive, kept local)
// ===========================================================================

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
