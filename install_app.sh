#!/bin/bash
set -e

echo "Installing ChatORAI..."

# Require sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    exit 1
fi

# ---------------------------------------------------------
# 1. Find flutter reliably
# ---------------------------------------------------------

# Try from sudo user
if [ -n "$SUDO_USER" ]; then
    FLUTTER_BIN=$(sudo -u "$SUDO_USER" bash -c 'which flutter' 2>/dev/null || true)
fi

# Try root PATH
if [ -z "$FLUTTER_BIN" ]; then
    FLUTTER_BIN=$(which flutter 2>/dev/null || true)
fi

# Try common install locations
if [ -z "$FLUTTER_BIN" ]; then
    for p in \
        "/home/$SUDO_USER/Soft/flutter/bin/flutter" \
        "/home/$SUDO_USER/flutter/bin/flutter" \
        "/opt/flutter/bin/flutter" \
        "/usr/local/flutter/bin/flutter"
    do
        if [ -x "$p" ]; then
            FLUTTER_BIN="$p"
            break
        fi
    done
fi

# Final check
if [ -z "$FLUTTER_BIN" ]; then
    echo "❌ Flutter not found."
    echo "Make sure flutter works when you run: which flutter"
    exit 1
fi

export PATH="$(dirname "$FLUTTER_BIN"):$PATH"
echo "Using Flutter: $FLUTTER_BIN"

# ---------------------------------------------------------
# 2. Build application
# ---------------------------------------------------------
echo "Step 1: Building application..."
cd "$(dirname "$0")"

flutter build linux --release

echo "Build OK"

# ---------------------------------------------------------
# 3. Install files
# ---------------------------------------------------------
echo "Step 2: Installing files..."

install -d /usr/local/lib/chatorai
install -d /usr/local/bin

cp -r build/linux/x64/release/bundle/* /usr/local/lib/chatorai/

# ---------------------------------------------------------
# 4. Install icon
# ---------------------------------------------------------
echo "Step 3: Installing icon..."

# Try different icon filenames
for ICON_NAME in "chatorai_logo_black.png" "chatorai_logo.png" "chatorai_logo"; do
    if [ -f "assets/$ICON_NAME" ]; then
        ICON_SRC="assets/$ICON_NAME"
        break
    fi
done

ICON_DST="/usr/share/icons/hicolor/256x256/apps/chatorai.png"

mkdir -p "$(dirname "$ICON_DST")"

if [ -f "$ICON_SRC" ]; then
    if command -v convert &>/dev/null; then
        convert "$ICON_SRC" -resize 256x256 "$ICON_DST" || cp "$ICON_SRC" "$ICON_DST"
    else
        cp "$ICON_SRC" "$ICON_DST"
    fi
else
    echo "⚠️ Icon not found, creating placeholder"
    # Create a simple PNG placeholder (1x1 pixel transparent)
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > "$ICON_DST"
fi

# ---------------------------------------------------------
# 5. Test OpenGL compatibility
# ---------------------------------------------------------
echo "Step 4: Testing OpenGL compatibility..."

APP_PATH="/usr/local/lib/chatorai/chatorai"

USE_SOFT_GL=0

if ! "$APP_PATH" --version >/dev/null 2>&1; then
    echo "⚠️ Hardware OpenGL failed, enabling software rendering"
    USE_SOFT_GL=1
fi

# Create flag file if needed
if [ "$USE_SOFT_GL" -eq 1 ]; then
    touch /usr/local/lib/chatorai/.force_soft_gl
else
    rm -f /usr/local/lib/chatorai/.force_soft_gl
fi

# ---------------------------------------------------------
# 6. Create launcher
# ---------------------------------------------------------
echo "Step 5: Creating launcher..."

cat > /usr/local/bin/chatorai << 'EOF'
#!/bin/bash
INSTALL_DIR="/usr/local/lib/chatorai"

# Auto-switch to software rendering if needed.
# Reference the flag file by absolute path so we don't need to cd into the
# install directory — that would otherwise override the user's launch cwd,
# breaking Directory.current-based tooling (bash/glob/grep/read/write).
if [ -f "$INSTALL_DIR/.force_soft_gl" ]; then
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
fi

# Launch the binary by absolute path, preserving the caller's working directory.
exec "$INSTALL_DIR/chatorai" "$@"
EOF

chmod +x /usr/local/bin/chatorai

# ---------------------------------------------------------
# 7. Desktop entry
# ---------------------------------------------------------
echo "Step 6: Creating desktop entry..."

cat > /usr/share/applications/chatorai.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=ChatORAI
Comment=AI Chat Application
Exec=/usr/local/bin/chatorai
Icon=chatorai
Terminal=false
Categories=Utility;Network;Chat;
Keywords=AI;Chat;Assistant;OpenRouter;
StartupNotify=true
EOF

# ---------------------------------------------------------
# 8. Update icon cache
# ---------------------------------------------------------
echo "Step 7: Updating icon cache..."

update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true

echo ""
echo "✅ Installation complete!"
echo ""
echo "Run: chatorai"
echo ""
echo "To uninstall:"
echo "  sudo rm -rf /usr/local/lib/chatorai"
echo "  sudo rm /usr/local/bin/chatorai"
echo "  sudo rm /usr/share/applications/chatorai.desktop"
echo "  sudo rm /usr/share/icons/hicolor/256x256/apps/chatorai.png"
echo ""
