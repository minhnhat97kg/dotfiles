#!/usr/bin/env bash
# Restore previously focused window for the current space
set -euo pipefail
space=$(yabai -m query --spaces --space | jq -r '.index') || exit 0
file="$TMPDIR/yabai-focus/space_$space"
[ -f "$file" ] || exit 0
win=$(cat "$file")
# Check window still exists in this space
if yabai -m query --windows --window "$win" >/dev/null 2>&1; then
  yabai -m window --focus "$win" || true
fi