import 'dart:async';

import 'package:chatorai/features/settings/providers/auto_approve_provider.dart';
import 'package:chatorai/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global / Project scope selector tab bar.
///
/// Extracted from [_ScopeToggle] in auto_approve_screen.dart.
class AutoApproveScopeSelector extends ConsumerWidget {
  const AutoApproveScopeSelector({
    super.key,
    required this.state,
    required this.localizations,
    required this.onScopeChanged,
  });

  final AutoApproveState state;
  final AppLocalizations localizations;
  final void Function(AutoApproveScope scope) onScopeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(autoApproveProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      key: ValueKey(state.scope),
      length: 2,
      initialIndex: state.scope == AutoApproveScope.global ? 0 : 1,
      child: Builder(
        builder: (innerContext) {
          final tabBar = unifiedTabBar(
            isDark: isDark,
            onTap: (index) {
              if (index == 1 && !state.supportsProjectScope) {
                DefaultTabController.of(innerContext).animateTo(0);
                return;
              }
              final scope = index == 0
                  ? AutoApproveScope.global
                  : AutoApproveScope.project;
              if (scope == state.scope) return;
              unawaited(notifier.setScope(scope));
              onScopeChanged(scope);
            },
            tabs: [
              Tab(text: localizations.scopeGlobal),
              Tab(
                child: Tooltip(
                  message: state.supportsProjectScope
                      ? ''
                      : localizations.autoApproveScopeProjectDisabledTooltip,
                  child: Text(
                    localizations.scopeProject,
                    style: TextStyle(
                      color: state.supportsProjectScope
                          ? null
                          : (isDark
                                ? ChatoraiColors.darkSecondaryTextColor
                                      .withValues(alpha: 0.5)
                                : ChatoraiColors.secondaryTextColor.withValues(
                                    alpha: 0.5,
                                  )),
                    ),
                  ),
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              unifiedTabContainer(tabBar: tabBar, isDark: isDark),
              const SizedBox(height: ChatoraiSpacing.xs),
              Text(
                localizations.autoApproveScopeHint,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.sm,
                  color: isDark
                      ? ChatoraiColors.darkSecondaryTextColor
                      : ChatoraiColors.secondaryTextColor,
                ),
              ),
              if (!state.supportsProjectScope)
                Padding(
                  padding: const EdgeInsets.only(top: ChatoraiSpacing.xs),
                  child: Text(
                    localizations.autoApproveScopeProjectDisabledTooltip,
                    style: TextStyle(
                      fontSize: ChatoraiFontSizes.xs,
                      color: isDark
                          ? ChatoraiColors.darkSecondaryTextColor
                          : ChatoraiColors.secondaryTextColor,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
