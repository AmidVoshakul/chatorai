import 'package:flutter/material.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';

void showSettingsAboutDialog(
  BuildContext context,
  AppLocalizations localizations,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

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
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.appTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? UbuntuColors.light : UbuntuColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.appDescription,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? UbuntuColors.darkSecondaryTextColor
                          : UbuntuColors.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
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
