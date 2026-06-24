import 'package:chatorai/features/chat/data/models/model_card_model.dart';
import 'package:chatorai/features/models/screens/models_screen.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

// ===========================================================================
// WIDGET CLASS
// ===========================================================================

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String selectedModel;
  final ChatModel? selectedModelObject;
  final bool Function() hasHeadings;
  final VoidCallback onToggleNavigator;
  final Function(String modelId, ChatModel? modelObject) onModelSelected;
  final VoidCallback? onMenuPressed;

  const ChatAppBar({
    super.key,
    required this.selectedModel,
    this.selectedModelObject,
    required this.hasHeadings,
    required this.onToggleNavigator,
    required this.onModelSelected,
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
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModelsScreen(
              onModelSelected: (String modelId, ChatModel? modelObject) {
                onModelSelected(modelId, modelObject);
              },
              currentModel: selectedModel,
            ),
          ),
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
    );
  }
}
