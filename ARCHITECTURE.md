# ChatORAI Architecture

**Last updated:** 2026-06-12

## Project Overview

ChatORAI is a multi-platform AI chat application built with Flutter 3.41.0 and Riverpod 3.x. It supports any OpenAI-compatible API (OpenRouter, local models, custom endpoints) via `ai_sdk_dart` v1.1.0.

Key characteristics:

- Feature-first directory structure
- MVVM pattern with Riverpod providers
- Layered architecture: Presentation → Domain → Data
- Tool execution system with granular permissions
- Internationalization with 6 languages (en, ru, uk, zh, ja, ar)

## Directory Layout

```
lib/
├── core/                    # Application core, cross-cutting concerns
│   ├── config/              # Configuration management (chatorai.json, schema, loader)
│   ├── constants/           # App-wide constants, enums, themes
│   ├── context/             # Token counting, overflow detection, compaction
│   ├── error/               # Error classification and handling
│   ├── permission/          # Permission service and models
│   └── utils/               # Shared utilities (logger, formatters)
├── features/                # Feature-based modules (primary organization)
│   ├── agents/              # Subagent system and static registry
│   ├── chat/                # Main chat feature (domain, data, presentation)
│   │   ├── domain/
│   │   │   └── services/    # ChatAiService, chat storage
│   │   ├── data/
│   │   │   ├── models/      # DTOs and chat/part models (in chat/ subfolder)
│   │   │   │   └── chat/
│   │   │   │       ├── chat_message.dart
│   │   │   │       ├── message_part.dart
│   │   │   │       └── ...
│   │   │   ├── repositories/
│   │   │   └── providers/   # Riverpod providers (chat, streaming, screen)
│   │   └── presentation/
│   │       ├── screens/     # ChatScreen (split into parts)
│   │       ├── widgets/     # ChatMessages, ChatInput, parts/
│   │       └── view_models/ # (not used; logic in providers)
│   ├── models_browser/      # Model selection and provider management
│   ├── settings/            # App settings, theme, language, API key
│   ├── skills/              # Skill-based agent capabilities and SkillService
│   └── tools/               # Built-in tool implementations (12 tools)
├── generated/               # Auto-generated localization (app_localizations.dart)
└── l10n/                    # ARB files for translation (6 languages)
```
lib/
├── core/                    # Application core, cross-cutting concerns
│   ├── config/              # Configuration management (chatorai.json, schema, loader)
│   ├── constants/           # App-wide constants, enums, themes
│   ├── context/             # Token counting, overflow detection, compaction
│   ├── error/               # Error classification and handling
│   ├── permission/          # Permission service and models
│   └── utils/               # Shared utilities (logger, formatters)
├── features/                # Feature-based modules (primary organization)
│   ├── agents/              # Subagent system and static registry
│   ├── chat/                # Main chat feature (domain, data, presentation)
│   │   ├── domain/
│   │   │   └── services/    # ChatAiService, chat storage
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── chat/    # Message and parts hierarchy
│   │   │   │       ├── chat_message.dart
│   │   │   │       ├── message_part.dart
│   │   │   │       └── ...
│   │   │   ├── repositories/
│   │   │   └── providers/   # Riverpod providers (chat, streaming, screen)
│   │   └── presentation/
│   │       ├── screens/     # ChatScreen (split into parts)
│   │       ├── widgets/     # ChatMessages, ChatInput, parts/
│   │       └── view_models/ # (not used; logic in providers)
│   ├── models_browser/      # Model selection and provider management
│   ├── settings/            # App settings, theme, language, API key
│   ├── skills/              # Skill-based agent capabilities and SkillService
│   └── tools/               # Built-in tool implementations (12 tools)
├── generated/               # Auto-generated localization (app_localizations.dart)
└── l10n/                    # ARB files for translation (6 languages)
```

## Architectural Patterns

### MVVM with Riverpod 3.x

- **Providers**: All state is exposed via Riverpod providers (`StateProvider`, `StateNotifierProvider`, `FutureProvider`).
- **ViewModels**: Notifier classes manage business logic and state transitions.
- **Views**: Stateless widgets that `ref.watch` providers for reactive updates.

### Layered Separation

Each feature follows a multi-layer structure:

- **Domain Layer**: Pure business logic, entities (ChatMessage, MessagePart), repository interfaces, services (ChatAiService). No Flutter dependencies.
- **Data Layer**: Repository implementations, data sources (local: SharedPreferences; remote: API via Dio), DTOs, model mapping.
- **Presentation Layer**: Flutter widgets, Riverpod providers for UI state, view models.

### Tool Execution Loop

The ChatAiService coordinates AI completions with tool execution:

1. `streamChatCompletion()` receives messages, model, temperature, and `ToolSet`.
2. Stream of `StreamTextEvent` chunks (text, reasoning, tool events).
3. Tool invocation lifecycle:
   - `onToolStart` → `ToolResultPart(state=running)` created
   - `tool.execute()` → may throw `ToolError`
   - `onToolEnd` → `ToolResultPart(state=completed)` with result
4. Max steps: 5, with automatic `compactionService.compact()` on overflow.
5. Error handling: retries with exponential backoff (base 2s, jitter, `Retry-After` support).

### Permission System

- Configured via `chatorai.json` (section `permission`).
- Default ruleset: `read`, `glob`, `grep` → `allow`; others → `ask`.
- Evaluator: last-match-wins, default=`ask`.
- UI Modal: Once / Always allow / Reject. "Always" promotes to runtime ruleset.
- Integration: `tool.preExecute()` → `PermissionService.ask()` → `tool.execute()`.
- **Implementation location:** `lib/core/permission/permission_service.dart`

### Configuration Management

- **Development**: `.env` (gitignored) for API keys and dev settings.
- **Runtime**: Users enter API key in app settings → stored in `SharedPreferences`.
- **chatorai.json**: User-editable JSON with `$schema` URL for IDE autocomplete. Validated against `lib/core/config/chatorai_schema.dart`.
- Sections: `permission`, `provider` (reserved for multi-provider registry), `keybinding`.

### Internationalization

- ARB files in `lib/l10n/` for 6 languages.
- RTL support for Arabic.
- After editing any ARB: `flutter gen-l10n`.
- Generated output: `lib/generated/app_localizations.dart` (do not edit manually).

### Platform Specifics

- **Linux**: Requires `libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2`.
- **Windows**: Visual C++ workload + Windows 10/11 SDK required for builds; CMake errors if missing.
- **iOS**: Requires macOS; cannot build on Linux.
- **Web**: Uses Flutter web renderer.

## Data Flow

```
User types message
  ↓
