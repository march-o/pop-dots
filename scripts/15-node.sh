#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
NPM_LIST="$REPO_ROOT/packages/npm.txt"
NVM_SNIPPET='export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

if ! command -v curl >/dev/null 2>&1; then
  log "curl not available; skipping nvm/Codex install."
  exit 0
fi

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  log "Installing nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

ensure_nvm_init() {
  local target="$1"
  if [[ -f "$target" ]]; then
    if ! rg -q "NVM_DIR=.*\\.nvm" "$target"; then
      log "Adding nvm init to $target"
      {
        echo ""
        echo "# NVM"
        echo "$NVM_SNIPPET"
      } >> "$target"
    fi
  fi
}

ensure_nvm_init "$HOME/.zshrc"
ensure_nvm_init "$HOME/.bashrc"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  log "Loading nvm"
  # nvm relies on unset variables; avoid nounset issues.
  set +u
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
  log "Installing latest Node LTS"
  nvm install --lts
  log "Using Node LTS"
  nvm use --lts
  set -u
  if [[ -f "$NPM_LIST" ]]; then
    log "Installing npm globals from $NPM_LIST"
    awk '!/^[[:space:]]*($|#)/ {print $0}' "$NPM_LIST" | xargs -r npm install -g
  fi
fi
