#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------------------------
# ChatORAI one-command installer (end users, no Flutter required)
#
# Downloads a prebuilt Linux bundle from GitHub Releases and installs it to the
# current user's home (no sudo / no root needed):
#   - app:   ~/.local/share/chatorai
#   - launcher: ~/.local/bin/chatorai   (added to PATH if missing)
#   - desktop entry + icon under ~/.local/share
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AmidVoshakul/chatorai/main/install_chatorai.sh | bash
#   ./install_chatorai.sh                 # latest stable release
#   ./install_chatorai.sh --version 0.1.0 # specific version
#   ./install_chatorai.sh --help
# -----------------------------------------------------------------------------

REPO="AmidVoshakul/chatorai"

RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat <<EOF
ChatORAI Installer

Usage: install_chatorai.sh [options]

Options:
  -h, --help               Show this help message
  -v, --version <version>  Install a specific version (e.g. 0.1.0 or v0.1.0)
EOF
}

# ---------------------------------------------------------
# Argument parsing (opencode-style)
# ---------------------------------------------------------
VERSION=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            if [[ -n "${2:-}" ]]; then
                VERSION="$2"
                shift 2
            else
                echo -e "${RED}Error: --version requires a value${NC}"
                exit 1
            fi
            ;;
        *)
            echo "Warning: unknown option '$1'" >&2
            shift
            ;;
    esac
done

# ---------------------------------------------------------
# User-local install directories (no sudo)
# ---------------------------------------------------------
INSTALL_DIR="$HOME/.local/share/chatorai"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"

echo "Installing ChatORAI to $INSTALL_DIR ..."

# ---------------------------------------------------------
# 1. Detect architecture
# ---------------------------------------------------------
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_TRIPLE="x64" ;;
    aarch64 | arm64) ARCH_TRIPLE="arm64" ;;
    *) echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

# ---------------------------------------------------------
# 2. Resolve version / download URL
# ---------------------------------------------------------
if [ -z "$VERSION" ]; then
    echo "Resolving latest release..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
fi

if [ -z "$VERSION" ]; then
    echo -e "${RED}Could not determine latest version.${NC}"
    echo "   Try: ./install_chatorai.sh --version v0.1.0"
    echo "   Releases: https://github.com/$REPO/releases"
    exit 1
fi

# Normalize to a tag (assets are published under vX.Y.Z).
case "$VERSION" in
    v*) VERSION_TAG="$VERSION" ;;
    *)  VERSION_TAG="v$VERSION" ;;
esac

echo "Installing ChatORAI $VERSION_TAG for linux-$ARCH_TRIPLE..."

URL="https://github.com/$REPO/releases/download/${VERSION_TAG}/chatorai-linux-${ARCH_TRIPLE}-${VERSION_TAG}.tar.gz"
TMPDIR=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT
cd "$TMPDIR"

# ---------------------------------------------------------
# 3. Download + extract
# ---------------------------------------------------------
echo "Downloading $URL ..."
if ! curl -fL -o bundle.tar.gz "$URL"; then
    echo -e "${RED}Download failed. Check the version and your connection.${NC}"
    echo "   Available releases: https://github.com/$REPO/releases"
    exit 1
fi

echo "Extracting..."
mkdir -p bundle
tar -xzf bundle.tar.gz -C bundle

# Find the directory that holds the `chatorai` executable (expect exactly one).
mapfile -t BIN_MATCHES < <(find bundle -type f -name chatorai 2>/dev/null)
if [ "${#BIN_MATCHES[@]}" -ne 1 ]; then
    echo -e "${RED}Expected exactly one 'chatorai' binary in the archive, found ${#BIN_MATCHES[@]}.${NC}"
    exit 1
fi
BUNDLE_ROOT="$(dirname "${BIN_MATCHES[0]}")"
if [ ! -f "$BUNDLE_ROOT/chatorai" ]; then
    echo -e "${RED}Could not locate the ChatORAI executable in the archive.${NC}"
    exit 1
fi

# ---------------------------------------------------------
# 4. Install files
# ---------------------------------------------------------
echo "Installing files..."
install -d "$INSTALL_DIR"
install -d "$BIN_DIR"
rm -rf "$INSTALL_DIR"/*
cp -r "$BUNDLE_ROOT"/* "$INSTALL_DIR"/

# ---------------------------------------------------------
# 5. Create launcher + desktop entry
# ---------------------------------------------------------
echo "Creating launcher..."
cat > "$BIN_DIR/chatorai" << 'EOF'
#!/bin/bash
INSTALL_DIR="$HOME/.local/share/chatorai"

# Explicit override always wins.
if [ "$CHATORAI_FORCE_SOFT_GL" = "1" ] || [ -f "$INSTALL_DIR/.force_soft_gl" ]; then
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    exec "$INSTALL_DIR/chatorai" "$@"
fi
if [ "$CHATORAI_FORCE_SOFT_GL" = "0" ]; then
    exec "$INSTALL_DIR/chatorai" "$@"
fi

# Proactively check the OpenGL version once and cache the decision.
if command -v glxinfo >/dev/null 2>&1; then
    GLV="$(glxinfo 2>/dev/null | grep -m1 -i 'OpenGL version string' \
        | sed -n 's/^[^:]*: *\([0-9]\+\)\..*/\1/p')"
    if [ -n "$GLV" ] && [ "$GLV" -lt 3 ]; then
        touch "$INSTALL_DIR/.force_soft_gl" 2>/dev/null || true
        export LIBGL_ALWAYS_SOFTWARE=1
        export GALLIUM_DRIVER=llvmpipe
        exec "$INSTALL_DIR/chatorai" "$@"
    fi
