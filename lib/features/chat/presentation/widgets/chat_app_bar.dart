import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:chatorai/features/models/screens/models_screen.dart';

// ===========================================================================
// WIDGET CLASS
// ===========================================================================

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String selectedModel;
  final ModelConfig? selectedModelObject;
  final bool Function() hasHeadings;
  final VoidCallback onToggleNavigator;
  final Function(String modelId, ModelConfig? modelObject) onModelSelected;
  final VoidCallback? onOpenModelSelector;
  final VoidCallback? onMenuPressed;

  const ChatAppBar({
    super.key,
    required this.selectedModel,
    this.selectedModelObject,
    required this.hasHeadings,
    required this.onToggleNavigator,
    required this.onModelSelected,
    this.onOpenModelSelector,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // =======================================================================
  // BUILD METHOD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final modelTextColor = isDark ? Colors.grey[700] : theme.iconTheme.color;
    final localizations = AppLocalizations.of(context)!;

    return AppBar(
      title: const Text(''),
      backgroundColor: theme.canvasColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, size: ChatoraiIconSizes.buttonIcon),
          onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
          tooltip: localizations.openMenuTooltip,
        ),
      ),
      actions: [
        if (selectedModelObject != null)
          _buildModelButton(context, modelTextColor),
        if (hasHeadings())
          IconButton(
            icon: Icon(
              Icons.format_list_bulleted,
              size: ChatoraiIconSizes.buttonIcon,
            ),
            onPressed: onToggleNavigator,
            tooltip: localizations.toggleNavigatorTooltip,
          ),
      ],
    );
  }

  Widget _buildModelButton(BuildContext context, Color? modelTextColor) {
    final localizations = AppLocalizations.of(context)!;
    return Tooltip(
      message: localizations.selectModelTooltip,
      child: TextButton(
        onPressed:
            onOpenModelSelector ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ModelsScreen()),
              );
            },
        child: Text(
          selectedModelObject!.name,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.sm,
            fontWeight: FontWeight.w600,
            color: modelTextColor,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
