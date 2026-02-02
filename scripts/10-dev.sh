#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

if [[ "${NO_SUDO:-0}" -eq 1 ]]; then
  log "NO_SUDO=1 set; skipping dev package install."
  exit 0
fi

have_pkg() {
  dpkg -s "$1" >/dev/null 2>&1
}

log "Updating apt index"
sudo apt-get update

if ! have_pkg docker.io; then
  log "Installing docker.io"
  sudo apt-get install -y docker.io
fi

if have_pkg docker-compose-plugin; then
  :
elif have_pkg docker-compose; then
  :
else
  log "Installing docker compose"
  if apt-cache show docker-compose-plugin >/dev/null 2>&1; then
    sudo apt-get install -y docker-compose-plugin
  else
    sudo apt-get install -y docker-compose
  fi
fi

if getent group docker >/dev/null 2>&1; then
  if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    log "Adding $USER to docker group"
    sudo usermod -aG docker "$USER"
  fi
fi

if [[ ! -f "$HOME/.gitconfig" ]]; then
  log "Setting global git defaults"
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global fetch.prune true
fi
