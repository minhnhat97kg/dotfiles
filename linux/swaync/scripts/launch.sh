#!/usr/bin/env bash
# Start swaync against a RUNTIME COPY of its config, then draw the toggle labels
# from live state.
#
# Why a copy: the toggle buttons spell their state with characters ("[x] Wifi" /
# "[ ] Wifi"), which means editing the label in the config and reloading — and the
# managed ~/.config/swaync/config.json is a read-only nix store symlink. Same
# pattern, and the same reason, as waybar's scripts/launch.sh.
#
# We exec swaync so it stays the systemd unit's main process and Restart works.
set -euo pipefail

CONFIG_DIR="$HOME/.config/swaync"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/swaync"
RUNTIME_CFG="$RUNTIME_DIR/config.json"

mkdir -p "$RUNTIME_DIR"
install -m 0644 "$CONFIG_DIR/config.json" "$RUNTIME_CFG"

# Seed the labels before swaync reads the file — no reload, nothing is running yet.
"$CONFIG_DIR/scripts/toggle.sh" sync --no-reload

exec swaync -c "$RUNTIME_CFG" -s "$CONFIG_DIR/style.css"
