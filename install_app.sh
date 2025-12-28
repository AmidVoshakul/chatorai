#!/bin/bash

# Simple installation script for Gen UI Chat AI
set -e

echo "Installing Gen UI Chat AI..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    exit 1
fi

# Build the application first
echo "Step 1: Building application..."
cd "$(dirname "$0")"
export PATH="/opt/flutter/bin:$PATH"
flutter build linux --release

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# Create directories
echo "Step 2: Creating directories..."
mkdir -p /usr/local/lib/gen-ui-chat-ai
mkdir -p /usr/local/bin

# Copy application files
echo "Step 3: Copying files..."
cp -r build/linux/x64/release/bundle/* /usr/local/lib/gen-ui-chat-ai/

# Create wrapper script
echo "Step 4: Creating launcher..."
cat > /usr/local/bin/gen-ui-chat-ai << 'EOF'
#!/bin/bash
export PATH="/opt/flutter/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/lib/gen-ui-chat-ai/lib:$LD_LIBRARY_PATH"
cd /usr/local/lib/gen-ui-chat-ai
exec ./gen_ui_chat_ai "$@"
EOF

chmod +x /usr/local/bin/gen-ui-chat-ai

# Create desktop launcher with proper environment
cat > /usr/local/lib/gen-ui-chat-ai/gen-ui-chat-ai-launcher << 'EOF'
#!/bin/bash
# Set environment variables
export PATH="/opt/flutter/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/lib/gen-ui-chat-ai/lib:$LD_LIBRARY_PATH"
export DISPLAY=${DISPLAY:-:0}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime-$(whoami)}
export HOME=${HOME:-/home/$(whoami)}
export USER=${USER:-$(whoami)}

# Fix for OpenGL issues in some environments
export MESA_GL_VERSION_OVERRIDE=3.3
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

# Change to app directory
cd /usr/local/lib/gen-ui-chat-ai

# Execute the application
exec ./gen_ui_chat_ai "$@"
EOF

chmod +x /usr/local/lib/gen-ui-chat-ai/gen-ui-chat-ai-launcher

# Create desktop file
echo "Step 5: Creating desktop entry..."
cat > /usr/share/applications/gen-ui-chat-ai.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Gen UI Chat AI
Comment=AI Chat UI Application
Exec=/usr/local/lib/gen-ui-chat-ai/gen-ui-chat-ai-launcher
Icon=gen-ui-chat-ai
Terminal=false
Categories=Utility;Network;Chat;
Keywords=AI;Chat;Assistant;OpenRouter;
StartupNotify=true
EOF

# Also create a terminal-based version as fallback
cat > /usr/share/applications/gen-ui-chat-ai-terminal.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Gen UI Chat AI (Terminal)
Comment=AI Chat UI Application - Terminal version
Exec=gnome-terminal -e "/usr/local/bin/gen-ui-chat-ai"
Icon=gen-ui-chat-ai
Terminal=false
Categories=Utility;Network;Chat;
Keywords=AI;Chat;Assistant;OpenRouter;
EOF

# Create icon
echo "Step 6: Installing icon..."
mkdir -p /usr/share/icons/hicolor/256x256/apps/
# Create a simple icon using ImageMagick if available
if command -v convert &> /dev/null; then
    convert -size 256x256 xc:"#4A90E2" -pointsize 100 -fill white -gravity center -annotate +0+0 "AI" /usr/share/icons/hicolor/256x256/apps/gen-ui-chat-ai.png
else
    # Create a placeholder
    echo "Note: Creating placeholder icon. Install ImageMagick for better icon."
    echo "AI" > /usr/share/icons/hicolor/256x256/apps/gen-ui-chat-ai.png
fi

# Update icon cache
echo "Step 7: Updating icon cache..."
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true

# Update desktop database
echo "Step 8: Updating desktop database..."
update-desktop-database /usr/share/applications 2>/dev/null || true

echo ""
echo "✅ Installation complete!"
echo ""
echo "You can now:"
echo "  - Run from terminal: gen-ui-chat-ai"
echo "  - Find in applications menu: 'Gen UI Chat AI'"
echo "  - Or run: /usr/local/lib/gen-ui-chat-ai/gen_ui_chat_ai"
echo ""
echo "To uninstall:"
echo "  sudo rm -rf /usr/local/lib/gen-ui-chat-ai"
echo "  sudo rm /usr/local/bin/gen-ui-chat-ai"
echo "  sudo rm /usr/share/applications/gen-ui-chat-ai.desktop"
echo "  sudo rm /usr/share/icons/hicolor/256x256/apps/gen-ui-chat-ai.png"