fi

# Otherwise try hardware GL. If the GUI dies from a GL-related crash, retry with
# software rendering and remember it. Only auto-retry the GUI (no CLI args).
"$INSTALL_DIR/chatorai" "$@"
RC=$?
if { [ "$RC" = "139" ] || [ "$RC" = "134" ]; } && [ "$#" -eq 0 ]; then
    echo "chatorai: hardware OpenGL crashed (exit $RC); retrying with software rendering" >&2
    touch "$INSTALL_DIR/.force_soft_gl" 2>/dev/null || true
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    exec "$INSTALL_DIR/chatorai" "$@"
fi
exit $RC
EOF
chmod +x "$BIN_DIR/chatorai"

echo "Creating desktop entry..."
install -d "$APP_DIR"
cat > "$APP_DIR/chatorai.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=ChatORAI
Comment=AI Chat Application
Exec=$HOME/.local/bin/chatorai
Icon=chatorai
Terminal=false
Categories=Utility;Network;Chat;
Keywords=AI;Chat;Assistant;Multimodal;Multiagent;
StartupNotify=true
EOF

# ---------------------------------------------------------
# 6. Install icon (best-effort — never block the launcher)
# ---------------------------------------------------------
(
set +e
echo "Installing icon..."
ICON_DST="$ICON_DIR/chatorai.png"
mkdir -p "$ICON_DIR" 2>/dev/null || true

ICON_SRC=$(find "$INSTALL_DIR/data/flutter_assets/assets" \
    -maxdepth 1 -type f -name 'chatorai_logo*.png' 2>/dev/null | head -1 || true)
if [ -z "$ICON_SRC" ]; then
    ICON_SRC=$(find "$INSTALL_DIR" -maxdepth 2 -type f -name '*.png' 2>/dev/null | head -1 || true)
fi

if [ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ]; then
    if command -v convert >/dev/null 2>&1; then
        convert "$ICON_SRC" -resize 256x256 "$ICON_DST" 2>/dev/null || cp "$ICON_SRC" "$ICON_DST" 2>/dev/null || true
    else
        cp "$ICON_SRC" "$ICON_DST" 2>/dev/null || true
    fi
else
    echo "⚠️ Icon not found, creating placeholder"
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > "$ICON_DST" 2>/dev/null || true
fi
)

# ---------------------------------------------------------
# 7. OpenGL compatibility (install-time hint, best-effort)
# ---------------------------------------------------------
echo "Checking OpenGL compatibility..."
USE_SOFT_GL=0
if command -v glxinfo >/dev/null 2>&1; then
    GLX_OUT="$(glxinfo 2>/dev/null || true)"
    GL_VERSION_LINE="$(echo "$GLX_OUT" | grep -m1 -i 'OpenGL version string' || true)"
    GL_MAJOR="$(echo "$GL_VERSION_LINE" | sed -n 's/^[^:]*: *\([0-9]\+\)\..*/\1/p')"

    if [ -z "$GLX_OUT" ] \
       || echo "$GLX_OUT" | grep -qiE 'renderer string:.*(llvmpipe|softpipe|swrast)'; then
        USE_SOFT_GL=1
    elif [ -n "$GL_MAJOR" ] && [ "$GL_MAJOR" -lt 3 ]; then
        echo "   Detected OpenGL < 3.0 (${GL_MAJOR}.x) — enabling software rendering"
        USE_SOFT_GL=1
    else
        echo "   OpenGL >= 3.0 detected"
    fi
else
    echo "   glxinfo not available; the launcher will auto-detect at runtime"
fi

if [ "$USE_SOFT_GL" -eq 1 ]; then
    touch "$INSTALL_DIR/.force_soft_gl" 2>/dev/null || true
    echo "   Software rendering enabled. To force hardware GL later:"
    echo "     rm $INSTALL_DIR/.force_soft_gl"
else
    rm -f "$INSTALL_DIR/.force_soft_gl" 2>/dev/null || true
fi

# ---------------------------------------------------------
# 8. Ensure ~/.local/bin is on PATH
# ---------------------------------------------------------
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo "Note: $BIN_DIR is not on your PATH. Add it to your shell profile:"
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac

# ---------------------------------------------------------
# 9. Update caches
# ---------------------------------------------------------
echo "Updating caches..."
update-desktop-database "$APP_DIR" 2>/dev/null || true
gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo ""
echo "✅ Installation complete!"
echo ""
echo "Run:            chatorai"
echo "Update later:   chatorai upgrade"
echo "Uninstall:      chatorai uninstall          (removes app only)"
echo "                chatorai uninstall --keep-data   (removes app, keeps data)"
echo ""
