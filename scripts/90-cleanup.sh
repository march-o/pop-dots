#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

export DEBIAN_FRONTEND=noninteractive

SUDO="${SUDO:-sudo -n}"

if [[ "${NO_SUDO:-0}" -eq 1 ]]; then
  log "NO_SUDO=1 set; skipping apt autoremove."
  exit 0
fi

log "Running apt autoremove"
$SUDO apt-get autoremove -y

log "If you were added to the docker group, log out and back in for it to take effect."
