import 'package:flutter/material.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/screens/models_screen.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String selectedModel;
  final OpenRouterModel? selectedModelObject;
  final bool Function() hasHeadings;
  final VoidCallback onToggleNavigator;
  final Function(String modelId, OpenRouterModel? modelObject) onModelSelected;

  const ChatAppBar({
    super.key,
    required this.selectedModel,
    this.selectedModelObject,
    required this.hasHeadings,
    required this.onToggleNavigator,
    required this.onModelSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    final modelTextColor = theme.brightness == Brightness.dark
        ? Colors.grey[700]
        : theme.iconTheme.color;

    return AppBar(
      title: Text(
        '',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: theme.canvasColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, size: 20),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        if (selectedModelObject == null)
          SizedBox(width: isMobile ? screenWidth * 0.50 : 0)
        else if (isMobile)
          SizedBox(
            width: screenWidth * 0.50,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  selectedModelObject!.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: modelTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              selectedModelObject!.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: modelTextColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        IconButton(
          icon: const Icon(Icons.smart_toy, size: 20),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModelsScreen(
                  onModelSelected:
                      (String modelId, OpenRouterModel? modelObject) {
                        onModelSelected(modelId, modelObject);
                      },
                  currentModel: selectedModel,
                ),
              ),
            );
          },
          tooltip:
              AppLocalizations.of(context)?.selectModelTooltip ??
              'Select Model',
        ),
        if (hasHeadings())
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.format_list_bulleted, size: 20),
              onPressed: onToggleNavigator,
              tooltip:
                  AppLocalizations.of(context)?.toggleNavigatorTooltip ??
                  'Toggle Navigator',
            ),
          ),
      ],
    );
  }
}
