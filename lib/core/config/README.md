# Configuration System

## Overview

The config system loads and validates `chatorai.json` — the application-wide settings file.

### Config File Location (priority order)

1. Project-local: `<project>/.chatorai/chatorai.json`
2. Global: `~/.config/chatorai/chatorai.json`

### Config Schema

```json5
{
  "version": 1,
  "permission": {
    "default": "ask",
    "rules": [
      { "permission": "read", "pattern": "*", "action": "allow" },
      { "permission": "bash", "pattern": "*", "action": "ask" }
    ]
  },
  "keybinding": {
    "leader": "ctrl+x",
    "bindings": {
      "session_new": "ctrl+n",
      "app_exit": "ctrl+q"
    }
  },
  "skills": {
    "directories": [".chatorai/skills"],
    "enabled": true
  }
}
```

### Sections

| Section | Purpose | Used By |
|---------|---------|---------|
| `permission` | Tool permission rules | `PermissionService`, `ToolRegistry` |
| `keybinding` | Keyboard shortcuts | `KeybindManager` |
| `skills` | Skill directories | `SkillService` |

### Key Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `ConfigManager` | `config_manager.dart` | Loads, validates, parses config |
| `ConfigLoader` | `config_loader.dart` | Searches for config file |
| `chatorai_schema.dart` | `chatorai_schema.dart` | JSON Schema for validation |
| `config_provider.dart` | `config_provider.dart` | Riverpod provider |

### Usage

```dart
final config = ref.watch(configProvider);
config.when(
  data: (cfg) => cfg.permission['default'], // 'ask'
  loading: () => null,
  error: (_, __) => null,
);
```
