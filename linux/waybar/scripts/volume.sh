#!/usr/bin/env bash
set -euo pipefail
raw="$(wpctl get-volume @DEFAULT_AUDIO_SINK@)"
percent="$(echo "$raw" | awk '{printf "%d", $2*100}')"
muted="false"
echo "$raw" | grep -q MUTED && muted="true"
exec python3 "$(dirname "$0")/volume.py" "$percent" "$muted"