ChatInput widget → onSendMessage callback
  ↓
chatScreenNotifier.sendMessage()
  ↓
ChatAiService.streamChatCompletion(...)
  ↓
Message chunks streamed:
  - TextPart (content)
  - ReasoningPart (thinking process)
  - ToolCallPart / ToolResultPart (tool execution)
  - TaskPart / QuestionPart / TodoPart (special workflows)
  ↓
ChatStorageService.addMessageToChat() persists messages
  ↓
Providers update state → UI rebuilds (ChatMessages, ChatMessageBubble)
```

### Streaming & Auto-scroll

- Streaming updates throttled to 250ms or word boundaries (whichever comes first).
- Auto-scroll during streaming is enabled/disabled based on user scroll position:
  - Near bottom (≤150px) → auto-scroll stays ON.
  - Scrolled up (>150px) → auto-scroll OFF until user returns near bottom.
- After sending a message: smooth force scroll (300ms animation).
- Assistant bubble wrapped in `AnimatedSize(150ms)` synchronized with streaming scroll to prevent text overflow.

## Component Boundaries

### Chat Feature Module

```
lib/features/chat/
├── domain/
│   ├── services/
│   │   ├── chat_ai_service.dart    # AI completion with tool loop
│   │   └── chat_storage_service.dart # Persistence abstraction
├── data/
│   ├── models/
│   │   └── chat/                  # Message and parts hierarchy
│   │       ├── chat_message.dart  # UserMessage, AssistantMessage, SystemMessage, ErrorMessage
│   │       ├── message_part.dart  # Abstract part base
│   │       ├── text_part.dart
│   │       ├── reasoning_part.dart
│   │       ├── tool_call_part.dart
│   │       ├── tool_result_part.dart
│   │       ├── task_part.dart
│   │       ├── question_part.dart
│   │       ├── todo_part.dart
│   │       └── chat_model.dart    # Chat aggregate
│   ├── repositories/
│   │   └── chat_repository_impl.dart
│   └── providers/
│       ├── chat_providers.dart    # chatListProvider, currentChatIdProvider, currentChatProvider
│       ├── chat_screen_notifier.dart
│       ├── streaming_message_provider.dart
│       └── chat_input_provider.dart
└── presentation/
    ├── screens/
    │   ├── chat_screen.dart
    │   ├── chat_screen_scroll.dart
    │   ├── chat_screen_streaming.dart
    │   └── chat_screen_content.dart
    ├── widgets/
    │   ├── chat_messages.dart
    │   ├── chat_message_bubble.dart
    │   ├── chat_input.dart          # @-mention triggers implemented; # and / planned
    │   ├── parts/                  # One widget per MessagePart type
    │   │   ├── text_part_widget.dart
    │   │   ├── reasoning_part_widget.dart
    │   │   ├── tool_call_part_widget.dart
    │   │   ├── tool_result_part_widget.dart
    │   │   ├── task_part_widget.dart
    │   │   ├── question_part_widget.dart
    │   │   └── todo_part_widget.dart
    │   └── agent_mention_popup.dart
    └── view_models/                # Not used; logic in providers
