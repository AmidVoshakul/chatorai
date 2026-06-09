// Chat feature — barrel export
// Data layer
export 'data/models/chat/chat_message_export.dart';
export 'data/models/chat_models.dart';
export 'data/models/chat_model.dart';
export 'data/models/model_settings.dart';
export 'data/models/provider_settings.dart';
export 'data/models/ai_provider.dart';
export 'data/providers/chat_repository.dart';

// Domain layer
export 'domain/services/chat_ai_service.dart';
export 'domain/services/chat_retry_service.dart';
export 'domain/services/chat_message_converter.dart';
export 'domain/services/chat_token_service.dart';
export 'domain/services/chat_cancellation.dart';
export 'domain/services/speech_to_text_service.dart';

// Presentation layer — providers
export 'data/providers/chat_providers.dart';
export 'data/providers/chat_input_provider.dart' hide ChatInputState;
export 'data/providers/chat_screen_notifier.dart';
export 'data/providers/chat_streaming_notifier.dart';
export 'data/providers/streaming_message_provider.dart';
export 'data/providers/sidebar_provider.dart';
export 'data/providers/models_provider.dart';

// Presentation layer — screens
export 'presentation/screens/chat_screen.dart';

// Presentation layer — widgets
export 'presentation/widgets/chat_input.dart';
export 'presentation/widgets/chat_messages.dart';
export 'presentation/widgets/chat_app_bar.dart';
