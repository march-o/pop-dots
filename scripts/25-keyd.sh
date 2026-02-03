#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

install_keyd() {
  if command -v keyd >/dev/null 2>&1; then
    return 0
  fi

  log "Installing keyd"
  $SUDO apt-get update
  if $SUDO apt-get install -y keyd; then
    return 0
  fi

  log "keyd not available in default repos; trying PPA"
  $SUDO apt-get install -y software-properties-common
  $SUDO add-apt-repository -y ppa:keyd-team/ppa
  $SUDO apt-get update
  $SUDO apt-get install -y keyd
}

if [[ -z "${KEYD:-}" ]]; then
  log "KEYD not set; skipping keyd setup."
  exit 0
fi

if [[ "${NO_SUDO:-0}" -eq 1 ]]; then
  log "NO_SUDO=1 set; skipping keyd setup."
  exit 0
fi

SUDO="${SUDO:-sudo -n}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONF_SRC="$REPO_ROOT/system/keyd/default.conf"
CONF_DIR="/etc/keyd"
CONF_DST="$CONF_DIR/default.conf"

if [[ ! -f "$CONF_SRC" ]]; then
  log "Missing keyd config template at $CONF_SRC"
  exit 1
fi

install_keyd

log "Installing keyd config to $CONF_DST"
$SUDO install -d -m 0755 "$CONF_DIR"
$SUDO install -m 0644 "$CONF_SRC" "$CONF_DST"

log "Enabling keyd service"
$SUDO systemctl enable --now keyd.service
$SUDO systemctl restart keyd.service