```

**Note:** Message models are in `data/models/chat/`, not `domain/models/`. The `apply_patch_part_widget.dart` does not exist; `ApplyPatchPart` is not a recognized message part type. Only `@` triggers are currently implemented in `chat_input.dart`; `#` (file references) and `/` (slash commands) are planned for future releases.

### Tools Feature Module

```
lib/features/tools/
├── built_in/                      # 12 built-in tools
│   ├── bash.dart                 # Shell command execution
│   ├── edit.dart                 # In-file text replacement
│   ├── glob.dart                 # File pattern matching
│   ├── grep.dart                 # Content search
│   ├── read.dart                 # File reading
│   ├── task.dart                 # Subagent delegation
│   ├── todo_write.dart           # Todo list management
│   ├── webfetch.dart             # URL content fetching
│   ├── websearch.dart            # Web search via SearXNG
│   ├── write.dart                # File creation/overwrite
│   ├── apply_patch.dart          # Unified diff application (rendered via ToolResultPartWidget)
│   └── built_in_tools.dart       # Registration barrel (registers 11 tools, excluding skill)
├── permission/                   # Permission system (actual location: lib/core/permission/)
│   ├── permission_service.dart   # Located in lib/core/permission/
│   ├── permission_dialog.dart
│   ├── models/
│   │   ├── permission_context.dart
│   │   ├── rule.dart
│   │   ├── ruleset.dart
│   │   ├── evaluator.dart
│   │   └── wildcard.dart
│   └── arity.dart               # Tool arity definitions
├── tool_registry.dart           # Singleton registry, toSDKTools()
├── tools.dart                   # Feature barrel export
└── (tool part widgets live in lib/features/chat/presentation/widgets/parts/)
```

**Note:** The `skill` tool is registered separately via `skill_providers.dart`. The `question` tool exists but is not currently registered. `path_sandbox.dart` is a utility module, not a tool.

## State Management

- **Riverpod 3.x** exclusively.
- Use `Notifier` subclasses (`StateNotifier` deprecated).
- Avoid creating new `StatefulWidget`; prefer `StateProvider` + `Consumer`.
- In tests: use `ProviderContainer` directly (see `test/test_chat_input_provider.dart`).

## Reliability & Security

- **Retry**: Unbounded exponential backoff with jitter, respects `Retry-After` headers.
- **Cancellation**: `CancellationToken` via `ChatAiService.cancelAllRequests()` on emergency stop.
- **Sanitization**: No secrets in logs; user-facing errors are truncated, no stack traces.
- **Storage**: `.env` dev-only; runtime API key in `SharedPreferences`.
- **TLS**: Enforced for all external requests via Dio.
- **Rate Limiting**: Implemented at provider level (OpenRouter rate limits respected via backoff).

## Development Commands

```bash
flutter pub get              # fetch dependencies
flutter gen-l10n             # ONLY after editing lib/l10n/*.arb
flutter analyze             # lint (tests excluded via analysis_options.yaml)
flutter test                # unit + widget tests
LIBGL_ALWAYS_SOFTWARE=1 flutter run -d linux  # Linux software rendering
```

See `docs/COMMANDS.md` for complete command reference including slash commands and tool usage.

## Testing Strategy

- Unit tests: Business logic, services, providers.
- Widget tests: UI components, auto-scroll behavior, rendering.
- Integration tests: Currently problematic; run via standalone scripts (e.g., `integration_test/api_test.dart`).
- `flutter analyze` clean required; tests do not block lint.

## Future Considerations

- **Session Hierarchy**: Parent-child sessions with context isolation (not yet implemented).
- **MCP/LSP**: Built-in tools for code intelligence (exploration phase).
- **Agent Registry**: Currently static (hardcoded in `AgentRegistry`); dynamic skill-based discovery is a future goal.
- **Keybinds System**: GUI hotkeys for desktop (planning phase).
- **Emergency Stop**: Double-press Escape to halt all processes (planning phase).

**Note:** The Compaction Service is already implemented and in use; it is not a future milestone.

---

For user-facing documentation, see `README.md`. For environment setup, see `docs/ENVIRONMENT.md`. For API reference, see `docs/API.md`. For roadmap, see `docs/ROADMAP.md`.
