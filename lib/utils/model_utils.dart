import 'package:chatorai/models/chat_model.dart';

/// Utility functions for model-related operations
class ModelUtils {
  /// Remove duplicate models by ID, keeping the first occurrence
  static List<ChatModel> deduplicateModels(List<ChatModel> models) {
    final Map<String, ChatModel> uniqueModels = {};
    for (final model in models) {
      uniqueModels[model.id] = model;
    }
    return uniqueModels.values.toList();
  }
}
