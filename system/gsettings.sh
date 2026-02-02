#!/usr/bin/env bash
set -euo pipefail

have_schema() {
  gsettings list-schemas | grep -qx "$1"
}

if ! command -v gsettings >/dev/null 2>&1; then
  echo "gsettings not available; skipping."
  exit 0
fi

if ! have_schema org.gnome.desktop.peripherals.touchpad; then
  echo "Missing schema org.gnome.desktop.peripherals.touchpad; skipping."
else
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
fi

if ! have_schema org.gnome.desktop.peripherals.mouse; then
  echo "Missing schema org.gnome.desktop.peripherals.mouse; skipping."
else
  gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true
fi

if ! have_schema org.gnome.desktop.interface; then
  echo "Missing schema org.gnome.desktop.interface; skipping."
else
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  gsettings set org.gnome.desktop.interface enable-animations false
fi

if ! have_schema org.gnome.desktop.default-applications.terminal; then
  echo "Missing schema org.gnome.desktop.default-applications.terminal; skipping."
else
  gsettings set org.gnome.desktop.default-applications.terminal exec "kitty"
  gsettings set org.gnome.desktop.default-applications.terminal exec-arg ""
fi

# COSMIC (Wayland) uses its own config for touchpad settings.
if [[ "${XDG_CURRENT_DESKTOP:-}" == *COSMIC* ]]; then
  COSMIC_COMP_DIR="$HOME/.config/cosmic/com.system76.CosmicComp/v1"
  COSMIC_SRC="/usr/share/cosmic/com.system76.CosmicComp/v1/input_touchpad"
  COSMIC_DST="$HOME/.config/cosmic/com.system76.CosmicComp/v1/input_touchpad"
  COSMIC_ACTIONS_SRC="/usr/share/cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions"
  COSMIC_ACTIONS_DST="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions"

  mkdir -p "$COSMIC_COMP_DIR"
  echo "true" > "$COSMIC_COMP_DIR/autotile"
  echo "Global" > "$COSMIC_COMP_DIR/autotile_behavior"

  if [[ -f "$COSMIC_SRC" ]]; then
    mkdir -p "$(dirname -- "$COSMIC_DST")"
    sed -E \
      -e 's/natural_scroll:None/natural_scroll:Some(true)/' \
      -e 's/natural_scroll:Some\\(false\\)/natural_scroll:Some(true)/' \
      "$COSMIC_SRC" > "$COSMIC_DST"
  else
    echo "COSMIC touchpad defaults not found; skipping."
  fi

  if [[ -f "$COSMIC_ACTIONS_SRC" ]]; then
    mkdir -p "$(dirname -- "$COSMIC_ACTIONS_DST")"
    sed -E \
      -e 's/Terminal: \"[^\"]*\"/Terminal: \"kitty\"/' \
      "$COSMIC_ACTIONS_SRC" > "$COSMIC_ACTIONS_DST"
  else
    echo "COSMIC system actions not found; skipping."
  fi
fi
