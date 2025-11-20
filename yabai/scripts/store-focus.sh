#!/usr/bin/env bash
# Store currently focused window id per space
set -euo pipefail
win=$(yabai -m query --windows --window | jq -r '.id') || exit 0
space=$(yabai -m query --windows --window | jq -r '.space') || exit 0
[ -z "$win" ] && exit 0
mkdir -p "$TMPDIR/yabai-focus"
echo "$win" > "$TMPDIR/yabai-focus/space_$space"