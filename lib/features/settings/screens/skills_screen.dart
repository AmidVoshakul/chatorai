import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_marketplace_catalog.dart';
import 'package:chatorai/core/skills/skill_parser.dart';
import 'package:chatorai/features/settings/providers/skills_management_provider.dart';
import 'package:chatorai/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/markdown_styles.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Premium GUI for reviewing, creating, editing, deleting and installing skills
/// for both the Global (user-level) and Project scopes.
///
/// Backed by [skillsManagementProvider]; every change persists to disk and
/// invalidates the skill service so a running chat picks it up without a
/// restart.
class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  SkillsManagementNotifier get _notifier =>
      ref.read(skillsManagementProvider.notifier);

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _createSkill(SkillsScope scope) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<_NewSkillResult>(
      context: context,
      builder: (_) => const _NewSkillDialog(),
    );
    if (result == null) return;
    try {
      await _notifier.createSkill(
        scope: scope,
        name: result.name,
        description: result.description,
        content: result.content,
      );
      _showSuccess(l10n.skillsCreated);
    } catch (e) {
      _showError(l10n.skillsSaveError(e.toString()));
    }
  }

  Future<void> _installFromUrl(SkillsScope scope) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<_InstallUrlResult>(
      context: context,
      builder: (_) => const _InstallUrlDialog(),
    );
    if (result == null) return;
    try {
      final installed = await _notifier.installFromUrl(
        scope: scope,
        url: result.url,
        apiKey: result.apiKey,
      );
      if (installed.isEmpty) {
        _showInfo(l10n.skillsInstallNone);
      } else {
        _showSuccess(l10n.skillsInstalled(installed.length));
      }
    } catch (e) {
      _showError(l10n.skillsSaveError(e.toString()));
    }
  }

  Future<void> _installMarketEntry(
    SkillMarketplaceEntry entry,
    SkillsScope scope,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (entry.isBundled) {
        await _notifier.installBundled(scope: scope, entry: entry);
      } else {
        await _notifier.installUrlEntry(scope: scope, entry: entry);
      }
      _showSuccess(l10n.skillsInstalledToast(entry.displayName));
    } catch (e) {
      _showError(l10n.skillsSaveError(e.toString()));
    }
  }

  Future<void> _previewMarketEntry(SkillMarketplaceEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    String content;
    try {
      content = await _notifier.loadEntryContent(entry);
    } catch (e) {
      _showError(l10n.skillsSaveError(e.toString()));
      return;
    }
    if (!mounted) return;

    String? description;
    String body = content;
    try {
      final parsed = SkillParser.parse('${entry.id}/SKILL.md', content);
      description = parsed.description;
      body = parsed.content;
    } catch (_) {
      // Fall back to raw content when frontmatter cannot be parsed.
    }

    final supportsProject =
        ref.read(skillsManagementProvider).value?.supportsProjectScope ?? false;
    final scope = await showDialog<SkillsScope>(
      context: context,
      builder: (_) => _SkillPreviewDialog(
        entry: entry,
        description: description,
        body: body,
        supportsProject: supportsProject,
        installedGlobal: _notifier.isInstalled(
          scope: SkillsScope.global,
          entry: entry,
        ),
        installedProject:
            supportsProject &&
            _notifier.isInstalled(scope: SkillsScope.project, entry: entry),
      ),
    );
    if (scope == null) return;
    await _installMarketEntry(entry, scope);
  }

  Future<void> _openSkill(SkillInfo skill, {required bool managed}) async {
    final l10n = AppLocalizations.of(context)!;
    String initial;
    try {
      initial = await _notifier.readSkillFile(skill);
    } catch (e) {
      _showError(l10n.skillsSaveError(e.toString()));
      return;
    }
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => FileEditorDialog(
        title: skill.name,
        subtitle: skill.directory,
        initialContent: initial,
        readOnly: !managed,
        hintText: l10n.skillsContentHint,
      ),
    );
    if (result == null) return;
    try {
      await _notifier.saveSkillFile(skill, result);
      _showSuccess(l10n.skillsSaved);
    } catch (e) {
      _showError(l10n.skillsSaveError(e.toString()));
    }
  }

  Future<void> _confirmRemove(SkillInfo skill, SkillsScope scope) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.skillsRemoveTitle),
        content: Text(l10n.skillsRemoveContent(skill.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ChatoraiColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _notifier.deleteSkill(scope: scope, skill: skill);
      _showInfo(l10n.skillsRemoved);
    } catch (e) {
      _showError(l10n.skillsSaveError(e.toString()));
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    SnackbarUtils.showSuccessSnackBar(context: context, message: message);
  }

  void _showError(String message) {
    if (!mounted) return;
    SnackbarUtils.showErrorSnackBar(context: context, message: message);
  }

  void _showInfo(String message) {
    if (!mounted) return;
    SnackbarUtils.showInfoSnackBar(context: context, message: message);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncState = ref.watch(skillsManagementProvider);

    return asyncState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.skillsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.skillsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(ChatoraiSpacing.lg),
            child: Text(l10n.skillsSaveError(error.toString())),
          ),
        ),
      ),
      data: (state) => _buildScaffold(context, l10n, isDark, state),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    SkillsManagementState state,
  ) {
    final supportsProject = state.supportsProjectScope;

    final tabSpecs = <_TabSpec>[
      _TabSpec(
        icon: Icons.public_rounded,
        label: l10n.instructionsScopeGlobal,
        tooltip: l10n.skillsTabGlobalTooltip,
      ),
      if (supportsProject)
        _TabSpec(
          icon: Icons.folder_outlined,
          label: l10n.instructionsScopeProject,
          tooltip: l10n.skillsTabProjectTooltip,
        ),
      _TabSpec(
        icon: Icons.storefront_outlined,
        label: l10n.skillsMarketplaceTab,
        tooltip: l10n.skillsTabMarketplaceTooltip,
      ),
    ];

    final views = <Widget>[
      _ScopeView(
        scope: SkillsScope.global,
        data: state.global,
        isDark: isDark,
        onOpen: _openSkill,
        onCreate: _createSkill,
        onInstall: _installFromUrl,
        onRemove: _confirmRemove,
      ),
      if (supportsProject)
        _ScopeView(
          scope: SkillsScope.project,
          data: state.project,
          isDark: isDark,
          onOpen: _openSkill,
          onCreate: _createSkill,
          onInstall: _installFromUrl,
          onRemove: _confirmRemove,
        ),
      _MarketplaceView(
        isDark: isDark,
        supportsProject: supportsProject,
        isInstalled: (entry, scope) =>
            _notifier.isInstalled(scope: scope, entry: entry),
        loadDescriptions: _notifier.loadDescriptions,
        onInstall: _installMarketEntry,
        onPreview: _previewMarketEntry,
      ),
    ];

    return DefaultTabController(
      length: tabSpecs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.skillsTitle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: hairlineColor(isDark)),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Collapse to icon-only when the bar is too narrow to show
                  // every label comfortably (roughly < 120px per tab).
                  final iconOnly = constraints.maxWidth < tabSpecs.length * 120;
                  return TabBar(
                    indicatorColor: ChatoraiColors.orange,
                    dividerColor: Colors.transparent,
                    labelColor: titleColor(isDark),
                    unselectedLabelColor: subtleColor(isDark),
                    tabs: [
                      for (final spec in tabSpecs)
                        _ScopeTab(spec: spec, iconOnly: iconOnly),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        body: TabBarView(children: views),
      ),
    );
  }
}

