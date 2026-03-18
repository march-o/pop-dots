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

if [[ ! -f "$PIPX_LIST" ]]; then
  log "No pipx package list at $PIPX_LIST; skipping."
  exit 0
fi

if ! command -v uv >/dev/null 2>&1; then
  log "uv not found; skipping tool installs."
  exit 0
fi

log "Installing uv tools from $PIPX_LIST"
installed="$(uv tool list 2>/dev/null | awk '{print $1}')"

while IFS= read -r pkg; do
  if [[ "$pkg" =~ ^[[:space:]]*$ ]] || [[ "$pkg" =~ ^[[:space:]]*# ]]; then
    continue
  fi
  if printf '%s\n' "$installed" | grep -qx "$pkg"; then
    log "uv tool already installed: $pkg"
    continue
  fi
  uv tool install "$pkg"
done < "$PIPX_LIST"
