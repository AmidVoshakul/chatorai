// Feature: Chat
export 'package:chatorai/features/agents/data/models/agent_provider.dart';
export 'package:chatorai/features/chat/data/providers/chat_providers.dart';
export 'package:chatorai/features/chat/data/providers/chat_screen_notifier.dart';
export 'package:chatorai/features/chat/data/providers/sidebar_provider.dart';
export 'package:chatorai/features/chat/data/providers/streaming_message_provider.dart';
export 'package:chatorai/features/chat/data/providers/chat_input_provider.dart';

// Feature: Settings
export 'package:chatorai/features/settings/presentation/providers/theme_provider.dart';
export 'package:chatorai/features/settings/presentation/providers/language_provider.dart';
export 'package:chatorai/features/settings/presentation/providers/model_settings_provider.dart';
export 'package:chatorai/features/settings/presentation/providers/provider_settings_provider.dart';

// Feature: Models Browser
export 'package:chatorai/features/models_browser/presentation/providers/model_provider.dart'
    show modelProvider;

// Feature: Tools
export 'package:chatorai/features/tools/data/models/tool_registry_provider.dart';

// Core: AI
export 'package:chatorai/core/ai/ai_provider.dart' show openRouterAiProvider;

// Core: Permissions
export 'package:chatorai/core/permission/permission_provider.dart';

// Core: Config
export 'package:chatorai/core/config/config_manager.dart';
export 'package:chatorai/core/config/config_provider.dart' show configProvider;

// Models (shared)
export 'package:chatorai/features/chat/data/models/ai_provider.dart';
export 'package:chatorai/features/chat/data/models/provider_settings.dart';
