import 'package:chatorai/features/settings/screens/agents_instructions_screen.dart';
import 'package:chatorai/features/settings/screens/auto_approve_screen.dart';
import 'package:chatorai/features/settings/screens/config_screen.dart';
import 'package:chatorai/features/settings/screens/mcp_servers_screen.dart';
import 'package:chatorai/features/settings/screens/provider_settings_screen.dart';
import 'package:chatorai/features/settings/screens/skills_screen.dart';
import 'package:chatorai/features/settings/screens/stats_screen.dart';
import 'package:chatorai/features/settings/widgets/about_dialog.dart';
import 'package:chatorai/features/settings/widgets/settings_appearance_section.dart';
import 'package:chatorai/features/settings/widgets/settings_accessibility_section.dart';
import 'package:chatorai/features/settings/widgets/settings_section_header.dart';
import 'package:chatorai/features/settings/widgets/settings_selection_card.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// SETTINGS SCREEN
// ===========================================================================

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        centerTitle: true,
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ChatoraiSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(title: localizations.providerConfiguration),
            const SizedBox(height: ChatoraiSpacing.lg),
            SettingsSelectionCard(
              icon: Icons.api,
              title: localizations.providers,
              subtitle: localizations.manageProviders,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProviderSettingsScreen(),
                ),
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.xl),
            SettingsSelectionCard(
              icon: Icons.bar_chart,
              title: localizations.usageStatistics,
              subtitle: localizations.totalSessions,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.xl),
            SettingsSectionHeader(title: localizations.configuration),
            const SizedBox(height: ChatoraiSpacing.lg),
            SettingsSelectionCard(
              icon: Icons.settings,
              title: localizations.configuration,
              subtitle: localizations.configuration,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfigScreen()),
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.xl),
            SettingsSelectionCard(
              icon: Icons.extension,
              title: localizations.mcpServers,
              subtitle: localizations.settingsMcpSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const McpServersScreen()),
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.xl),
            SettingsSelectionCard(
              icon: Icons.description_outlined,
              title: localizations.agentsInstructions,
              subtitle: localizations.agentsInstructionsSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AgentsInstructionsScreen(),
                ),
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.md),
            SettingsSelectionCard(
              icon: Icons.auto_awesome_outlined,
              title: localizations.skillsTitle,
              subtitle: localizations.skillsSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SkillsScreen()),
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.xl),
            SettingsSelectionCard(
              icon: Icons.check_circle_outline,
              title: localizations.autoApproveTitle,
              subtitle: localizations.autoApproveSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AutoApproveScreen()),
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.xl),
            const SettingsAppearanceSection(),
            const SizedBox(height: ChatoraiSpacing.xl),
            const SettingsAccessibilitySection(),
            const SizedBox(height: ChatoraiSpacing.xl),
            SettingsSelectionCard(
              icon: Icons.info_outline,
              title: localizations.appInfo,
              subtitle: '',
              onTap: () => showSettingsAboutDialog(context, localizations),
            ),
            const SizedBox(height: ChatoraiSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
}
