import 'package:chatorai/services/openrouter/openrouter_service.dart';

/// Utility functions for model-related operations
class ModelUtils {
  /// Remove duplicate models by ID, keeping the first occurrence
  static List<OpenRouterModel> deduplicateModels(List<OpenRouterModel> models) {
    final Map<String, OpenRouterModel> uniqueModels = {};
    for (final model in models) {
      uniqueModels[model.id] = model;
    }
    return uniqueModels.values.toList();
  }
}
