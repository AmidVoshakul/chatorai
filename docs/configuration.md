# Configuration

**Last updated:** 2026-07-07

ChatORAI can be configured via a JSON file (`chatorai.json`) to customize permissions, keybindings, provider settings, MCP servers, and more.

The configuration file location is resolved via `XdgPaths.configHome` (see `lib/shared/utils/xdg_paths.dart`). The search order is:

1. `<configHome>/chatorai.json` — user-global config (highest priority)
2. `./.chatorai/chatorai.json` — project-specific config (used as fallback)

**Typical paths by platform:**

| Platform | Config path                                                        |
| -------- | ------------------------------------------------------------------ |
| Linux    | `~/.config/com.chatorai.app/chatorai.json` (or `$XDG_CONFIG_HOME`) |
| macOS    | `~/Library/Application Support/com.chatorai.app/chatorai.json`     |
| Windows  | `%APPDATA%\com.chatorai.app\config\chatorai.json`                  |
| Mobile   | Sandboxed app support directory (no user-accessible path)          |

The directory name is derived from the package bundle ID at runtime via `package_info_plus`.

If both locations exist, they are merged with the user-global file taking precedence.

## JSON Schema

The file is validated against the JSON Schema defined in `lib/config/chatorai_schema.dart`. The `$schema` URL is:

```
http://json-schema.org/draft/2020-12/schema#
```

IDE autocomplete may use this schema if the `$schema` field is added to the file.

## Structure

```json
{
  "version": 1,
  "permission": { ... },
  "keybinding": { ... },
  "skills": { ... },
  "compaction": { ... },
  "formatter": { ... },
  "mcp": { ... }
}
```

### `version`

Integer indicating the configuration schema version. Currently `1`.

### `permission`

Controls which tools are allowed, denied, or require user confirmation. Supports two shapes:

- **String** — sets a default action for all permissions: `"allow"`, `"ask"`, or `"deny"`.
- **Object** — maps permission names to either a default action (string) or per-pattern actions (object).

Permission names correspond to tool IDs: `read`, `edit`, `write`, `bash`, `glob`, `grep`, `webfetch`, `websearch`, `task`, `todowrite`, `question`, `skill`, `lsp`, `doom_loop`, `external_directory`, etc.

#### Per-Pattern Rules

```json
{
  "permission": {
    "edit": {
      "*.env": "deny",
      "lib/**": "allow",
      "*": "ask"
    }
  }
}
```

Patterns use glob-like syntax and support home directory expansion (`~`, `$HOME`).

#### Default Rules

If no permission configuration is provided, the following defaults apply (source: `lib/core/permission/ruleset.dart` — `PermissionRuleset.defaults()`):

```json
{
  "permission": {
    "read": "allow",
    "glob": "allow",
    "grep": "allow",
    "webfetch": "allow",
    "websearch": "allow",
    "task": "allow",
    "question": "allow",
    "todowrite": "allow",
    "skill": "allow",
    "lsp": "allow",
    "bash": "ask",
    "edit": "ask",
    "write": "ask",
    "doom_loop": "ask",
    "external_directory": "ask"
  }
}
```

Tools without a ruleset entry (e.g. `apply_patch`, `format`, `invalid`, `plan_exit`, `json_schema`) fall back to `ask` via the evaluator.

### `keybinding`

Customizes keyboard shortcuts. The config field is parsed and stored in
`ChatOrAIConfig.keybinding`, but the actual shortcuts are **hardcoded** in
`lib/core/keyboard/shortcuts.dart` (`AppShortcuts` widget). The configuration
is not currently applied at runtime — the `KeybindManager` class referenced in
earlier drafts does not exist. Future work: wire `chatorai.json` keybinding
settings into the shortcut system.

Example (for reference; not yet functional):

```json
{
  "keybinding": {
    "leader": "ctrl+x",
    "timeout": 2000,
    "bindings": {
      "session_child_next": "ctrl+right",
      "app_exit": "ctrl+q"
    }
  }
}
```

