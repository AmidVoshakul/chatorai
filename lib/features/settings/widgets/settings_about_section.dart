import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        String version = '';
        if (snapshot.hasData) {
          version = snapshot.data!.version.split('+').first;
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? ChatoraiColors.darkCard : ChatoraiColors.lightCard,
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
            border: Border.all(
              color: isDark
                  ? ChatoraiColors.darkInputBorder
                  : ChatoraiColors.inputBorder,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(ChatoraiSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.appTitle,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.xxl,
                  fontWeight: FontWeight.bold,
                  color: isDark ? ChatoraiColors.light : ChatoraiColors.dark,
                ),
              ),
              const SizedBox(height: ChatoraiSpacing.sm),
              Text(
                localizations.appDescription,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.base,
                  height: 1.5,
                  color: isDark
                      ? ChatoraiColors.darkSecondaryTextColor
                      : ChatoraiColors.secondaryTextColor,
                ),
              ),
              if (version.isNotEmpty) ...[
                const SizedBox(height: ChatoraiSpacing.sm),
                Text(
                  '${localizations.versionLabel} $version',
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.base,
                    color: isDark
                        ? ChatoraiColors.darkSecondaryTextColor
                        : ChatoraiColors.secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
