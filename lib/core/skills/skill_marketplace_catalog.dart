/// Functional category used to group marketplace skills and power the category
/// filter chips.
enum SkillCategory {
  coding('coding'),
  writing('writing'),
  research('research'),
  design('design'),
  productivity('productivity'),
  data('data'),
  other('other');

  const SkillCategory(this.value);
  final String value;
}

/// How a marketplace skill is delivered / installed.
enum SkillDelivery { bundled, url }

/// A preconfigured, ready-to-install skill shown in the Marketplace tab.
///
/// Two flavors, kept in one type so the UI renders them uniformly:
/// - [SkillDelivery.bundled]: shipped inside the app as an asset
///   (`assets/skills/<assetSlug>/SKILL.md`); installs fully offline by copying
///   the asset into the chosen scope root.
/// - [SkillDelivery.url]: fetched from a remote `index.json` via the existing
///   [UrlSource] download pipeline; may be auth-gated ([requiresToken]).
///
/// Instances are static data (no network at construction), so the catalog stays
/// trivial to extend — add an entry here plus a localized `descriptionKey` in
/// the ARB files.
class SkillMarketplaceEntry {
  /// Stable identifier; for bundled skills this equals the installed directory
  /// slug, so it doubles as the "is installed" key.
  final String id;
  final String displayName;
  final SkillCategory category;
  final SkillDelivery delivery;

  /// Asset directory slug under `assets/skills/`. Required for bundled entries.
  final String? assetSlug;

  /// Remote `index.json` base URL. Required for URL entries.
  final String? url;

  /// True when the URL source needs an API key/token to fetch.
  final bool requiresToken;

  /// ARB key identifying this entry's localized one-line description. Resolved
  /// in the UI layer (via [SkillMarketplaceL10n]) so this catalog stays a pure,
  /// Flutter-free data source.
  final String descriptionKey;

  const SkillMarketplaceEntry.bundled({
    required this.id,
    required this.displayName,
    required this.category,
    required String this.assetSlug,
    required this.descriptionKey,
  }) : delivery = SkillDelivery.bundled,
       url = null,
       requiresToken = false;

  const SkillMarketplaceEntry.url({
    required this.id,
    required this.displayName,
    required this.category,
    required String this.url,
    required this.descriptionKey,
    this.requiresToken = false,
  }) : delivery = SkillDelivery.url,
       assetSlug = null;

  bool get isBundled => delivery == SkillDelivery.bundled;

  /// Absolute asset path to this bundled skill's `SKILL.md`.
  String get assetPath => 'assets/skills/$assetSlug/SKILL.md';
}

/// The built-in Skills Marketplace catalog.
///
/// Bundled entries ship as assets and install offline. URL entries (none yet —
/// the hybrid extension point) install through the remote `index.json`
/// pipeline. Keep `id` equal to `assetSlug` for bundled skills so the installed
/// directory name matches the "installed" lookup key.
const List<SkillMarketplaceEntry> skillMarketplaceCatalog = [
  // ---- Coding -------------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'code-reviewer',
    displayName: 'Code Reviewer',
    category: SkillCategory.coding,
    assetSlug: 'code-reviewer',
    descriptionKey: 'skillsMarketDescCodeReviewer',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'clean-code',
    displayName: 'Clean Code',
    category: SkillCategory.coding,
    assetSlug: 'clean-code',
    descriptionKey: 'skillsMarketDescCleanCode',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'dry',
    displayName: 'DRY',
    category: SkillCategory.coding,
    assetSlug: 'dry',
    descriptionKey: 'skillsMarketDescDry',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'architect-review',
    displayName: 'Architect Review',
    category: SkillCategory.coding,
    assetSlug: 'architect-review',
    descriptionKey: 'skillsMarketDescArchitectReview',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'backend-architect',
    displayName: 'Backend Architect',
    category: SkillCategory.coding,
    assetSlug: 'backend-architect',
    descriptionKey: 'skillsMarketDescBackendArchitect',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'flutter-expert',
    displayName: 'Flutter Expert',
    category: SkillCategory.coding,
    assetSlug: 'flutter-expert',
    descriptionKey: 'skillsMarketDescFlutterExpert',
  ),
  // ---- Writing ------------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'agents-md',
    displayName: 'AGENTS.md',
    category: SkillCategory.writing,
    assetSlug: 'agents-md',
    descriptionKey: 'skillsMarketDescAgentsMd',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'ux-copy',
    displayName: 'UX Copy',
    category: SkillCategory.writing,
    assetSlug: 'ux-copy',
    descriptionKey: 'skillsMarketDescUxCopy',
  ),
  // ---- Research -----------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'deep-research',
    displayName: 'Deep Research',
    category: SkillCategory.research,
    assetSlug: 'deep-research',
    descriptionKey: 'skillsMarketDescDeepResearch',
  ),
  // ---- Design -------------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'ui-ux-designer',
    displayName: 'UI/UX Designer',
    category: SkillCategory.design,
    assetSlug: 'ui-ux-designer',
    descriptionKey: 'skillsMarketDescUiUxDesigner',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'uxui-principles',
    displayName: 'UX/UI Principles',
    category: SkillCategory.design,
    assetSlug: 'uxui-principles',
    descriptionKey: 'skillsMarketDescUxuiPrinciples',
  ),
  // ---- Productivity -------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'commit',
    displayName: 'Commit',
    category: SkillCategory.productivity,
    assetSlug: 'commit',
    descriptionKey: 'skillsMarketDescCommit',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'tool-design',
    displayName: 'Tool Design',
    category: SkillCategory.productivity,
    assetSlug: 'tool-design',
    descriptionKey: 'skillsMarketDescToolDesign',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'product-manager',
    displayName: 'Product Manager',
    category: SkillCategory.productivity,
    assetSlug: 'product-manager',
    descriptionKey: 'skillsMarketDescProductManager',
  ),
  // ---- Data ---------------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'data-scientist',
    displayName: 'Data Scientist',
    category: SkillCategory.data,
    assetSlug: 'data-scientist',
    descriptionKey: 'skillsMarketDescDataScientist',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'database-optimizer',
    displayName: 'Database Optimizer',
    category: SkillCategory.data,
    assetSlug: 'database-optimizer',
    descriptionKey: 'skillsMarketDescDatabaseOptimizer',
  ),
  // ---- Other --------------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'debugger',
    displayName: 'Debugger',
    category: SkillCategory.other,
    assetSlug: 'debugger',
    descriptionKey: 'skillsMarketDescDebugger',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'security-auditor',
    displayName: 'Security Auditor',
    category: SkillCategory.other,
    assetSlug: 'security-auditor',
    descriptionKey: 'skillsMarketDescSecurityAuditor',
  ),
];

/// Distinct categories present in [skillMarketplaceCatalog], in a stable order
/// for rendering filter chips.
List<SkillCategory> skillMarketplaceCategories() {
  final seen = <SkillCategory>{};
  for (final e in skillMarketplaceCatalog) {
    seen.add(e.category);
  }
  return SkillCategory.values.where((c) => seen.contains(c)).toList();
}
