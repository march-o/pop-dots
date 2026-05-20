#!/bin/sh
# Fix broken COSMIC tiling after suspend.
# Toggles autotile off then on via config file; cosmic-config picks up the
# change via inotify and the compositor retiles all windows.
# Also reloads kitty config so window_alert_on_bell takes effect on resume.

[ "$1" = "post" ] || exit 0

case "$2" in
    suspend|hibernate|hybrid-sleep|suspend-then-hibernate) ;;
    *) exit 0 ;;
esac

log() { logger -t cosmic-retile "$1"; }

log "resume detected, starting post-suspend fixes"

COSMIC_USER=$(ps -C cosmic-comp -o user= 2>/dev/null | head -n1 | tr -d ' ')
if [ -z "$COSMIC_USER" ]; then
    log "cosmic-comp not running, skipping"
    exit 0
fi

log "COSMIC session user: $COSMIC_USER"

# Reload kitty config so settings like window_alert_on_bell take effect.
# SIGUSR1 triggers a config reload in all running kitty processes.
KITTY_PIDS=$(pgrep -u "$COSMIC_USER" -x kitty 2>/dev/null || true)
if [ -n "$KITTY_PIDS" ]; then
    log "sending SIGUSR1 to kitty pids: $KITTY_PIDS"
    # shellcheck disable=SC2086
    kill -USR1 $KITTY_PIDS 2>/dev/null || true
fi

# Wait for displays to reconnect and the compositor to process them.
sleep 2

AUTOTILE="/home/${COSMIC_USER}/.config/cosmic/com.system76.CosmicComp/v1/autotile"
if [ ! -f "$AUTOTILE" ]; then
    log "autotile config not found at $AUTOTILE, skipping retile"
    exit 0
fi

if [ "$(cat "$AUTOTILE")" != "true" ]; then
    log "autotile is not enabled, skipping retile"
    exit 0
fi

log "toggling autotile to force retile"
printf 'false' > "$AUTOTILE"
sleep 1
printf 'true' > "$AUTOTILE"
log "done"
