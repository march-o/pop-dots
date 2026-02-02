#!/usr/bin/env bash
set -euo pipefail

banner() {
  echo ""
  echo "==> $1"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO=""
NO_SUDO=0

for arg in "$@"; do
  case "$arg" in
    --no-sudo)
      NO_SUDO=1
      ;;
    *)
      if [[ -z "$REPO" ]]; then
        REPO="$arg"
      fi
      ;;
  esac
done

REPO="${REPO:-$SCRIPT_DIR}"

if [[ "$NO_SUDO" -eq 0 ]]; then
  banner "Checking sudo"
  sudo -v

  # Keep sudo alive for the duration of the script.
  while true; do
    sleep 50
    sudo -n true
  done 2>/dev/null &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
else
  banner "No-sudo mode"
fi

if [[ "$NO_SUDO" -eq 0 ]]; then
  banner "Installing core packages"
  sudo apt-get update
  sudo apt-get install -y git curl ca-certificates gnupg lsb-release
fi

banner "Installing chezmoi"
mkdir -p "$HOME/.local/bin"
if ! command -v chezmoi >/dev/null 2>&1; then
  sh -c "$(curl -fsSL https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

export PATH="$HOME/.local/bin:$PATH"

banner "Initializing chezmoi"
if [[ -d "$REPO" ]]; then
  chezmoi init --apply --source "$REPO"
  CHEZMOI_SRC="$REPO"
else
  chezmoi init --apply "$REPO"
  CHEZMOI_SRC="$(chezmoi source-path)"
fi

if [[ -d "$CHEZMOI_SRC/dotfiles" ]]; then
  banner "Applying dotfiles"
  chezmoi apply --source "$CHEZMOI_SRC/dotfiles" --force
fi

banner "Running setup scripts"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/00-core.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/10-dev.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/12-shell.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/15-node.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/20-ui.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/90-cleanup.sh"

banner "Done"
