import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/l10n/app_localizations.dart';

/// Functional category used to group marketplace servers and power the
/// category filter chips.
enum McpCategory {
  search('search'),
  docs('docs'),
  design('design'),
  dev('dev'),
  finance('finance'),
  travel('travel'),
  jobs('jobs'),
  productivity('productivity'),
  social('social'),
  other('other');

  const McpCategory(this.value);
  final String value;
}

/// A preconfigured, ready-to-install MCP server shown in the Marketplace tab.
///
/// Instances are static data (no network), so the UI can render instantly and
/// the catalog stays easy to extend — add an entry here and a localized
/// `descriptionKey` in the ARB files.
class McpMarketplaceEntry {
  final String id;
  final String displayName;
  final String url;
  final McpCategory category;
  final String descriptionKey;
  final String? iconAsset;
  final String brandColor;

  /// True when the server requires an API key/token to function (auth-gated).
  /// Such entries install without a token and prompt for one later from the
  /// Installed tab; the Marketplace surfaces this with a "needs key" badge.
  final bool requiresToken;

  const McpMarketplaceEntry({
    required this.id,
    required this.displayName,
    required this.url,
    required this.category,
    required this.descriptionKey,
    this.iconAsset,
    required this.brandColor,
    this.requiresToken = false,
  });

  /// Builds the [McpServerConfig] exactly as a manual "remote" add would,
  /// without a token (public servers work as-is; auth-gated ones can be
  /// edited later from the Installed tab).
  McpServerConfig toConfig() => McpServerConfig.remote(url: url, enabled: true);

  /// Resolves the localized description for this entry.
  String description(AppLocalizations l10n) {
    return switch (id) {
      'exa' => l10n.mcpMarketDescExa,
      'context7' => l10n.mcpMarketDescContext7,
      'hugging-face' => l10n.mcpMarketDescHuggingFace,
      'parallel' => l10n.mcpMarketDescParallel,
      'tavily' => l10n.mcpMarketDescTavily,
      'github' => l10n.mcpMarketDescGithub,
      'postman' => l10n.mcpMarketDescPostman,
      'slack' => l10n.mcpMarketDescSlack,
      'figma' => l10n.mcpMarketDescFigma,
      'canva' => l10n.mcpMarketDescCanva,
      'stripe' => l10n.mcpMarketDescStripe,
      'trivago' => l10n.mcpMarketDescTrivago,
      'send' => l10n.mcpMarketDescSend,
      'ziprecruiter' => l10n.mcpMarketDescZiprecruiter,
      'adobe-creativity' => l10n.mcpMarketDescAdobeCreativity,
      _ => '',
    };
  }
}

