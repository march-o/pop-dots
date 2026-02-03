#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

KITTY_DIR="$HOME/.local/kitty.app"
KITTY_BIN="$KITTY_DIR/bin/kitty"
LOCAL_BIN="$HOME/.local/bin"
SYMLINK="$LOCAL_BIN/kitty"
DESKTOP_SRC="$KITTY_DIR/share/applications/kitty.desktop"
DESKTOP_DST="$HOME/.local/share/applications/kitty.desktop"
ICONS_SRC="$KITTY_DIR/share/icons/hicolor"
ICONS_DST="$HOME/.local/share/icons/hicolor"

log "Installing Kitty (official installer)"
if ! command -v curl >/dev/null 2>&1; then
  log "curl not available; skipping Kitty install."
  exit 0
fi

mkdir -p "$LOCAL_BIN"

# Avoid launching kitty during install (see kitty binary install docs).
if ! curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n; then
  log "Kitty installer failed."
  exit 1
fi

if [[ -x "$KITTY_BIN" ]]; then
  ln -sf "$KITTY_BIN" "$SYMLINK"
  log "Kitty installed at $KITTY_BIN"
else
  log "Kitty install completed, but binary not found at $KITTY_BIN."
fi

if [[ -f "$DESKTOP_SRC" ]]; then
  mkdir -p "$(dirname "$DESKTOP_DST")"
  cp -f "$DESKTOP_SRC" "$DESKTOP_DST"
  # Ensure the desktop entry points to the PATH-installed kitty and standard icon name.
  sed -i \
    -e 's|^Exec=.*|Exec=kitty|' \
    -e 's|^TryExec=.*|TryExec=kitty|' \
    -e 's|^Icon=.*|Icon=kitty|' \
    "$DESKTOP_DST"
  if [[ -d "$ICONS_SRC" ]]; then
    mkdir -p "$ICONS_DST"
    cp -fR "$ICONS_SRC/"* "$ICONS_DST/"
  fi
  log "Installed Kitty desktop entry"
fi
