import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/features/chat/data/models/chat_model.dart';

class ModelFeaturesWidget extends StatelessWidget {
  final ChatModel model;

  const ModelFeaturesWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _buildChip(
          context: context,
          label: model.isFree ? localizations.free : localizations.paid,
          color: model.isFree ? Colors.green : Colors.orange,
          icon: model.isFree ? Icons.attach_money : Icons.payment,
        ),
        if (model.supportsReasoning)
          _buildChip(
            context: context,
            label: localizations.reasoning,
            color: Colors.blue,
            icon: Icons.psychology,
          ),
        if (model.supportsMultimodal)
          _buildChip(
            context: context,
            label: localizations.multimodal,
            color: Colors.purple,
            icon: Icons.view_in_ar,
          ),
        if (model.capabilities.vision)
          _buildChip(
            context: context,
            label: localizations.vision,
            color: Colors.deepOrange,
            icon: Icons.visibility,
          ),
        if (model.capabilities.tools)
          _buildChip(
            context: context,
            label: localizations.tools,
            color: Colors.teal,
            icon: Icons.build,
          ),
        _buildChip(
          context: context,
          label: localizations.available,
          color: Colors.green,
          icon: Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
      labelStyle: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(icon, size: 14, color: color),
    );
  }
}
