#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Do not run as root; script uses sudo internally." >&2
  exit 1
fi

if ! systemctl list-unit-files keyd.service >/dev/null 2>&1 || \
   ! systemctl list-unit-files keyd.service | grep -q keyd.service; then
  echo "keyd service not found; nothing to disable." >&2
  exit 0
fi

sudo systemctl disable --now keyd.service
sudo rm -f /etc/keyd/default.conf
echo "keyd disabled."
