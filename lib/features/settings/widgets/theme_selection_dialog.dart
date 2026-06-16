import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_provider.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showThemeSelectionDialog(
  BuildContext context,
  AppLocalizations localizations,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Consumer(
        builder: (context, ref, child) {
          final themeMode = ref.watch(themeProvider.select((s) => s.themeMode));

          return Dialog(
            backgroundColor: isDark
                ? ChatoraiColors.darkCard
                : ChatoraiColors.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark
                    ? ChatoraiColors.darkInputBorder
                    : ChatoraiColors.inputBorder,
                width: 1,
              ),
            ),
            elevation: 0,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.theme,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? ChatoraiColors.light
                              : ChatoraiColors.dark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDialogOption(
                        context: context,
                        icon: Icons.brightness_6,
                        title: localizations.system,
                        subtitle: localizations.useSystemTheme,
                        isSelected: themeMode == AppThemeMode.system,
                        onTap: () {
                          ref
                              .read(themeProvider.notifier)
                              .setThemeMode(AppThemeMode.system);
                          Navigator.pop(dialogContext);
                          SnackbarUtils.showSuccessSnackBar(
                            context: context,
                            message: localizations.settingsSaved,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDialogOption(
                        context: context,
                        icon: Icons.wb_sunny,
                        title: localizations.light,
                        subtitle: localizations.useLightTheme,
                        isSelected: themeMode == AppThemeMode.light,
                        onTap: () {
                          ref
                              .read(themeProvider.notifier)
                              .setThemeMode(AppThemeMode.light);
                          Navigator.pop(dialogContext);
                          SnackbarUtils.showSuccessSnackBar(
                            context: context,
                            message: localizations.settingsSaved,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDialogOption(
                        context: context,
                        icon: Icons.nightlight,
                        title: localizations.dark,
                        subtitle: localizations.useDarkTheme,
                        isSelected: themeMode == AppThemeMode.dark,
                        onTap: () {
                          ref
                              .read(themeProvider.notifier)
                              .setThemeMode(AppThemeMode.dark);
                          Navigator.pop(dialogContext);
                          SnackbarUtils.showSuccessSnackBar(
                            context: context,
                            message: localizations.settingsSaved,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: isDark
                        ? ChatoraiColors.darkSecondaryTextColor
                        : ChatoraiColors.secondaryTextColor,
                    onPressed: () => Navigator.pop(dialogContext),
                    tooltip: localizations.close,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildDialogOption({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? (isDark
                    ? ChatoraiColors.darkSurface
                    : ChatoraiColors.lightSurface)
              : Colors.transparent,
          border: isSelected
              ? Border.all(color: ChatoraiColors.orange, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? ChatoraiColors.orange
                  : (isDark
                        ? ChatoraiColors.darkSecondaryTextColor
                        : ChatoraiColors.secondaryTextColor),
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? ChatoraiColors.orange
                          : (isDark
                                ? ChatoraiColors.darkTextColor
                                : ChatoraiColors.lightTextColor),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? ChatoraiColors.darkSecondaryTextColor
                          : ChatoraiColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: ChatoraiColors.orange, size: 20),
          ],
        ),
      ),
    ),
  );
}
