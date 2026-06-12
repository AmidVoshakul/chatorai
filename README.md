# ChatORAI

![Screenshot of ChatORAI interface](https://github.com/AmidVoshakul/chatorai/blob/main/screenshots/Screenshot_2025-12-30_01-04-32.png)

A modern AI chat application built with Flutter and Riverpod. Connect to any OpenAI-compatible API (OpenRouter, local models, custom endpoints) and chat with powerful language models.

**🇷🇺 Русская версия**: [README_RU.md](README_RU.md)

## ✨ Features

- **Multi-provider support** — Use OpenRouter, local LLMs, or any OpenAI-compatible endpoint
- **Agent system** — Invoke specialized subagents with `@mention` (explore, code-reviewer, general)
- **Tool execution** — AI can run shell commands, read/edit files, search code, fetch web content
- **Voice & camera** — Speech-to-text and image attachments
- **Markdown rendering** — Syntax highlighting, collapsible reasoning blocks
- **Dark & light themes** — Adaptive UI with smooth transitions
- **Multi-language** — 6 languages (en, ru, uk, zh, ja, ar) with RTL support
- **Local storage** — Chat history and settings persisted

## 🚀 Quick Start

### Prerequisites

- Flutter 3.41.0 (stable)
- Dart SDK 3.11.0+
- Linux users: install system libs (`libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2`)

### 1. Configure API

**For development** — copy `.env.example` to `.env` and add your API key:
```env
OPENROUTER_API_KEY=your_key_here
```
`.env` is gitignored and **not included in release builds**.

**For end users** — the app provides a settings screen to enter API key and base URL. Values are stored securely in `SharedPreferences`.

### 2. Install & Run

```bash
flutter pub get
flutter gen-l10n   # only after editing lib/l10n/*.arb
flutter analyze
flutter test
flutter run -d linux   # or windows, chrome, android, ios (macOS required)
```

That's it! The app will launch and you can start chatting.

## 📚 Documentation

For detailed information, see the docs directory:

- [Architecture](ARCHITECTURE.md) — System design and component boundaries
- [API Reference](docs/API.md) — Providers, services, models, tools
- [Commands](docs/COMMANDS.md) — CLI commands and `@` agent mentions
- [Environment](docs/ENVIRONMENT.md) — Setup and dependencies
- [Roadmap](docs/ROADMAP.md) — Completed milestones and future plans

## 🖥️ Installation Packages

### Linux

```bash
sudo ./install_app.sh
```

Installs to `/usr/local/lib/chatorai/` with desktop entry and `chatorai` command.

### Windows

```powershell
# Build first
flutter build windows --release

# Then run installer as Administrator
PowerShell -ExecutionPolicy Bypass -File ".\install_app.ps1"
```

Installs to `C:\Program Files\ChatORAI\` with Start Menu shortcut.

## 🔧 Development Commands

```bash
flutter pub get              # fetch dependencies
flutter gen-l10n             # regenerate localization strings
flutter analyze             # lint (tests excluded)
flutter test                # run unit and widget tests
flutter build <platform>    # build release bundle
```

## 🛡️ Security & Permissions

- **Dev vs Runtime**: `.env` is for development only; release users enter credentials in-app.
- **Tool permissions**: Controlled via `chatorai.json`. By default, `read`, `glob`, `grep` are allowed; others require confirmation.
- **No secret logging**: API keys and tokens are never printed to logs.
- **TLS enforced**: All external communication uses HTTPS.

## 🤝 Contributing

See `CONTRIBUTING.md` for git workflow, code style, and testing requirements.

## 📄 License

MIT
