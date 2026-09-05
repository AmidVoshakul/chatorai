import 'package:chatorai/core/llm/models/model_config.dart';

/// Utility functions for model-related operations
class ModelUtils {
  /// Remove duplicate models by ID, keeping the first occurrence
  static List<ModelConfig> deduplicateModels(List<ModelConfig> models) {
    final Map<String, ModelConfig> uniqueModels = {};
    for (final model in models) {
      uniqueModels[model.id] = model;
    }
    return uniqueModels.values.toList();
  }
}
