#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

export PATH="$HOME/.local/bin:$PATH"
UV_DEFAULT_PYTHON="${UV_DEFAULT_PYTHON:-3.12}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PIPX_LIST="$REPO_ROOT/packages/pipx.txt"

if ! command -v uv >/dev/null 2>&1; then
  if command -v curl >/dev/null 2>&1; then
    log "Installing uv (user-level)"
    mkdir -p "$HOME/.local/bin"
    curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh
  elif command -v wget >/dev/null 2>&1; then
    log "Installing uv (user-level)"
    mkdir -p "$HOME/.local/bin"
    wget -qO- https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh
  else
    log "curl/wget not found; skipping uv install."
  fi
else
  log "uv already installed"
fi

if command -v uv >/dev/null 2>&1 && [[ -n "$UV_DEFAULT_PYTHON" ]]; then
  log "Installing default Python via uv: $UV_DEFAULT_PYTHON"
  uv python install --default "$UV_DEFAULT_PYTHON"
fi

log "Ensuring pipx is on PATH"
if command -v pipx >/dev/null 2>&1; then
  pipx ensurepath >/dev/null 2>&1 || true
else
  log "pipx not found; skipping pipx package installs."
fi

if [[ ! -f "$PIPX_LIST" ]]; then
  log "No pipx package list at $PIPX_LIST; skipping."
  exit 0
fi

if ! command -v pipx >/dev/null 2>&1; then
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