### `skills`

Configures skill discovery paths and remote sources. Skills provide specialized AI instructions and workflows.

```json
{
  "skills": {
    "paths": [".opencode/skills/"],
    "urls": [
      "https://example.com/skills/index.json",
      {
        "url": "https://example.com/skills/index.json",
        "cache_ttl": 3600,
        "api_key": "..."
      }
    ]
  }
}
```

| Field   | Type       | Description                              |
| ------- | ---------- | ---------------------------------------- |
| `paths` | `string[]` | Directories to scan for `SKILL.md` files |
| `urls`  | `array`    | Remote skill sources (URL to `index.json`) |

### `compaction`

Controls automatic context compaction when token budget is exceeded.

```json
{
  "compaction": {
    "auto": true,
    "prune": true,
    "keep": { "tokens": 4000 },
    "buffer": 2000
  }
}
```

| Field          | Type      | Description                                     |
| -------------- | --------- | ----------------------------------------------- |
| `auto`         | `bool`    | Enable automatic compaction                      |
| `prune`        | `bool`    | Prune old tool outputs                          |
| `keep.tokens`  | `int`     | Tokens to preserve as recent context            |
| `buffer`       | `int`     | Token buffer before triggering compaction       |

### `formatter`

Configures external code formatters (e.g. `dart format`).

```json
{
  "formatter": {
    "formatters": {
      "dart": {
        "disabled": false,
        "command": ["dart", "format", "--output=show"],
        "extensions": [".dart"]
      }
    }
  }
}
```

### `mcp`

Configures external MCP (Model Context Protocol) servers. These servers provide additional tools that appear as native built-in tools during AI conversations.

```json
{
  "mcp": {
    "default_timeout": 30000,
    "servers": {
      "my-server": {
        "type": "local",
        "command": "npx",
        "args": ["-y", "my-mcp-server"],
        "cwd": "/home/user",
        "environment": { "NODE_ENV": "production" },
        "timeout": 30000
      },
      "remote-server": {
        "type": "remote",
        "url": "https://api.example.com/mcp",
        "headers": { "Authorization": "Bearer ..." },
        "oauth": {
          "client_id": "...",
          "client_secret": "...",
          "scope": "...",
          "callback_port": 8080,
          "redirect_uri": "http://localhost:8080/callback"
        }
      }
    }
  }
}
```

**Server types:**

| Type   | Required fields        | Optional fields                                                |
| ------ | ---------------------- | -------------------------------------------------------------- |
| local  | `command`, `args`      | `cwd`, `environment`, `enabled`, `timeout`, `type: "local"`    |
| remote | `url`                 | `headers`, `oauth`, `enabled`, `timeout`, `type: "remote"`     |

Tools discovered from MCP servers are registered into the `ToolRegistry` and participate in the tool execution pipeline alongside built-in tools.

## Validation

On startup, the configuration is loaded and validated. If the JSON is malformed or does not conform to the schema, an error is thrown and the default configuration is used. Users will see an error message in the UI.

## Examples

### Minimal (use defaults)

```json
{
  "version": 1
}
```

### Restrict Bash and Edit

```json
{
  "version": 1,
  "permission": {
    "bash": "deny",
    "edit": "deny"
  }
}
```

### Allow Read/Glob/Grep Only

```json
{
  "version": 1,
  "permission": {
    "read": "allow",
    "glob": "allow",
    "grep": "allow",
    "*": "deny"
  }
}
```

## Tips

- Use `"*"` as a pattern to match all paths.
- Patterns are case-sensitive on Linux/macOS and case-insensitive on Windows.
- The `always` permission granted via UI is stored in memory only and resets on app restart.
- For advanced use, combine string defaults and pattern objects within the same permission section.

## Diagrams

- [Config Resolution Chain](../diagrams/architecture-overview.md#config-resolution-chain)
- [Permission Evaluator Pipeline](../diagrams/architecture-overview.md#tool-execution-lifecycle)
