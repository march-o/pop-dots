#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $1"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
FLATPAK_LIST="$REPO_ROOT/packages/flatpak.txt"
DCONF_FILE="$REPO_ROOT/system/gnome.dconf"

log "Applying GNOME/COSMIC settings"
"$REPO_ROOT/system/gsettings.sh"

if [[ "${NO_SUDO:-0}" -eq 0 ]]; then
  if command -v update-alternatives >/dev/null 2>&1 && [[ -x /usr/bin/kitty ]]; then
    log "Setting x-terminal-emulator to kitty"
    if ! sudo update-alternatives --set x-terminal-emulator /usr/bin/kitty; then
      log "Failed to set x-terminal-emulator via update-alternatives."
    fi
  fi
else
  log "No-sudo mode: skipping update-alternatives for x-terminal-emulator."
fi

if [[ -s "$DCONF_FILE" ]]; then
  if command -v dconf >/dev/null 2>&1; then
    log "Loading dconf from $DCONF_FILE"
    dconf load / < "$DCONF_FILE"
  else
    log "dconf not available; skipping."
  fi
fi

if command -v flatpak >/dev/null 2>&1; then
  if [[ -f "$FLATPAK_LIST" ]]; then
    log "Installing Flatpaks from $FLATPAK_LIST"
    awk '!/^[[:space:]]*($|#)/ {print $0}' "$FLATPAK_LIST" | xargs -r -n1 flatpak install -y flathub
  fi
else
  log "flatpak not available; skipping."
fi

CHROME_DESKTOP="com.google.Chrome.desktop"
if command -v xdg-settings >/dev/null 2>&1 && command -v xdg-mime >/dev/null 2>&1; then
  if [[ -f "/var/lib/flatpak/exports/share/applications/$CHROME_DESKTOP" \
    || -f "$HOME/.local/share/flatpak/exports/share/applications/$CHROME_DESKTOP" \
    || -f "/usr/share/applications/$CHROME_DESKTOP" ]]; then
    log "Setting default browser to $CHROME_DESKTOP"
    if ! xdg-settings set default-web-browser "$CHROME_DESKTOP"; then
      log "Failed to set default browser via xdg-settings."
    fi
    if ! xdg-mime default "$CHROME_DESKTOP" x-scheme-handler/http; then
      log "Failed to set HTTP handler via xdg-mime."
    fi
    if ! xdg-mime default "$CHROME_DESKTOP" x-scheme-handler/https; then
      log "Failed to set HTTPS handler via xdg-mime."
    fi
  fi
fi
