#!/usr/bin/env bash
set -euo pipefail
name="$1"  # brightness or volume

state_dir="$HOME/.cache/waybar"
mkdir -p "$state_dir"
state_file="$state_dir/${name}_expanded"

if [ -f "$state_file" ]; then
    rm -f "$state_file"
else
    touch "$state_file"
fi

case "$name" in
    brightness) pkill -RTMIN+8 waybar ;;
    volume)     pkill -RTMIN+9 waybar ;;
esac
