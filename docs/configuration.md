# Configuration

ChatORAI can be configured via a JSON file (`chatorai.json`) to customize permissions, keybindings, provider settings, and more.

The configuration file is searched in the following order (first found wins):

1. `./.chatorai/chatorai.json` (project-specific config, highest priority)
2. `~/.config/chatorai/chatorai.json` (global user config, used as fallback)

If both exist, they are merged with the user file taking precedence.

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
  "provider": { ... },
  "keybinding": { ... },
  "skills": { ... }
}
```

### `version`

Integer indicating the configuration schema version. Currently `1`.

### `permission`

Controls which tools are allowed, denied, or require user confirmation. Supports two shapes:

- **String** — sets a default action for all permissions: `"allow"`, `"ask"`, or `"deny"`.
- **Object** — maps permission names to either a default action (string) or per-pattern actions (object).

Permission names correspond to tool IDs: `read`, `edit`, `write`, `bash`, `glob`, `grep`, `webfetch`, `websearch`, `doom_loop`, etc.

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

If no permission configuration is provided, the following defaults apply:

```json
{
  "permission": {
    "read": "allow",
    "glob": "allow",
    "grep": "allow",
    "bash": "ask",
    "edit": "ask",
    "write": "ask",
    "webfetch": "allow",
    "websearch": "allow",
    "doom_loop": "ask",
    "skills": "allow"
  }
}
```

### `provider`

Reserved for future multi-provider registry configuration. Currently not used.

### `keybinding`

Customizes keyboard shortcuts. **Note:** The keybinds system is not yet implemented. This section is reserved for future use.

Example (planned structure):

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

Configures external skill sources. Skills are loaded from local directories or remote URLs.

```json
{
  "skills": {
    "paths": ["~/.config/chatorai/skills"],
    "urls": [
      "https://example.com/skills-index.json",
      {
        "url": "https://another.com/skills.json",
        "cache_ttl": 3600,
        "api_key": "optional_key"
      }
    ]
  }
}
```

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
