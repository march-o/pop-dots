#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

export DEBIAN_FRONTEND=noninteractive

SUDO="${SUDO:-sudo -n}"

if [[ "${NO_SUDO:-0}" -eq 1 ]]; then
  log "NO_SUDO=1 set; skipping core package install."
  exit 0
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
APT_LIST="$REPO_ROOT/packages/apt.txt"

log "Updating apt index"
$SUDO apt-get update

if [[ -f "$APT_LIST" ]]; then
  log "Installing apt packages from $APT_LIST"
  # Install packages, skipping blank lines and comments.
  awk '!/^[[:space:]]*($|#)/ {print $0}' "$APT_LIST" | xargs -r $SUDO apt-get install -y
fi

if ! command -v flatpak >/dev/null 2>&1; then
  log "Installing flatpak"
  $SUDO apt-get install -y flatpak
fi

if ! flatpak remotes | awk '{print $1}' | grep -qx flathub; then
  log "Adding flathub remote"
  $SUDO flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi
