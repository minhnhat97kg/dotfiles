#!/usr/bin/env bash
set -euo pipefail

# Waybar (menu bar) and waybar-dock (dock) are each launched and supervised by
# their own systemd unit. This watcher only restarts the relevant unit when
# its config or style changes on disk (e.g. a `home-manager switch` swapping
# the symlink) — it never launches or babysits either waybar process itself.
CONFIG_DIR="$HOME/.config/waybar"

watch() {
    local svc="$1"; shift
    while inotifywait -qq -e close_write,move,create,delete "$@"; do
        sleep 0.1
        systemctl --user restart "$svc" || true
    done
}

watch waybar.service "$CONFIG_DIR/config.jsonc" "$CONFIG_DIR/style.css" &
watch waybar-dock.service "$CONFIG_DIR/dock.jsonc" "$CONFIG_DIR/dock.css" &
wait -n
