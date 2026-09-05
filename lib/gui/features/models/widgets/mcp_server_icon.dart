import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Resolves and renders an icon for an MCP server by its name/id.
///
/// Uses the same asset set as [ProviderIcon] but renders the source in its
/// natural colors (no monochrome tint) so brand-colored PNG/SVG assets show
/// correctly on the MCP cards. Falls back to a generic extension icon.
class McpServerIcon extends StatelessWidget {
  final String? serverId;
  final double size;

  const McpServerIcon({super.key, this.serverId, this.size = 28});

  static const _iconMap = {
    'context7': 'assets/provider/context7-color.svg',
    'codegraph': 'assets/provider/codegraph-color.svg',
    'exa': 'assets/provider/exa-color.svg',
    'searxng': 'assets/provider/searxng.svg',
    'sequential-thinking': 'assets/provider/sequential-thinking.svg',
    'tavily': 'assets/provider/tavily-color.svg',
    'hugging-face': 'assets/provider/huggingface-icon.svg',
    'parallel': 'assets/provider/parallel-color.svg',
    'github': 'assets/provider/githubcopilot.svg',
    'postman': 'assets/provider/postman-color.svg',
    'slack': 'assets/provider/slack-color.svg',
    'figma': 'assets/provider/figma-color.svg',
    'canva': 'assets/provider/canva-icon.svg',
    'stripe': 'assets/provider/stripe-payment-icon.svg',
    'trivago': 'assets/provider/trivago-color.svg',
    'send': 'assets/provider/send-color.svg',
    'ziprecruiter': 'assets/provider/ziprecruiter-color.svg',
    'adobe-creativity': 'assets/provider/adobe-color.svg',
  };

  @override
  Widget build(BuildContext context) {
    final id = serverId?.toLowerCase();
    final path = id != null ? _iconMap[id] : null;

    if (path == null) {
      final iconColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black;
      return Icon(Icons.extension_outlined, size: size, color: iconColor);
    }

    if (path.endsWith('.svg')) {
      return SvgPicture.asset(path, width: size, height: size);
    }
    return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
  }
}