/// Declarative description of a scope tab (icon + label + tooltip).
class _TabSpec {
  final IconData icon;
  final String label;
  final String tooltip;
  const _TabSpec({
    required this.icon,
    required this.label,
    required this.tooltip,
  });
}

/// A tab with the icon to the LEFT of the label (never stacked). On narrow
/// layouts [iconOnly] hides the label, keeping just the icon. Always wrapped in
/// a [Tooltip] so the meaning stays discoverable in both modes and languages.
class _ScopeTab extends StatelessWidget {
  final _TabSpec spec;
  final bool iconOnly;
  const _ScopeTab({required this.spec, required this.iconOnly});

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 48,
      child: Tooltip(
        message: spec.tooltip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(spec.icon, size: 20),
            if (!iconOnly) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Scope view (Global / Project tab body)
// =============================================================================

class _ScopeView extends StatelessWidget {
  final SkillsScope scope;
  final ScopeSkills data;
  final bool isDark;
  final void Function(SkillInfo, {required bool managed}) onOpen;
  final void Function(SkillsScope) onCreate;
  final void Function(SkillsScope) onInstall;
  final void Function(SkillInfo, SkillsScope) onRemove;

  const _ScopeView({
    required this.scope,
    required this.data,
    required this.isDark,
    required this.onOpen,
    required this.onCreate,
    required this.onInstall,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SectionTitle(
                title: l10n.skillsSectionTitle,
                helper: l10n.skillsSectionHelper,
                isDark: isDark,
              ),
            ),
            _AddMenu(
              onCreate: () => onCreate(scope),
              onInstall: () => onInstall(scope),
            ),
          ],
        ),
        const SizedBox(height: ChatoraiSpacing.md),
        if (data.skills.isEmpty)
          _EmptySkills(isDark: isDark)
        else
          CardGrid(
            children: [
              for (final skill in data.managed)
                _SkillCard(
                  skill: skill,
                  isDark: isDark,
                  managed: true,
                  onTap: () => onOpen(skill, managed: true),
                  onRemove: () => onRemove(skill, scope),
                ),
              for (final skill in data.readOnly)
                _SkillCard(
                  skill: skill,
                  isDark: isDark,
                  managed: false,
                  onTap: () => onOpen(skill, managed: false),
                  onRemove: null,
                ),
            ],
          ),
      ],
    );
  }
}

