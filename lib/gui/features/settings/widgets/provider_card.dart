import 'package:chatorai/gui/features/models/widgets/provider_icon.dart';
import 'package:chatorai/gui/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A card that displays a provider's name, status, and action buttons.
///
/// Replaces the legacy [AiProvider]+[ProviderSettings] pair with a simple
/// [providerId]+[name] + individual settings parameters.
class ProviderCard extends StatelessWidget {
  final String providerId;
  final String name;
  final String? iconPath;
  final String? baseUrl;
  final bool enabled;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onSelectModels;
  final VoidCallback onDelete;

  const ProviderCard({
    super.key,
    required this.providerId,
    required this.name,
    this.iconPath,
    this.baseUrl,
    required this.enabled,
    required this.isDark,
    required this.onToggle,
    required this.onEdit,
    required this.onSelectModels,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      decoration: premiumCard(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProviderIcon(),
              const SizedBox(width: ChatoraiSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.lg,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ChatoraiColors.pureWhite
                        : ChatoraiColors.pureBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ChatoraiSpacing.sm),
          Text(
            baseUrl ?? '',
            style: TextStyle(
              fontSize: ChatoraiFontSizes.caption,
              color: isDark
                  ? ChatoraiColors.darkSecondaryTextColor
                  : ChatoraiColors.secondaryTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ChatoraiSpacing.md),
          Row(
            children: [
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: enabled,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: ChatoraiColors.orange,
                  activeTrackColor: ChatoraiColors.orange.withAlpha(150),
                  inactiveThumbColor: isDark
                      ? ChatoraiColors.toggleInactiveThumbDark
                      : ChatoraiColors.toggleInactiveThumbLight,
                  inactiveTrackColor: isDark
                      ? ChatoraiColors.toggleInactiveTrackDark
                      : ChatoraiColors.toggleInactiveTrackLight,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              _ActionButton(
                icon: Icons.edit_outlined,
                isDark: isDark,
                onTap: onEdit,
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              _ActionButton(
                icon: Icons.model_training_outlined,
                isDark: isDark,
                onTap: onSelectModels,
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              _ActionButton(
                icon: Icons.delete_outline,
                isDark: isDark,
                isDestructive: true,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderIcon() {
    final iconColor = isDark
        ? ChatoraiColors.pureWhite
        : ChatoraiColors.pureBlack;
    if (iconPath != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        child: SvgPicture.asset(
          iconPath!,
          width: ChatoraiIconSizes.xxl,
          height: ChatoraiIconSizes.xxl,
        ),
      );
    }
    return ProviderIcon(providerId: providerId, size: ChatoraiIconSizes.xxl);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? (isDark
              ? ChatoraiColors.darkSecondaryTextColor.withAlpha(80)
              : ChatoraiColors.secondaryTextColor.withAlpha(80))
        : isDestructive
        ? ChatoraiColors.error
        : (isDark
              ? ChatoraiColors.darkSecondaryTextColor
              : ChatoraiColors.secondaryTextColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(ChatoraiSpacing.xs + 2),
        child: Icon(icon, size: ChatoraiIconSizes.xl, color: color),
      ),
    );
  }
}
