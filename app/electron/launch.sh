#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
# Inferno Terminal — Desktop Launch Script
#
# This script is invoked by the .desktop launcher.
# It ensures PATH is correct (sources profile if needed),
# sets Electron flags for Linux compatibility,
# and starts the Electron app.
#
# NOTE: We intentionally do NOT use set -e here.
# When launched from a desktop menu, stderr/stdout go
# nowhere — a silent exit is worse than a partial start.
# All errors are logged to $LOG_FILE for debugging.
# ─────────────────────────────────────────────────────

# ── Logging ──
LOG_DIR="$HOME/.local/share/inferno-terminal"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/launch.log"

# Rotate log if > 100KB
if [[ -f "$LOG_FILE" ]] && (( $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) > 102400 )); then
  mv "$LOG_FILE" "$LOG_FILE.old" 2>/dev/null
fi

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }
die() { log "FATAL: $*"; notify-send "Inferno Terminal" "$*" 2>/dev/null || true; exit 1; }

log "=== Launch started (PID $$) ==="

# ── Resolve app directory (next to this script's parent) ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
log "APP_DIR=$APP_DIR"

# ── Source shell profile if node isn't on PATH ──
if ! command -v node &>/dev/null; then
  log "node not on PATH, sourcing profiles…"
  for profile in "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$profile" ]]; then
      log "  sourcing $profile"
      source "$profile" 2>/dev/null || true
      command -v node &>/dev/null && break
    fi
  done
fi

# nvm support
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  log "Loading nvm…"
  source "$HOME/.nvm/nvm.sh" 2>/dev/null || true
fi

# Volta support
if [[ -d "$HOME/.volta" ]]; then
  export PATH="$HOME/.volta/bin:$PATH"
fi

# fnm support
if command -v fnm &>/dev/null; then
  eval "$(fnm env 2>/dev/null)" 2>/dev/null || true
fi

# ── Verify node is available ──
if ! command -v node &>/dev/null; then
  log "node still not found, scanning common paths…"
  for p in /usr/local/bin /usr/bin /snap/bin "$HOME/.local/bin"; do
    if [[ -x "$p/node" ]]; then
      export PATH="$p:$PATH"
      log "  found node at $p"
      break
    fi
  done
fi

if ! command -v node &>/dev/null; then
  die "Node.js not found. Please install Node.js."
fi

log "node=$(command -v node) version=$(node --version 2>/dev/null)"

# ── Resolve the Electron binary directly (avoid npx overhead) ──
ELECTRON_BIN="$APP_DIR/node_modules/.bin/electron"
if [[ ! -x "$ELECTRON_BIN" ]]; then
  # Fallback: try the dist binary
  ELECTRON_BIN="$APP_DIR/node_modules/electron/dist/electron"
fi
if [[ ! -x "$ELECTRON_BIN" ]]; then
  die "Electron binary not found in $APP_DIR/node_modules"
fi

log "ELECTRON_BIN=$ELECTRON_BIN"

# ── Clean stale Electron singleton locks ──
# If a previous instance crashed, the SingletonLock symlink is left behind
# pointing to a dead PID. This prevents Electron's requestSingleInstanceLock()
# from succeeding, causing new launches to silently quit.
LOCK_DIR="$HOME/.config/inferno-terminal"
LOCK_FILE="$LOCK_DIR/SingletonLock"
if [[ -L "$LOCK_FILE" ]]; then
  LOCK_TARGET="$(readlink "$LOCK_FILE" 2>/dev/null)"
  # Lock target format: hostname-PID
  LOCK_PID="${LOCK_TARGET##*-}"
  if [[ -n "$LOCK_PID" ]] && ! kill -0 "$LOCK_PID" 2>/dev/null; then
    log "Removing stale SingletonLock (dead PID $LOCK_PID)"
    rm -f "$LOCK_FILE" "$LOCK_DIR/SingletonSocket" 2>/dev/null
  fi
fi

# ── Electron flags for Linux desktop compatibility ──
export ELECTRON_DISABLE_SANDBOX=1
ELECTRON_FLAGS=""

# If running under Wayland, tell Electron to use Ozone/Wayland
if [[ "$XDG_SESSION_TYPE" = "wayland" ]]; then
  ELECTRON_FLAGS="--enable-features=UseOzonePlatform --ozone-platform=wayland"
  log "Wayland detected, adding Ozone flags"
fi

# ── Launch ──
cd "$APP_DIR" || die "Cannot cd to $APP_DIR"
log "Launching: $ELECTRON_BIN . $ELECTRON_FLAGS $*"
exec "$ELECTRON_BIN" . $ELECTRON_FLAGS "$@" >> "$LOG_FILE" 2>&1
