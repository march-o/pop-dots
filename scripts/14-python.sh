#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PIPX_LIST="$REPO_ROOT/packages/pipx.txt"

if ! command -v pipx >/dev/null 2>&1; then
  log "pipx not found; skipping pipx package installs."
  exit 0
fi

log "Ensuring pipx is on PATH"
pipx ensurepath >/dev/null 2>&1 || true

if [[ ! -f "$PIPX_LIST" ]]; then
  log "No pipx package list at $PIPX_LIST; skipping."
  exit 0
fi

log "Installing pipx packages from $PIPX_LIST"
installed="$(pipx list --short 2>/dev/null | awk '{print $1}')"

while IFS= read -r pkg; do
  if [[ "$pkg" =~ ^[[:space:]]*$ ]] || [[ "$pkg" =~ ^[[:space:]]*# ]]; then
    continue
  fi
  if printf '%s\n' "$installed" | grep -qx "$pkg"; then
    log "pipx package already installed: $pkg"
    continue
  fi
  pipx install "$pkg"
done < "$PIPX_LIST"
