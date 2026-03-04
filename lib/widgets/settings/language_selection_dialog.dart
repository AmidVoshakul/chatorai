import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers/language_provider.dart';
import 'package:chatorai/utils/snackbar_utils.dart';

void showLanguageSelectionDialog(
  BuildContext context,
  AppLocalizations localizations,
  dynamic controller,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final languageProvider = Provider.of<LanguageProvider>(
    context,
    listen: false,
  );

  final languages = <String, String>{
    'en': localizations.english,
    'ru': localizations.russian,
    'uk': localizations.ukrainian,
    'ar': localizations.arabic,
    'zh': localizations.chinese,
    'ja': localizations.japanese,
  };

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: isDark
            ? UbuntuColors.darkCard
            : UbuntuColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? UbuntuColors.darkInputBorder
                : UbuntuColors.inputBorder,
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
                    localizations.language,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? UbuntuColors.light : UbuntuColors.dark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.maxFinite,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: languages.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark
                            ? UbuntuColors.darkInputBorder
                            : UbuntuColors.inputBorder,
                      ),
                      itemBuilder: (context, index) {
                        final entry = languages.entries.elementAt(index);
                        final isSelected =
                            languageProvider.selectedLanguage == entry.key;

                        return _buildDialogOption(
                          context: context,
                          icon: Icons.language,
                          title: entry.key.toUpperCase(),
                          subtitle: entry.value,
                          isSelected: isSelected,
                          onTap: () {
                            languageProvider.selectedLanguage = entry.key;
                            Navigator.pop(context);
                            SnackbarUtils.showSuccessSnackBar(
                              context: context,
                              message: localizations.settingsSaved,
                            );
                          },
                        );
                      },
                    ),
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
                    ? UbuntuColors.darkSecondaryTextColor
                    : UbuntuColors.secondaryTextColor,
                onPressed: () => Navigator.pop(context),
                tooltip: localizations.close,
              ),
            ),
          ],
        ),
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
              ? (isDark ? UbuntuColors.darkSurface : UbuntuColors.lightSurface)
              : Colors.transparent,
          border: isSelected
              ? Border.all(color: UbuntuColors.orange, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? UbuntuColors.orange
                  : (isDark
                        ? UbuntuColors.darkSecondaryTextColor
                        : UbuntuColors.secondaryTextColor),
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
                          ? UbuntuColors.orange
                          : (isDark
                                ? UbuntuColors.darkTextColor
                                : UbuntuColors.lightTextColor),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? UbuntuColors.darkSecondaryTextColor
                          : UbuntuColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: UbuntuColors.orange, size: 20),
          ],
        ),
      ),
    ),
  );
}