// =============================================================================
// Skill card + add menu + empty state
// =============================================================================

class _AddMenu extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onInstall;

  const _AddMenu({required this.onCreate, required this.onInstall});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<int>(
      tooltip: l10n.commonAdd,
      position: PopupMenuPosition.under,
      icon: const Icon(
        Icons.add_circle_rounded,
        color: ChatoraiColors.orange,
        size: ChatoraiIconSizes.xxl,
      ),
      onSelected: (v) => v == 0 ? onCreate() : onInstall(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 18),
              const SizedBox(width: ChatoraiSpacing.sm),
              Text(l10n.skillsNewSkill),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              const Icon(Icons.cloud_download_outlined, size: 18),
              const SizedBox(width: ChatoraiSpacing.sm),
              Text(l10n.skillsInstallFromUrl),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  final SkillInfo skill;
  final bool isDark;
  final bool managed;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _SkillCard({
    required this.skill,
    required this.isDark,
    required this.managed,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(ChatoraiSpacing.lg),
          decoration: premiumCard(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      skill.name,
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.lg,
                        fontWeight: FontWeight.w700,
                        color: titleColor(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (managed) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: ChatoraiIconSizes.lg,
                      color: subtleColor(isDark),
                      tooltip: l10n.commonEdit,
                      visualDensity: VisualDensity.compact,
                      onPressed: onTap,
                    ),
                    if (onRemove != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        iconSize: ChatoraiIconSizes.lg,
                        color: ChatoraiColors.error,
                        tooltip: l10n.commonRemove,
                        visualDensity: VisualDensity.compact,
                        onPressed: onRemove,
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                skill.description,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.sm,
                  height: 1.35,
                  color: subtleColor(isDark),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: ChatoraiSpacing.md),
              Wrap(
                spacing: ChatoraiSpacing.xs,
                runSpacing: ChatoraiSpacing.xs,
                children: [
                  if (skill.files.isNotEmpty)
                    PillBadge(
                      label: l10n.skillsFilesCount(skill.files.length),
                      color: ChatoraiColors.orange,
                      isDark: isDark,
                    ),
                  if (!managed)
                    PillBadge(
                      label: l10n.skillsReadOnly,
                      color: subtleColor(isDark),
                      isDark: isDark,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySkills extends StatelessWidget {
  final bool isDark;

  const _EmptySkills({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChatoraiSpacing.xxl),
      decoration: premiumCard(isDark),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: ChatoraiIconSizes.huge,
            color: subtleColor(isDark),
          ),
          const SizedBox(height: ChatoraiSpacing.md),
          Text(
            l10n.skillsEmpty,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.lg,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? ChatoraiColors.darkTextColor
                  : ChatoraiColors.lightTextColor,
            ),
          ),
          const SizedBox(height: ChatoraiSpacing.xs),
          Text(
            l10n.skillsEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.base,
              color: subtleColor(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Marketplace view
// =============================================================================

class _MarketplaceView extends StatefulWidget {
  final bool isDark;
  final bool supportsProject;
  final bool Function(SkillMarketplaceEntry, SkillsScope) isInstalled;
  final Future<Map<String, String>> Function(List<SkillMarketplaceEntry>)
  loadDescriptions;
  final void Function(SkillMarketplaceEntry, SkillsScope) onInstall;
  final void Function(SkillMarketplaceEntry) onPreview;

  const _MarketplaceView({
    required this.isDark,
    required this.supportsProject,
    required this.isInstalled,
    required this.loadDescriptions,
    required this.onInstall,
    required this.onPreview,
  });

  @override
  State<_MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<_MarketplaceView> {
  final _searchController = TextEditingController();
  String _query = '';
  SkillCategory? _category;

  /// Descriptions parsed from each bundled skill's `SKILL.md` frontmatter,
  /// keyed by entry id. Populated lazily; cards fall back to the localized
  /// description until the asset resolves.
  final Map<String, String> _descriptions = {};

  @override
  void initState() {
    super.initState();
    _loadDescriptions();
  }

  Future<void> _loadDescriptions() async {
    final bundled = skillMarketplaceCatalog
        .where((e) => e.isBundled)
        .toList(growable: false);
    final loaded = await widget.loadDescriptions(bundled);
    if (!mounted || loaded.isEmpty) return;
    setState(() => _descriptions.addAll(loaded));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryLabel(AppLocalizations l10n, SkillCategory c) {
    return switch (c) {
      SkillCategory.coding => l10n.skillsCategoryCoding,
      SkillCategory.writing => l10n.skillsCategoryWriting,
      SkillCategory.research => l10n.skillsCategoryResearch,
      SkillCategory.design => l10n.skillsCategoryDesign,
      SkillCategory.productivity => l10n.skillsCategoryProductivity,
      SkillCategory.data => l10n.skillsCategoryData,
      SkillCategory.other => l10n.skillsCategoryOther,
    };
  }

  List<SkillMarketplaceEntry> get _filtered {
    final q = _query.trim().toLowerCase();
    return skillMarketplaceCatalog.where((e) {
      if (_category != null && e.category != _category) return false;
      if (q.isEmpty) return true;
      return e.displayName.toLowerCase().contains(q) ||
          e.id.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = widget.isDark;
    final categories = skillMarketplaceCategories();
    final entries = _filtered;

    return ListView(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: l10n.skillsMarketplaceSearchHint,
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.md),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              CategoryChip(
                label: l10n.skillsCategoryAll,
                selected: _category == null,
                isDark: isDark,
                onTap: () => setState(() => _category = null),
              ),
              for (final c in categories) ...[
                const SizedBox(width: ChatoraiSpacing.xs),
                CategoryChip(
                  label: _categoryLabel(l10n, c),
                  selected: _category == c,
                  isDark: isDark,
                  onTap: () => setState(() => _category = c),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.md),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(ChatoraiSpacing.xxl),
            child: Center(
              child: Text(
                l10n.skillsMarketplaceEmpty,
                style: TextStyle(color: subtleColor(isDark)),
              ),
            ),
          )
        else
          CardGrid(
            children: [
              for (final entry in entries)
                _SkillMarketCard(
                  entry: entry,
                  isDark: isDark,
                  description: _descriptions[entry.id],
                  installedGlobal: widget.isInstalled(
                    entry,
                    SkillsScope.global,
                  ),
                  installedProject:
                      widget.supportsProject &&
                      widget.isInstalled(entry, SkillsScope.project),
                  supportsProject: widget.supportsProject,
                  onInstall: (scope) => widget.onInstall(entry, scope),
                  onOpen: () => widget.onPreview(entry),
                ),
            ],
          ),
      ],
    );
  }
}

class _SkillMarketCard extends StatelessWidget {
  final SkillMarketplaceEntry entry;
  final bool isDark;

  /// Description parsed from the skill's `SKILL.md` frontmatter. Falls back to
  /// the localized catalog description while the asset is still loading.
  final String? description;
  final bool installedGlobal;
  final bool installedProject;
  final bool supportsProject;
  final void Function(SkillsScope) onInstall;
  final VoidCallback onOpen;

  const _SkillMarketCard({
    required this.entry,
    required this.isDark,
    required this.description,
    required this.installedGlobal,
    required this.installedProject,
    required this.supportsProject,
    required this.onInstall,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final installed = installedGlobal || installedProject;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(ChatoraiSpacing.lg),
          decoration: premiumCard(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.displayName,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.lg,
                  fontWeight: FontWeight.w700,
                  color: titleColor(isDark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                description ?? entry.localizedDescription(l10n),
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.sm,
                  height: 1.35,
                  color: subtleColor(isDark),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: ChatoraiSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _InstallButton(
                  supportsProject: supportsProject,
                  installedGlobal: installedGlobal,
                  installedProject: installedProject,
                  installed: installed,
                  onInstall: onInstall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Install control: a plain button when only the global scope exists, or a
/// scope-picker popup (Global / Project) on desktop.
class _InstallButton extends StatelessWidget {
  final bool supportsProject;
  final bool installedGlobal;
  final bool installedProject;
  final bool installed;
  final void Function(SkillsScope) onInstall;

  const _InstallButton({
    required this.supportsProject,
    required this.installedGlobal,
    required this.installedProject,
    required this.installed,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Installed anywhere → mirror the MCP marketplace: a disabled, success-tinted
    // "Installed" button so the state reads at a glance.
    if (installed) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check, size: 18),
        label: Text(l10n.skillsInstalledBadge),
        style: OutlinedButton.styleFrom(
          foregroundColor: ChatoraiColors.success,
          side: BorderSide(color: ChatoraiColors.success.withAlpha(120)),
        ),
      );
    }

    if (!supportsProject) {
      return OutlinedButton.icon(
        style: _installButtonStyle(),
        onPressed: () => onInstall(SkillsScope.global),
        icon: const Icon(Icons.download_rounded, size: 18),
        label: Text(l10n.skillsInstallAction),
      );
    }

    return OutlinedButton.icon(
      style: _installButtonStyle(),
      onPressed: () => _showScopeMenu(context, l10n),
      icon: const Icon(Icons.download_rounded, size: 18),
      label: Text(l10n.skillsInstallAction),
    );
  }

  Future<void> _showScopeMenu(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final scope = await showMenu<SkillsScope>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: SkillsScope.global,
          child: Text(l10n.skillsInstallToGlobal),
        ),
        PopupMenuItem(
          value: SkillsScope.project,
          child: Text(l10n.skillsInstallToProject),
        ),
      ],
    );
    if (scope != null) onInstall(scope);
  }
}

/// Muted orange-outlined install button style: fills solid orange only on
/// hover/press/focus, so a grid of these does not overwhelm the eye at rest.
/// Shared by the card [_InstallButton] and the preview dialog for one look.
ButtonStyle _installButtonStyle() {
  bool active(Set<WidgetState> states) =>
      states.contains(WidgetState.pressed) ||
      states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.focused);

  return ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          active(states) ? ChatoraiColors.pureWhite : ChatoraiColors.orange,
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => active(states) ? ChatoraiColors.orange : null,
    ),
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    side: WidgetStateProperty.resolveWith(
      (states) => BorderSide(
        color: active(states)
            ? ChatoraiColors.orange
            : ChatoraiColors.orange.withAlpha(120),
      ),
    ),
  );
}

// =============================================================================
// Dialogs
// =============================================================================

/// Read-only preview of a marketplace skill's `SKILL.md`, with an Install
/// action at the bottom so the user can install right after reading. Pops a
/// [SkillsScope] on install, or `null` on close.
class _SkillPreviewDialog extends StatelessWidget {
  final SkillMarketplaceEntry entry;
  final String? description;
  final String body;
  final bool supportsProject;
  final bool installedGlobal;
  final bool installedProject;

  const _SkillPreviewDialog({
    required this.entry,
    required this.description,
    required this.body,
    required this.supportsProject,
    required this.installedGlobal,
    required this.installedProject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final installed = installedGlobal || installedProject;

    final screenSize = MediaQuery.of(context).size;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width < 600 ? 16 : 40,
        vertical: 24,
      ),
      constraints: BoxConstraints(
        maxWidth: screenSize.width < 600 ? screenSize.width - 32 : 640,
        maxHeight: screenSize.height * 0.8,
      ),
      title: Text(entry.displayName),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (description != null && description!.isNotEmpty) ...[
                Text(
                  description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(140),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: 16),
              ],
              MarkdownBody(
                data: body,
                selectable: true,
                styleSheet: ChatoraiMarkdownStyles.getMarkdownStyles(context),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.skillsPreviewClose),
        ),
        if (installed)
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.check, size: 18),
            label: Text(l10n.skillsInstalledBadge),
            style: OutlinedButton.styleFrom(
              foregroundColor: ChatoraiColors.success,
              side: BorderSide(color: ChatoraiColors.success.withAlpha(120)),
            ),
          )
        else if (!supportsProject)
          OutlinedButton.icon(
            style: _installButtonStyle(),
            onPressed: () => Navigator.pop(context, SkillsScope.global),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(l10n.skillsInstallAction),
          )
        else
          PopupMenuButton<SkillsScope>(
            tooltip: l10n.skillsInstallAction,
            position: PopupMenuPosition.under,
            onSelected: (scope) => Navigator.pop(context, scope),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: SkillsScope.global,
                child: Text(l10n.skillsInstallToGlobal),
              ),
              PopupMenuItem(
                value: SkillsScope.project,
                child: Text(l10n.skillsInstallToProject),
              ),
            ],
            child: IgnorePointer(
              child: OutlinedButton.icon(
                style: _installButtonStyle(),
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l10n.skillsInstallAction),
              ),
            ),
          ),
      ],
    );
  }
}

class _NewSkillResult {
  final String name;
  final String description;
  final String content;
  const _NewSkillResult(this.name, this.description, this.content);
}

class _NewSkillDialog extends StatefulWidget {
  const _NewSkillDialog();

  @override
  State<_NewSkillDialog> createState() => _NewSkillDialogState();
}

class _NewSkillDialogState extends State<_NewSkillDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width < 600 ? 16 : 40,
        vertical: 24,
      ),
      constraints: BoxConstraints(
        maxWidth: screenSize.width < 600 ? screenSize.width - 32 : 560,
        maxHeight: screenSize.height * 0.8,
      ),
      title: Text(l10n.skillsNewSkill),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.skillsNameLabel,
                  hintText: l10n.skillsNameHint,
                ),
              ),
              const SizedBox(height: ChatoraiSpacing.md),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: l10n.skillsDescriptionLabel,
                  hintText: l10n.skillsDescriptionHint,
                ),
              ),
              const SizedBox(height: ChatoraiSpacing.md),
              TextField(
                controller: _contentController,
                minLines: 6,
                maxLines: 14,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.code,
                ),
                decoration: InputDecoration(
                  labelText: l10n.skillsContentLabel,
                  hintText: l10n.skillsContentHint,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ChatoraiColors.orange,
            foregroundColor: ChatoraiColors.pureWhite,
          ),
          onPressed: () {
            final name = _nameController.text.trim();
            final desc = _descController.text.trim();
            if (name.isEmpty || desc.isEmpty) return;
            Navigator.pop(
              context,
              _NewSkillResult(name, desc, _contentController.text),
            );
          },
          child: Text(l10n.commonAdd),
        ),
      ],
    );
  }
}

