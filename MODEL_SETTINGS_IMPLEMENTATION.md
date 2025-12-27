# Model Settings Implementation

## Overview
This implementation adds comprehensive model parameter settings to the chat application, allowing users to customize AI model behavior per model.

## Features Added

### 1. Settings Icon in Chat Input
- **Location**: Added next to the "+" button in both mobile and desktop layouts
- **Icon**: `settings_input_component_outlined`
- **Functionality**: Opens a draggable scrollable sheet with model settings

### 2. Model Settings Sheet
- **Type**: Draggable scrollable bottom sheet (mobile) / Modal (desktop)
- **Content**: Comprehensive parameter controls for the active model

#### Parameters Available:
- **Temperature** (0.0 - 2.0): Controls randomness
  - Lower = more focused, deterministic
  - Higher = more creative, random
- **Max Tokens** (1 - 8192): Maximum response length
- **Top P** (0.0 - 1.0): Nucleus sampling
  - Lower = more focused
  - Higher = more diverse
- **Frequency Penalty** (-2.0 - 2.0): Reduces repetition
- **Presence Penalty** (-2.0 - 2.0): Encourages new topics
- **System Prompt**: Custom instructions for the AI
- **Stream Response**: Toggle for real-time vs. complete responses

#### UI Features:
- Shows current values with visual indicators
- Displays API limits when available
- Real-time value display
- Reset to defaults button
- Apply settings button
- Responsive design for mobile and desktop

### 3. Data Model (`ModelSettings`)
```dart
class ModelSettings {
  final String modelId;
  final double temperature;
  final int maxTokens;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final String? systemPrompt;
  final bool stream;
  final int? maxContextLength;
  
  // API metadata
  final int? apiMaxTokens;
  final double? apiMaxTemperature;
  final double? apiMinTemperature;
  final int? apiContextLength;
}
```

### 4. Settings Provider (`ModelSettingsProvider`)
- **Persistence**: Uses SharedPreferences to save settings per model
- **Caching**: In-memory cache for performance
- **Active Model Management**: Tracks current model settings
- **API Integration**: Fetches model info from OpenRouter API

#### Key Methods:
- `loadSettings(modelId)`: Load settings for a model
- `saveSettings(settings)`: Persist settings
- `setActiveModel(modelId)`: Set current model
- `updateActiveSettings(settings)`: Update current settings
- `updateActiveParameter()`: Update individual parameters
- `resetActiveSettings()`: Reset to defaults
- `deleteSettings(modelId)`: Remove saved settings

### 5. Integration with Chat Flow
When sending a message:
1. ChatInput collects message and optional media
2. ChatScreen gets model settings from provider
3. Settings are applied to API request:
   - System prompt added to message history
   - All parameters passed to OpenRouter API
4. Response streamed with custom parameters

### 6. Localization
Added translations for all UI elements:
- **English**: `app_en.arb`
- **Russian**: `app_ru.arb`
- **Ukrainian**: `app_uk.arb`
- **Arabic**: `app_ar.arb`
- **Chinese**: `app_zh.arb`
- **Japanese**: `app_ja.arb`

## Usage Example

### Opening Settings
1. Select a model from the model selection screen
2. Tap the settings icon (⚙️) next to the "+" button
3. The settings sheet opens showing current parameters
4. Adjust parameters as needed
5. Tap "Apply Settings" to save

### API Integration
```dart
// Get settings for current model
final settingsProvider = context.read<ModelSettingsProvider>();
final settings = await settingsProvider.getSettings(modelId);

// Apply to API request
await openRouterService.streamChatCompletion(
  messages: messages,
  model: modelId,
  temperature: settings.temperature,
  maxTokens: settings.maxTokens,
  topP: settings.topP,
  frequencyPenalty: settings.frequencyPenalty,
  presencePenalty: settings.presencePenalty,
  includeReasoning: true,
  onChunk: (content) { /* ... */ },
  onCompletion: (content) { /* ... */ },
);
```

## Testing
Comprehensive unit tests added in `test/test_model_settings.dart`:
- Data class tests (serialization, equality, copyWith)
- Provider tests (load, save, update, delete)
- Integration tests (full flow, persistence)

Run tests:
```bash
flutter test test/test_model_settings.dart
```

## Files Modified/Created

### New Files:
- `lib/models/model_settings.dart` - Data model
- `lib/providers/model_settings_provider.dart` - Settings management
- `lib/widgets/chat/model_settings_sheet.dart` - UI component
- `test/test_model_settings.dart` - Unit tests

### Modified Files:
- `lib/widgets/chat/chat_input.dart` - Added settings button
- `lib/l10n/app_en.arb` - English translations
- `lib/l10n/app_ru.arb` - Russian translations
- `lib/screens/chat_screen.dart` - Updated to use model settings

## Benefits

1. **Flexibility**: Each model can have different parameters
2. **Transparency**: Shows API limits and current values
3. **Persistence**: Settings saved across app restarts
4. **User Control**: Fine-tune model behavior per use case
5. **No Breaking Changes**: Fully backward compatible

## Future Enhancements

- Preset configurations (e.g., "Creative", "Precise", "Fast")
- Export/import settings
- Settings templates for different tasks
- Visual feedback for parameter effects
- Model-specific recommendations

## Notes

- Settings are model-specific (different models can have different settings)
- API limits are fetched from OpenRouter when available
- System prompts are added to the message history automatically
- All changes are persisted immediately
- The implementation is fully compatible with existing chat functionality
