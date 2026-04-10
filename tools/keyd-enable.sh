#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONF_SRC="$REPO_ROOT/system/keyd/default.conf"
CONF_DIR="/etc/keyd"
CONF_DST="$CONF_DIR/default.conf"

if [[ $EUID -eq 0 ]]; then
  echo "Do not run as root; script uses sudo internally." >&2
  exit 1
fi

if ! command -v keyd >/dev/null 2>&1; then
  echo "keyd is not installed. Run bootstrap.sh with KEYD=1 first." >&2
  exit 1
fi

if [[ ! -f "$CONF_SRC" ]]; then
  echo "Missing keyd config at $CONF_SRC" >&2
  exit 1
fi

sudo install -d -m 0755 "$CONF_DIR"
sudo install -m 0644 "$CONF_SRC" "$CONF_DST"
sudo systemctl enable --now keyd.service
sudo systemctl restart keyd.service
echo "keyd enabled."
