import 'package:flutter/material.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

void showSettingsAboutDialog(
  BuildContext context,
  AppLocalizations localizations,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          String version = '';
          if (snapshot.hasData) {
            // Get version without build number (e.g., "1.0.0" from "1.0.0+1")
            final fullVersion = snapshot.data!.version;
            version = fullVersion.split('+').first;
          }

          // Calculate max height for dialog (90% of screen height)
          final maxHeight = MediaQuery.of(context).size.height * 0.9;

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
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.appTitle,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? ChatoraiColors.light
                                  : ChatoraiColors.dark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations.appDescription,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: isDark
                                  ? ChatoraiColors.darkSecondaryTextColor
                                  : ChatoraiColors.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (version.isNotEmpty)
                            Text(
                              '${localizations.versionLabel} $version',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark
                                    ? ChatoraiColors.darkSecondaryTextColor
                                    : ChatoraiColors.secondaryTextColor,
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
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
                      onPressed: () => Navigator.pop(context),
                      tooltip: localizations.close,
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
}
