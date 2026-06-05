# Quick Commands Reference

## 🚀 Development

### Run App
```bash
# Windows
flutter run -d windows

# Linux
flutter run -d linux

# Web
flutter run -d chrome

# Android (connected device)
flutter run -d android

# iOS (macOS only)
flutter run -d ios
```

### Build Release
```bash
# Windows
flutter build windows --release

# Linux
flutter build linux --release

# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Web
flutter build web --release

# iOS (macOS required)
flutter build ios --release
```

## 🔧 Development Tools

### Hot Reload
While app is running:
- Press `r` → Hot reload
- Press `R` → Hot restart
- Press `q` → Quit

### Testing
```bash
# Run all tests
flutter test

# Run specific test
flutter test test/test_name.dart

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Check for outdated dependencies
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade
```

## 📦 Dependencies

### Add Package
```bash
flutter pub add package_name
```

### Remove Package
```bash
flutter pub remove package_name
```

### Update All
```bash
flutter pub upgrade --major-versions
```

## 🪟 Windows-Specific

### Build and Install
```bash
# Build
flutter build windows --release

# Install (PowerShell as Admin)
PowerShell -ExecutionPolicy Bypass -File ".\install_app.ps1"

# Or using batch file (as Admin)
install_app.bat
```

### Clean Build
```bash
# Remove build artifacts
flutter clean

# Get dependencies again
flutter pub get

# Rebuild
flutter build windows --release
```

## 🐧 Linux-Specific

### Build and Install
```bash
# Build
flutter build linux --release

# Install (as root)
sudo ./install_app.sh

# Or manual
sudo cp -r build/linux/x64/release/bundle/* /usr/local/lib/chatorai/
sudo ln -sf /usr/local/lib/chatorai/chatorai /usr/local/bin/chatorai
```

### Dependencies (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2
```

## 📱 Android

### Build APK
```bash
flutter build apk --release
```

### Build App Bundle
```bash
flutter build appbundle --release
```

### Install on Device
```bash
# Install directly
flutter install -d android_device_id

# List devices
flutter devices
```

### Keystore Setup
```bash
# Create keystore (one time)
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Place in android/app/ and configure android/key.properties
```

## 🌐 Web

### Build
```bash
flutter build web --release
```

### Run with specific port
```bash
flutter run -d chrome --web-port 8080
```

### Deploy to GitHub Pages
```bash
# Build
flutter build web --release

# Clone your gh-pages branch
cd build/web
git init
git add .
git commit -m "Deploy"
git push -f origin main:gh-pages
```

## 🧪 Testing

### Unit + Widget Tests
```bash
# All tests (flat test/ directory, no subfolders)
flutter test

# Single file
flutter test test/test_chat_input_provider.dart
```

### Integration Test
```bash
# Standalone Dart script (requires .env)
dart integration_test/api_test.dart

# NOT: flutter test integration_test/
```

### Test Coverage
```bash
# Generate coverage
flutter test --coverage

# View coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 🔍 Debugging

### Verbose Output
```bash
flutter run -d windows --verbose
```

### View Logs
```bash
flutter logs
```

### Debug in VS Code
1. Open project in VS Code
2. Press F5 or click "Run → Start Debugging"
3. Select target platform

### Debug in Android Studio
1. Open project
2. Run → Edit Configurations
3. Add Flutter configuration
4. Select device and debug

## 🚀 CI/CD

### GitHub Actions Example
```yaml
name: Flutter CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter test
      - run: flutter build linux --release
```

## 📊 Performance

### Profile App
```bash
flutter run --profile -d windows
```

### Memory Usage
```bash
# Windows
Get-Process chatorai | Select-Object WS

# Linux
ps -o pid,rss,vsz,cmd -C chatorai
```

### Build Time
```bash
# Time the build
time flutter build windows --release
```

## 🛠️ Troubleshooting

### Clean Everything
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### Doctor
```bash
flutter doctor
flutter doctor -v
```

### Reset
```bash
# Remove all generated files
rm -rf .dart_tool/
rm -rf build/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies

# Rebuild
flutter pub get
flutter run
```

## 📝 File Structure

```
chatorai/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── themes/
│   ├── utils/
│   └── widgets/
├── test/
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
├── assets/
├── .env
├── pubspec.yaml
└── README.md
```

## 🎯 Quick Actions

| Action | Command |
|--------|---------|
| Run | `flutter run -d windows` |
| Build | `flutter build windows --release` |
| Test | `flutter test` |
| Analyze | `flutter analyze` |
| Format | `flutter format .` |
| Clean | `flutter clean && flutter pub get` |
| Upgrade | `flutter pub upgrade --major-versions` |
| Doctor | `flutter doctor` |

## 📞 Help

- **Documentation**: [README.md](README.md)
- **Windows Setup**: [WINDOWS_SETUP.md](WINDOWS_SETUP.md)
- **Russian Guide**: [README_RU.md](README_RU.md)
- **Flutter Docs**: https://flutter.dev/docs
- **Pub Packages**: https://pub.dev
