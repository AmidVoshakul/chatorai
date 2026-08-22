import 'dart:io';

import 'package:chatorai/features/settings/providers/auto_approve_provider.dart';
import 'package:chatorai/features/settings/widgets/auto_approve/auto_approve_category_list.dart';
import 'package:chatorai/features/settings/widgets/auto_approve/auto_approve_help_section.dart';
import 'package:chatorai/features/settings/widgets/auto_approve/auto_approve_scope_selector.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoApproveScreen extends ConsumerWidget {
  final bool embedded;

  const AutoApproveScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final asyncState = ref.watch(autoApproveProvider);
    final state = asyncState.value;

    if (embedded) {
      if (asyncState is AsyncLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (asyncState is AsyncError) {
        return Center(
          child: Text(
            localizations.autoApproveError(asyncState.error.toString()),
          ),
        );
      }
      if (state == null) return const SizedBox.shrink();
      return Material(
        type: MaterialType.transparency,
        child: _AutoApproveContent(
          state: state,
          localizations: localizations,
          onChanged: (categoryId, defaultAction, exceptions) {
            ref
                .read(autoApproveProvider.notifier)
                .save(
                  categoryId: categoryId,
                  defaultAction: defaultAction,
                  exceptions: exceptions,
                );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.autoApproveTitle),
        centerTitle: true,
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: asyncState is AsyncLoading
          ? const Center(child: CircularProgressIndicator())
          : asyncState is AsyncError
          ? Center(
              child: Text(
                localizations.autoApproveError(asyncState.error.toString()),
              ),
            )
          : state == null
          ? const SizedBox.shrink()
          : _AutoApproveContent(
              state: state,
              localizations: localizations,
              onChanged: (categoryId, defaultAction, exceptions) {
                ref
                    .read(autoApproveProvider.notifier)
                    .save(
                      categoryId: categoryId,
                      defaultAction: defaultAction,
                      exceptions: exceptions,
                    );
              },
            ),
    );
  }
}

class _AutoApproveContent extends StatelessWidget {
  const _AutoApproveContent({
    required this.state,
    required this.localizations,
    required this.onChanged,
  });

  final AutoApproveState state;
  final AppLocalizations localizations;
  final void Function(
    String categoryId,
    String? defaultAction,
    Map<String, String> exceptions,
  )
  onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoApproveHelpSection(localizations: localizations, isDark: isDark),
          const SizedBox(height: ChatoraiSpacing.lg),
          if (!Platform.isAndroid && !Platform.isIOS) ...[
            AutoApproveScopeSelector(
              state: state,
              localizations: localizations,
              onScopeChanged: (_) {},
            ),
            const SizedBox(height: ChatoraiSpacing.lg),
          ],
          AutoApproveCategoryList(
            state: state,
            localizations: localizations,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
