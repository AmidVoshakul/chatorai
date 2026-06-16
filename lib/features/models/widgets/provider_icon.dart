import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProviderIcon extends StatelessWidget {
  final String? providerId;
  final double size;
  final Color? color;

  const ProviderIcon({super.key, this.providerId, this.size = 28, this.color});

  static const _iconMap = {
    'ai302': 'assets/provider/ai302.svg',
    'alibaba': 'assets/provider/alibaba-icon.svg',
    'amazon': 'assets/provider/amazon-icon.svg',
    'anthropic': 'assets/provider/claude-ai-icon.svg',
    'azure': 'assets/provider/azure-ai-icon.svg',
    'cloudflare': 'assets/provider/cloudflare-icon.svg',
    'deepseek': 'assets/provider/huggingface-icon.svg',
    'gitlab': 'assets/provider/gitlab-icon.svg',
    'google': 'assets/provider/google-gemini-icon.svg',
    'groq': 'assets/provider/groq-icon.svg',
    'huggingface': 'assets/provider/huggingface-icon.svg',
    'lmstudio': 'assets/provider/lmstudio.svg',
    'mistral': 'assets/provider/mistral-ai-icon.svg',
    'novita': 'assets/provider/novita-color.svg',
    'nvidia': 'assets/provider/nvidia-icon.svg',
    'ollama': 'assets/provider/ollama-icon.svg',
    'openai': 'assets/provider/openai-icon.svg',
    'openrouter': 'assets/provider/openrouter-icon.svg',
    'perplexity': 'assets/provider/perplexity-ai-icon.svg',
    'speedai': 'assets/provider/speedai-color.svg',
    'vercel': 'assets/provider/vercel-icon.svg',
    'vllm': 'assets/provider/vllm-color.svg',
    'xai': 'assets/provider/xai.svg',
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
