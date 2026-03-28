#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
# libcss/desktop — Linux Desktop Integration Installer
#
# Generic installer for any Electron app built with
# the libcss/desktop scaffold. Configure the variables
# below to match your application.
# ─────────────────────────────────────────────────────
set -e

# ╔═══════════════════════════════════════════════════╗
# ║  APP CONFIGURATION — Change these for your app    ║
# ╚═══════════════════════════════════════════════════╝
APP_NAME="Inferno Terminal"
APP_SLUG="inferno-terminal"          # lowercase, no spaces
APP_COMMENT="Hellish terminal emulator"
APP_CATEGORIES="System;TerminalEmulator"
APP_KEYWORDS="terminal;console;shell;inferno"
ICON_FILE="icon.svg"                 # relative to electron/ folder
BANNER_COLOR="1;31"                  # ANSI color for banner
BANNER_NAME_COLOR="1;33"
BANNER_ICON="☠"

# ── Derived paths (don't edit) ────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"
ELECTRON_DIR="$APP_DIR/electron"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"

# ── Banner ────────────────────────────────────────────
echo -e "\033[${BANNER_COLOR}m"
echo "  ╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲"
echo -e "  \033[${BANNER_NAME_COLOR}m${BANNER_ICON}  ${APP_NAME} — Desktop Setup\033[${BANNER_COLOR}m"
echo "  ╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱"
echo -e "\033[0m"

# 1. Install npm deps if needed
if [ ! -d "$APP_DIR/node_modules" ]; then
  echo "→ Installing npm dependencies..."
  cd "$APP_DIR" && npm install
fi

# 2. Create directories
mkdir -p "$DESKTOP_DIR" "$ICON_DIR"

# 3. Copy icon
if [ -f "$ELECTRON_DIR/$ICON_FILE" ]; then
  cp "$ELECTRON_DIR/$ICON_FILE" "$ICON_DIR/${APP_SLUG}.svg"
  echo "→ Icon installed to $ICON_DIR/${APP_SLUG}.svg"
else
  echo "⚠ Icon not found at $ELECTRON_DIR/$ICON_FILE — skipping"
fi

# 4. Generate .desktop file
cat > "$DESKTOP_DIR/${APP_SLUG}.desktop" << EOF
[Desktop Entry]
Name=${APP_NAME}
Comment=${APP_COMMENT}
Exec=${ELECTRON_DIR}/launch.sh
Icon=${APP_SLUG}
Terminal=false
Type=Application
Categories=${APP_CATEGORIES};
Keywords=${APP_KEYWORDS};
StartupWMClass=${APP_SLUG}
StartupNotify=true
EOF

chmod +x "$DESKTOP_DIR/${APP_SLUG}.desktop"
echo "→ Desktop launcher installed to $DESKTOP_DIR/${APP_SLUG}.desktop"

# 5. Update desktop database
if command -v update-desktop-database &>/dev/null; then
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

# 6. Validate
if command -v desktop-file-validate &>/dev/null; then
  if desktop-file-validate "$DESKTOP_DIR/${APP_SLUG}.desktop" 2>/dev/null; then
    echo "→ Desktop file validated successfully"
  fi
fi

echo ""
echo -e "\033[1;32m✓ Done! You can now find '${APP_NAME}' in your application menu.\033[0m"
echo -e "\033[0;90m  Or run: cd ${APP_DIR} && npm run electron\033[0m"
echo -e "\033[0;90m  Or run: npm run electron\033[0m"