class _InstallUrlResult {
  final String url;
  final String? apiKey;
  const _InstallUrlResult(this.url, this.apiKey);
}

class _InstallUrlDialog extends StatefulWidget {
  const _InstallUrlDialog();

  @override
  State<_InstallUrlDialog> createState() => _InstallUrlDialogState();
}

class _InstallUrlDialogState extends State<_InstallUrlDialog> {
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width < 600 ? 16 : 40,
        vertical: 24,
      ),
      constraints: BoxConstraints(
        maxWidth: screenSize.width < 600 ? screenSize.width - 32 : 520,
        maxHeight: screenSize.height * 0.8,
      ),
      title: Text(l10n.skillsInstallFromUrl),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.skillsUrlLabel,
                hintText: l10n.skillsUrlHint,
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.md),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.skillsApiKeyLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ChatoraiColors.orange,
            foregroundColor: ChatoraiColors.pureWhite,
          ),
          onPressed: () {
            final url = _urlController.text.trim();
            if (url.isEmpty) return;
            final apiKey = _apiKeyController.text.trim();
            Navigator.pop(
              context,
              _InstallUrlResult(url, apiKey.isEmpty ? null : apiKey),
            );
          },
          child: Text(l10n.commonAdd),
        ),
      ],
    );
  }
}

