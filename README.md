# Gen UI Chat AI

A modern AI chat interface with support for multiple models and voice input.

## 🌟 Features

- **Multiple AI Models** - Support for various models via OpenRouter
- **Voice Input** - Speech-to-text integration
- **Markdown & Code** - Advanced rendering with syntax highlighting
- **Dark/Light Themes** - Adaptive UI with Ubuntu design
- **Multi-language** - RTL support and localization
- **Local Storage** - Chat history and preferences

## 🚀 Quick Start

### 1. Configuration

Create `.env` file in project root:
```env
OPENROUTER_API_KEY=your_api_key_here
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
```

### 2. Development

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Build for Linux
flutter build linux
```

## 📦 Linux Installation

### Automatic (Recommended)

```bash
sudo ./install_app.sh
```

This installs:
- App to `/usr/local/lib/gen-ui-chat-ai/`
- Desktop entry and icon
- `gen-ui-chat-ai` command

### Manual

```bash
sudo cp -r build/linux/x64/release/bundle/* /usr/local/lib/gen-ui-chat-ai/
sudo ln -sf /usr/local/lib/gen-ui-chat-ai/gen_ui_chat_ai /usr/local/bin/gen-ui-chat-ai
```

### Run After Install

- **Menu**: Find "Gen UI Chat AI"
- **Terminal**: `gen-ui-chat-ai`

### Uninstall

```bash
sudo rm -rf /usr/local/lib/gen-ui-chat-ai
sudo rm /usr/local/bin/gen-ui-chat-ai
sudo rm /usr/share/applications/gen-ui-chat-ai.desktop
sudo rm /usr/share/icons/hicolor/256x256/apps/gen-ui-chat-ai.png
```

## 🔧 Building for Other Platforms

```bash
# Android
flutter build apk --release

# iOS (macOS required)
flutter build ios

# Web
flutter build web
```

## 📋 Dependencies

- `provider` - State management
- `speech_to_text` - Voice input
- `flutter_markdown_plus` - Markdown rendering
- `dio` - HTTP client
- `shared_preferences` - Local storage
- `image_picker` - Image selection
- `camera` - Camera access

## 🛠️ Development

```bash
# Tests
flutter test

# Hot reload
flutter run --hot-reload

# Analyze
flutter analyze
```

## 🐛 Troubleshooting

### Menu launch issues
```bash
# Test terminal launch
gen-ui-chat-ai

# Check installation
ls -la /usr/local/lib/gen-ui-chat-ai/
```

### Missing dependencies (Ubuntu/Debian)
```bash
sudo apt install libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2
```

## 📄 License

MIT License