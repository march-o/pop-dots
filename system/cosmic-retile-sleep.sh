#!/bin/sh
# Fix broken COSMIC tiling after suspend.
# Toggles autotile off then on via config file; cosmic-config picks up the
# change via inotify and the compositor retiles all windows.

[ "$1" = "post" ] || exit 0

case "$2" in
    suspend|hibernate|hybrid-sleep|suspend-then-hibernate) ;;
    *) exit 0 ;;
esac

# Wait for displays to reconnect and the compositor to process them.
sleep 2

COSMIC_USER=$(ps -C cosmic-comp -o user= 2>/dev/null | head -n1 | tr -d ' ')
[ -n "$COSMIC_USER" ] || exit 0

AUTOTILE="/home/${COSMIC_USER}/.config/cosmic/com.system76.CosmicComp/v1/autotile"
[ -f "$AUTOTILE" ] || exit 0
[ "$(cat "$AUTOTILE")" = "true" ] || exit 0

printf 'false' > "$AUTOTILE"
sleep 1
printf 'true' > "$AUTOTILE"