/// The built-in MCP Marketplace catalog.
///
/// Every entry was verified reachable at catalog creation time. Auth-gated
/// servers (returning 401/403 on an unauthenticated `initialize`) are kept
/// intentionally: they install without a token and prompt for one later from
/// the Installed tab.
const List<McpMarketplaceEntry> mcpMarketplaceCatalog = [
  McpMarketplaceEntry(
    id: 'exa',
    displayName: 'Exa',
    url: 'https://mcp.exa.ai/mcp',
    category: McpCategory.search,
    descriptionKey: 'mcpMarketDescExa',
    brandColor: '#7C5CFF',
  ),
  McpMarketplaceEntry(
    id: 'context7',
    displayName: 'Context7',
    url: 'https://mcp.context7.com/mcp',
    category: McpCategory.docs,
    descriptionKey: 'mcpMarketDescContext7',
    brandColor: '#1A73E8',
  ),
  McpMarketplaceEntry(
    id: 'hugging-face',
    displayName: 'Hugging Face',
    url: 'https://huggingface.co/mcp',
    category: McpCategory.dev,
    descriptionKey: 'mcpMarketDescHuggingFace',
    iconAsset: 'assets/provider/huggingface-icon.svg',
    brandColor: '#FFD21E',
  ),
  McpMarketplaceEntry(
    id: 'parallel',
    displayName: 'Parallel',
    url: 'https://search.parallel.ai/mcp',
    category: McpCategory.search,
    descriptionKey: 'mcpMarketDescParallel',
    brandColor: '#0EA5A4',
  ),
  McpMarketplaceEntry(
    id: 'tavily',
    displayName: 'Tavily',
    url: 'https://mcp.tavily.com/mcp',
    category: McpCategory.search,
    descriptionKey: 'mcpMarketDescTavily',
    brandColor: '#008080',
  ),
  McpMarketplaceEntry(
    id: 'github',
    displayName: 'GitHub',
    url: 'https://api.githubcopilot.com/mcp/',
    category: McpCategory.dev,
    descriptionKey: 'mcpMarketDescGithub',
    iconAsset: 'assets/provider/githubcopilot.svg',
    brandColor: '#6A737D',
    requiresToken: true,
  ),
  McpMarketplaceEntry(
    id: 'postman',
    displayName: 'Postman',
    url: 'https://mcp.postman.com/minimal',
    category: McpCategory.dev,
    descriptionKey: 'mcpMarketDescPostman',
    brandColor: '#FF6C37',
    requiresToken: true,
  ),
  McpMarketplaceEntry(
    id: 'slack',
    displayName: 'Slack',
    url: 'https://mcp.slack.com/mcp',
    category: McpCategory.social,
    descriptionKey: 'mcpMarketDescSlack',
    brandColor: '#611F69',
    requiresToken: true,
  ),
  McpMarketplaceEntry(
    id: 'figma',
    displayName: 'Figma',
    url: 'https://mcp.figma.com/mcp',
    category: McpCategory.design,
    descriptionKey: 'mcpMarketDescFigma',
    brandColor: '#A259FF',
    requiresToken: true,
  ),
  McpMarketplaceEntry(
    id: 'canva',
    displayName: 'Canva',
    url: 'https://mcp.canva.com/mcp',
    category: McpCategory.design,
    descriptionKey: 'mcpMarketDescCanva',
    brandColor: '#00C4CC',
  ),
  McpMarketplaceEntry(
    id: 'stripe',
    displayName: 'Stripe',
    url: 'https://mcp.stripe.com',
    category: McpCategory.finance,
    descriptionKey: 'mcpMarketDescStripe',
    brandColor: '#635BFF',
    requiresToken: true,
  ),
  McpMarketplaceEntry(
    id: 'trivago',
    displayName: 'Trivago',
    url: 'https://mcp.trivago.com/mcp',
    category: McpCategory.travel,
    descriptionKey: 'mcpMarketDescTrivago',
    brandColor: '#FF6E00',
    requiresToken: true,
  ),
  McpMarketplaceEntry(
    id: 'send',
    displayName: 'Send',
    url: 'https://www.send.co/mcp',
    category: McpCategory.productivity,
    descriptionKey: 'mcpMarketDescSend',
    brandColor: '#4F46E5',
    requiresToken: true,
  ),
  McpMarketplaceEntry(
    id: 'ziprecruiter',
    displayName: 'ZipRecruiter',
    url: 'https://api.ziprecruiter.com/mcp',
    category: McpCategory.jobs,
    descriptionKey: 'mcpMarketDescZiprecruiter',
    brandColor: '#2C3E50',
    requiresToken: true,
  ),
  McpMarketplaceEntry(
    id: 'adobe-creativity',
    displayName: 'Adobe',
    url: 'https://adobe-creativity.adobe.io/mcp',
    category: McpCategory.design,
    descriptionKey: 'mcpMarketDescAdobeCreativity',
    brandColor: '#FA0F00',
    requiresToken: true,
  ),
];

/// Distinct categories present in [mcpMarketplaceCatalog], in a stable order
/// for rendering filter chips.
List<McpCategory> marketplaceCategories() {
  final seen = <McpCategory>{};
  for (final e in mcpMarketplaceCatalog) {
    seen.add(e.category);
  }
  return McpCategory.values.where((c) => seen.contains(c)).toList();
}
