#!/usr/bin/env bash
set -euo pipefail

# Waybar is launched and supervised by waybar.service. This watcher only
# restarts that service when the config or style changes on disk (e.g. a
# `home-manager switch` swapping the symlink) — it never launches or babysits
# waybar itself.
CONFIG_DIR="$HOME/.config/waybar"

while inotifywait -qq -e close_write,move,create,delete \
    "$CONFIG_DIR/config.jsonc" "$CONFIG_DIR/style.css"; do
    sleep 0.1
    systemctl --user restart waybar.service || true
done
