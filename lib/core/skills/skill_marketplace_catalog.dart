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
/// trivial to extend — add an entry here. The one-line description is parsed
/// from the bundled skill's `SKILL.md` frontmatter, so no ARB keys are needed.
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

  /// Optional ARB key for a localized one-line description. Intentionally
  /// unused for bundled skills: descriptions are parsed at runtime from each
  /// skill's `SKILL.md` frontmatter (`SkillParser` → `SkillInfo.description`),
  /// which is always English. The field is kept only so the original 18
  /// entries with non-null `descriptionKey` values don't require a schema
  /// migration; the UI layer (`SkillMarketplaceL10n.localizedDescription`) now
  /// ignores it and falls back to [displayName].
  final String? descriptionKey;

  const SkillMarketplaceEntry.bundled({
    required this.id,
    required this.displayName,
    required this.category,
    required String this.assetSlug,
    this.descriptionKey,
  }) : delivery = SkillDelivery.bundled,
       url = null,
       requiresToken = false;

  const SkillMarketplaceEntry.url({
    required this.id,
    required this.displayName,
    required this.category,
    required String this.url,
    this.descriptionKey,
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
  ),
  SkillMarketplaceEntry.bundled(
    id: 'clean-code',
    displayName: 'Clean Code',
    category: SkillCategory.coding,
    assetSlug: 'clean-code',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'dry',
    displayName: 'DRY',
    category: SkillCategory.coding,
    assetSlug: 'dry',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'architect-review',
    displayName: 'Architect Review',
    category: SkillCategory.coding,
    assetSlug: 'architect-review',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'backend-architect',
    displayName: 'Backend Architect',
    category: SkillCategory.coding,
    assetSlug: 'backend-architect',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'flutter-expert',
    displayName: 'Flutter Expert',
    category: SkillCategory.coding,
    assetSlug: 'flutter-expert',
  ),
  // ---- Writing ------------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'agents-md',
    displayName: 'AGENTS.md',
    category: SkillCategory.writing,
    assetSlug: 'agents-md',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'ux-copy',
    displayName: 'UX Copy',
    category: SkillCategory.writing,
    assetSlug: 'ux-copy',
  ),
  // ---- Research -----------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'deep-research',
    displayName: 'Deep Research',
    category: SkillCategory.research,
    assetSlug: 'deep-research',
  ),
  // ---- Design -------------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'ui-ux-designer',
    displayName: 'UI/UX Designer',
    category: SkillCategory.design,
    assetSlug: 'ui-ux-designer',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'uxui-principles',
    displayName: 'UX/UI Principles',
    category: SkillCategory.design,
    assetSlug: 'uxui-principles',
  ),
  // ---- Productivity -------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'commit',
    displayName: 'Commit',
    category: SkillCategory.productivity,
    assetSlug: 'commit',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'tool-design',
    displayName: 'Tool Design',
    category: SkillCategory.productivity,
    assetSlug: 'tool-design',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'product-manager',
    displayName: 'Product Manager',
    category: SkillCategory.productivity,
    assetSlug: 'product-manager',
  ),
  // ---- Data ---------------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'data-scientist',
    displayName: 'Data Scientist',
    category: SkillCategory.data,
    assetSlug: 'data-scientist',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'database-optimizer',
    displayName: 'Database Optimizer',
    category: SkillCategory.data,
    assetSlug: 'database-optimizer',
  ),
  // ---- Other --------------------------------------------------------------
  SkillMarketplaceEntry.bundled(
    id: 'debugger',
    displayName: 'Debugger',
    category: SkillCategory.other,
    assetSlug: 'debugger',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'security-auditor',
    displayName: 'Security Auditor',
    category: SkillCategory.other,
    assetSlug: 'security-auditor',
  ),
  // ---- Coding (marketplace expansion) ----
  SkillMarketplaceEntry.bundled(
    id: 'test-driven-development',
    displayName: 'Test Driven Development',
    category: SkillCategory.coding,
    assetSlug: 'test-driven-development',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'systematic-debugging',
    displayName: 'Systematic Debugging',
    category: SkillCategory.coding,
    assetSlug: 'systematic-debugging',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'find-bugs',
    displayName: 'Find Bugs',
    category: SkillCategory.coding,
    assetSlug: 'find-bugs',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'code-simplifier',
    displayName: 'Code Simplifier',
    category: SkillCategory.coding,
    assetSlug: 'code-simplifier',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'dependency-upgrade',
    displayName: 'Dependency Upgrade',
    category: SkillCategory.coding,
    assetSlug: 'dependency-upgrade',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'docker-expert',
    displayName: 'Docker Expert',
    category: SkillCategory.coding,
    assetSlug: 'docker-expert',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'kubernetes-architect',
    displayName: 'Kubernetes Architect',
    category: SkillCategory.coding,
    assetSlug: 'kubernetes-architect',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'terraform-specialist',
    displayName: 'Terraform Specialist',
    category: SkillCategory.coding,
    assetSlug: 'terraform-specialist',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'git-advanced-workflows',
    displayName: 'Git Advanced Workflows',
    category: SkillCategory.coding,
    assetSlug: 'git-advanced-workflows',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'git-hooks-automation',
    displayName: 'Git Hooks Automation',
    category: SkillCategory.coding,
    assetSlug: 'git-hooks-automation',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'deployment-pipeline-design',
    displayName: 'Deployment Pipeline Design',
    category: SkillCategory.coding,
    assetSlug: 'deployment-pipeline-design',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'distributed-tracing',
    displayName: 'Distributed Tracing',
    category: SkillCategory.coding,
    assetSlug: 'distributed-tracing',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'incident-responder',
    displayName: 'Incident Responder',
    category: SkillCategory.coding,
    assetSlug: 'incident-responder',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'typescript-expert',
    displayName: 'Typescript Expert',
    category: SkillCategory.coding,
    assetSlug: 'typescript-expert',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'python-pro',
    displayName: 'Python Pro',
    category: SkillCategory.coding,
    assetSlug: 'python-pro',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'golang-pro',
    displayName: 'Golang Pro',
    category: SkillCategory.coding,
    assetSlug: 'golang-pro',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'rust-pro',
    displayName: 'Rust Pro',
    category: SkillCategory.coding,
    assetSlug: 'rust-pro',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'java-pro',
    displayName: 'Java Pro',
    category: SkillCategory.coding,
    assetSlug: 'java-pro',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'nodejs-best-practices',
    displayName: 'Nodejs Best Practices',
    category: SkillCategory.coding,
    assetSlug: 'nodejs-best-practices',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'graphql',
    displayName: 'GRAPHQL',
    category: SkillCategory.coding,
    assetSlug: 'graphql',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'sql-pro',
    displayName: 'SQL Pro',
    category: SkillCategory.coding,
    assetSlug: 'sql-pro',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'architecture-decision-records',
    displayName: 'Architecture Decision Records',
    category: SkillCategory.coding,
    assetSlug: 'architecture-decision-records',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'llm-structured-output',
    displayName: 'LLM Structured Output',
    category: SkillCategory.coding,
    assetSlug: 'llm-structured-output',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'multi-agent-patterns',
    displayName: 'Multi Agent Patterns',
    category: SkillCategory.coding,
    assetSlug: 'multi-agent-patterns',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'agent-memory-systems',
    displayName: 'Agent Memory Systems',
    category: SkillCategory.coding,
    assetSlug: 'agent-memory-systems',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'mcp-builder',
    displayName: 'MCP Builder',
    category: SkillCategory.coding,
    assetSlug: 'mcp-builder',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'llm-app-patterns',
    displayName: 'LLM App Patterns',
    category: SkillCategory.coding,
    assetSlug: 'llm-app-patterns',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'rag-engineer',
    displayName: 'RAG Engineer',
    category: SkillCategory.coding,
    assetSlug: 'rag-engineer',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'prompt-engineer',
    displayName: 'Prompt Engineer',
    category: SkillCategory.coding,
    assetSlug: 'prompt-engineer',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'skill-creator',
    displayName: 'Skill Creator',
    category: SkillCategory.coding,
    assetSlug: 'skill-creator',
  ),
  // ---- Design (marketplace expansion) ----
  SkillMarketplaceEntry.bundled(
    id: 'react-best-practices',
    displayName: 'REACT Best Practices',
    category: SkillCategory.design,
    assetSlug: 'react-best-practices',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'nextjs-best-practices',
    displayName: 'NEXTJS Best Practices',
    category: SkillCategory.design,
    assetSlug: 'nextjs-best-practices',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'angular-best-practices',
    displayName: 'Angular Best Practices',
    category: SkillCategory.design,
    assetSlug: 'angular-best-practices',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'sveltekit',
    displayName: 'SVELTEKIT',
    category: SkillCategory.design,
    assetSlug: 'sveltekit',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'astro',
    displayName: 'ASTRO',
    category: SkillCategory.design,
    assetSlug: 'astro',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'tailwind-patterns',
    displayName: 'Tailwind Patterns',
    category: SkillCategory.design,
    assetSlug: 'tailwind-patterns',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'shadcn',
    displayName: 'Shadcn',
    category: SkillCategory.design,
    assetSlug: 'shadcn',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'radix-ui-design-system',
    displayName: 'Radix UI Design System',
    category: SkillCategory.design,
    assetSlug: 'radix-ui-design-system',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'swiftui-expert-skill',
    displayName: 'Swiftui Expert Skill',
    category: SkillCategory.design,
    assetSlug: 'swiftui-expert-skill',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'android-jetpack-compose-expert',
    displayName: 'Android Jetpack Compose Expert',
    category: SkillCategory.design,
    assetSlug: 'android-jetpack-compose-expert',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'swift-concurrency-expert',
    displayName: 'Swift Concurrency Expert',
    category: SkillCategory.design,
    assetSlug: 'swift-concurrency-expert',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'mobile-design',
    displayName: 'Mobile Design',
    category: SkillCategory.design,
    assetSlug: 'mobile-design',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'brainstorming',
    displayName: 'Brainstorming',
    category: SkillCategory.design,
    assetSlug: 'brainstorming',
  ),
  // ---- Other (marketplace expansion) ----
  SkillMarketplaceEntry.bundled(
    id: 'api-security-best-practices',
    displayName: 'API Security Best Practices',
    category: SkillCategory.other,
    assetSlug: 'api-security-best-practices',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'backend-security-coder',
    displayName: 'Backend Security Coder',
    category: SkillCategory.other,
    assetSlug: 'backend-security-coder',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'frontend-security-coder',
    displayName: 'Frontend Security Coder',
    category: SkillCategory.other,
    assetSlug: 'frontend-security-coder',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'mobile-security-coder',
    displayName: 'Mobile Security Coder',
    category: SkillCategory.other,
    assetSlug: 'mobile-security-coder',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'threat-modeling-expert',
    displayName: 'Threat Modeling Expert',
    category: SkillCategory.other,
    assetSlug: 'threat-modeling-expert',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'pentest-checklist',
    displayName: 'Pentest Checklist',
    category: SkillCategory.other,
    assetSlug: 'pentest-checklist',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'semgrep-rule-creator',
    displayName: 'Semgrep Rule Creator',
    category: SkillCategory.other,
    assetSlug: 'semgrep-rule-creator',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'secrets-management',
    displayName: 'Secrets Management',
    category: SkillCategory.other,
    assetSlug: 'secrets-management',
  ),
  // ---- Writing (marketplace expansion) ----
  SkillMarketplaceEntry.bundled(
    id: 'readme',
    displayName: 'Readme',
    category: SkillCategory.writing,
    assetSlug: 'readme',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'copy-editing',
    displayName: 'Copy Editing',
    category: SkillCategory.writing,
    assetSlug: 'copy-editing',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'blog-writing-guide',
    displayName: 'Blog Writing Guide',
    category: SkillCategory.writing,
    assetSlug: 'blog-writing-guide',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'documentation-templates',
    displayName: 'Documentation Templates',
    category: SkillCategory.writing,
    assetSlug: 'documentation-templates',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'docs-architect',
    displayName: 'Docs Architect',
    category: SkillCategory.writing,
    assetSlug: 'docs-architect',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'design-md',
    displayName: 'Design Md',
    category: SkillCategory.writing,
    assetSlug: 'design-md',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'scientific-writing',
    displayName: 'Scientific Writing',
    category: SkillCategory.writing,
    assetSlug: 'scientific-writing',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'citation-management',
    displayName: 'Citation Management',
    category: SkillCategory.writing,
    assetSlug: 'citation-management',
  ),
  SkillMarketplaceEntry.bundled(
    id: 'copywriting',
    displayName: 'Copywriting',
    category: SkillCategory.writing,
    assetSlug: 'copywriting',
  ),
  // ---- Research (marketplace expansion) ----
  SkillMarketplaceEntry.bundled(
    id: 'web-scraper',
    displayName: 'Web Scraper',
    category: SkillCategory.research,
    assetSlug: 'web-scraper',
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
