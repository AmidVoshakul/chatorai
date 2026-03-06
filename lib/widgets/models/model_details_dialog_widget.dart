import 'package:flutter/material.dart';
import 'package:chatorai/themes/app_theme.dart' show ChatoraiColors;
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/services/openrouter_service.dart';

class ModelDetailsDialogWidget extends StatelessWidget {
  final OpenRouterModel model;

  const ModelDetailsDialogWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      scrollable: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge!.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            model.id,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall!.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, localizations.description),
          const SizedBox(height: 4),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? ChatoraiColors.darkBorderColor
                : ChatoraiColors.lightBorderColor,
          ),
          const SizedBox(height: 8),
          Text(
            model.description,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium!.color,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context, localizations.technicalDetails),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            localizations.provider,
            model.provider ?? '',
            Icons.account_circle,
          ),
          if (model.provider != null)
            _buildDetailRow(
              context,
              localizations.context,
              model.formattedContextLength,
              Icons.text_fields,
            ),
          _buildDetailRow(
            context,
            localizations.inputTokens,
            model.pricingPrompt != null
                ? '\$${model.pricingPrompt}/M'
                : localizations.notAvailable,
            Icons.attach_money,
          ),
          _buildDetailRow(
            context,
            localizations.outputTokens,
            model.pricingCompletion != null
                ? '\$${model.pricingCompletion}/M'
                : localizations.notAvailable,
            Icons.monetization_on,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context, localizations.features),
          const SizedBox(height: 4),
          Text(
            localizations.featuresDisplayedBasedOnActualModelCapabilities,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall!.color,
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureChips(context, localizations),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.close),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.titleMedium!.color,
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall!.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChips(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFeatureChip(
          label: model.isFree ? localizations.free : localizations.paid,
          enabled: true,
          color: model.isFree ? Colors.green : Colors.orange,
          icon: model.isFree ? Icons.attach_money : Icons.payment,
        ),
        if (model.supportsReasoning)
          _buildFeatureChip(
            label: localizations.reasoning,
            enabled: true,
            color: Colors.blue,
            icon: Icons.psychology,
          ),
        if (model.supportsMultimodal)
          _buildFeatureChip(
            label: localizations.multimodal,
            enabled: true,
            color: Colors.purple,
            icon: Icons.view_in_ar,
          ),
        if (model.capabilities.vision)
          _buildFeatureChip(
            label: localizations.vision,
            enabled: true,
            color: Colors.deepOrange,
            icon: Icons.visibility,
          ),
        if (model.capabilities.tools)
          _buildFeatureChip(
            label: localizations.tools,
            enabled: true,
            color: Colors.teal,
            icon: Icons.build,
          ),
      ],
    );
  }

  Widget _buildFeatureChip({
    required String label,
    required bool enabled,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: enabled ? color : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: enabled
            ? color.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.1),
        side: BorderSide(
          color: enabled
              ? color.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1.5,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        avatar: Icon(icon, size: 14, color: enabled ? color : Colors.grey[600]),
      ),
    );
  }
}

void showModelDetailsDialog(BuildContext context, OpenRouterModel model) {
  showDialog(
    context: context,
    builder: (BuildContext context) => ModelDetailsDialogWidget(model: model),
  );
}
