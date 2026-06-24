import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProviderIcon extends StatelessWidget {
  final String? providerId;
  final double size;
  final Color? color;

  const ProviderIcon({super.key, this.providerId, this.size = 28, this.color});

  static const _iconMap = {
    '302ai': 'assets/provider/ai302.svg',
    'alibaba': 'assets/provider/alibaba-icon.svg',
    'amazon-bedrock': 'assets/provider/bedrock-color.svg',
    'anthropic': 'assets/provider/anthropic.svg',
    'azure': 'assets/provider/azure-ai-icon.svg',
    'baseten': 'assets/provider/baseten.svg',
    'cerebras': 'assets/provider/cerebras-color.svg',
    'cloudflare-ai-gateway': 'assets/provider/cloudflare-color.svg',
    'cloudflare-workers-ai': 'assets/provider/cloudflare-icon.svg',
    'cohere': 'assets/provider/cohere-color.svg',
    'deepinfra': 'assets/provider/deepinfra-color.svg',
    'deepseek': 'assets/provider/deepseek-color.svg',
    'fireworks': 'assets/provider/fireworks-color.svg',
    'github-copilot': 'assets/provider/githubcopilot.svg',
    'gitlab': 'assets/provider/gitlab-icon.svg',
    'google': 'assets/provider/google-gemini-icon.svg',
    'google-vertex': 'assets/provider/vertexai-color.svg',
    'groq': 'assets/provider/groq-icon.svg',
    'huggingface': 'assets/provider/huggingface-icon.svg',
    'kilo': 'assets/provider/kilocode.svg',
    'lmstudio': 'assets/provider/lmstudio.svg',
    'mistral': 'assets/provider/mistral-ai-icon.svg',
    'novita': 'assets/provider/novita-color.svg',
    'nvidia': 'assets/provider/nvidia-icon.svg',
    'ollama': 'assets/provider/ollama-icon.svg',
    'openai': 'assets/provider/openai-icon.svg',
    'openai-compatible': 'assets/provider/openai-icon.svg',
    'opencode': 'assets/provider/opencode.svg',
    'openrouter': 'assets/provider/openrouter-icon.svg',
    'perplexity': 'assets/provider/perplexity-ai-icon.svg',
    'togetherai': 'assets/provider/together-color.svg',
    'venice': 'assets/provider/venice.svg',
    'vercel': 'assets/provider/vercel-icon.svg',
    'vllm': 'assets/provider/vllm-color.svg',
    'xai': 'assets/provider/xai.svg',
    'zenmux': 'assets/provider/zenmux.svg',
  };

  @override
  Widget build(BuildContext context) {
    final path = providerId != null
        ? _iconMap[providerId!.toLowerCase()]
        : null;
    final iconColor =
        color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black);

    if (path != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        child: SvgPicture.asset(path, width: size, height: size),
      );
    }

    return Icon(Icons.smart_toy_outlined, size: size, color: iconColor);
  }
}
