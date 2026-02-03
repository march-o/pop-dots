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

export DEBIAN_FRONTEND=noninteractive
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes"
export SUDO="sudo -n"

if [[ "$NO_SUDO" -eq 0 ]]; then
  banner "Checking sudo"
  if ! sudo -n true 2>/dev/null; then
    echo "sudo credentials are not cached. Run 'sudo -v' in another terminal or use --no-sudo."
    exit 1
  fi

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
  $SUDO apt-get update
  $SUDO apt-get install -y git curl ca-certificates gnupg lsb-release
fi

banner "Installing chezmoi"
mkdir -p "$HOME/.local/bin"
if ! command -v chezmoi >/dev/null 2>&1; then
  sh -c "$(curl -fsSL https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

export PATH="$HOME/.local/bin:$PATH"

banner "Initializing chezmoi source"
if [[ -d "$REPO" ]]; then
  CHEZMOI_SRC="$REPO"
else
  # Initialize source without applying to avoid writing to $HOME.
  chezmoi init --force "$REPO"
  CHEZMOI_SRC="$(chezmoi source-path)"
fi

if [[ -d "$CHEZMOI_SRC/dotfiles" ]]; then
  if find "$CHEZMOI_SRC/dotfiles" -type f \
    ! -name 'README.md' \
    ! -name '.chezmoiignore' \
    -print -quit | grep -q .; then
    banner "Applying dotfiles"
    chezmoi apply --source "$CHEZMOI_SRC/dotfiles" --force
  else
    banner "Skipping dotfiles (empty)"
  fi
fi

banner "Running setup scripts"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/00-core.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/25-keyd.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/10-dev.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/12-shell.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/13-kitty.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/15-node.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/20-ui.sh"
NO_SUDO="$NO_SUDO" "$CHEZMOI_SRC/scripts/90-cleanup.sh"

banner "Done"
