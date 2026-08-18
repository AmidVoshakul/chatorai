import 'package:chatorai/features/settings/screens/agents_instructions_screen.dart';
import 'package:chatorai/features/settings/screens/config_screen.dart';
import 'package:chatorai/features/settings/screens/mcp_servers_screen.dart';
import 'package:chatorai/features/settings/screens/provider_settings_screen.dart';
import 'package:chatorai/features/settings/screens/provider_settings_dialogs.dart';
import 'package:chatorai/features/settings/screens/skills_screen.dart';
import 'package:chatorai/features/settings/screens/stats_screen.dart';
import 'package:chatorai/features/settings/widgets/settings_about_section.dart';
import 'package:chatorai/features/settings/widgets/settings_appearance_section.dart';
import 'package:chatorai/features/settings/widgets/settings_accessibility_section.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// SETTINGS WINDOW (desktop two-column shell)
// ===========================================================================

class _SettingsCategorySpec {
  final IconData icon;
  final String Function(AppLocalizations) label;
  final Widget Function(BuildContext) builder;
  final List<Widget>? headerActions;

  const _SettingsCategorySpec({
    required this.icon,
    required this.label,
    required this.builder,
    this.headerActions,
  });
}

class SettingsWindow extends StatefulWidget {
  const SettingsWindow({super.key});

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  int _selectedIndex = 0;
  final _mcpServersKey = GlobalKey<State<McpServersScreen>>();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final palette = ChatoraiSettingsWindow.of(context);
    final categories = _categories(localizations);

