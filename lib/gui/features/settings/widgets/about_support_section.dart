import 'package:chatorai/gui/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/link_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// "Support the Project" block shared by the About dialog and the
/// About settings section. Single source of truth (DRY) for the
/// support links so both places stay in sync.
class AboutSupportSection extends StatelessWidget {
  static const String githubUrl = 'https://github.com/AmidVoshakul/chatorai';
  static const String sponsorUrl = 'https://github.com/sponsors/AmidVoshakul';
  static const String issuesUrl =
      'https://github.com/AmidVoshakul/chatorai/issues';

  const AboutSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: premiumCard(isDark),
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.supportProjectTitle,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.lg,
              fontWeight: FontWeight.bold,
              color: isDark ? ChatoraiColors.light : ChatoraiColors.dark,
            ),
          ),
          const SizedBox(height: ChatoraiSpacing.xs),
          Text(
            localizations.supportProjectSubtitle,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.base,
              height: 1.5,
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: ChatoraiSpacing.md),
          _SupportButton(
            isDark: isDark,
            label: localizations.supportStarOnGitHub,
            url: githubUrl,
            leading: ColorFiltered(
              colorFilter: ColorFilter.mode(
                isDark ? ChatoraiColors.pureWhite : ChatoraiColors.pureBlack,
                BlendMode.srcIn,
              ),
              child: SvgPicture.asset(
                'assets/provider/github.svg',
                width: ChatoraiIconSizes.buttonIcon,
                height: ChatoraiIconSizes.buttonIcon,
              ),
            ),
          ),
          const SizedBox(height: ChatoraiSpacing.sm),
          _SupportButton(
            isDark: isDark,
            label: localizations.supportBecomeSponsor,
            url: sponsorUrl,
            leading: Icon(
              Icons.favorite,
              size: ChatoraiIconSizes.buttonIcon,
              color: ChatoraiColors.errorLight,
            ),
          ),
          const SizedBox(height: ChatoraiSpacing.sm),
          _SupportButton(
            isDark: isDark,
            label: localizations.supportShareThoughts,
            url: issuesUrl,
            leading: Icon(
              Icons.forum,
              size: ChatoraiIconSizes.buttonIcon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  final bool isDark;
  final String label;
  final String url;
  final Widget leading;

  const _SupportButton({
    required this.isDark,
    required this.label,
    required this.url,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => launchExternalLink(url),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.lg,
            vertical: ChatoraiSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
          ),
          side: BorderSide(
            color: isDark
                ? ChatoraiColors.darkInputBorder
                : ChatoraiColors.inputBorder,
          ),
          foregroundColor: isDark ? ChatoraiColors.light : ChatoraiColors.dark,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: ChatoraiSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: ChatoraiIconSizes.sm,
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
