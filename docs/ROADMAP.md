# Roadmap

**Last updated:** 2026-06-23

This roadmap outlines completed milestones, current sprint goals, and planned future features for ChatORAI.

---

## Completed Milestones

### ChatORAI v1.0 Release (2025-12-30)

- Full migration to **Riverpod 3.x** and Notifier-only state management.
- **Feature-first architecture** — modular `lib/features/` structure, clean separation of concerns (Presentation/Domain/Data).
- **Tool execution system** — 12 built-in tools, permission prompts, streaming tool events.
- **Permission system** — user-configurable `chatorai.json`, Once/Always/Reject UI, wildcard rules.
- **Tool display** — Inline icons with state indicators (pending/running/completed/error), expandable outputs, title formatting, copy-to-clipboard.
- **Chat Display V2** — MessagePart pipeline (Text, Reasoning, Tool, Task, Question, Todo), `AnimatedSize` synchronized streaming, improved auto-scroll.
- **Robust streaming** — throttling (250ms / word boundary), error recovery, backoff with jitter, `Retry-After` support.
- **Secure storage** — `.env` dev-only, runtime API key in `SharedPreferences`, no secret logging.
- **Markdown + code highlighting** — syntax highlighting, collapsible reasoning blocks.
- **Multi-language** — 6 languages (en, ru, uk, zh, ja, ar), RTL for Arabic.
- **Platform builds** — Linux, Windows, Android, Web, iOS (macOS required).
- **Installation packages** — Linux `install_app.sh`, Windows `install_app.ps1`/`.bat`.

### Post-Release Improvements (2026-01 to 2026-06)

- Voice input integration (speech_to_text)
- Camera & image attachments (image_picker)
- File picker with broad format support
- Markdown heading navigation sidebar
- Real-time API key validation with auto-save
- Context management: token counting and overflow warnings
- Heading anchor registry for in-chat navigation
- Improved model selection (two-column layout on wide screens)
- Network connectivity service and status monitoring
- Comprehensive localization updates across all languages
- CI/CD: GitHub Actions workflows for test and release
- Codebase health: 0 analyzer warnings, extensive unit/widget tests

### Compaction Service (Implemented)

- Automatic context summarization when token budget approaches limit.
- Located in `lib/core/context/compaction_service.dart`.
- `CompactionOrchestrator` (`lib/core/context/compaction_orchestrator.dart`) wires `CompactionService` into the session event pipeline using a real `CompletionProvider` (no stub).
- Splits messages into head (old) + tail (recent), summarizes head via LLM, prunes old tool outputs.
- Already integrated into the streaming pipeline.

### Multi-Provider Registry (Implemented)

- Dynamic provider configuration beyond OpenRouter.
- UI for managing multiple backends (`ProviderSettingsScreen`).
- Stores API keys, base URLs, and selected models per provider.
- Supports any OpenAI-compatible endpoint.

### @-Mention System (Implemented)

- Agent invocation via `@agent_name` in chat input (only subagents).
- Dropdown popup above input with fuzzy search.
- Static `AgentRegistry` provides predefined agents (only subagents): `explore`, `general`, etc.
- Subagents receive full user message as context with appropriate permissions.

### Tool Registration & Output Truncation (Implemented)

- Centralized built-in tool registration in `built_in_tools.dart`, including `question` tool.
- `skill` tool moved to built_in and registered centrally.
- Output truncation for tool results (2000 lines / 50KB) to prevent performance issues.
- `path_sandbox` utility moved to `lib/shared/utils/`.

---

## Current Sprint (Q2 2026)

### Focus: Remaining Planned Features

- **Session Hierarchy (Phase C)** — support for parent/child sessions with context isolation and navigation (not yet implemented).
- **Agent Registry Evolution** — currently static; dynamic skill-based discovery is a future goal.
- **Keybinds System** — GUI hotkeys for desktop (planning phase).
- **Emergency Stop** — double-press Escape to halt all processes (planning phase).
- **MCP/LSP Tools** — code intelligence integration (exploration phase).

---

## Planned Features

### Short-term (Next Minor Release)

| Feature                     | Status                                                                         | Notes                                                                             |
| --------------------------- | ------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| **Session tree navigation** | Prototyping                                                                    | UI for parent/child/peer sessions, with merge and fork operations.                |
| **MCP/LSP tools**           | Exploration                                                                    | `mcp` and `lsp` built-in tools for code intelligence within the chat.             |
| **Browser automation**      | Integration testing via Playwright MCP; consider exposing as user-facing tool. |
| **Enhanced permission UI**  | Planning                                                                       | Settings screen to edit `chatorai.json` rules visually.                           |
| **Keybinds system**         | Draft plan                                                                     | GUI hotkeys for desktop (leader key + chord support). Implementation not started. |

### Medium-term (H2 2026)

- **Local model support** — direct connection to Ollama, LM Studio, llama.cpp via OpenAI-compatible endpoint.
- **Plugin architecture** — allow community tools and agents.
- **Collaborative sessions** — read-only sharing of chat sessions via URL or file export.
- **Voice responses** — TTS playback for assistant messages.
- **Offline mode** — cache recent chats and models for disconnected use.
- **Performance profiling** — built-in diagnostics for token usage, tool latency, API costs.

### Long-term (2027+)

- **Multi-modal extensions** — video analysis, diagram generation.
- **IDE integration** — plugin for VS Code/IntelliJ to forward context to ChatORAI.
- **Enterprise features** — SSO, audit logging, per-user rate limits.
- **AI-powered code review automation** — integrate with PR workflows.

---

## Known Limitations

- iOS builds require macOS; cannot be built on Windows/Linux CI without macOS runners.
- Web version has performance constraints (memory, streaming latency).
- `analysis_options.yaml` excludes `test/**` from lint; test code may contain intentional warnings.
- Some integration tests are disabled due to Riverpod provider complexity; widget+unit coverage is preferred.

---

## Community & Contributing

We welcome contributions! Please see `CONTRIBUTING.md` for:

- Git workflow (feature branches, PR reviews)
- Code style (Dart 3.9, strong typing, no implicit-dynamic warnings)
- Test enforcement (run `flutter test`, update tests with behavior changes)
- Documentation updates (keep this roadmap and API docs in sync)

---

For detailed API reference, see `docs/API.md`.  
For command-line and slash commands, see `docs/COMMANDS.md`.  
For environment setup, see `docs/ENVIRONMENT.md`.  
For architecture, see `ARCHITECTURE.md`.
