// Feature: Chat
// Core: Config
export 'package:chatorai/core/config/config_manager.dart';
export 'package:chatorai/core/config/config_provider.dart'
    show configProvider, compactionConfigProvider;
export 'package:chatorai/core/keyboard/keybinding_provider.dart';
// Core: Agents
export 'package:chatorai/core/agents/agent_provider.dart'
    show currentAgentProvider;
// Core: Settings
export 'package:chatorai/core/i18n/language_provider.dart';
// Core: Permissions
export 'package:chatorai/core/permission/permission_provider.dart';
// Feature: Skills
export 'package:chatorai/core/skills/skills.dart';
// Feature: Sessions
export 'package:chatorai/features/sessions/providers/session_providers.dart';
export 'package:chatorai/features/sessions/providers/session_parts_provider.dart';
export 'package:chatorai/features/sessions/providers/sidebar_provider.dart';
// Feature: Tools
export 'package:chatorai/core/tools/tool_registry_provider.dart';
export 'package:chatorai/features/chat/data/providers/chat_input_provider.dart';
export 'package:chatorai/features/chat/data/providers/chat_providers.dart';
export 'package:chatorai/features/chat/data/providers/chat_screen_notifier.dart';
export 'package:chatorai/features/chat/data/providers/chat_scroll_intent_provider.dart';
// Feature: Models Browser
export 'package:chatorai/features/models/providers/model_provider.dart'
    show modelProvider;
export 'package:chatorai/features/models/providers/models_provider.dart'
    show modelsScreenProvider;
export 'package:chatorai/features/settings/providers/model_settings_provider.dart';
// Core: Theme
export 'package:chatorai/shared/theme/theme_provider.dart';
// Feature: Bootstrap (startup initialization)
export 'package:chatorai/features/bootstrap/bootstrap_provider.dart';
// Shared: Workspace
export 'package:chatorai/shared/workspace/workspace_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Chat screen scaffold key provider for global shortcuts
final scaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>(
  (ref) => GlobalKey<ScaffoldState>(),
);