    return Column(
      children: [
        _TopBar(palette: palette, onClose: () => Navigator.pop(context)),
        _HairlineDivider(color: palette.divider),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryNav(
                palette: palette,
                categories: categories,
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
              _HairlineDivider(color: palette.divider),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ChatoraiSettingsWindow.contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PaneHeader(
                          title: categories[_selectedIndex].label(
                            localizations,
                          ),
                          palette: palette,
                          actions: categories[_selectedIndex].headerActions,
                        ),
                        _HairlineDivider(color: palette.divider),
                        Expanded(
                          key: ValueKey(_selectedIndex),
                          child: categories[_selectedIndex].builder(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_SettingsCategorySpec> _categories(AppLocalizations l10n) => [
    _SettingsCategorySpec(
      icon: Icons.api,
      label: (_) => l10n.providers,
      builder: (_) => const ProviderSettingsScreen(embedded: true),
      headerActions: [
        Consumer(
          builder: (context, ref, _) {
            return Padding(
              padding: const EdgeInsets.only(right: ChatoraiSpacing.sm),
              child: FilledButton.icon(
                onPressed: () => showAddProviderDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addProvider),
                style: FilledButton.styleFrom(
                  backgroundColor: ChatoraiColors.orange,
                  foregroundColor: ChatoraiColors.pureWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChatoraiSpacing.md,
                    vertical: ChatoraiSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ChatoraiBorderRadius.sm,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    _SettingsCategorySpec(
      icon: Icons.bar_chart,
      label: (_) => l10n.usageStatistics,
      builder: (_) => const StatsScreen(embedded: true),
    ),
    _SettingsCategorySpec(
      icon: Icons.settings,
      label: (_) => l10n.configuration,
      builder: (_) => const ConfigScreen(embedded: true),
    ),
    _SettingsCategorySpec(
      icon: Icons.extension,
      label: (_) => l10n.mcpServers,
      builder: (_) => McpServersScreen(embedded: true, key: _mcpServersKey),
      headerActions: [
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.mcpTooltipAdd,
            onPressed: () {
              final state = _mcpServersKey.currentState;
              if (state != null) {
                (state as dynamic)._showAddDialog();
              }
            },
          ),
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.mcpTooltipRefresh,
            onPressed: () {
              final state = _mcpServersKey.currentState;
              if (state != null) {
                (state as dynamic)._onRefresh();
              }
            },
          ),
        ),
      ],
    ),
    _SettingsCategorySpec(
      icon: Icons.description_outlined,
      label: (_) => l10n.agentsInstructions,
      builder: (_) => const AgentsInstructionsScreen(embedded: true),
    ),
    _SettingsCategorySpec(
      icon: Icons.auto_awesome_outlined,
      label: (_) => l10n.skillsTitle,
      builder: (_) => const SkillsScreen(embedded: true),
    ),
    _SettingsCategorySpec(
      icon: Icons.palette_outlined,
      label: (_) => l10n.appearance,
      builder: (_) => const SingleChildScrollView(
        padding: EdgeInsets.all(ChatoraiSpacing.lg),
        child: SettingsAppearanceSection(showHeader: false),
      ),
    ),
    _SettingsCategorySpec(
      icon: Icons.accessibility_new,
      label: (_) => l10n.accessibility,
      builder: (_) => const SingleChildScrollView(
        padding: EdgeInsets.all(ChatoraiSpacing.lg),
        child: SettingsAccessibilitySection(showHeader: false),
      ),
    ),
    _SettingsCategorySpec(
      icon: Icons.info,
      label: (_) => l10n.appInfo,
      builder: (_) => const SingleChildScrollView(
        padding: EdgeInsets.all(ChatoraiSpacing.lg),
        child: SettingsAboutSection(),
      ),
    ),
  ];
}

// ===========================================================================
// TOP BAR
// ===========================================================================
class _TopBar extends StatelessWidget {
  final ChatoraiSettingsWindowColors palette;
  final VoidCallback onClose;

  const _TopBar({required this.palette, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return SizedBox(
      height: ChatoraiSettingsWindow.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(
              Icons.settings,
              size: ChatoraiIconSizes.lg,
              color: palette.indicator,
            ),
            const SizedBox(width: ChatoraiSpacing.md),
            Expanded(
              child: Text(
                localizations.settings,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.xl,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            _ToolbarIconButton(
              icon: Icons.close,
              tooltip: localizations.close,
              onPressed: onClose,
              palette: palette,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ChatoraiSettingsWindowColors palette;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: ChatoraiIconSizes.md, color: palette.icon),
        ),
      ),
    );
  }
}

// ===========================================================================
// HAIRLINE DIVIDER
// ===========================================================================
class _HairlineDivider extends StatelessWidget {
  final Color color;
  const _HairlineDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(height: ChatoraiBorderWidth.thin, color: color);
  }
}

// ===========================================================================
// CATEGORY NAV (left column)
// ===========================================================================
class _CategoryNav extends StatelessWidget {
  final ChatoraiSettingsWindowColors palette;
  final List<_SettingsCategorySpec> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CategoryNav({
    required this.palette,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ChatoraiSettingsWindow.navWidth,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          vertical: ChatoraiSpacing.sm,
          horizontal: ChatoraiSpacing.sm,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return _NavItem(
            spec: categories[index],
            selected: selected,
            palette: palette,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _SettingsCategorySpec spec;
  final bool selected;
  final ChatoraiSettingsWindowColors palette;
  final VoidCallback onTap;

  const _NavItem({
    required this.spec,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bg = selected ? palette.navItemSelected : null;
    final textColor = selected ? palette.text : palette.icon;
    final iconColor = selected ? palette.indicator : palette.icon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      child: AnimatedContainer(
        duration: ChatoraiDurations.fast,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.md,
            vertical: ChatoraiSpacing.sm,
          ),
          child: Row(
            children: [
              if (selected)
                Container(
                  width: ChatoraiBorderWidth.bold,
                  height: 20,
                  decoration: BoxDecoration(
                    color: palette.indicator,
                    borderRadius: BorderRadius.circular(
                      ChatoraiBorderWidth.bold,
                    ),
                  ),
                )
              else
                const SizedBox(width: ChatoraiBorderWidth.bold),
              const SizedBox(width: ChatoraiSpacing.sm),
              Icon(spec.icon, size: ChatoraiIconSizes.md, color: iconColor),
              const SizedBox(width: ChatoraiSpacing.sm),
              Expanded(
                child: Text(
                  spec.label(localizations),
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.base,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// PANE HEADER
// ===========================================================================
class _PaneHeader extends StatelessWidget {
  final String title;
  final ChatoraiSettingsWindowColors palette;
  final List<Widget>? actions;

  const _PaneHeader({required this.title, required this.palette, this.actions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ChatoraiSettingsWindow.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.xxl,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            if (actions != null) ...?actions,
          ],
        ),
      ),
    );
  }
}
