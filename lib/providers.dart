// Feature: Chat
// Core: Config
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core: Agents
export 'package:chatorai/core/agents/agent_provider.dart'
    show currentAgentProvider;
export 'package:chatorai/core/config/config_manager.dart';
export 'package:chatorai/core/config/config_provider.dart'
    show configProvider, compactionConfigProvider;
// Core: Settings
export 'package:chatorai/core/i18n/language_provider.dart';
export 'package:chatorai/core/keyboard/keybinding_provider.dart';
// Core: Permissions
export 'package:chatorai/core/permission/permission_provider.dart';
// Feature: Skills
export 'package:chatorai/core/skills/skills.dart';
// Feature: Tools
export 'package:chatorai/gui/features/chat/data/providers/tool_registry_provider.dart';
// Feature: Bootstrap (startup initialization)
export 'package:chatorai/gui/features/bootstrap/bootstrap_provider.dart';
export 'package:chatorai/gui/features/chat/data/providers/chat_input_provider.dart';
export 'package:chatorai/gui/features/chat/data/providers/chat_providers.dart';
export 'package:chatorai/gui/features/chat/data/providers/chat_screen_notifier.dart';
export 'package:chatorai/gui/features/chat/data/providers/chat_scroll_intent_provider.dart';
// Feature: Models Browser
export 'package:chatorai/gui/features/models/providers/model_provider.dart'
    show modelProvider;
export 'package:chatorai/gui/features/models/providers/models_provider.dart'
    show modelsScreenProvider;
export 'package:chatorai/gui/features/sessions/providers/session_parts_provider.dart';
// Feature: Sessions
export 'package:chatorai/gui/features/sessions/providers/session_providers.dart';
export 'package:chatorai/gui/features/sessions/providers/sidebar_provider.dart';
export 'package:chatorai/gui/features/settings/providers/model_settings_provider.dart';
// Core: Theme
export 'package:chatorai/gui/shared/theme/theme_provider.dart';
// Shared: Workspace
export 'package:chatorai/gui/shared/workspace/workspace_provider.dart';

// Chat screen scaffold key provider for global shortcuts
final scaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>(
  (ref) => GlobalKey<ScaffoldState>(),
);