/// Resolves a marketplace entry's localized one-line description in the UI
/// layer, keeping [SkillMarketplaceEntry] a pure, Flutter-free data source.
///
/// Falls back to [SkillMarketplaceEntry.displayName] for any entry whose
/// [SkillMarketplaceEntry.descriptionKey] has no matching ARB string yet, so a
/// newly-added catalog entry never renders as blank text.
extension SkillMarketplaceL10n on SkillMarketplaceEntry {
  String localizedDescription(AppLocalizations l10n) {
    return switch (descriptionKey) {
      'skillsMarketDescCodeReviewer' => l10n.skillsMarketDescCodeReviewer,
      'skillsMarketDescCleanCode' => l10n.skillsMarketDescCleanCode,
      'skillsMarketDescDry' => l10n.skillsMarketDescDry,
      'skillsMarketDescArchitectReview' => l10n.skillsMarketDescArchitectReview,
      'skillsMarketDescBackendArchitect' =>
        l10n.skillsMarketDescBackendArchitect,
      'skillsMarketDescFlutterExpert' => l10n.skillsMarketDescFlutterExpert,
      'skillsMarketDescAgentsMd' => l10n.skillsMarketDescAgentsMd,
      'skillsMarketDescUxCopy' => l10n.skillsMarketDescUxCopy,
      'skillsMarketDescDeepResearch' => l10n.skillsMarketDescDeepResearch,
      'skillsMarketDescUiUxDesigner' => l10n.skillsMarketDescUiUxDesigner,
      'skillsMarketDescUxuiPrinciples' => l10n.skillsMarketDescUxuiPrinciples,
      'skillsMarketDescCommit' => l10n.skillsMarketDescCommit,
      'skillsMarketDescToolDesign' => l10n.skillsMarketDescToolDesign,
      'skillsMarketDescProductManager' => l10n.skillsMarketDescProductManager,
      'skillsMarketDescDataScientist' => l10n.skillsMarketDescDataScientist,
      'skillsMarketDescDatabaseOptimizer' =>
        l10n.skillsMarketDescDatabaseOptimizer,
      'skillsMarketDescDebugger' => l10n.skillsMarketDescDebugger,
      'skillsMarketDescSecurityAuditor' => l10n.skillsMarketDescSecurityAuditor,
      _ => displayName,
    };
  }
}
