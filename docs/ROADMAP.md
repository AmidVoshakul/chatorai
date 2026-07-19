# Roadmap

**Last updated:** 2026-07-08

ChatORAI follows a milestone-driven development cycle. This document summarizes
completed milestones and future plans based on the current codebase state.

## Completed Milestones

### [0.1.0] — 2026-06-28

- Multi-provider AI chat via OpenRouter, local LLMs, and any OpenAI-compatible endpoint
- Voice input with speech-to-text and camera/image attachments
- Advanced Markdown rendering with syntax highlighting and collapsible reasoning blocks
- Dark / light theme support with adaptive transitions
- Multi-language support (6 languages) with RTL layout for Arabic
- Local chat history storage via SharedPreferences
- Streaming AI responses with auto-scroll and continuation suggestions
- Chat navigation by Markdown headings

### Session Core + Event Sourcing

- Drift-backed append-only event store with `SessionRunner` orchestration
- Event types: `SessionCreated`, `MessageAdded`, `TextStarted/Delta/Ended`,
  `ReasoningStarted/Delta/Ended`, `ToolCalled`, `ToolSuccess`, `ToolFailed`,
  `StepStarted/Ended/Failed`, `CompactionStarted/Ended`, `ChildSessionCreated`,
  `TaskStarted/Completed`
- `SessionRepository` with CRUD + full `replayEvents()` reconstruction
- `SessionTree` and `SessionStack` for hierarchical parent-child session navigation
- SessionID branded type (`ses_{uuid}`)

### Tool Execution System

- 16 unconditional + 3 conditional built-in tools registered via `ToolRegistry`
- Doom-loop guard (max 3 steps per turn) with cache deduplication
- `TruncationService` limits tool outputs to 2000 lines / 50 KB with expandable UI
- Interactive `QuestionPart` with cooldown dedup and multi-select support
- `PermissionBridge` integrates tool permissions with `PermissionService`
- `ChatRetryService` provides infinite retries with exponential backoff and `Retry-After` support

### MCP Integration

- `McpClientService` connects to local (stdio) and remote (HTTP) MCP servers
- Tool discovery and proxying into the native `ToolRegistry`
- Config models (`McpConfig`, `McpServerConfig`, `McpOAuthConfig`) in `lib/core/mcp/`

### Provider & Model Management

- `ProviderCatalogService` with 24-hour SharedPreferences cache
- 22 SVG provider icons with theme-aware rendering
- `AddProviderDialog` and `ModelSelectionDialog` for in-app configuration
- `ModelResolver` merges provider defaults, model metadata, and variant fields
- **Recent models**: horizontal "stories"-style strip of the top-6 recently/frequently used models on the model-selection screen, backed by `usageCounts`/`lastUsed` in `SharedPreferences` and the `recentModels` getter (shipped in 0.1.1)

### Chat Input & Display

- `@`-mention subagent system with fuzzy search dropdown
- `MessagePart`-based rendering (Text, Reasoning, ToolCall, ToolResult, Task, Question, Todo)
- `ShortcutHandler` / `AppShortcuts` for centralized keyboard management
- `AutoRestart` and overlay for microphone input

### Documentation & Quality

- Comprehensive `docs/` reference (API, Commands, Environment, Configuration, Security, XdgPaths)
- Mermaid diagrams for architecture, sessions, tools, and MCP topology
- Unit tests (43+ `ProviderCatalogService` tests) and widget tests
- Zero-warning `flutter analyze` target

---

## Future Plans

### Near-Term

- **Dynamic Keybinds System**: Wire `chatorai.json` keybinding config into `AppShortcuts`
- **Emergency Stop**: Double-press Escape to halt all active processes while preserving session state
- **File Export / Import**: Session export to JSON / Markdown for sharing and archival
- **Crash Recovery UX**: UI indicator for session restoring from event replay

### Mid-Term

- **Dynamic Agent Discovery**: Replace static `AgentRegistry` with skill-based discovery via MCP servers
- **Advanced MCP**: OAuth flow for remote MCP servers; SSE transport for streaming tool results
- **Web Transport**: Production hardening for Flutter Web renderer and deployment pipeline
- **Additional Model Providers**: Expand built-in provider catalog and icon set

### Long-Term

- **Plugin Architecture**: User-extensible skills and tool packages
- **Collaboration Features**: Shared sessions and multi-user chatrooms
- **Observability**: Built-in telemetry and debugging dashboard for tool execution

---

For implementation details, see `ARCHITECTURE.md`. For release notes, see `CHANGELOG.md`.
