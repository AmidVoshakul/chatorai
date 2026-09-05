# ChatORAI

![Screenshot of ChatORAI interface](https://github.com/AmidVoshakul/chatorai/raw/main/screenshots/Screenshot_2025-12-30_01-04-32.png)

A personal AI workstation for working with projects through intelligent agents across desktop, terminal, and mobile.
Once core. Multiple interfaces. Your projects, your models, your agents.

**🇷🇺 Русская версия**: [README_RU.md](README_RU.md)

## ✨ Features

- **Multi-provider support** — Use OpenRouter, local LLMs, or any OpenAI-compatible endpoint
- **Agent system** — Invoke specialized subagents with `@mention` (explore, general)
- **Tool execution** — AI can run shell commands, read/edit files, search code, fetch web content
- **Voice & camera** — Speech-to-text and image attachments
- **Markdown rendering** — Syntax highlighting, collapsible reasoning blocks
- **Dark & light themes** — Adaptive UI with smooth transitions
- **Multi-language** — 6 languages (en, ru, uk, zh, ja, ar) with RTL support
- **Recent models** — A horizontal strip of your top-6 most recently and frequently used models on the model-selection screen
- **Context usage indicator** — Ring chip in the chat input status bar shows context usage; tap/hover for a detailed popup with token breakdown (input, output, reasoning, cache read/write, tool tokens), spent USD, and a compact session button
- **Local storage** — Chat history and settings persisted

## 🚀 Quick Start

### End Users (no Flutter required)

Install ChatORAI with a single command — prebuilt binaries are published to
[GitHub Releases](https://github.com/AmidVoshakul/chatorai/releases/latest):

**Linux (one-line installer):**

```bash
curl -fsSL https://raw.githubusercontent.com/AmidVoshakul/chatorai/main/install_chatorai.sh | bash
```

Alternative Linux formats from the release page: `chatorai-*.AppImage` (portable, just `chmod +x` and run) and `chatorai-*.deb` (`sudo apt install ./chatorai-*.deb`).

**Windows:** download `install_chatorai.ps1` or `install_chatorai.bat` from the release, or use the `chatorai-*.zip` directly.

**macOS:** download `chatorai-*.dmg` from the release and drag to Applications.

After install, update anytime with `chatorai upgrade`.

### Developers (build from source)

Prerequisites:

- Flutter 3.44.0 (stable)
- Dart SDK 3.11.0+
- Linux users: install system libs (`libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2`)

Configure API key:

**For development** — copy `.env.example` to `.env` and add your API key:

```env
OPENROUTER_API_KEY=sk-...
NVIDIA_API_KEY=nvapi-...
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

`.env` is gitignored and **not included in release builds**.

**For end users** — the app provides a settings screen to enter API key and base URL. Values are stored securely in `SharedPreferences`.

Build & run:

```bash
flutter pub get
flutter gen-l10n   # only after editing lib/l10n/*.arb
flutter analyze
flutter test
flutter run -d linux   # or windows, android, ios (macOS required for iOS)
LIBGL_ALWAYS_SOFTWARE=1 flutter run -d linux  # Linux software rendering
```

That's it! The app will launch and you can start chatting.

## 📚 Documentation

### Core Documentation

- [Architecture](ARCHITECTURE.md) — System design, component boundaries, and data flows
- [API Reference](docs/API.md) — Providers, services, models, and tools
- [Commands](docs/COMMANDS.md) — CLI commands and `@` agent mentions
- [Environment](docs/ENVIRONMENT.md) — Setup, dependencies, and platform notes
- [Configuration](docs/CONFIGURATION.md) — chatorai.json schema and options
- [Security](docs/SECURITY.md) — Permission system, secret handling, and trust boundaries
- [Platform Paths](docs/xdg-paths.md) — XDG-aware path resolution (Linux/macOS/Windows/mobile)

### Diagrams

- [Architecture Overview](docs/diagrams/architecture-overview.md) — Data flow, session pipeline, MCP topology, config resolution, install/upgrade flow
- [Session Core](docs/diagrams/sessions.md) — Drift ER diagram and SessionEvent state machine
- [Tool System](docs/diagrams/tools.md) — Tool registry, conditional registration, execution lifecycle
- [MCP Integration](docs/diagrams/mcp.md) — Transport topology, connection lifecycle, config models
- [CI / Release Pipeline](docs/diagrams/ci-release.md) — GitHub Actions workflow, artifact packaging, GitHub Release publication

### Platform Guides

- [Windows Setup](WINDOWS_SETUP.md) — Visual Studio, CMake, and Windows-specific troubleshooting
- [Privacy Policy](PRIVACY_POLICY.md) — Data handling and third-party services

### Community

- [Contributing](CONTRIBUTING.md) — Git workflow, code style, and testing requirements
- [Code of Conduct](CODE_OF_CONDUCT.md) — Community standards and enforcement

## 🖥️ Installation

Prebuilt binaries are published to [GitHub Releases](https://github.com/AmidVoshakul/chatorai/releases/latest) on every tagged version. **No Flutter SDK required** for end users.

### Linux (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/AmidVoshakul/chatorai/main/install_chatorai.sh | bash
```

Downloads the latest prebuilt bundle, installs to `~/.local/share/chatorai/` with a desktop entry and `chatorai` command. Or grab `chatorai-*.AppImage` (run directly) / `chatorai-*.deb` from the release page.

### Windows

Download `install_chatorai.ps1` or `install_chatorai.bat` from the release, or extract `chatorai-*.zip` to `C:\Program Files\ChatORAI\`. Adds Start Menu shortcut and PATH entry.

### macOS

Download `chatorai-*.dmg` from the release and drag ChatORAI to Applications.

### Update

```bash
chatorai upgrade
```

### Uninstall

```bash
chatorai uninstall
```

### CLI

ChatORAI is a single binary. `chatorai --help` lists commands (`stats`, `models`, `upgrade`, `--version`); `chatorai` with no args launches the GUI.

## 🛡️ Security & Permissions

- **Dev vs Runtime**: `.env` is for development only; release users enter credentials in-app.
- **Tool permissions**: Controlled via `chatorai.json`. By default, `read`, `glob`, `grep` are allowed; others require confirmation.
- **No secret logging**: API keys and tokens are never printed to logs.
- **TLS enforced**: All external communication uses HTTPS.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for git workflow, code style, and testing requirements.

If you enjoy using ChatORAI, you can also support the project by starring it on [GitHub](https://github.com/AmidVoshakul/chatorai) or sponsoring [AmidVoshakul](https://github.com/sponsors/AmidVoshakul).

## 📄 License

MIT
