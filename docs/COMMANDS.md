# Commands Reference

**Last updated:** 2026-06-12

ChatORAI supports:

1. **CLI/Development Commands** — for building, testing, and running the app.
2. **@-Commands** — agent invocation (currently the only quick command implemented).
3. **Tool Commands** — built-in tools invoked by the AI.

---

## CLI Commands

These are shell commands used during development and deployment.

### Dependency & Generation

```bash
flutter pub get              # Fetch Dart dependencies
flutter gen-l10n             # Generate localization (only after editing lib/l10n/*.arb)
```

### Quality Assurance

```bash
flutter analyze             # Static analysis (lint). Excludes test/** per analysis_options.yaml.
flutter test                # Run unit and widget tests
flutter test --coverage     # With coverage report (requires lcov)
```

### Run & Build

```bash
# Development (hot reload)
flutter run -d linux
flutter run -d windows
flutter run -d chrome
flutter run -d android
flutter run -d ios          # Requires macOS

# Release builds
flutter build linux --release
flutter build windows --release
flutter build apk --release  # Android
flutter build ios --release  # macOS
flutter build web --release
```

### Platform-specific Notes

- **Linux**: Install system libs first: `libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2`.
- **Windows**: Requires Visual C++ workload + Windows 10/11 SDK; CMake must be available.
- **iOS**: Requires macOS and Xcode; cannot build from Linux.

---

## @-Commands (Agent Calls)

Type `@` followed by agent name to quickly invoke a subagent with additional context.

**Syntax:**

```
@agent_name <your prompt>
```

**Example:**

```
@explore review this function for security issues
```

or

```
review this function for security issues use @explore
```

**Available Agents:**

- `@general` — General-purpose assistant
- `@explore` — Fast agent for codebase exploration (read-only)
- `@name-subagent` - Custom subagents

  **UI:** Dropdown appears above chat input, filtered by fuzzy search. Selection inserts `@agent_name` and the subagent receives the full user message as context.

**Note:** `#` (file references) and `/` (slash commands) are planned for future releases but not yet implemented.

---

## Tool Commands (Built-in)

When the AI invokes tools, they appear inline in the chat stream with icons and status.

| Tool          | Description            | Input Schema                                                                       | Default Permission |
| ------------- | ---------------------- | ---------------------------------------------------------------------------------- | ------------------ |
| `bash`        | Execute shell command  | `{ "command": "...", "timeoutMs": 30000 }`                                         | ask                |
| `read`        | Read file contents     | `{ "path": "...", "offset": 0, "limit": 1000 }`                                    | allow              |
| `edit`        | Replace text in file   | `{ "path": "...", "oldString": "...", "newString": "..." }`                        | ask                |
| `write`       | Create/overwrite file  | `{ "path": "...", "content": "..." }`                                              | ask                |
| `glob`        | Find files by pattern  | `{ "pattern": "**/*.dart", "path": "lib" }`                                        | allow              |
| `grep`        | Search file contents   | `{ "pattern": "...", "path": "lib", "filePattern": "*.dart" }`                     | allow              |
| `webfetch`    | Fetch URL content      | `{ "url": "https://...", "format": "markdown" }`                                   | ask                |
| `websearch`   | Search web via SearXNG | `{ "query": "...", "engines": [...], "categories": [...] }`                        | ask                |
| `task`        | Spawn subagent         | `{ "prompt": "...", "context": {...}, "subagentType": "explore" }`                 | ask                |
| `todowrite`   | Update todo list       | `{ "todos": [{ "content": "...", "status": "pending"/"completed" }] }`             | ask                |
| `skill`       | Load specialized skill | `{ "name": "...", "params": {...} }`                                               | ask                |
| `apply_patch` | Apply unified diff     | `{ "patch": "diff --git a/... b/...", "dryRun": false }`                           | ask                |
| `question`    | Ask user questions     | `{ "questions": [{ "question": string, "options": [string], "multiple": bool }] }` | ask                |

**States:** `pending` (∼), `running` (spinner), `completed` (✓), `error` (✗). Tool results can be expanded to show full output.

**Note:** All tool outputs are truncated to 2000 lines or 50KB when displayed.

---

## Configuration Commands

These are not interactive commands but JSON configuration options.

### chatorai.json Permission Section

```json5
{
  version: 1,
  permission: {
    default: "ask",
    rules: [
      { tool: "read", action: "*", resource: "*", permission: "allow" },
      {
        tool: "bash",
        action: "execute",
        resource: "/home/**",
        permission: "deny",
      },
    ],
  },
}
```

**Rule fields:**

- `tool`: Tool name (e.g., `bash`, `edit`).
- `action`: Action string (usually `"execute"`).
- `resource`: Resource pattern (path, URL, regex). Wildcards supported via `*` and `?`.
- `permission`: `allow`, `deny`, or `ask`.

**Wildcard patterns:**

- `*` matches any sequence (except `/` for paths).
- `?` matches a single character.
- Patterns are matched against the tool's primary input (e.g., `path` for read/edit, `command` for bash).

For environment variables and system dependencies, see `docs/ENVIRONMENT.md`.  
For API reference, see `docs/API.md`.  
For architecture, see `ARCHITECTURE.md`.
